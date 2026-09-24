"""Import depuis ODAT/virements/import_virement : datation par le contenu, rangement par journée, vir_imports."""
from datetime import datetime
from pathlib import Path

import db
import virements_import as vi


def _cfg(racine: Path) -> dict:
    return {"oracle": racine / "ORACLE", "edf": racine / "EDF", "rejets": racine / "REJETS"}


def _instance(dossier: Path, guid: str, jour_aaaammjj: str | None, avec_dk=True, avec_csv=True) -> Path:
    inst = dossier / guid
    (inst / "SOURCE").mkdir(parents=True)
    (inst / "TARGET").mkdir()
    (inst / "TALEND" / "LS_OUT.OK").parent.mkdir()
    (inst / "TALEND" / "LS_OUT.OK").write_text("")
    if avec_dk and jour_aaaammjj:
        (inst / "SOURCE" / f"DK_FIN01_30003-0001DCWEXP-{jour_aaaammjj}-49069237_{jour_aaaammjj}-014541.txt").write_text("x")
    if avec_csv and jour_aaaammjj:
        (inst / "TARGET" / f"ORACLE_VIREMENTS_REGROUPEMENTS_REALISES_{jour_aaaammjj}-015039.csv").write_text("x")
    for i in range(2):
        (inst / "TARGET" / f"CDPG.NC4.IMPORT_ACK.DLK_VIR_1789689039520902{i}.PY_TRANSFER.I_DAL_VIR.DALKIA.NULL").write_text("x")
        (inst / "TARGET" / f"CDPG.NC4.IMPORT_ACK.DLK_VIR_1789689039520902{i}.PY_TRANSFER.I_DAL_VIR.DALKIA.NULL.asc").write_text("x")
    return inst


def test_date_instance_depuis_dk_puis_csv(tmp_path):
    assert vi.date_instance(_instance(tmp_path, "a", "20260918")) == "18092026"
    assert vi.date_instance(_instance(tmp_path, "b", "20260915", avec_dk=False)) == "15092026"
    assert vi.date_instance(_instance(tmp_path, "c", None)) is None


def test_date_quartz_depuis_le_nom(tmp_path):
    f = tmp_path / "Liste des virements importés du jour18092026.xls"
    f.write_bytes(b"")
    assert vi.date_quartz(f) == "18092026"
    assert vi.date_quartz(tmp_path / "17092026_Liste des rejets bancaires du jour - Virement.xls") == "17092026"
    assert vi.date_quartz(tmp_path / "Liste des virements importés du jour.xls") is None   # inexistant : illisible


def test_scanner_puis_importer(tmp_path):
    racine = tmp_path / "virements"
    depot = racine / vi.DEPOT
    _instance(depot, "uuid-a", "20260918")
    _instance(depot, "uuid-b", "20260915")
    _instance(depot / "17092026", "uuid-c", None)                     # journée déposée entière, date du dossier parent
    _instance(depot, "uuid-d", None)                                  # indatable
    (depot / "Liste des virements importés du jour18092026.xls").write_bytes(b"")
    (depot / "EDF").mkdir()                                            # sous-dossiers du dépôt Drive (Apps Script)
    (depot / "EDF" / "17092026_Liste des virements importés du jour.xls").write_bytes(b"")
    (depot / "REJET").mkdir()
    (depot / "REJET" / "17092026_Liste des rejets bancaires du jour - Virement.xls").write_bytes(b"")
    (depot / "notes.txt").write_text("x")
    _instance(racine / "ORACLE" / "18092026", "uuid-deja", "20260918")           # déjà rangée : on ne réimporte pas
    _instance(depot, "uuid-deja", "20260918")

    etats = {e.chemin.name: e.etat for e in vi.scanner(depot, _cfg(racine))}
    assert etats == {"uuid-a": "à importer", "uuid-b": "à importer", "uuid-c": "à importer", "uuid-d": "date introuvable",
                     "Liste des virements importés du jour18092026.xls": "à importer", "notes.txt": "non reconnu",
                     "17092026_Liste des virements importés du jour.xls": "à importer",
                     "17092026_Liste des rejets bancaires du jour - Virement.xls": "à importer",
                     "uuid-deja": "déjà présent"}

    con = db.connect(tmp_path / "t.db")
    bilan = vi.importer(depot, _cfg(racine), con, quand=datetime(2026, 9, 21, 8, 0))
    assert sorted(e.chemin.name for e in bilan.importes) == sorted([
        "uuid-a", "uuid-b", "uuid-c", "Liste des virements importés du jour18092026.xls",
        "17092026_Liste des virements importés du jour.xls", "17092026_Liste des rejets bancaires du jour - Virement.xls"])
    assert sorted(e.chemin.name for e in bilan.ignores) == ["notes.txt", "uuid-d", "uuid-deja"]
    assert (racine / "ORACLE" / "18092026" / "uuid-a" / "SOURCE").is_dir() and (racine / "ORACLE" / "15092026" / "uuid-b").is_dir()
    assert (racine / "ORACLE" / "17092026" / "uuid-c").is_dir() and not (depot / "17092026").exists()
    assert (racine / "EDF" / "Liste des virements importés du jour18092026.xls").is_file()
    assert (racine / "EDF" / "Liste des virements importés du jour17092026.xls").is_file()
    assert (racine / "REJETS" / "17092026_Liste des rejets bancaires du jour - Virement.xls").is_file()
    assert (depot / "EDF").is_dir() and (depot / "REJET").is_dir()   # sous-dossiers Drive conservés
    assert (depot / "uuid-d").is_dir() and (depot / "notes.txt").is_file() and (depot / "uuid-deja").is_dir()
    rows = {r[0]: tuple(r) for r in con.execute("SELECT guid, date_ctrl, nb_fichiers, nb_envois, importe_le, controle_le FROM vir_imports")}
    assert rows["uuid-a"] == ("uuid-a", "2026-09-18", 7, 2, "2026-09-21 08:00:00", None)
    assert set(rows) == {"uuid-a", "uuid-b", "uuid-c"}
    assert "3 instance(s), 2 fichier(s) Quartz et 1 fichier(s) de rejets" in bilan.message and "15/09, 17/09, 18/09" in bilan.message
    assert "3 élément(s) laissé(s)" in bilan.message
    # second passage : plus rien à importer
    assert vi.importer(depot, _cfg(racine), con).importes == []
    con.close()
