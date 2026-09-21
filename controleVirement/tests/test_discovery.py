from cv.discovery import discover_instances


def _mkinstance(base, guid):
    d = base / guid
    (d / "SOURCE").mkdir(parents=True)
    (d / "TARGET").mkdir()
    return d


def test_discover_apparie_les_guids(tmp_path):
    src = tmp_path / "26062026_source"
    cib = tmp_path / "26062026_cible"
    src.mkdir(); cib.mkdir()
    _mkinstance(src, "guidA"); _mkinstance(cib, "guidA")
    _mkinstance(src, "guidB")            # source seule (orphelin)
    _mkinstance(cib, "guidC")            # cible seule (orphelin)

    instances = {i.guid: i for i in discover_instances(tmp_path, "26062026")}
    assert set(instances) == {"guidA", "guidB", "guidC"}
    assert instances["guidA"].source_dir is not None
    assert instances["guidA"].cible_dir is not None
    assert instances["guidB"].cible_dir is None
    assert instances["guidC"].source_dir is None


def test_disposition_courante_sans_suffixe_ni_source(tmp_path):
    """Depuis septembre 2026 : ODAT/virements/JJMMAAAA/<uuid>/{SOURCE,TALEND,TARGET}, pas de dossier _source."""
    from cv.discovery import discover_instances, dossier_cible
    inst = tmp_path / "18092026" / "3693b409347c4c89967976e0924428e1"
    (inst / "SOURCE").mkdir(parents=True)
    (inst / "TARGET").mkdir()
    assert dossier_cible(tmp_path, "18092026") == tmp_path / "18092026"
    found = discover_instances(tmp_path, "18092026")
    assert [i.guid for i in found] == ["3693b409347c4c89967976e0924428e1"]
    assert found[0].cible_dir == inst and found[0].source_dir is None
    # l'ancienne disposition reste lue
    (tmp_path / "17092026_cible" / "abc").mkdir(parents=True)
    assert dossier_cible(tmp_path, "17092026") == tmp_path / "17092026_cible"
    assert [i.guid for i in discover_instances(tmp_path, "17092026")] == ["abc"]
