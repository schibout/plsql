"""Mail de rapport : brouillon .eml (à ouvrir dans Outlook, destinataires et envoi à la main) ou envoi SMTP
direct quand la section [mail] de config.ini est renseignée. Commun aux onglets Virements et Prélèvements.

Module pur : ne lit aucune donnée métier, met en forme ce qu'on lui donne.
"""
from __future__ import annotations
import configparser
import mimetypes
import smtplib
from datetime import datetime
from email.message import EmailMessage
from email.utils import formatdate, make_msgid
from pathlib import Path

from oracle_refresh import CONFIG

DEFAUTS = {"smtp_hote": "", "smtp_port": "25", "expediteur": "", "destinataires_virements": "",
           "destinataires_prelevements": "", "destinataires_matin": ""}


def config_mail() -> dict:
    """Section [mail] de config.ini, complétée par les valeurs par défaut (tout vide = brouillon .eml seulement)."""
    cfg = configparser.ConfigParser(interpolation=None, inline_comment_prefixes=(";", "#"))
    if CONFIG.exists():
        cfg.read(CONFIG, encoding="utf-8")
    val = {k: (cfg.get("mail", k, fallback=v) or "").strip() for k, v in DEFAUTS.items()}
    val["smtp_port"] = int(val["smtp_port"] or 25)
    return val


def destinataires(cfg: dict, onglet: str) -> list[str]:
    """Adresses de la clé destinataires_<onglet>, séparées par ; ou , (liste vide si non renseignée)."""
    brut = cfg.get(f"destinataires_{onglet}", "") or ""
    return [a.strip() for a in brut.replace(",", ";").split(";") if a.strip()]


def composer(sujet: str, corps_html: str, corps_texte: str, pieces: list[Path] = (),
             expediteur: str = "", destinataires: list[str] = ()) -> EmailMessage:
    """Message multipart : texte + HTML, pièces jointes lues sur disque. Sans expéditeur ni destinataire,
    c'est un brouillon que le client mail complétera."""
    msg = EmailMessage()
    msg["Subject"] = sujet
    msg["Date"] = formatdate(localtime=True)
    msg["Message-ID"] = make_msgid(domain="odat-watch.local")
    if expediteur:
        msg["From"] = expediteur
    if destinataires:
        msg["To"] = ", ".join(destinataires)
    msg["X-Unsent"] = "1"          # Outlook ouvre le .eml en mode composition
    msg.set_content(corps_texte)
    msg.add_alternative(corps_html, subtype="html")
    for piece in pieces:
        piece = Path(piece)
        if not piece.is_file():
            continue
        ctype, _ = mimetypes.guess_type(piece.name)
        maintype, subtype = (ctype or "application/octet-stream").split("/", 1)
        msg.add_attachment(piece.read_bytes(), maintype=maintype, subtype=subtype, filename=piece.name)
    return msg


def eml(msg: EmailMessage) -> bytes:
    """Le message tel qu'un client mail le lit (fichier .eml)."""
    return bytes(msg)


def envoyer(msg: EmailMessage, cfg: dict) -> str:
    """Envoi SMTP sans authentification (relais interne). Lève si [mail] smtp_hote est vide."""
    if not cfg.get("smtp_hote"):
        raise RuntimeError("Envoi impossible : [mail] smtp_hote n'est pas renseigné dans config.ini.")
    if not msg["To"]:
        raise RuntimeError("Envoi impossible : aucun destinataire.")
    del msg["X-Unsent"]
    with smtplib.SMTP(cfg["smtp_hote"], cfg["smtp_port"], timeout=30) as smtp:
        smtp.send_message(msg)
    return f"Envoyé à {msg['To']} le {datetime.now():%d/%m/%Y %H:%M} via {cfg['smtp_hote']}."


def nom_fichier(prefixe: str, date_txt: str) -> str:
    return f"{prefixe}_{date_txt}_{datetime.now():%H%M%S}.eml"
