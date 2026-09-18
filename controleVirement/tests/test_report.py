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


def test_write_reports_doublons_rend_ko(tmp_path):
    fichiers = [{"guid": "g1", "categorie": "ACK", "fichier": "ACK_B", "statut": "DOUBLON",
                 "detail": "envoi identique a ACK_A"}]
    doublons = [{"guid": "g1", "fichier": "ACK_B", "guid_original": "g1", "fichier_original": "ACK_A",
                 "nb_virements": 2, "montant_cts": 30000}]
    ok = write_reports(tmp_path / "rapport", fichiers, [], [], [], None, [], doublons)
    assert ok is False
    assert (tmp_path / "rapport" / "controle_doublons_ack.csv").exists()
    synth = (tmp_path / "rapport" / "synthese.md").read_text(encoding="utf-8")
    assert "en double" in synth
    assert "ACK_B" in synth and "ACK_A" in synth
    assert "300,00 EUR" in synth
    # Un doublon n'est pas un fichier manquant : il ne doit pas figurer dans cette section
    assert "Fichiers manquants ou incomplets" not in synth


def test_write_reports_detail_des_virements_en_double(tmp_path):
    doublons = [{"guid": "g1", "fichier": "ACK_B", "guid_original": "g1", "fichier_original": "ACK_A",
                 "nb_virements": 1, "montant_cts": 100}]
    detail = [{"guid": "g1", "fichier": "ACK_B", "fichier_original": "ACK_A",
               "nom": "COMMUNE D ALLAUCH", "iban": "FR7612345", "bic": "BIC1", "montant_cts": 100}]
    ok = write_reports(tmp_path / "rapport", [], [], [], [], None, [], doublons, detail)
    assert ok is False
    csv_detail = (tmp_path / "rapport" / "controle_doublons_virements.csv").read_text(encoding="utf-8")
    assert "COMMUNE D ALLAUCH" in csv_detail and "FR7612345" in csv_detail
    synth = (tmp_path / "rapport" / "synthese.md").read_text(encoding="utf-8")
    assert "COMMUNE D ALLAUCH" in synth and "FR7612345" in synth
    assert "controle_doublons_virements.csv" in synth


def test_write_reports_synthese_simple(tmp_path):
    fichiers = [{"guid": "g1", "categorie": "DK", "fichier": "DK_x", "statut": "MANQUANT", "detail": ""}]
    totaux_edf = [{"guid": "g1", "fichier_edf": "ACK_x", "statut_lignes": "OK", "statut_montant": "OK",
                   "nb_sources_regroupees": 1, "nb_ack_footer": 3, "montant_ack_footer": 30000}]
    doublons = [{"guid": "g1", "fichier": "ACK_B", "guid_original": "g1", "fichier_original": "ACK_A",
                 "nb_virements": 2, "montant_cts": 100}]
    quartz_totaux = {"nb_cible": 5, "nb_quartz": 5, "montant_cible_cts": 30100,
                     "montant_quartz_cts": 30100, "statut_lignes": "OK", "statut_montant": "OK"}
    write_reports(tmp_path / "rapport", fichiers, [], totaux_edf, [], quartz_totaux, [], doublons)
    simple = (tmp_path / "rapport" / "synthese_simple.md").read_text(encoding="utf-8")
    assert "Points d'attention" in simple
    assert "1 fichier(s) manquant(s)" in simple
    assert "1 envoi(s) transmis en double" in simple and "1,00 EUR" in simple
    assert "300,00 EUR" in simple           # montant transmis
    assert "ACK_B" not in simple            # pas de detail par fichier
    assert len(simple.splitlines()) < 40


def test_write_reports_synthese_simple_conforme(tmp_path):
    write_reports(tmp_path / "rapport", [], [], [], [])
    simple = (tmp_path / "rapport" / "synthese_simple.md").read_text(encoding="utf-8")
    assert "Conforme" in simple and "Points d'attention" not in simple
