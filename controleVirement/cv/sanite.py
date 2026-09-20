"""Controles de sanite du dossier cible, sans le dossier source.

Une ligne par constat : guid, fichier, type, gravite (KO / A_VERIFIER), detail.
"""
from cv.doublons import KO, A_VERIFIER


def iban_valide(iban: str) -> bool:
    """Cle de controle IBAN (ISO 7064 mod 97-10)."""
    s = "".join(iban.split()).upper()
    if len(s) < 15 or not s[:2].isalpha() or not s[2:4].isdigit():
        return False
    if not s.isalnum():
        return False
    s = s[4:] + s[:4]
    return int("".join(str(int(c, 36)) for c in s)) % 97 == 1


def _date_aammjj(date_jjmmaaaa: str) -> str:
    return date_jjmmaaaa[6:8] + date_jjmmaaaa[2:4] + date_jjmmaaaa[0:2]


def controle_sanite(guid, acks_parses, asc_names, oracle_rows, date, ls_out):
    """acks_parses : {nom: LotAck} ; asc_names : {nom: chemin} des signatures ; ls_out : contenu de LS_OUT.OK."""
    lignes = []

    def ajoute(fichier, type_, gravite, detail):
        lignes.append({"guid": guid, "fichier": fichier, "type": type_, "gravite": gravite, "detail": detail})

    if ls_out is None:
        ajoute("TALEND/LS_OUT.OK", "TALEND_SANS_RETOUR", A_VERIFIER, "fichier absent ou vide")
    elif ls_out.strip() != "0":
        ajoute("TALEND/LS_OUT.OK", "TALEND_KO", KO, f"code retour '{ls_out.strip()}' au lieu de 0")

    payeur_attendu = {r.nom_fichier_edf: r.iban_payeur for r in oracle_rows}
    references = set(payeur_attendu)
    attendu_aammjj = _date_aammjj(date)
    for nom, ack in sorted(acks_parses.items()):
        asc = asc_names.get(nom + ".asc")
        if asc is None or asc.stat().st_size == 0:
            ajoute(nom, "SIGNATURE_ABSENTE", KO, "pas de fichier .asc (signature PGP) ou fichier vide")
        if nom in references and payeur_attendu[nom] and ack.iban_payeur != payeur_attendu[nom]:
            ajoute(nom, "PAYEUR_DIFFERENT", KO,
                   f"payeur ACK '{ack.iban_payeur}' / Oracle '{payeur_attendu[nom]}'")
        if nom in references and not ack.virements:
            ajoute(nom, "ACK_VIDE", KO, "reference par Oracle mais aucun virement")
        if ack.date_creation and ack.date_creation != attendu_aammjj:
            ajoute(nom, "DATE_DIFFERENTE", A_VERIFIER,
                   f"cree le {ack.date_creation} (AAMMJJ) alors que la journee controlee est {date}")
        if ack.footer_count != len(ack.virements):
            ajoute(nom, "PIED_INCOHERENT", KO,
                   f"pied {ack.footer_count} virement(s) / {len(ack.virements)} enregistrement(s) 06")
        for v in ack.virements:
            if v.montant_cts <= 0:
                ajoute(nom, "MONTANT_NUL_OU_NEGATIF", KO, f"{v.nom} / {v.iban} : {v.montant_cts} cts")
            if not iban_valide(v.iban):
                ajoute(nom, "IBAN_INVALIDE", KO, f"{v.nom} : '{v.iban}'")
            if not v.bic.strip():
                ajoute(nom, "BIC_ABSENT", A_VERIFIER, f"{v.nom} / {v.iban}")
    return lignes
