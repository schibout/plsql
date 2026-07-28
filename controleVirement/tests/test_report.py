from cv.report import write_reports


def test_write_reports_tout_ok(tmp_path):
    fichiers = [{"guid": "g1", "categorie": "DK", "fichier": "DK_x", "statut": "OK", "detail": ""}]
    totaux_source = [{"guid": "g1", "fichier_source": "DK_FIN01_x", "statut_lignes": "OK",
                      "statut_montant": "OK", "euro_lines": 1}]
    totaux_edf = [{"guid": "g1", "fichier_edf": "ACK_x", "statut_lignes": "OK",
                   "statut_montant": "OK", "nb_sources_regroupees": 1}]
    quartz_totaux = {"nb_cible": 2, "nb_quartz": 2, "montant_cible_cts": 300,
                     "montant_quartz_cts": 300, "statut_lignes": "OK", "statut_montant": "OK"}
    ok = write_reports(tmp_path / "rapport", fichiers, totaux_source, totaux_edf, [],
                       quartz_totaux, [])
    assert ok is True
    assert (tmp_path / "rapport" / "controle_fichiers.csv").exists()
    assert (tmp_path / "rapport" / "controle_totaux_source.csv").exists()
    assert (tmp_path / "rapport" / "controle_totaux_edf.csv").exists()
    assert (tmp_path / "rapport" / "controle_lignes_ecarts.csv").exists()
    assert (tmp_path / "rapport" / "controle_quartz_ecarts.csv").exists()
    assert (tmp_path / "rapport" / "synthese.md").exists()


def test_write_reports_detecte_ko(tmp_path):
    fichiers = [{"guid": "g1", "categorie": "DK", "fichier": "DK_x", "statut": "MANQUANT", "detail": ""}]
    totaux_edf = [{"guid": "g1", "fichier_edf": "ACK_x", "statut_lignes": "OK",
                   "statut_montant": "KO", "nb_sources_regroupees": 2}]
    ok = write_reports(tmp_path / "rapport", fichiers, [], totaux_edf, [])
    assert ok is False
    synth = (tmp_path / "rapport" / "synthese.md").read_text(encoding="utf-8")
    assert "KO" in synth or "MANQUANT" in synth


def test_write_reports_quartz_ecart_rend_ko(tmp_path):
    quartz_totaux = {"nb_cible": 2, "nb_quartz": 1, "montant_cible_cts": 300,
                     "montant_quartz_cts": 100, "statut_lignes": "KO", "statut_montant": "KO"}
    quartz_ecarts = [{"montant_cts": 200, "type_ecart": "ABSENT_QUARTZ", "detail": "..."}]
    ok = write_reports(tmp_path / "rapport", [], [], [], [], quartz_totaux, quartz_ecarts)
    assert ok is False
    synth = (tmp_path / "rapport" / "synthese.md").read_text(encoding="utf-8")
    assert "Quartz" in synth
