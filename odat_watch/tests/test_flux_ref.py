"""Référentiel des flux : motif du nom de fichier, interlocuteurs, attributs libres, catalogue du schéma FIN01."""
import pytest

import db
import flux_ref as fx

SRC_FRS = "FAC02_SRC_FACTURESFOURNISSEURS_220926-012110_ST_FAC02_639256368703434929_001"
SRC_CLI = "FAC02_SRC_FACTURESCLIENTS_220926-010555_ST_FAC02_639256359557488818_001"
SRC_GL = "FAC02_SRC_ECRITURESGL_220926-012213"
CEL_FRS = "CEL01_SRC_FACTURESFOURNISSEURS_210926-201628_ST_CEL01_639256185881865112_001"


def _base(tmp_path):
    return db.connect(tmp_path / "t.db")


# ------------------------------------------------------------------ motif

def test_motif_joker():
    assert fx.reconnait("FAC02_SRC_FACTURESFOURNISSEURS_*", SRC_FRS)
    assert not fx.reconnait("FAC02_SRC_FACTURESFOURNISSEURS_*", SRC_CLI)
    assert fx.reconnait("*_ECRITURESGL_*", SRC_GL)
    assert fx.reconnait("fac02_src_facturesclients_*", SRC_CLI)      # casse ignorée
    assert not fx.reconnait("", SRC_CLI) and not fx.reconnait(None, SRC_CLI)


def test_motif_expression_reguliere():
    assert fx.reconnait(r"^(FAC02|CEL01)_SRC_FACTURES", SRC_FRS)
    assert not fx.reconnait(r"^CEL01_SRC_", SRC_FRS)
    assert not fx.reconnait("^([", SRC_FRS)                          # regex invalide : ne reconnaît rien


def test_flux_du_fichier_prend_le_motif_le_plus_precis(tmp_path):
    con = _base(tmp_path)
    fx.enregistrer(con, {"code": "LARGE", "motif": "FAC02_SRC_*"})
    fx.enregistrer(con, {"code": "PRECIS", "motif": "FAC02_SRC_FACTURESFOURNISSEURS_*"})
    assert fx.flux_du_fichier(con, SRC_FRS)["code"] == "PRECIS"
    assert fx.flux_du_fichier(con, SRC_CLI)["code"] == "LARGE"
    assert fx.flux_du_fichier(con, "AUTRE_CHOSE.csv") is None
    con.close()


# ------------------------------------------------------------------ fiche

def test_enregistrer_relire_supprimer(tmp_path):
    con = _base(tmp_path)
    fx.enregistrer(con, {"code": "X", "application": "CEL01", "nom_application": "CELERIS", "sens": "entrant",
                         "objet": "Factures Fournisseurs (AP)", "type_flux": "FOURNISSEURS",
                         "motif": "CEL01_SRC_FACTURESFOURNISSEURS_*", "domaine": "FINANCES"})
    f = fx.flux(con)
    assert len(f) == 1 and f.iloc[0]["nom_application"] == "CELERIS" and f.iloc[0]["cree_le"]
    assert fx.libelle(f.iloc[0].to_dict()) == "CEL01 → Oracle Factures Fournisseurs (AP)"
    fx.enregistrer(con, {"code": "X", "objet": "Renommé"})           # mise à jour partielle, cree_le conservé
    assert fx.flux(con).iloc[0]["objet"] == "Renommé" and fx.flux(con).iloc[0]["nom_application"] == "CELERIS"
    assert fx.flux(con).iloc[0]["cree_le"] == f.iloc[0]["cree_le"]
    fx.supprimer(con, "X")
    assert fx.flux(con).empty
    con.close()


def test_enregistrer_refuse_un_code_vide(tmp_path):
    con = _base(tmp_path)
    with pytest.raises(ValueError):
        fx.enregistrer(con, {"code": "  "})
    con.close()


def test_code_et_type_deduits_de_l_objet():
    assert fx.code_flux("CEL01", "entrant", "Factures Fournisseurs (AP)") == "CEL01_IN_FACTURES_FOURNISSEURS_AP"
    assert fx.code_flux("PEV01", "sortant", "Prélèvement") == "PEV01_OUT_PRELEVEMENT"
    assert fx.type_depuis_objet("Factures clients (AR)") == "CLIENTS"
    assert fx.type_depuis_objet("Ecritures GL") == "GL"
    assert fx.type_depuis_objet("Fournisseur FULL") == "AUTRE"        # référentiel, pas des factures


def test_interlocuteurs_et_attributs_suivent_le_flux(tmp_path):
    con = _base(tmp_path)
    fx.enregistrer(con, {"code": "FRS", "motif": "FAC02_SRC_FACTURESFOURNISSEURS_*"})
    fx.remplacer_interlocuteurs(con, "FRS", [{"nom": "Dupont", "role": "metier", "mail": "a@dalkia.fr"},
                                             {"nom": "EAI", "role": "EAI", "mail": "eai@dalkia.fr", "telephone": "0102"}])
    fx.remplacer_attributs(con, "FRS", {"criticite": "haute", "heure_attendue": "02:00"})
    assert list(fx.interlocuteurs(con, "FRS")["nom"]) == ["Dupont", "EAI"]
    assert fx.attributs(con, "FRS") == {"criticite": "haute", "heure_attendue": "02:00"}
    assert fx.interlocuteurs(con, "FRS", role="EAI").iloc[0]["mail"] == "eai@dalkia.fr"
    fx.remplacer_interlocuteurs(con, "FRS", [{"nom": "Seul", "role": "amont"}])
    assert list(fx.interlocuteurs(con, "FRS")["nom"]) == ["Seul"]
    fx.supprimer(con, "FRS")
    assert fx.interlocuteurs(con, "FRS").empty and fx.attributs(con, "FRS") == {}
    con.close()


# ------------------------------------------------------------------ fichiers connus et découverte

def _fichiers_connus(con):
    con.executemany("INSERT INTO fr_lignes(empreinte, fichier, folio) VALUES (?,?,?)",
                    [("e1", SRC_FRS, "GAZ"), ("e2", SRC_CLI, "GCA"), ("e3", SRC_FRS, "BIO"), ("e4", CEL_FRS, "CEE")])
    con.execute("INSERT INTO gdr_lignes(line_gdr, type, fichier_source, folio) VALUES ('l1','GL',?,?)", (SRC_GL, "FGE"))
    con.commit()


def test_fichiers_transmis_connus_et_apercu(tmp_path):
    con = _base(tmp_path)
    _fichiers_connus(con)
    assert set(fx.fichiers_connus(con)) == {SRC_FRS, SRC_CLI, SRC_GL, CEL_FRS}
    nb, exemples = fx.apercu_motif(con, "FAC02_SRC_FACTURES*")
    assert nb == 2 and SRC_FRS in exemples
    assert fx.apercu_motif(con, "RIEN_*") == (0, [])
    con.close()


def test_fichiers_sans_flux_et_decouverte(tmp_path):
    con = _base(tmp_path)
    _fichiers_connus(con)
    fx.enregistrer(con, {"code": "FRS", "motif": "FAC02_SRC_FACTURESFOURNISSEURS_*"})
    assert set(fx.fichiers_sans_flux(con)) == {SRC_CLI, SRC_GL, CEL_FRS}
    props = fx.decouvrir(con)
    assert {p["motif"] for p in props} == {"FAC02_SRC_FACTURESCLIENTS_*", "FAC02_SRC_ECRITURESGL_*",
                                           "CEL01_SRC_FACTURESFOURNISSEURS_*"}
    cli = next(p for p in props if p["motif"] == "FAC02_SRC_FACTURESCLIENTS_*")
    assert cli["sens"] == "entrant" and cli["type_flux"] == "CLIENTS" and cli["application"] == "FAC02"
    assert cli["code"] == "FAC02_SRC_FACTURESCLIENTS" and cli["nb_fichiers"] == 1
    # le code d'une fiche proposée vient du préfixe du fichier : un fichier intermédiaire ne prend jamais la
    # place d'un flux du schéma (codes APP_IN_OBJET)
    pivot = fx.proposer_fiche("CEL01_PIVOT_GL_ECRITURESGL_20260729-170423")
    assert pivot["code"] == "CEL01_PIVOT_GL_ECRITURESGL" and pivot["objet"] == "Ecritures GL"
    assert pivot["code"] != fx.code_flux("CEL01", "entrant", "Ecritures GL")
    con.close()


def test_fiche_proposee_coupe_avant_l_horodatage():
    p = fx.proposer_fiche("CDPG.NC4.EXPORT.2026050409253302485.COMP.E_COMP_DALKIA.E_COMPTA_1")
    assert p["motif"] == "CDPG.NC4.EXPORT.*" and p["application"] == "CDPG"
    assert fx.reconnait(p["motif"], "CDPG.NC4.EXPORT.2026091505465800820.STAT.E_DLK_AFB_RDC.AFB")
    q = fx.proposer_fiche("GXP01_SRC_ECRITURESGL_0119_PVR_260626-170105")
    assert q["motif"] == "GXP01_SRC_ECRITURESGL_*" and q["type_flux"] == "GL"     # code société à 4 chiffres coupé
    assert fx.proposer_fiche("FAC02_SRC_ECRITURESGL")["motif"] == "FAC02_SRC_ECRITURESGL"


# ------------------------------------------------------------------ catalogue du schéma FIN01

def test_catalogue_fin01_reflete_le_schema():
    cat = fx.catalogue_fin01()
    assert len(cat) == 66
    assert sum(f["sens"] == "entrant" for f in cat) == 33 and sum(f["sens"] == "sortant" for f in cat) == 33
    assert len({f["code"] for f in cat}) == 66                        # codes uniques
    cel = [f for f in cat if f["application"] == "CEL01"]
    assert {f["sens"] for f in cel} == {"entrant", "sortant"}           # CELERIS envoie et reçoit
    ref = next(f for f in cat if f["application"] == "REF02" and f["objet"] == "Centre Finance")
    assert ref["domaine"] == "REFERENTIEL" and ref["nature"] == "Flux Asynchrone (Fil de l'eau)"
    pev = next(f for f in cat if f["application"] == "PEV01" and f["objet"] == "Virement")
    assert pev["sens"] == "sortant" and pev["domaine"] == "PARTENAIRES EXTERNES"


def test_charger_catalogue_complete_motifs_et_sources(tmp_path):
    con = _base(tmp_path)
    _fichiers_connus(con)
    assert fx.charger_catalogue(con) == 66
    assert fx.charger_catalogue(con) == 0                                # déjà présents : rien de nouveau
    f = fx.flux(con).set_index("code")
    # motif déduit des fichiers transmis connus, seulement quand un fichier correspond
    assert f.loc["CEL01_IN_FACTURES_FOURNISSEURS_AP", "motif"] == "CEL01_SRC_FACTURESFOURNISSEURS_*"
    assert f.loc["CEL01_IN_FACTURES_FOURNISSEURS_AP", "source_etat"] == "ctrl_flux"
    assert f.loc["FAC02_IN_FACTURES_CLIENTS_AR", "motif"] == "FAC02_SRC_FACTURESCLIENTS_*"
    assert f.loc["NOT01_IN_FACTURES_FOURNISSEURS", "motif"] == ""       # aucun fichier NOT01 connu
    # sources d'état connues d'ODAT Watch
    assert f.loc["PEV01_OUT_VIREMENT", "source_etat"] == "virements"
    assert f.loc["PEV01_OUT_PRELEVEMENT", "source_etat"] == "prelevements"
    assert f.loc["EDF01_IN_RELEVES_DE_COMPTE", "source_etat"] == "releves"
    # une fiche modifiée à la main n'est pas écrasée par un rechargement
    fx.enregistrer(con, {"code": "NOT01_IN_FACTURES_FOURNISSEURS", "motif": "NOT01_SRC_*"})
    fx.charger_catalogue(con)
    assert fx.flux(con).set_index("code").loc["NOT01_IN_FACTURES_FOURNISSEURS", "motif"] == "NOT01_SRC_*"
    con.close()


# ------------------------------------------------------------------ import / export

def test_export_puis_import_csv(tmp_path):
    con = _base(tmp_path)
    fx.enregistrer(con, {"code": "FRS", "application": "FAC02", "objet": "Factures", "sens": "entrant",
                         "motif": "FAC02_SRC_FACTURESFOURNISSEURS_*"})
    fx.remplacer_interlocuteurs(con, "FRS", [{"nom": "Dupont", "role": "metier", "mail": "a@dalkia.fr"}])
    fx.remplacer_attributs(con, "FRS", {"criticite": "haute"})
    con2 = db.connect(tmp_path / "t2.db")
    assert fx.importer_csv(con2, fx.exporter_csv(con)) == 1
    assert fx.flux(con2).iloc[0]["application"] == "FAC02"
    assert fx.interlocuteurs(con2, "FRS").iloc[0]["mail"] == "a@dalkia.fr"
    assert fx.attributs(con2, "FRS") == {"criticite": "haute"}
    con.close()
    con2.close()
