from cv.montant import euros_to_cts, is_euro_amount


def test_euros_to_cts_avec_point():
    assert euros_to_cts("17957.83") == 1795783


def test_euros_to_cts_avec_virgule():
    assert euros_to_cts("104431,26") == 10443126


def test_euros_to_cts_entier_sans_decimale():
    assert euros_to_cts("1000") == 100000


def test_euros_to_cts_une_decimale():
    assert euros_to_cts("5.5") == 550


def test_euros_to_cts_vide():
    assert euros_to_cts("") == 0
    assert euros_to_cts("   ") == 0


def test_is_euro_amount():
    assert is_euro_amount("17957.83") is True
    assert is_euro_amount("104431,26") is True
    assert is_euro_amount("1795783") is False
