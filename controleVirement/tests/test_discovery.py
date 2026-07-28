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
