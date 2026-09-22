"""Récupération des logs d'une sélection de demandes : liste pour copy_ebs_logs.sh et état local."""
import db
import logs


def _base(tmp_path):
    con = db.connect(tmp_path / "t.db")
    con.executemany(
        "INSERT INTO ora_requests(request_id, job_name, source, phase_code, status_code, logfile_name, outfile_name) "
        "VALUES (?,?,?,?,?,?,?)",
        [(1, "JOB_A", "oracle", "C", "E", "/log/l1.req", "/out/o1.out"),
         (2, "JOB_B", "oracle", "C", "N", "/log/l2.req", "/out/o2.out"),
         (3, "JOB_C", "oracle", "C", "E", None, None),
         (4, "JOB_D", "mock", "C", "E", "/log/l4.req", "/out/o4.out")])
    con.execute("INSERT INTO ora_request_logs(request_id, kind, path) VALUES (1, 'req', 'l1.req')")
    con.commit()
    return con


def test_chemins_de_la_selection(tmp_path):
    con = _base(tmp_path)
    c = logs.chemins(con, [1, 2, 3])
    assert [r["request_id"] for r in c] == [1, 2, 3]
    assert c[0]["logfile_name"] == "/log/l1.req" and c[0]["deja_local"] is True
    assert c[1]["deja_local"] is False
    assert c[2]["logfile_name"] is None                      # demande sans chemin connu
    assert logs.chemins(con, []) == []
    con.close()


def test_liste_de_la_selection(tmp_path):
    con = _base(tmp_path)
    dest = tmp_path / "list.txt"
    msg = logs.ecrire_liste(dest, request_ids=[1, 2, 3], con=con)
    lignes = dest.read_text(encoding="utf-8").strip().split("\n")
    assert lignes == ["/log/l1.req /out/o1.out", "/log/l2.req /out/o2.out"]   # la 3 n'a pas de chemin
    assert "2 ligne(s)" in msg and str(dest) in msg
    con.close()


def test_liste_par_defaut_inchangee(tmp_path):
    # sans sélection : demandes en erreur, source oracle, dont le log n'est pas déjà en base
    con = _base(tmp_path)
    dest = tmp_path / "list.txt"
    logs.ecrire_liste(dest, con=con)
    assert dest.read_text(encoding="utf-8").strip() == ""    # la 1 a son log, la 3 n'a pas de chemin
    con.execute("DELETE FROM ora_request_logs")
    con.commit()
    logs.ecrire_liste(dest, con=con)
    assert dest.read_text(encoding="utf-8").strip() == "/log/l1.req /out/o1.out"
    con.close()


def test_contenu_liste(tmp_path):
    con = _base(tmp_path)
    assert logs.contenu_liste(con, [1, 2]) == "/log/l1.req /out/o1.out\n/log/l2.req /out/o2.out\n"
    con.close()
