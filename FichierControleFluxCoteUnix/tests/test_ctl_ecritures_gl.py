import os
import builtins
from pathlib import Path

import pytest

import ctl_ecritures_gl as gl


DOSSIER_SCRIPT = Path(__file__).resolve().parents[1]
DOSSIER_EXEMPLE = DOSSIER_SCRIPT / "04072026_GL_GER"


def ecriture(piece="P001", debit="10,00", credit="10,00", origine="GER"):
    champs = [""] * 27
    champs[0] = piece
    champs[8] = debit
    champs[9] = credit
    champs[11] = origine
    return ";".join(champs)


def creer_flux(tmp_path, lignes_src, lignes_ctl, nom="FAC02_SRC_ECRITURESGL_TEST.csv"):
    source = tmp_path if tmp_path.name.upper() == "SOURCE" else tmp_path / "SOURCE"
    source.mkdir(parents=True, exist_ok=True)
    src = source / nom
    ctl = source / nom.replace("_SRC_", "_CTL_")
    src.write_text("\n".join(lignes_src) + "\n", encoding="latin-1")
    ctl.write_text("\n".join(lignes_ctl) + "\n", encoding="latin-1")
    return src, ctl


def test_ac1_instance_gl_reference_conforme():
    src = gl.selectionner_src(DOSSIER_EXEMPLE)
    ctl = Path(str(src).replace("_SRC_", "_CTL_"))

    resultat = gl.controler(src, ctl, generer_rapport=False)

    assert resultat.code_retour == 0
    assert resultat.origines["GER"].nb_src == 36
    assert resultat.origines["GER"].debit_src == 1_197_196
    assert resultat.origines["GER"].credit_src == 1_197_196
    assert resultat.origines["FGE"].nb_src == 5
    assert resultat.origines["FGE"].debit_src == 1_321_666
    assert resultat.origines["FGE"].credit_src == 1_321_666


def test_ac2_ctl_est_deduit_du_nom_src(tmp_path):
    tmp_path = tmp_path / "dossier avec espaces"
    tmp_path.mkdir()
    src, ctl = creer_flux(
        tmp_path,
        [ecriture()],
        ["GER;25/08/2026;1;10,00;10,00;FAC02_SRC_ECRITURESGL_TEST;0"],
    )

    assert gl.deduire_ctl(src) == ctl
    assert gl.executer([str(src)], generer_rapport=False) == 0


def test_ac3_ecart_de_montant_retourne_anomalie(tmp_path):
    src, ctl = creer_flux(
        tmp_path,
        [ecriture()],
        ["GER;25/08/2026;1;10,01;10,00;FAC02_SRC_ECRITURESGL_TEST;0"],
    )

    resultat = gl.controler(src, ctl, generer_rapport=False)

    assert resultat.code_retour == 2
    assert resultat.origines["GER"].statut == "ECART"


def test_ac4_piece_desequilibree_retourne_anomalie(tmp_path):
    src, ctl = creer_flux(
        tmp_path,
        [ecriture(debit="10,00", credit="9,99")],
        ["GER;25/08/2026;1;10,00;9,99;FAC02_SRC_ECRITURESGL_TEST;0"],
    )

    resultat = gl.controler(src, ctl, generer_rapport=False)

    assert resultat.code_retour == 2
    assert resultat.pieces_desequilibrees == [("GER", "P001", 1000, 999)]


def test_ac5_fichier_absent_retourne_erreur_technique(tmp_path, capsys):
    code = gl.executer([str(tmp_path / "absent.csv")], generer_rapport=False)

    assert code == 1
    assert "introuvable" in capsys.readouterr().err.lower()


@pytest.mark.parametrize(
    "ligne,message",
    [
        ("trop;court", "12 colonnes"),
        (ecriture(debit="abc"), "montant illisible"),
        (ecriture(piece=""), "numero de piece vide"),
        (ecriture(origine=""), "origine vide"),
    ],
)
def test_ac6_ligne_invalide_retourne_erreur_technique(tmp_path, capsys, ligne, message):
    src, _ = creer_flux(
        tmp_path,
        [ligne],
        ["GER;25/08/2026;1;10,00;10,00;FAC02_SRC_ECRITURESGL_TEST;0"],
    )

    code = gl.executer([str(src)], generer_rapport=False)

    assert code == 1
    erreur = capsys.readouterr().err.lower()
    assert "ligne 1" in erreur
    assert message in erreur


def test_ac7_calcul_en_centimes_est_exact(tmp_path):
    src, ctl = creer_flux(
        tmp_path,
        [
            ecriture(piece="P001", debit="0,10", credit="0,00"),
            ecriture(piece="P001", debit="0,20", credit="0,30"),
        ],
        ["GER;25/08/2026;1;0,30;0,30;FAC02_SRC_ECRITURESGL_TEST;0"],
    )

    resultat = gl.controler(src, ctl, generer_rapport=False)

    assert resultat.code_retour == 0
    assert resultat.origines["GER"].debit_src == 30
    assert resultat.origines["GER"].credit_src == 30


def test_ac9_les_fichiers_restent_inchanges(tmp_path):
    src, ctl = creer_flux(
        tmp_path,
        [ecriture()],
        ["GER;25/08/2026;1;10,00;10,00;FAC02_SRC_ECRITURESGL_TEST;0"],
    )
    avant = {p: (p.read_bytes(), p.stat().st_mtime_ns) for p in (src, ctl)}

    gl.controler(src, ctl, generer_rapport=False)

    apres = {p: (p.read_bytes(), p.stat().st_mtime_ns) for p in (src, ctl)}
    assert apres == avant


def test_ac8_absence_openpyxl_ne_change_pas_le_resultat(tmp_path, monkeypatch, capsys):
    src, ctl = creer_flux(
        tmp_path,
        [ecriture()],
        ["GER;25/08/2026;1;10,00;10,00;FAC02_SRC_ECRITURESGL_TEST;0"],
    )
    resultat = gl.controler(src, ctl, generer_rapport=False)
    import_reel = builtins.__import__

    def import_sans_openpyxl(nom, *args, **kwargs):
        if nom.startswith("openpyxl"):
            raise ImportError("openpyxl absent pour le test")
        return import_reel(nom, *args, **kwargs)

    monkeypatch.setattr(builtins, "__import__", import_sans_openpyxl)

    assert gl.generer_excel(resultat) is None
    assert resultat.code_retour == 0
    assert "non genere" in capsys.readouterr().err.lower()


def test_ec1_selectionne_recursivement_le_src_le_plus_recent(tmp_path):
    ancien = tmp_path / "a" / "SOURCE" / "FAC02_SRC_ECRITURESGL_ANCIEN.csv"
    recent = tmp_path / "b" / "SOURCE" / "FAC02_SRC_ECRITURESGL_RECENT.csv"
    ancien.parent.mkdir(parents=True)
    recent.parent.mkdir(parents=True)
    ancien.write_text(ecriture(), encoding="latin-1")
    recent.write_text(ecriture(), encoding="latin-1")
    os.utime(ancien, (1, 1))
    os.utime(recent, (2, 2))

    assert gl.selectionner_src(tmp_path) == recent.resolve()


def test_fr3_sans_argument_recherche_dans_source(tmp_path, monkeypatch):
    dossier_script = tmp_path / "outil"
    source = dossier_script / "SOURCE"
    source.mkdir(parents=True)
    src = source / "FAC02_SRC_ECRITURESGL_AUTO.csv"
    src.write_text(ecriture(), encoding="latin-1")
    monkeypatch.setattr(gl, "__file__", str(dossier_script / "ctl_ecritures_gl.py"))

    assert gl.selectionner_src() == src.resolve()


def test_ec2_origines_presentes_d_un_seul_cote_sont_en_ecart(tmp_path):
    src, ctl = creer_flux(
        tmp_path,
        [ecriture(origine="GER"), ecriture(piece="P002", origine="FGE")],
        ["GER;25/08/2026;1;10,00;10,00;FAC02_SRC_ECRITURESGL_TEST;0"],
    )

    resultat = gl.controler(src, ctl, generer_rapport=False)

    assert resultat.code_retour == 2
    assert resultat.origines["GER"].statut == "OK"
    assert resultat.origines["FGE"].statut == "ECART"


def test_ec5_montants_vides_sont_interpretes_comme_zero(tmp_path):
    src, ctl = creer_flux(
        tmp_path,
        [ecriture(debit="", credit="")],
        ["GER;25/08/2026;1;;;FAC02_SRC_ECRITURESGL_TEST;0"],
    )

    resultat = gl.controler(src, ctl, generer_rapport=False)

    assert resultat.code_retour == 0
    assert resultat.origines["GER"].debit_src == 0
    assert resultat.origines["GER"].credit_src == 0


def test_ec7_echec_ecriture_excel_reste_un_avertissement(tmp_path, monkeypatch, capsys):
    src, ctl = creer_flux(
        tmp_path,
        [ecriture()],
        ["GER;25/08/2026;1;10,00;10,00;FAC02_SRC_ECRITURESGL_TEST;0"],
    )
    resultat = gl.controler(src, ctl, generer_rapport=False)

    def echec_sauvegarde(*args, **kwargs):
        raise PermissionError("rapport ouvert")

    monkeypatch.setattr("openpyxl.workbook.workbook.Workbook.save", echec_sauvegarde)

    assert gl.generer_excel(resultat) is None
    assert resultat.code_retour == 0
    assert "rapport excel non genere" in capsys.readouterr().err.lower()


def test_ec8_dossier_sans_src_retourne_erreur_technique(tmp_path, capsys):
    assert gl.executer([str(tmp_path)], generer_rapport=False) == 1
    assert "aucun fichier" in capsys.readouterr().err.lower()


def test_ec6_origine_dupliquee_dans_ctl_est_refusee(tmp_path, capsys):
    src, ctl = creer_flux(
        tmp_path,
        [ecriture()],
        [
            "GER;25/08/2026;1;10,00;10,00;FAC02_SRC_ECRITURESGL_TEST;0",
            "GER;25/08/2026;1;10,00;10,00;FAC02_SRC_ECRITURESGL_TEST;0",
        ],
    )

    assert gl.executer([str(src), str(ctl)], generer_rapport=False) == 1
    assert "dupliquee" in capsys.readouterr().err.lower()
