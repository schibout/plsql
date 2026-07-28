"""Parseurs des formats de virement : DK, DK_FIN01, ACK, CSV Oracle."""
from pathlib import Path

from cv.model import Virement, LotDK, LotAck, OracleRow
from cv.montant import euros_to_cts, is_euro_amount

# Indices de colonnes (0-based) dans DK / DK_FIN01
_AMOUNT = 9
_NOM = 10
_IBAN = 12
_BIC = 14


def _read_lines(path) -> list:
    with open(path, encoding="latin-1") as fh:
        return [l for l in fh.read().splitlines() if l.strip()]


def _entete(lines):
    champs = lines[0].split(";")
    return champs[1], euros_to_cts(champs[2])


def _virement_depuis_ligne(cols, montant_cts):
    return Virement(
        iban=cols[_IBAN].strip(),
        montant_cts=montant_cts,
        nom=cols[_NOM].strip(),
        bic=cols[_BIC].strip(),
    )


def parse_dk(path) -> LotDK:
    lines = _read_lines(path)
    ref, entete_cts = _entete(lines)
    virements = []
    for ligne in lines[2:]:
        cols = ligne.split(";")
        virements.append(_virement_depuis_ligne(cols, euros_to_cts(cols[_AMOUNT])))
    return LotDK(ref=ref, montant_entete_cts=entete_cts, virements=virements, euro_lines=0)


# Indices de colonnes dans l'export Quartz (feuille 0)
_Q_MONTANT = 5
_Q_CODE = 6
_Q_MOTIF = 7
_Q_TIERS = 8


def _quartz_virements(matrix) -> list:
    """Extrait les virements de detail d'une matrice Quartz (lignes 'VSEP')."""
    virements = []
    for row in matrix:
        if len(row) <= _Q_TIERS:
            continue
        if str(row[_Q_CODE]).strip() != "VSEP":
            continue
        montant_cts = round(float(row[_Q_MONTANT]) * 100)
        virements.append(Virement(
            iban="",
            montant_cts=montant_cts,
            nom=str(row[_Q_TIERS]).strip(),
            bic="",
        ))
    return virements


def parse_quartz_xls(path) -> list:
    """Parse l'export Quartz (.xls binaire) et retourne les virements importes."""
    try:
        import xlrd
    except ImportError as exc:  # pragma: no cover
        raise RuntimeError(
            "Le module 'xlrd' est requis pour lire les fichiers .xls Quartz. "
            "Installez-le : python -m pip install xlrd"
        ) from exc
    wb = xlrd.open_workbook(path)
    sh = wb.sheet_by_index(0)
    matrix = [[sh.cell_value(r, c) for c in range(sh.ncols)] for r in range(sh.nrows)]
    return _quartz_virements(matrix)


def parse_oracle_csv(path) -> list:
    lines = _read_lines(path)
    rows = []
    for ligne in lines[1:]:
        c = ligne.split(";")
        rows.append(OracleRow(
            code_banque=c[0].strip(),
            iban_payeur=c[1].strip(),
            date=c[2].strip(),
            nom_fichier_source=c[3].strip(),
            nb_source=int(c[4]),
            montant_source_cts=euros_to_cts(c[5]),
            nom_fichier_edf=c[6].strip(),
            nb_edf=int(c[7]),
            montant_edf_cts=euros_to_cts(c[8]),
        ))
    return rows


def parse_ack(path) -> LotAck:
    iban_payeur = ""
    virements = []
    footer_count = 0
    footer_total_cts = 0
    for ligne in _read_lines(path):
        rec = ligne[0:2]
        if rec == "03":
            iban_payeur = ligne[80:107].strip()
        elif rec == "06":
            virements.append(Virement(
                nom=ligne[23:47].strip(),
                bic=ligne[71:82].strip(),
                iban=ligne[82:116].strip(),
                montant_cts=int(ligne[116:132]),
            ))
        elif rec == "08":
            footer_count = int(ligne[4:11])
            footer_total_cts = int(ligne[11:27])
    return LotAck(
        iban_payeur=iban_payeur,
        virements=virements,
        footer_count=footer_count,
        footer_total_cts=footer_total_cts,
    )


def parse_dk_fin01(path) -> LotDK:
    lines = _read_lines(path)
    ref, entete_cts = _entete(lines)
    virements = []
    euro_lines = 0
    for ligne in lines[2:]:
        cols = ligne.split(";")
        amount = cols[_AMOUNT].strip()
        if is_euro_amount(amount):
            euro_lines += 1
            continue
        virements.append(_virement_depuis_ligne(cols, int(amount)))
    return LotDK(ref=ref, montant_entete_cts=entete_cts, virements=virements, euro_lines=euro_lines)
