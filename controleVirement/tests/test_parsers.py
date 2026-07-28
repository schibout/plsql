from cv.parsers import parse_dk, parse_dk_fin01, parse_oracle_csv

EN_TETE = "AP_VE_1-2;DK_0001_30003-0001DEWRBT-20260626-48313956;104431.26;AP;;ORACLE"
COLS = "ENTITYID;COUNTERPARTYID;CASHFLOWTYPE;PAYMENTMETHOD;PRIORITYID;VALUEDATE;TRANSACTIONDATE;ENTITYBANKACCOUNTNUMBER;CURRENCYCODE;AMOUNT;COUNTERPARTYNAME;COUNTERPARTYBANKACCOUNTNUMBER;CPTYSECONDARYACCOUNTNUMBER;COUNTERPARTYBANKACCOUNTCOUNTRYCODE;COUNTERPARTYBANKCODE"


def _ligne(amount, nom, iban, bic):
    c = ["0001", "NO", "COMMP", "EFT", "0", "07/01/2026", "06/30/2026",
         "FR76", "EUR", amount, nom, "3000", iban, "FR", bic]
    return ";".join(c)


def test_parse_dk_montants_euros(tmp_path):
    p = tmp_path / "DK_30003-0001DEWRBT-x.txt"
    p.write_text("\n".join([
        EN_TETE, COLS,
        _ligne("17957.83", "COMMUNE D ALLAUCH", "FR093000100512C138000000021", "BDFEFRPPCCT"),
        _ligne("988.04", "COMMUNE D ISTRES", "FR883000100107D136000000003", "BDFEFRPPCCT"),
    ]), encoding="latin-1")
    lot = parse_dk(p)
    assert lot.montant_entete_cts == 10443126
    assert len(lot.virements) == 2
    assert lot.virements[0].montant_cts == 1795783
    assert lot.virements[0].iban == "FR093000100512C138000000021"
    assert lot.virements[0].nom == "COMMUNE D ALLAUCH"
    assert lot.virements[0].bic == "BDFEFRPPCCT"
    assert lot.euro_lines == 0


from cv.parsers import parse_ack


def _place(champs):
    """Construit un enregistrement a positions fixes.

    champs : liste de (pos_1based, valeur). La valeur est ecrite a partir de pos.
    """
    taille = max(pos - 1 + len(val) for pos, val in champs)
    buf = [" "] * taille
    for pos, val in champs:
        for i, ch in enumerate(val):
            buf[pos - 1 + i] = ch
    return "".join(buf)


def test_parse_ack(tmp_path):
    rec03 = _place([(1, "03"), (81, "FR7630003012400002515002490")]).ljust(203)
    rec06 = _place([
        (1, "06"),
        (24, "COMMUNE D ALLAUCH"),
        (48, "BANQUE DE FRANCE"),
        (72, "BDFEFRPPCCT"),
        (83, "FR093000100512C138000000021"),
        (117, "0000000001795783"),
        (133, "20260626"),
    ]).ljust(398)
    rec08 = _place([(1, "08"), (5, "0000001"), (12, "0000000001795783")]).ljust(203)
    p = tmp_path / "CDPG.NC4.IMPORT_ACK.DLK_VIR_x.PY_TRANSFER.I_DAL_VIR.DALKIA.NULL"
    p.write_text("\n".join([rec03, rec06, rec08]), encoding="latin-1")

    ack = parse_ack(p)
    assert ack.iban_payeur == "FR7630003012400002515002490"
    assert ack.footer_count == 1
    assert ack.footer_total_cts == 1795783
    assert len(ack.virements) == 1
    v = ack.virements[0]
    assert v.montant_cts == 1795783
    assert v.iban == "FR093000100512C138000000021"
    assert v.nom == "COMMUNE D ALLAUCH"
    assert v.bic == "BDFEFRPPCCT"


def test_parse_dk_fin01_exclut_ligne_euros(tmp_path):
    p = tmp_path / "DK_FIN01_30003-0001DEWRBT-x.txt"
    p.write_text("\n".join([
        EN_TETE, COLS,
        _ligne("17957.83", "COMMUNE D ALLAUCH", "FR093000100512C138000000021", "BDFEFRPPCCT"),  # parasite euros
        _ligne("1795783", "COMMUNE D ALLAUCH", "FR093000100512C138000000021", "BDFEFRPPCCT"),
        _ligne("98804", "COMMUNE D ISTRES", "FR883000100107D136000000003", "BDFEFRPPCCT"),
    ]), encoding="latin-1")
    lot = parse_dk_fin01(p)
    assert lot.euro_lines == 1
    assert len(lot.virements) == 2
    assert [v.montant_cts for v in lot.virements] == [1795783, 98804]


def test_parse_oracle_csv(tmp_path):
    header = ("Code banque payeur;IBAN compte bancaire payeur;Date;Nom du fichier source;"
              "Nombre de virements du fichier source;Montant des virements du fichier source;"
              "Nom du fichier EDF;Nombre de virements du fichier EDF;Montant total du fichier EDF")
    row = ("30003;FR7630003012400002515002490;20260630;"
           "DK_FIN01_30003-0001DEWRBT-20260626-48313956_20260626-024023.txt;3;104431,26;"
           "CDPG.NC4.IMPORT_ACK.DLK_VIR_17824349963281142.PY_TRANSFER.I_DAL_VIR.DALKIA.NULL;3;104431,26")
    p = tmp_path / "ORACLE_VIREMENTS_REGROUPEMENTS_REALISES_x.csv"
    p.write_text("\n".join([header, row]), encoding="latin-1")

    rows = parse_oracle_csv(p)
    assert len(rows) == 1
    r = rows[0]
    assert r.nom_fichier_source.startswith("DK_FIN01_30003-0001DEWRBT")
    assert r.nb_source == 3
    assert r.montant_source_cts == 10443126
    assert r.nom_fichier_edf.startswith("CDPG.NC4.IMPORT_ACK")
    assert r.nb_edf == 3
    assert r.montant_edf_cts == 10443126


from cv.parsers import _quartz_virements


def test_quartz_virements_filtre_les_lignes_vsep():
    # colonnes : 0=compte ... 5=montant 6=code 7=motif 8=tiers
    matrix = [
        ["Compte societe", "", "", "", "", "", "", "", ""],           # entete/filtre
        ["Compte societe", "Desc", "", "", "Dev", "Transaction", "Code transaction", "Motif", "Tiers"],
        ["0001CE512010", "0001 - DALKIA", 46199.0, 46203.0, "EUR", 7557.12, "VSEP", "20260626-0231DMSRBT...", "FONCIA IGD"],
        ["0001CE512010", "0001 - DALKIA", 46199.0, 46203.0, "EUR", 155099.0, "VSEP", "20260626-0231DMSRBT...", "SCI VENDOME EUROPE"],
        ["30/06/2026", "", "", 2.0, "EUR", 162656.12, "", "", ""],     # sous-total : ignore
        ["EUR", "", "", 2.0, "EUR", 162656.12, "", "", ""],            # total general : ignore
    ]
    virs = _quartz_virements(matrix)
    assert len(virs) == 2
    assert virs[0].montant_cts == 755712
    assert virs[0].nom == "FONCIA IGD"
    assert virs[1].montant_cts == 15509900
    assert virs[1].nom == "SCI VENDOME EUROPE"
