"""Normalisation des montants : toujours en centimes entiers."""


def is_euro_amount(s: str) -> bool:
    """True si la chaine montant porte un separateur decimal (donc exprimee en euros)."""
    return "." in s or "," in s


def euros_to_cts(s: str) -> int:
    """Convertit un montant euros ('17957,83' ou '17957.83') en centimes entiers."""
    s = s.strip().replace(",", ".")
    if not s:
        return 0
    neg = s.startswith("-")
    s = s.lstrip("-")
    if "." in s:
        entier, dec = s.split(".", 1)
        dec = (dec + "00")[:2]
    else:
        entier, dec = s, "00"
    val = int(entier or "0") * 100 + int(dec)
    return -val if neg else val
