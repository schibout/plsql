"""Mail de rapport : brouillon .eml relisible par un client mail, pièces jointes, config [mail]."""
from email import policy
from email.parser import BytesParser

import mail


def test_config_mail_par_defaut(monkeypatch, tmp_path):
    monkeypatch.setattr(mail, "CONFIG", tmp_path / "absent.ini")
    cfg = mail.config_mail()
    assert cfg["smtp_hote"] == "" and cfg["smtp_port"] == 25
    assert mail.destinataires(cfg, "virements") == []


def test_config_mail_lue(monkeypatch, tmp_path):
    ini = tmp_path / "config.ini"
    ini.write_text("[mail]\nsmtp_hote = relais.interne\nsmtp_port = 2525\nexpediteur = odat@dalkia.fr\n"
                   "destinataires_virements = a@dalkia.fr; b@dalkia.fr ,c@dalkia.fr\n", encoding="utf-8")
    monkeypatch.setattr(mail, "CONFIG", ini)
    cfg = mail.config_mail()
    assert cfg["smtp_hote"] == "relais.interne" and cfg["smtp_port"] == 2525
    assert mail.destinataires(cfg, "virements") == ["a@dalkia.fr", "b@dalkia.fr", "c@dalkia.fr"]
    assert mail.destinataires(cfg, "prelevements") == []


def test_composer_eml_avec_pieces_jointes(tmp_path):
    html = tmp_path / "Virements_18092026.html"
    html.write_text("<html><body><b>ok</b></body></html>", encoding="utf-8")
    csv = tmp_path / "doublons.csv"
    csv.write_text("a;b\n1;2\n", encoding="utf-8")
    msg = mail.composer("Virements du 18/09/2026 : Conforme", "<p>Conforme</p>", "Conforme",
                        [html, csv, tmp_path / "absent.xlsx"], destinataires=["a@dalkia.fr"])
    lu = BytesParser(policy=policy.default).parsebytes(mail.eml(msg))
    assert lu["Subject"] == "Virements du 18/09/2026 : Conforme" and lu["To"] == "a@dalkia.fr"
    assert lu["X-Unsent"] == "1"                       # Outlook l'ouvre en composition
    pieces = [p.get_filename() for p in lu.iter_attachments()]
    assert pieces == ["Virements_18092026.html", "doublons.csv"]   # la pièce absente est ignorée
    assert lu.get_body(preferencelist=("html",)).get_content().strip() == "<p>Conforme</p>"
    assert "Conforme" in lu.get_body(preferencelist=("plain",)).get_content()


def test_envoyer_refuse_sans_smtp():
    import pytest
    msg = mail.composer("x", "<p>x</p>", "x", destinataires=["a@b"])
    with pytest.raises(RuntimeError):
        mail.envoyer(msg, {"smtp_hote": "", "smtp_port": 25})
