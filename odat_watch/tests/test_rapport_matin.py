"""Rapport HTML du contrôle du matin : pur, sans Oracle ni SQLite."""
from datetime import date, datetime

import pandas as pd

import controle_matin as cm
import rapport_matin as rm


def _sections(**maj):
    out = [cm.Section(cle=cle, titre=titre, df=pd.DataFrame()) for cle, titre, _sql, _a in cm.CATALOGUE]
    for sec in out:
        if sec.cle in maj:
            v = maj[sec.cle]
            if isinstance(v, str):
                sec.erreur = v
            else:
                sec.df, sec.alerte = v, True
    return out


def _resultat(statut="OK", executed_at=datetime(2026, 9, 19, 7, 30), **maj):
    c = dict(nb_flux_dsp=6, nb_ndf=3, nb_fac_xerox=10, nb_fac_tradeshift=4, nb_fac_dsp=0,
             nb_gl_interface=12, nb_gl_lignes=250, nb_traitements=80, nb_erreurs=0,
             nb_warnings=0, nb_rb_imports=2, nb_images_manq=0)
    debut, fin = cm.plage_par_defaut(executed_at)
    return cm.Resultat(executed_at=executed_at, debut=debut, fin=fin, nb_jours_histo=3,
                       compteurs=c, statuts=cm.statuts(c), statut_global=statut,
                       sections=_sections(**maj), duree_s=4.2, date_rb_max=date(2026, 9, 18))


def test_structure_generale():
    h = rm.construire(_resultat())
    assert h.count("<h2>") == 15
    assert "Contrôle quotidien FIN-FINANCE — 19/09/2026" in h
    assert "18/09/2026 19:00" in h and "19/09/2026 07:00" in h      # plage contrôlée
    assert 'class="bandeau ok"' in h
    assert "Aucune ligne" in h
    assert "Flux DSP (fichiers)" in h and "pill ok" in h


def test_bandeau_selon_statut():
    assert 'bandeau warn' in rm.construire(_resultat("WARNING"))
    assert 'bandeau ko' in rm.construire(_resultat("ALERTE"))
    assert 'bandeau ko' in rm.construire(_resultat("ERREUR"))


def test_tableau_et_echappement():
    df = pd.DataFrame({"REQ_ID": [1], "JOB_CTM": ["FINFIN_J18TRT_04_IMP01_Q"], "MSG": ["a < b & c"]})
    h = rm.construire(_resultat("ALERTE", nuit_err_detail=df))
    assert "<th>JOB_CTM</th>" in h
    assert "a &lt; b &amp; c" in h
    assert "a < b" not in h


def test_section_en_erreur_affiche_le_message_oracle():
    h = rm.construire(_resultat("ERREUR", rb="ORA-00942: table ou vue inexistante"))
    assert "ORA-00942" in h
    assert 'class="erreur"' in h


def test_rappel_lundi():
    lundi = datetime(2026, 9, 21, 7, 30)
    assert "fichier SG" in rm.construire(_resultat(executed_at=lundi))
    assert "fichier SG" not in rm.construire(_resultat())


def test_ecrire_nomme_le_fichier(tmp_path):
    p = rm.ecrire(_resultat(), tmp_path)
    assert p.name == "Controle_Matin_20260919_0730.html"
    assert p.read_text(encoding="utf-8").startswith("<!DOCTYPE html>")
