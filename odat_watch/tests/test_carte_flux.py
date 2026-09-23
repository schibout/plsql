"""Carte des flux : état de chaque flux selon sa source, nœuds et liens du diagramme, compteurs."""
import carte_flux as cf
import db
import flux_ref as fx

CEL_FRS = "CEL01_SRC_FACTURESFOURNISSEURS_210926-201628_ST_CEL01_639256185881865112_001"


def _ligne(con, fichier, folio, ecart=0.0, date="21/09/2026", emp=None):
    con.execute("INSERT INTO fr_lignes(empreinte, folio, date, type, fichier, fichier_base, amont_nb, amont_debit, "
                "si_nb, si_debit, ecart_nb, ecart_debit, present) VALUES (?,?,?,?,?,?,10,1000,10,?,0,?,1)",
                (emp or f"{fichier}|{folio}", folio, date, "FOURNISSEURS", fichier, fichier[:40], 1000 - ecart, ecart))
    con.commit()


def _fiche(**kw):
    base = {"code": "CEL01_IN_FACTURES_FOURNISSEURS_AP", "application": "CEL01", "nom_application": "CELERIS",
            "domaine": "FINANCES", "sens": "entrant", "objet": "Factures Fournisseurs (AP)",
            "nature": "Flux Asynchrone (Batch)", "statut": "Actif", "type_flux": "FOURNISSEURS",
            "motif": "CEL01_SRC_FACTURESFOURNISSEURS_*", "source_etat": "ctrl_flux"}
    base.update(kw)
    return base


def test_etat_ctrl_flux_ok_puis_ecart(tmp_path):
    con = db.connect(tmp_path / "t.db")
    assert cf.etat_flux(con, _fiche())["etat"] == "inconnu"            # aucun fichier reconnu
    _ligne(con, CEL_FRS, "CEE")
    e = cf.etat_flux(con, _fiche())
    assert e["etat"] == "ok" and e["nb_fichiers"] == 1 and e["vu_le"].strftime("%d/%m/%Y") == "21/09/2026"
    _ligne(con, CEL_FRS, "CEG", ecart=250.0)
    e = cf.etat_flux(con, _fiche())
    assert e["etat"] == "ecart" and e["ecart"] == 250.0 and "1 ligne(s) en écart" in e["detail"]
    con.close()


def test_ligne_rapprochee_ne_compte_plus(tmp_path):
    con = db.connect(tmp_path / "t.db")
    _ligne(con, CEL_FRS, "CEE", ecart=100.0, emp="a")
    _ligne(con, CEL_FRS, "CEG", ecart=-100.0, emp="b")
    assert cf.etat_flux(con, _fiche())["etat"] == "ecart"
    import ctrl_flux as cx
    cx.rapprocher(["a", "b"], "compensé", con)
    assert cf.etat_flux(con, _fiche())["etat"] == "ok"
    con.close()


def test_etat_sans_motif_ni_source_et_inactif(tmp_path):
    con = db.connect(tmp_path / "t.db")
    assert cf.etat_flux(con, _fiche(motif="", source_etat=""))["etat"] == "inconnu"
    assert cf.etat_flux(con, _fiche(statut="Inactif"))["etat"] == "inactif"
    con.close()


def test_etat_virements_prelevements_releves(tmp_path):
    con = db.connect(tmp_path / "t.db")
    vir = _fiche(code="PEV01_OUT_VIREMENT", motif="", source_etat="virements", sens="sortant")
    pre = _fiche(code="PEV01_OUT_PRELEVEMENT", motif="", source_etat="prelevements", sens="sortant")
    rel = _fiche(code="EDF01_IN_RELEVES_DE_COMPTE", motif="", source_etat="releves")
    assert cf.etat_flux(con, vir)["etat"] == "inconnu" and cf.etat_flux(con, pre)["etat"] == "inconnu"
    assert cf.etat_flux(con, rel)["etat"] == "inconnu"
    con.execute("INSERT INTO vir_histo(date_ctrl, executed_at, ok, nb_instances, nb_envoyes, montant_envoye, ko, "
                "a_verifier, ecarts) VALUES ('2026-09-19','2026-09-19 12:00:00',1,2,205,2667877.07,0,0,0)")
    con.execute("INSERT INTO pv_histo(reference, executed_at, statut_global, nb_cles, nb_emis, montant_emis) "
                "VALUES ('2026-09-18','2026-09-18 08:00:00','ANOMALIES',10,9,100.0)")
    con.execute("INSERT INTO rb_ebs(nom, nb_releves, nb_lignes, date_min, date_max) VALUES ('AFB120.txt_x',12,300,"
                "'2026-09-17','2026-09-18')")
    con.commit()
    v = cf.etat_flux(con, vir)
    assert v["etat"] == "ok" and "205 envoi(s)" in v["detail"] and v["vu_le"].day == 19
    p = cf.etat_flux(con, pre)
    assert p["etat"] == "ecart" and "ANOMALIES" in p["detail"]
    assert cf.etat_flux(con, rel)["etat"] == "ok"
    con.close()


def test_carte_sankey_et_resume(tmp_path):
    con = db.connect(tmp_path / "t.db")
    _ligne(con, CEL_FRS, "CEE")
    fx.charger_catalogue(con)
    df = cf.carte(con)
    assert len(df) == 66 and set(df["etat"]) <= set(cf.ETATS)
    assert df.set_index("code").loc["CEL01_IN_FACTURES_FOURNISSEURS_AP", "etat"] == "ok"
    s = cf.sankey(df)
    labels = [n["label"] for n in s["noeuds"]]
    assert cf.ORACLE in labels and labels.count("CEL01 · CELERIS") == 2   # CELERIS des deux côtés
    assert len(s["liens"]) == 66
    centre = next(i for i, n in enumerate(s["noeuds"]) if n["cle"] == "oracle")
    assert all(l["cible"] == centre for l in s["liens"] if df.set_index("code").loc[l["code"], "sens"] == "entrant")
    assert all(l["source"] == centre for l in s["liens"] if df.set_index("code").loc[l["code"], "sens"] == "sortant")
    r = cf.resume(df)
    assert r["flux"] == 66 and r["entrants"] == 33 and r["sortants"] == 33 and r["ok"] >= 1
    assert r["ok"] + r["ecart"] + r["inconnu"] + r["inactif"] == 66
    con.close()


def test_carte_vide():
    import sqlite3
    con = db.connect(":memory:")
    df = cf.carte(con)
    assert df.empty and "etat" in df.columns
    assert cf.resume(df)["flux"] == 0
    con.close()


def test_graphe_facon_neo4j(tmp_path):
    con = db.connect(tmp_path / "t.db")
    _ligne(con, CEL_FRS, "CEE", ecart=40.0)
    fx.charger_catalogue(con)
    g = cf.graphe(cf.carte(con))
    ids = [n["id"] for n in g["noeuds"]]
    assert ids[0] == cf.ORACLE_ID and len(ids) == 1 + 25                # Oracle + une fois chaque application
    assert len(set(ids)) == len(ids)
    oracle = g["noeuds"][0]
    assert oracle["x"] == 0 and oracle["y"] == 0 and oracle["couleur"] == cf.COULEUR_ORACLE
    cel = next(n for n in g["noeuds"] if n["id"] == "CEL01")
    assert cel["sens"] == "mixte" and cel["couleur"] == cf.COULEURS_DOMAINE["FINANCES"]
    assert "CELERIS" in cel["label"] and "flux" in cel["titre"]
    entrant_pur = next(n for n in g["noeuds"] if n["id"] == "REF02")
    sortant_pur = next(n for n in g["noeuds"] if n["id"] == "HEC01")
    assert entrant_pur["x"] < 0 < sortant_pur["x"]                       # entrants à gauche, sortants à droite
    assert len(g["liens"]) == 66
    vers_oracle = [l for l in g["liens"] if l["vers"] == cf.ORACLE_ID]
    depuis = [l for l in g["liens"] if l["de"] == cf.ORACLE_ID]
    assert len(vers_oracle) == 33 and len(depuis) == 33
    # les trois flux CEL01 -> Oracle s'écartent, le flux en écart est orange et épais
    cel_liens = [l for l in vers_oracle if l["de"] == "CEL01"]
    assert len({l["roundness"] for l in cel_liens}) == len(cel_liens) == 3
    ap = next(l for l in cel_liens if l["code"] == "CEL01_IN_FACTURES_FOURNISSEURS_AP")
    assert ap["etat"] == "ecart" and ap["couleur"] == cf.COULEURS_ETAT["ecart"] and ap["largeur"] == 3
    assert ap["tirets"] == [8, 4]                                        # batch
    ref = next(l for l in vers_oracle if l["code"] == "REF02_IN_CENTRE_FINANCE")
    assert ref["tirets"] == [2, 4]                                       # fil de l'eau
    assert cf.graphe(cf.carte(db.connect(":memory:")))["liens"] == []
    con.close()


def test_volumetrie_ctrl_flux_dans_l_etat(tmp_path):
    con = db.connect(tmp_path / "t.db")
    _ligne(con, CEL_FRS, "CEE", ecart=40.0, emp="a")
    _ligne(con, CEL_FRS, "CEG", emp="b")
    e = cf.etat_flux(con, _fiche())
    assert e["nb_fichiers"] == 1 and e["nb_lignes"] == 2 and e["nb_folios"] == 2
    assert e["folios"] == "CEE, CEG" and e["types"] == "FOURNISSEURS"
    assert e["nb_pieces"] == 20.0 and e["montant"] == 2000.0     # 10 pièces et 1 000 € amont par ligne
    assert e["ecart"] == 40.0 and e["nb_ecart"] == 1 and e["dernier_fichier"] == CEL_FRS
    # les colonnes de volumétrie remontent dans la carte
    fx.enregistrer(con, _fiche())
    ligne = cf.carte(con).iloc[0]
    for c in cf.COLS_VOLUME:
        assert c in ligne
    assert ligne["nb_folios"] == 2 and ligne["dernier_fichier"] == CEL_FRS
    con.close()


def test_infobulles_detaillees(tmp_path):
    con = db.connect(tmp_path / "t.db")
    _ligne(con, CEL_FRS, "CEE", ecart=40.0)
    fx.charger_catalogue(con)
    g = cf.graphe(cf.carte(con))
    cel = next(n for n in g["noeuds"] if n["id"] == "CEL01")
    # le nœud résume par type de flux, avec folios et motifs
    assert "FOURNISSEURS :" in cel["titre"] and "GL :" in cel["titre"]
    assert "Folios : CEE" in cel["titre"] and "Motifs :" in cel["titre"]
    assert "Dernier fichier : " + CEL_FRS in cel["titre"]
    assert cel["nb_fichiers"] == 1 and cel["ecart"] == 40.0 and cel["folios"] == ["CEE"]
    assert "pièces" in cel["label"] or "fichier" in cel["label"]
    # le lien porte le motif et la volumétrie du flux
    lien = next(l for l in g["liens"] if l["code"] == "CEL01_IN_FACTURES_FOURNISSEURS_AP")
    assert "[FOURNISSEURS]" in lien["titre"] and "Motif : CEL01_SRC_FACTURESFOURNISSEURS_*" in lien["titre"]
    assert "1 fichier(s)" in lien["titre"] and "Folios : CEE" in lien["titre"]
    assert lien["type_flux"] == "FOURNISSEURS"
    con.close()


def test_graphe_par_type_de_flux(tmp_path):
    con = db.connect(tmp_path / "t.db")
    _ligne(con, CEL_FRS, "CEE")
    fx.charger_catalogue(con)
    df = cf.carte(con)
    g = cf.graphe(df, par_type=True)
    ids = [n["id"] for n in g["noeuds"]]
    assert cf.ORACLE_ID in ids and len(ids) > 26                      # plus de nœuds qu'en mode application
    assert "CEL01 · FOURNISSEURS" in ids and "CEL01 · GL" in ids and "CEL01 · AUTRE" in ids
    frs = next(n for n in g["noeuds"] if n["id"] == "CEL01 · FOURNISSEURS")
    assert frs["type_flux"] == "FOURNISSEURS" and frs["application"] == "CEL01"
    assert frs["label"].startswith("CEL01 · FOURNISSEURS")
    assert len(g["liens"]) == len(df)                                  # toujours un lien par flux
    assert all(l["de"] == cf.ORACLE_ID or l["vers"] == cf.ORACLE_ID for l in g["liens"])
    con.close()
