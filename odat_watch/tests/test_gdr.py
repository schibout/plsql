"""GDR : lecture des exports, import en photos successives, pièces, rapprochement Folio Rose."""
from datetime import date
from pathlib import Path

import pandas as pd
import pytest

import db
import gdr

DOSSIER = Path(__file__).resolve().parents[2] / "ODAT" / "GDR"
pytestmark = pytest.mark.skipif(not DOSSIER.is_dir(), reason="données ODAT/GDR absentes")

AP_0306 = DOSSIER / "03062026_Synthese_des_rejets_AP_au_03-06-2026.csv"
GL_2905 = DOSSIER / "29052026_Synthese_des_rejets_GL_au_29-05-2026.csv"
GL_2905_02 = DOSSIER / "29052026_Synthese_des_rejets_GL_au_29-05-2026_02.csv"
GL_2806 = DOSSIER / "29062026_Synthese_des_rejets_GL_au_29-06-2026.csv"


def test_infos_nom():
    assert gdr.infos_nom("29052026_Synthese_des_rejets_GL_au_29-05-2026.csv") == (date(2026, 5, 29), "GL", 1)
    assert gdr.infos_nom("29052026_Synthese_des_rejets_AP_au_29-05-2026_02.csv") == (date(2026, 5, 29), "AP", 2)
    assert gdr.infos_nom("ExportCSV-19-08-2026.csv") is None


def test_lire_ap_report_du_code_rejet_et_montant_piece():
    f = gdr.lire_fichier(AP_0306)
    assert f.type == "AP" and f.date_photo == date(2026, 6, 3) and f.rang == 1
    l = f.lignes
    assert list(l.columns) == gdr.COLONNES
    assert (l["code_rejet"] != "").all()                       # lignes de continuation renseignées
    assert l["line_gdr"].is_unique
    p = l[l["numero_piece"] == "670000496062"]
    assert p["folio"].iloc[0] == "CEE" and p["fichier_source"].iloc[0].startswith("CEL01_SRC_FACTURESFOURNISSEURS_020626-200619")
    assert gdr.montant_piece(p) == 21586.44                    # ligne 401 = total de la facture


def test_lire_gl_montants_debit_credit():
    f = gdr.lire_fichier(GL_2905)
    l = f.lignes
    assert f.type == "GL" and len(l) == 17
    p = l[l["id_gdr"] == "588787"]
    assert len(p) == 2 and gdr.montant_piece(p) == 66146.30
    assert p["folio"].iloc[0] == "PAR" and p["fichier_source"].iloc[0] == "FAC02_SRC_ECRITURESGL_270526-171607"


def test_lire_fichier_vide():
    f = gdr.lire_fichier(DOSSIER / "29062026_Synthese_des_rejets_AR_au_29-06-2026.csv")
    assert f.type == "AR" and f.lignes.empty


def test_lire_nom_inattendu(tmp_path):
    p = tmp_path / "autre.csv"
    p.write_bytes(b"a;b\n1;2\n")
    with pytest.raises(ValueError):
        gdr.lire_fichier(p)


def test_importer_photos_successives(tmp_path):
    con = db.connect(tmp_path / "t.db")
    f1 = gdr.lire_fichier(GL_2905)
    assert gdr.importer(f1, con) is not None
    assert gdr.importer(gdr.lire_fichier(GL_2905), con) is None          # même hash
    ouverts = gdr.rejets(con)
    assert len(ouverts) == 17 and ouverts["present"].all()
    # second envoi du même jour (_02) : 2 lignes -> les 15 autres disparaissent, datées du 29/05
    gdr.importer(gdr.lire_fichier(GL_2905_02), con)
    tous = gdr.rejets(con, ouverts=False)
    assert tous["present"].sum() == 2 and (tous.loc[~tous["present"], "disparu_le"] == "2026-05-29").all()
    # photo plus récente : nouvelles lignes ; les 2 restantes disparaissent si absentes
    gdr.importer(gdr.lire_fichier(GL_2806), con)
    apres = gdr.rejets(con)
    assert len(apres) == len(gdr.lire_fichier(GL_2806).lignes)
    assert (apres["vu_le"] == "2026-06-29").all()
    # une photo plus ancienne importée après coup ne touche pas l'état courant
    assert gdr.importer(gdr.lire_fichier(DOSSIER / "28052026_Synthese_des_rejets_GL_au_28-05-2026.csv"), con) is not None
    assert len(gdr.rejets(con)) == len(apres)
    anciennes = gdr.rejets(con, ouverts=False)
    assert (anciennes.loc[anciennes["vu_le"] == "2026-05-28", "disparu_le"] == "2026-05-29").all()
    # le _02 du 28/05 est identique octet pour octet au _02 du 29/05 : refusé par le hash
    assert gdr.importer(gdr.lire_fichier(DOSSIER / "28052026_Synthese_des_rejets_GL_au_28-05-2026_02.csv"), con) is None
    assert len(gdr.fichiers(con)) == 4
    con.close()


def test_importer_dossier(tmp_path):
    d = tmp_path / "gdr"
    d.mkdir()
    for src in (GL_2905, GL_2905_02, AP_0306):
        (d / src.name).write_bytes(src.read_bytes())
    (d / "autre.csv").write_bytes(b"x;y\n")
    con = db.connect(tmp_path / "t.db")
    msgs = gdr.importer_dossier(d, con)
    assert len(msgs) == 3 and all("lignes" in m for m in msgs)
    assert gdr.importer_dossier(d, con) == []                            # rien de nouveau
    assert gdr.fichiers_du_dossier(d)[0].name.startswith("29052026") and gdr.fichiers_du_dossier(d)[-1].name.startswith("03062026")
    assert "introuvable" in gdr.importer_dossier(tmp_path / "absent", con)[0]
    con.close()


def _con_avec_gl(tmp_path):
    con = db.connect(tmp_path / "t.db")
    gdr.importer(gdr.lire_fichier(GL_2905), con)
    return con


def _ligne_fr(**kw):
    base = {"empreinte": "e1", "folio": "PAR", "fichier": "FAC02_SRC_ECRITURESGL_270526-171607", "amont_debit": 100000.0,
            "ecart_debit": 66146.30, "montant_oracle": None, "montant_interface": None}
    base.update(kw)
    return base


def test_pieces_et_verdicts(tmp_path):
    con = _con_avec_gl(tmp_path)
    pcs = gdr.pieces(gdr.rejets(con))
    assert pcs["id_gdr"].is_unique and set(pcs.columns) == set(gdr.COLS_PIECES)
    par = pcs[(pcs["fichier_source"] == "FAC02_SRC_ECRITURESGL_270526-171607") & (pcs["folio"] == "PAR")]
    assert len(par) == 1 and par["montant"].iloc[0] == 66146.30
    # l'écart débit = montant rejeté -> total
    assert gdr.verdict(_ligne_fr(), par)[0] == "total"
    assert "l'écart débit" in gdr.verdict(_ligne_fr(), par)[1]
    # rejet total de la pièce
    assert gdr.verdict(_ligne_fr(amont_debit=66146.30, ecart_debit=0.0), par)[1].endswith("(rejet total)")
    # pièce − montant OA
    niveau, texte = gdr.verdict(_ligne_fr(amont_debit=70000.0, ecart_debit=1.0, montant_oracle=3853.70), par)
    assert niveau == "total" and "montant OA" in texte
    niveau, texte = gdr.verdict(_ligne_fr(amont_debit=70000.0, ecart_debit=1.0, montant_interface=3853.70), par)
    assert niveau == "total" and "interface" in texte
    # montants différents -> probable, avec l'écart rappelé
    niveau, texte = gdr.verdict(_ligne_fr(ecart_debit=12.0), par)
    assert niveau == "probable" and "12,00 €" in texte
    assert gdr.verdict(_ligne_fr(), pcs.iloc[0:0]) == ("", "")
    con.close()


def test_verdict_piece_seule(tmp_path):
    con = _con_avec_gl(tmp_path)
    pcs = gdr.pieces(gdr.rejets(con))
    keh = pcs[pcs["folio"] == "KEH"]
    assert len(keh) >= 2
    une = keh.iloc[0]
    niveau, texte = gdr.verdict(_ligne_fr(folio="KEH", fichier=une["fichier_source"], ecart_debit=une["montant"]), keh)
    assert niveau == "piece" and une["numero_piece"] in texte
    con.close()


def test_rapprocher_folio_rose(tmp_path):
    con = _con_avec_gl(tmp_path)
    lignes = pd.DataFrame([_ligne_fr(), _ligne_fr(empreinte="e2", folio="ZZZ"),
                           _ligne_fr(empreinte="e3", folio="par", fichier="FAC02_SRC_ECRITURESGL_270526-171607 ", ecart_debit=5.0)])
    out, detail = gdr.rapprocher_folio_rose(lignes, con)
    assert list(out["gdr_niveau"]) == ["total", "", "probable"]      # folio et fichier normalisés (casse, espaces)
    assert set(detail) == {"e1", "e3"} and len(detail["e1"]) == 1
    vide, d = gdr.rapprocher_folio_rose(lignes.iloc[0:0], con)
    assert vide.empty and "gdr" in vide.columns and d == {}
    con.close()


def test_rapprocher_sans_gdr(tmp_path):
    con = db.connect(tmp_path / "t.db")
    out, detail = gdr.rapprocher_folio_rose(pd.DataFrame([_ligne_fr()]), con)
    assert (out["gdr"] == "").all() and detail == {}
    con.close()
