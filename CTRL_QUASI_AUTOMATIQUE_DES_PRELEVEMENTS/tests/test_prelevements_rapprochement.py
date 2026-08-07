"""Tests de la recherche du decalage J+n (option --recherche-jn).

Les deux premiers tests couvrent des pieges rencontres sur les donnees reelles :
sans eux, la recherche designe une journee EDF sans rapport.
"""
import sys
from datetime import date
from decimal import Decimal
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from prelevements_rapprochement import (  # noqa: E402
    chercher_date_cible, construire_rapprochement,
)


def edf(**jours):
    """{'20260624': (484, '2922913.94'), ...} -> index attendu par la recherche."""
    return {d: {"date": d, "nb": nb, "total": Decimal(mt)} for d, (nb, mt) in jours.items()}


def test_trouve_le_decalage_exact():
    index = edf(**{"20260703": (197, "1522539.05")})
    cible, mode = chercher_date_cible(date(2026, 7, 1), 197, Decimal("1522539.05"), index, 8)
    assert (cible, mode) == ("20260703", "exact")


def test_trouve_un_decalage_que_la_regle_fixe_ne_produit_pas():
    """Cas reel du 10/07 : la regle fixe vise le 14/07, jour ferie sans fichier
    EDF, et declare 377 prelevements perdus. Le bon decalage est J+5."""
    index = edf(**{"20260715": (376, "4620745.88")})
    cible, mode = chercher_date_cible(date(2026, 7, 10), 377, Decimal("4624079.83"), index, 8)
    assert cible == "20260715"       # J+5, hors de portee de la regle J+2/J+4
    assert mode == "ecart"           # l'ecart restant est un rejet


def test_la_contrainte_de_signe_ecarte_une_coincidence_de_nombre():
    """Cas reel du 25/07 : une journee EDF affiche le MEME nombre (2) pour un
    montant sans rapport. EDF remontant net des rejets, il ne peut jamais
    afficher plus qu'Oracle : ce candidat doit etre rejete."""
    index = edf(**{
        "20260728": (1, "2162.75"),      # vrai candidat : 1 de moins, montant coherent
        "20260730": (2, "16461.74"),     # meme nombre, montant 4x superieur -> a exclure
    })
    cible, mode = chercher_date_cible(date(2026, 7, 25), 2, Decimal("3821.10"), index, 8)
    assert cible == "20260728"
    assert mode == "ecart"


def test_departage_par_ecart_minimal_et_non_par_date_la_plus_proche():
    """Cas reel du 22/06 : une petite journee EDF proche satisfait la contrainte
    de signe. Prendre le premier candidat la retiendrait a tort."""
    index = edf(**{
        "20260623": (6, "356668.44"),        # proche, mais 479 lignes d'ecart
        "20260624": (484, "2922913.94"),     # plus loin, mais 1 seule ligne d'ecart
    })
    cible, _ = chercher_date_cible(date(2026, 6, 22), 485, Decimal("2923846.19"), index, 8)
    assert cible == "20260624"


def test_deux_journees_exactes_sont_signalees_ambigues():
    index = edf(**{"20260624": (5, "100.00"), "20260626": (5, "100.00")})
    cible, mode = chercher_date_cible(date(2026, 6, 22), 5, Decimal("100.00"), index, 8)
    assert mode == "ambigu"
    assert cible == "20260624"      # la plus proche, mais le rapport le signale


def test_aucun_candidat_quand_edf_n_a_rien_remonte():
    cible, mode = chercher_date_cible(date(2026, 8, 5), 1, Decimal("8000.00"), {}, 8)
    assert (cible, mode) == (None, "introuvable")


def test_une_journee_edf_plus_fournie_qu_oracle_n_est_pas_candidate():
    """EDF ne peut pas remonter PLUS que ce qu'Oracle a emis."""
    index = edf(**{"20260624": (10, "5000.00")})
    cible, mode = chercher_date_cible(date(2026, 6, 22), 5, Decimal("100.00"), index, 8)
    assert (cible, mode) == (None, "introuvable")


# --- Integration : l'option ne change rien quand elle est desactivee --------
ORA = [{"date": "20260710", "nb": 377, "total": Decimal("4624079.83")}]
EDF = [{"date": "20260715", "nb": 376, "total": Decimal("4620745.88")}]


def test_mode_par_defaut_applique_toujours_la_regle_fixe():
    lignes = construire_rapprochement(ORA, EDF)          # recherche_jn = 0
    assert lignes[0]["date_edf"] == "14/07/2026"          # vendredi + 4
    assert lignes[0]["nb_edf"] == 0                       # aucun fichier ce jour-la
    assert lignes[0]["statut"] == "Écart (J+4)"


def test_mode_recherche_corrige_la_cible():
    lignes = construire_rapprochement(ORA, EDF, recherche_jn=8)
    assert lignes[0]["date_edf"] == "15/07/2026"
    assert lignes[0]["nb_edf"] == 376
    assert lignes[0]["statut"] == "Écart (J+5)"


def test_journee_introuvable_est_marquee_non_trouve():
    lignes = construire_rapprochement(
        [{"date": "20260805", "nb": 1, "total": Decimal("8000.00")}], [], recherche_jn=8)
    assert lignes[0]["statut"] == "Non trouvé"


# --- Provenance : de quel fichier vient la ligne ----------------------------
def test_colonne_oracle_liste_les_noms_quand_ils_sont_peu_nombreux():
    ora = [{"date": "20260622", "nb": 1, "total": Decimal("100.00"),
            "fichiers": ["DK_a.txt", "DK_b.txt"]}]
    edf = [{"date": "20260624", "nb": 1, "total": Decimal("100.00"),
            "fichiers": ["IMPORT_AVP_DK.20260624.070103.csv"]}]
    lignes = construire_rapprochement(ora, edf)
    assert lignes[0]["fichier_oracle"] == "DK_a.txt + DK_b.txt"
    assert lignes[0]["fichier_edf"] == "IMPORT_AVP_DK.20260624.070103.csv"


def test_colonne_oracle_bascule_sur_le_dossier_au_dela_de_trois_fichiers():
    """Une date Oracle peut compter jusqu'a 78 fichiers : les lister rendrait
    la cellule illisible."""
    ora = [{"date": "20260622", "nb": 4, "total": Decimal("100.00"),
            "fichiers": [f"DK_{i}.txt" for i in range(4)]}]
    lignes = construire_rapprochement(ora, [])
    assert lignes[0]["fichier_oracle"] == "ORACLE\\20260622 (4 fichiers)"


def test_colonne_edf_indique_aucun_quand_rien_n_a_ete_recu():
    ora = [{"date": "20260805", "nb": 1, "total": Decimal("8000.00"), "fichiers": ["DK_a.txt"]}]
    lignes = construire_rapprochement(ora, [])
    assert lignes[0]["fichier_edf"] == "(aucun)"


# --- Rattachement du fichier de rejet --------------------------------------
def rejets(**par_date):
    """{'20260624': ('REJETS_...csv', '932.25', 1, ['CC01'])}"""
    from prelevements_rapprochement import parse_date
    return {parse_date(d): {"fichier": f, "total": Decimal(t), "nb": n, "codes": c}
            for d, (f, t, n, c) in par_date.items()}


def test_le_fichier_de_rejet_dont_le_total_egale_l_ecart_est_designe():
    """Cas reel du 22/06 : ecart de -932,25 EUR, un fichier de rejets du meme
    montant."""
    ora = [{"date": "20260622", "nb": 485, "total": Decimal("2923846.19"), "fichiers": []}]
    edf = [{"date": "20260624", "nb": 484, "total": Decimal("2922913.94"), "fichiers": []}]
    res = rejets(**{"20260624": ("REJETS_INTERNES_DK.20260624.070002.csv", "932.25", 1, ["CC01"])})
    lignes = construire_rapprochement(ora, edf, resume_rejets=res)
    assert "REJETS_INTERNES_DK.20260624.070002.csv" in lignes[0]["fichier_rejet"]
    assert "explique l'écart" in lignes[0]["fichier_rejet"]


def test_un_fichier_de_rejet_etranger_a_l_ecart_n_est_pas_designe_a_tort():
    """Cas reel du 23/07 : deux fichiers de rejets tombent dans la fenetre, mais
    seul celui dont le total correspond explique l'ecart. L'autre porte des
    rejets d'un autre SI (les fichiers de rejets ne nomment pas le SI)."""
    ora = [{"date": "20260723", "nb": 644, "total": Decimal("4015509.34"), "fichiers": []}]
    edf = [{"date": "20260727", "nb": 641, "total": Decimal("4002598.43"), "fichiers": []}]
    res = rejets(**{
        "20260724": ("REJETS_AUTRE_SI.csv", "183.67", 2, ["CC01"]),
        "20260727": ("REJETS_INTERNES_DK.20260727.070015.csv", "12910.91", 3, ["CC01", "CC02"]),
    })
    lignes = construire_rapprochement(ora, edf, recherche_jn=8, resume_rejets=res)
    assert lignes[0]["fichier_rejet"].startswith("REJETS_INTERNES_DK.20260727")
    assert "REJETS_AUTRE_SI.csv" not in lignes[0]["fichier_rejet"]


def test_quand_aucun_montant_ne_correspond_l_outil_ne_conclut_pas():
    ora = [{"date": "20260622", "nb": 10, "total": Decimal("1000.00"), "fichiers": []}]
    edf = [{"date": "20260624", "nb": 9, "total": Decimal("900.00"), "fichiers": []}]
    res = rejets(**{"20260624": ("REJETS_X.csv", "42.00", 1, ["CC01"])})
    lignes = construire_rapprochement(ora, edf, resume_rejets=res)
    assert "à vérifier" in lignes[0]["fichier_rejet"]
    assert "REJETS_X.csv" in lignes[0]["fichier_rejet"]


def test_aucun_rejet_dans_la_fenetre():
    ora = [{"date": "20260622", "nb": 10, "total": Decimal("1000.00"), "fichiers": []}]
    edf = [{"date": "20260624", "nb": 9, "total": Decimal("900.00"), "fichiers": []}]
    assert construire_rapprochement(ora, edf, resume_rejets={})[0]["fichier_rejet"] == "(aucun)"


def test_une_journee_conforme_ne_reference_aucun_rejet():
    """Sinon la colonne se remplirait de bruit sur les journees sans ecart."""
    ora = [{"date": "20260622", "nb": 1, "total": Decimal("100.00"), "fichiers": []}]
    edf = [{"date": "20260624", "nb": 1, "total": Decimal("100.00"), "fichiers": []}]
    res = rejets(**{"20260624": ("REJETS_X.csv", "42.00", 1, ["CC01"])})
    assert construire_rapprochement(ora, edf, resume_rejets=res)[0]["fichier_rejet"] == ""
