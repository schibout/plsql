#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""demiflux2.py - Lecture du second demi-flux d'un export (dossier TARGET)

Un export se presente en deux demi-flux qui portent le meme identifiant
d'instance Talend :

    DDMMYYYY_TYPE_FOLIO\\SOURCE\\<instance>\\   demi-flux 1, amont
    DDMMYYYY_TYPE_FOLIO\\TARGET\\<instance>\\   demi-flux 2, vers Oracle

Les controles ctl_fac02*.py et ctl_ecritures_gl.py ne lisent que le demi-flux
1 (rapprochement SRC <-> CTL). Ce module lit le demi-flux 2, celui qui est
reellement integre a Oracle, et en extrait les quatre preuves d'integration :

  - le fichier cible, image de la table d'interface Oracle :
      FOURNISSEURS  TARGET\\Header.csv + Line.csv  (AP_INVOICE*_INTERFACE)
      CLIENTS       TARGET\\FACTURESCLIENTS_FIN01.txt
      GL            TARGET\\FAC02_PIVOT_GL_*.txt   (porte par le demi-flux 1)
  - le nombre d'enregistrements publies, ecrit par Talend dans
      TS\\TALEND\\TS_OUT.<statut> ("141 has/have been successfully published") ;
  - les rejets fonctionnels, TARGET\\REJETS_FONCTIONNELS_<horodatage>.csv,
    qui nomment la piece rejetee, le code et le libelle de l'erreur ainsi que
    la fonction XXEAI_INTERFACE_TOOLS_PKG en cause ;
  - les erreurs par enregistrement laissees dans TMP\\.

Identites verifiees sur les exports du depot, et sur lesquelles s'appuie la
reconciliation (voir SPEC_RECONCILIATION_DEMIFLUX2.md) :

  FOURNISSEURS  lignes(Header) + lignes(Line) = publies
                = lignes de donnees du SRC - lignes rejetees
  CLIENTS       lignes(FACTURESCLIENTS_FIN01) = publies = lignes du SRC

Module de lecture uniquement : aucun affichage, aucun code retour. Il est
utilise par reconciliation.py.
"""

import csv
import re
import sys
from collections import OrderedDict, defaultdict
from dataclasses import dataclass, field
from decimal import Decimal, InvalidOperation
from pathlib import Path
from typing import Dict, List, Optional, Tuple


ENCODAGE = "latin-1"

# Statuts Talend, portes par l'extension du fichier temoin (LS_OUT / TS_OUT).
STATUTS = ("OK", "WARNING", "KO", "NULL")

# "141 has/have been successfully published", ecrit par le composant Talend
# LOG_T_0022_NBRECORDSPUBLISHED en seconde ligne du temoin TS_OUT.
MOTIF_PUBLIES = re.compile(r"(\d+)\s+has/have been successfully published", re.I)

# Le type de flux se lit dans le nom du fichier repris par le demi-flux 2.
MOTIFS_TYPE = (
    ("FACTURESFOURNISSEURS", "FOURNISSEUR"),
    ("FACTURESCLIENTS", "CLIENT"),
    ("ECRITURESGL", "GL"),
    ("ECRITURESCOMPTABLES", "GL"),
)

# Index (a partir de 0) des colonnes exploitees dans les fichiers cibles.
AP_HEADER_PIECE = 1
AP_HEADER_MONTANT = 10
AP_HEADER_FOLIO = 34         # ATTRIBUTE9
AP_HEADER_FICHIER = 35       # ATTRIBUTE10
AP_LIGNE_MONTANT = 5
AP_LIGNE_FOLIO = 46
AP_LIGNE_FICHIER = 47

AR_PORTEFEUILLE = 0
AR_PIECE = 3
AR_COMPTE = 6
AR_SENS = 10
AR_MONTANT = 11
AR_FICHIER = 36

GL_PIECE = 0
GL_DEBIT = 8
GL_CREDIT = 9
GL_ORIGINE = 11

# Champs du fichier de rejets fonctionnels, delimite par des barres verticales.
REJET_HORODATAGE = 0
REJET_CODE = 1
REJET_LIBELLE = 2
REJET_APPLICATION = 3
REJET_FLUX = 4
REJET_FICHIER = 5
REJET_EXTENSION = 6
REJET_LIGNE_SOURCE = 7
REJET_APPEL = 8
REJET_PIECE = 9
REJET_NB_CHAMPS = 10


class ErreurDemiFlux2(Exception):
    """Le demi-flux 2 est present mais illisible."""


@dataclass
class StatutTalend:
    """Temoins LS_OUT et TS_OUT d'une instance du demi-flux 2."""

    ls: Optional[str] = None
    ts: Optional[str] = None
    nb_publies: Optional[int] = None
    messages: List[str] = field(default_factory=list)

    @property
    def abouti(self) -> bool:
        """Le transfert vers Oracle a ete publie (un WARNING reste abouti).

        Un WARNING signale des rejets fonctionnels : le reste du fichier a bien
        ete publie, c'est le cas nominal d'une integration partielle.
        """
        return self.ts in ("OK", "WARNING")


@dataclass
class Rejet:
    """Une ligne du fichier REJETS_FONCTIONNELS."""

    horodatage: str
    code: str
    libelle: str
    application: str
    flux: str
    fichier: str
    ligne_source: str
    appel: str
    piece: str


@dataclass
class PieceRejetee:
    """Les lignes de rejet d'une meme piece, regroupees.

    Une piece rejetee produit autant de lignes que le SRC en comptait : seule
    celle qui porte le controle en echec est renseignee en code et libelle,
    les autres sont ses lignes soeurs, entrainees par la meme piece.
    """

    piece: str
    code: str
    libelle: str
    appel: str
    horodatage: str
    fichier: str
    nb_lignes: int


@dataclass
class CibleAp:
    """Header.csv + Line.csv, image de AP_INVOICE*_INTERFACE."""

    nb_entetes: int = 0
    nb_lignes: int = 0
    montant: int = 0                                   # centimes
    pieces: List[str] = field(default_factory=list)
    par_folio: Dict[str, int] = field(default_factory=dict)
    par_fichier: Dict[str, int] = field(default_factory=dict)

    @property
    def nb_enregistrements(self) -> int:
        return self.nb_entetes + self.nb_lignes


@dataclass
class CibleAr:
    """FACTURESCLIENTS_FIN01.txt, ce qui alimente DKA_IARPAFAC_INTERFACE."""

    nb_lignes: int = 0
    nb_lignes_client: int = 0                          # comptes 411*
    montant_par_portefeuille: Dict[str, int] = field(default_factory=dict)
    nb_par_portefeuille: Dict[str, int] = field(default_factory=dict)

    @property
    def nb_enregistrements(self) -> int:
        return self.nb_lignes


@dataclass
class CibleGl:
    """FAC02_PIVOT_GL_*.txt, ce qui alimente GL_INTERFACE."""

    nb_lignes: int = 0
    debit: int = 0
    credit: int = 0
    nb_par_origine: Dict[str, int] = field(default_factory=dict)
    debit_par_origine: Dict[str, int] = field(default_factory=dict)
    credit_par_origine: Dict[str, int] = field(default_factory=dict)
    pieces_desequilibrees: List[Tuple[str, str, int, int]] = field(default_factory=list)

    @property
    def nb_enregistrements(self) -> int:
        return self.nb_lignes

    @property
    def equilibre(self) -> bool:
        return self.debit == self.credit and not self.pieces_desequilibrees


@dataclass
class Instance:
    """Une instance Talend du demi-flux 2 d'un export."""

    guid: str
    chemin: Path
    type_flux: str
    fichier_source: Optional[str] = None               # fichier repris du demi-flux 1


def centimes(texte: str) -> int:
    """Montant francais ou anglais converti en centimes (0 si illisible).

    Les fichiers du demi-flux 1 utilisent la virgule decimale, ceux du
    demi-flux 2 le point : les deux doivent etre acceptes pour que les totaux
    des deux etages soient comparables.
    """
    valeur = (texte or "").strip().replace(" ", "").replace(" ", "")
    if not valeur:
        return 0
    try:
        return int((Decimal(valeur.replace(",", ".")) * 100).to_integral_value())
    except (InvalidOperation, ArithmeticError):
        return 0


def deduire_type(nom: str) -> Optional[str]:
    """Type de flux porte par un nom de fichier, ou None."""
    majuscule = str(nom).upper()
    for motif, type_flux in MOTIFS_TYPE:
        if motif in majuscule:
            return type_flux
    return None


def _lignes(chemin: Path):
    """Lignes non vides d'un fichier delimite par des points-virgules."""
    try:
        fichier = chemin.open("r", encoding=ENCODAGE, newline="")
    except OSError as exc:
        raise ErreurDemiFlux2("impossible de lire %s : %s" % (chemin, exc)) from exc
    with fichier:
        for champs in csv.reader(fichier, delimiter=";"):
            if champs and any(champ.strip() for champ in champs):
                yield champs


def _champ(champs: List[str], index: int) -> str:
    return champs[index].strip() if index < len(champs) else ""


def fichier_repris(instance_ou_chemin) -> Optional[Path]:
    """Fichier de donnees consomme par le demi-flux 2, dans son dossier SOURCE.

    Ce dossier contient aussi le fichier de controle CTL et, selon les flux,
    CLES_FONCTIONNELLES : le fichier de donnees se reconnait a son marqueur
    _SRC_. Le repli sur un autre nom porteur de type couvre les exports ou le
    marqueur est absent, sans jamais retenir un CTL.
    """
    instance = getattr(instance_ou_chemin, "chemin", instance_ou_chemin)
    dossier = Path(instance) / "SOURCE"
    if not dossier.is_dir():
        return None
    candidats = [
        chemin
        for chemin in sorted(dossier.iterdir())
        if chemin.is_file() and deduire_type(chemin.name)
    ]
    for chemin in candidats:
        if "_SRC_" in chemin.name.upper():
            return chemin
    for chemin in candidats:
        if "_CTL_" not in chemin.name.upper():
            return chemin
    return None


def trouver_instances(dossier_folio) -> List[Instance]:
    """Instances du demi-flux 2 d'un dossier d'export, les plus recentes en tete.

    Renvoie une liste vide si le demi-flux 2 n'a pas ete rapatrie : c'est un
    cas nominal (les exports GL n'en ont pas), pas une erreur.
    """
    racine = Path(dossier_folio).expanduser()
    if racine.is_file():
        racine = racine.parent
    cible = racine / "TARGET"
    if not cible.is_dir():
        return []

    instances = []
    for chemin in sorted(cible.iterdir(), key=lambda p: p.name.lower()):
        if not chemin.is_dir():
            continue
        fichier_source = None
        type_flux = None
        repris = fichier_repris(chemin)
        if repris is not None:
            fichier_source = repris.stem
            type_flux = deduire_type(repris.name)
        if type_flux is None:
            type_flux = deduire_type(racine.name) or "INCONNU"
        instances.append(
            Instance(
                guid=chemin.name,
                chemin=chemin,
                type_flux=type_flux,
                fichier_source=fichier_source,
            )
        )
    return instances


def lire_statut(instance: Instance) -> StatutTalend:
    """Temoins LS_OUT / TS_OUT de l'instance et nombre d'enregistrements publies."""
    statut = StatutTalend()
    for sous_dossier, attribut in (("LS", "ls"), ("TS", "ts")):
        dossier = instance.chemin / sous_dossier / "TALEND"
        if not dossier.is_dir():
            continue
        for temoin in sorted(dossier.iterdir()):
            if not temoin.is_file():
                continue
            extension = temoin.suffix.lstrip(".").upper()
            if extension not in STATUTS:
                continue
            setattr(statut, attribut, extension)
            try:
                contenu = temoin.read_text(encoding=ENCODAGE, errors="replace")
            except OSError:
                continue
            for ligne in contenu.splitlines():
                ligne = ligne.strip()
                if ligne:
                    statut.messages.append(ligne)
                correspondance = MOTIF_PUBLIES.search(ligne)
                if correspondance and attribut == "ts":
                    statut.nb_publies = int(correspondance.group(1))
    return statut


def fichiers_rejets(instance: Instance) -> List[Path]:
    dossier = instance.chemin / "TARGET"
    if not dossier.is_dir():
        return []
    return sorted(dossier.glob("REJETS_FONCTIONNELS_*.csv"))


def lire_rejets(instance: Instance) -> List[Rejet]:
    """Lignes des fichiers REJETS_FONCTIONNELS de l'instance.

    Le fichier est delimite par des barres verticales et non par des
    points-virgules : son 8e champ contient la ligne source rejetee, elle-meme
    delimitee par des points-virgules. Il est donc decoupe sur '|' uniquement,
    et le nombre de champs est borne pour qu'une barre verticale presente dans
    un libelle ne decale pas les champs suivants.
    """
    rejets = []
    for chemin in fichiers_rejets(instance):
        try:
            contenu = chemin.read_text(encoding=ENCODAGE, errors="replace")
        except OSError as exc:
            raise ErreurDemiFlux2("impossible de lire %s : %s" % (chemin, exc)) from exc
        for ligne in contenu.splitlines():
            if not ligne.strip():
                continue
            champs = ligne.split("|")
            if len(champs) < REJET_NB_CHAMPS:
                continue
            rejets.append(
                Rejet(
                    horodatage=champs[REJET_HORODATAGE].strip(),
                    code=champs[REJET_CODE].strip(),
                    libelle=champs[REJET_LIBELLE].strip(),
                    application=champs[REJET_APPLICATION].strip(),
                    flux=champs[REJET_FLUX].strip(),
                    fichier=champs[REJET_FICHIER].strip(),
                    ligne_source=champs[REJET_LIGNE_SOURCE],
                    appel=champs[REJET_APPEL].strip(),
                    piece=champs[REJET_PIECE].strip(),
                )
            )
    return rejets


def grouper_rejets(rejets: List[Rejet]) -> List[PieceRejetee]:
    """Regroupe les lignes de rejet par piece, dans l'ordre de rencontre.

    Le code et le libelle retenus sont ceux de la ligne qui les porte : les
    lignes soeurs d'une meme piece arrivent sans code, elles ne sont rejetees
    que parce que leur piece l'est.
    """
    groupes: "OrderedDict[str, PieceRejetee]" = OrderedDict()
    for rejet in rejets:
        cle = rejet.piece or "(piece inconnue)"
        groupe = groupes.get(cle)
        if groupe is None:
            groupe = PieceRejetee(
                piece=cle,
                code=rejet.code,
                libelle=rejet.libelle,
                appel=rejet.appel,
                horodatage=rejet.horodatage,
                fichier=rejet.fichier,
                nb_lignes=0,
            )
            groupes[cle] = groupe
        groupe.nb_lignes += 1
        if not groupe.code and rejet.code:
            groupe.code = rejet.code
            groupe.libelle = rejet.libelle
            groupe.appel = rejet.appel
    return list(groupes.values())


def lire_erreurs_tmp(instance: Instance) -> List[str]:
    """Pieces signalees en erreur dans TMP\\piece_erreur.csv.

    Ce fichier donne, par piece rejetee, la societe et les identifiants
    d'interface Oracle reserves : il confirme les rejets sans les remplacer.
    """
    chemin = instance.chemin / "TMP" / "piece_erreur.csv"
    if not chemin.is_file():
        return []
    pieces = []
    for champs in _lignes(chemin):
        piece = _champ(champs, 0)
        if piece:
            pieces.append(piece)
    return pieces


def lire_cible_ap(instance: Instance) -> Optional[CibleAp]:
    """Header.csv et Line.csv du demi-flux 2 fournisseurs."""
    dossier = instance.chemin / "TARGET"
    entetes = dossier / "Header.csv"
    lignes = dossier / "Line.csv"
    if not entetes.is_file() and not lignes.is_file():
        return None

    cible = CibleAp()
    par_folio: Dict[str, int] = defaultdict(int)
    par_fichier: Dict[str, int] = defaultdict(int)
    if entetes.is_file():
        for champs in _lignes(entetes):
            cible.nb_entetes += 1
            cible.montant += centimes(_champ(champs, AP_HEADER_MONTANT))
            piece = _champ(champs, AP_HEADER_PIECE)
            if piece:
                cible.pieces.append(piece)
            par_folio[_champ(champs, AP_HEADER_FOLIO)] += 1
            par_fichier[_champ(champs, AP_HEADER_FICHIER)] += 1
    if lignes.is_file():
        for champs in _lignes(lignes):
            cible.nb_lignes += 1
    cible.par_folio = dict(par_folio)
    cible.par_fichier = dict(par_fichier)
    return cible


def lire_cible_ar(instance: Instance) -> Optional[CibleAr]:
    """FACTURESCLIENTS_FIN01.txt du demi-flux 2 clients.

    Les montants sont totalises sur les seules lignes de comptes clients
    411*, avec le meme signe qu'en amont (credit negatif) : les totaux
    obtenus sont directement comparables a ceux du fichier CTL.
    """
    dossier = instance.chemin / "TARGET"
    candidats = sorted(dossier.glob("FACTURESCLIENTS*")) if dossier.is_dir() else []
    if not candidats:
        return None

    cible = CibleAr()
    montants: Dict[str, int] = defaultdict(int)
    nombres: Dict[str, int] = defaultdict(int)
    for chemin in candidats:
        for champs in _lignes(chemin):
            cible.nb_lignes += 1
            if not _champ(champs, AR_COMPTE).startswith("411"):
                continue
            cible.nb_lignes_client += 1
            portefeuille = _champ(champs, AR_PORTEFEUILLE)
            montant = centimes(_champ(champs, AR_MONTANT))
            if _champ(champs, AR_SENS).upper() == "C":
                montant = -montant
            montants[portefeuille] += montant
            nombres[portefeuille] += 1
    cible.montant_par_portefeuille = dict(montants)
    cible.nb_par_portefeuille = dict(nombres)
    return cible


def fichiers_pivot_gl(dossier_folio) -> List[Path]:
    """Fichiers pivot GL d'un export.

    Le pivot GL est produit en sortie du demi-flux 1 (il porte deja le code
    application et le nom du fichier source qui deviennent ATTRIBUTE9 et
    ATTRIBUTE10 dans GL_INTERFACE) : c'est lui l'image de ce qui part vers
    Oracle, on le cherche donc dans les deux demi-flux.
    """
    racine = Path(dossier_folio).expanduser()
    if racine.is_file():
        racine = racine.parent
    trouves = []
    for demi in ("SOURCE", "TARGET"):
        dossier = racine / demi
        if dossier.is_dir():
            trouves.extend(sorted(dossier.glob("*/TARGET/*PIVOT_GL*")))
    return trouves


def lire_cible_gl(chemin) -> CibleGl:
    """Fichier pivot GL : comptages, totaux et pieces desequilibrees."""
    cible = CibleGl()
    pieces: Dict[Tuple[str, str], List[int]] = defaultdict(lambda: [0, 0])
    nombres: Dict[str, int] = defaultdict(int)
    debits: Dict[str, int] = defaultdict(int)
    credits: Dict[str, int] = defaultdict(int)
    for champs in _lignes(Path(chemin)):
        cible.nb_lignes += 1
        piece = _champ(champs, GL_PIECE)
        origine = _champ(champs, GL_ORIGINE)
        debit = centimes(_champ(champs, GL_DEBIT))
        credit = centimes(_champ(champs, GL_CREDIT))
        cible.debit += debit
        cible.credit += credit
        nombres[origine] += 1
        debits[origine] += debit
        credits[origine] += credit
        pieces[(origine, piece)][0] += debit
        pieces[(origine, piece)][1] += credit
    cible.nb_par_origine = dict(nombres)
    cible.debit_par_origine = dict(debits)
    cible.credit_par_origine = dict(credits)
    cible.pieces_desequilibrees = sorted(
        (origine, piece, montants[0], montants[1])
        for (origine, piece), montants in pieces.items()
        if montants[0] != montants[1]
    )
    return cible


def lire_cible(instance: Instance):
    """Fichier cible de l'instance, selon son type de flux."""
    if instance.type_flux == "FOURNISSEUR":
        return lire_cible_ap(instance)
    if instance.type_flux == "CLIENT":
        return lire_cible_ar(instance)
    if instance.type_flux == "GL":
        dossier = instance.chemin / "TARGET"
        pivots = sorted(dossier.glob("*PIVOT_GL*")) if dossier.is_dir() else []
        return lire_cible_gl(pivots[0]) if pivots else None
    return None


def main(arguments=None) -> int:
    """Inventaire du demi-flux 2 d'un export, pour verification a la main."""
    args = list(sys.argv[1:] if arguments is None else arguments)
    if len(args) != 1:
        print("ERREUR : usage : demiflux2.py <dossier_export>", file=sys.stderr)
        return 1
    try:
        instances = trouver_instances(args[0])
    except ErreurDemiFlux2 as exc:
        print("ERREUR : %s" % exc, file=sys.stderr)
        return 1
    if not instances:
        print("Aucun demi-flux 2 rapatrie sous %s" % args[0])
        return 0
    for instance in instances:
        statut = lire_statut(instance)
        pieces = grouper_rejets(lire_rejets(instance))
        cible = lire_cible(instance)
        print("Instance %s (%s)" % (instance.guid, instance.type_flux))
        print("  fichier repris : %s" % (instance.fichier_source or "-"))
        print("  LS %s / TS %s / publies %s"
              % (statut.ls or "-", statut.ts or "-",
                 "-" if statut.nb_publies is None else statut.nb_publies))
        print("  cible : %s enregistrement(s)"
              % (cible.nb_enregistrements if cible else "-"))
        print("  rejets : %d piece(s)" % len(pieces))
        for piece in pieces:
            print("    %-20s %-8s %s" % (piece.piece, piece.code, piece.libelle))
    return 0


if __name__ == "__main__":
    sys.exit(main())
