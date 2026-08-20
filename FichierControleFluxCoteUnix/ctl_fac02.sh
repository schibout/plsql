#!/bin/sh
#=============================================================================
# ctl_fac02.sh - Controle du flux FAC02 (factures clients)
#
# Usage : ctl_fac02.sh <fichier_SRC> [fichier_CTL]
#         Si le fichier CTL est omis, il est deduit du nom du fichier SRC
#         (remplacement de _SRC_ par _CTL_ dans le meme repertoire).
#
# Traitements :
#   1. Synthese par portefeuille : nb de factures (lignes comptes 411*)
#      et montant total (Debit +, Credit -, montants en centimes / 100)
#   2. Rapprochement SRC <-> CTL (nb factures + montant par portefeuille)
#   3. Liste des factures a montant 0
#
# Code retour : 0 = rapprochement OK, 1 = ecart detecte, 2 = erreur usage
#=============================================================================

if [ $# -lt 1 ]; then
    echo "Usage : $0 <fichier_SRC> [fichier_CTL]" >&2
    exit 2
fi

SRC="$1"
if [ $# -ge 2 ]; then
    CTL="$2"
else
    CTL=`echo "$SRC" | sed 's/_SRC_/_CTL_/'`
fi

if [ ! -r "$SRC" ]; then
    echo "ERREUR : fichier SRC introuvable : $SRC" >&2
    exit 2
fi
if [ ! -r "$CTL" ]; then
    echo "ERREUR : fichier CTL introuvable : $CTL" >&2
    exit 2
fi

echo "============================================================================="
echo " CONTROLE FLUX FAC02 - FACTURES CLIENTS"
echo " Fichier SRC : $SRC"
echo " Fichier CTL : $CTL"
echo "============================================================================="

#-----------------------------------------------------------------------------
# 1. Synthese par portefeuille (lignes comptes clients 411*)
#-----------------------------------------------------------------------------
echo ""
echo "--- 1. SYNTHESE PAR PORTEFEUILLE (fichier SRC) ---"
awk -F';' '
$7 ~ /^411/ {
    m = $13 + 0
    if ($14 == "-") m = -m
    if ($12 == "C") m = -m
    cnt[$17]++
    amt[$17] += m
}
END {
    for (p in cnt) {
        v = sprintf("%.2f", amt[p] / 100)
        gsub(/\./, ",", v)
        printf "Portefeuille %-4s : %5d factures, montant %15s\n", p, cnt[p], v
    }
}' "$SRC" | sort

#-----------------------------------------------------------------------------
# 2. Rapprochement SRC <-> CTL
#-----------------------------------------------------------------------------
echo ""
echo "--- 2. RAPPROCHEMENT SRC <-> CTL ---"
RAPPRO=`awk -F';' '
FNR == NR {
    # Fichier CTL : PORTEFEUILLE;DATE;NB;MONTANT;MONTANT;FICHIER;0
    if (NF >= 4 && $1 != "") {
        gsub(/,/, ".", $4)
        ctl_cnt[$1] = $3 + 0
        ctl_amt[$1] = $4 + 0
        ctl_seen[$1] = 1
    }
    next
}
$7 ~ /^411/ {
    m = $13 + 0
    if ($14 == "-") m = -m
    if ($12 == "C") m = -m
    src_cnt[$17]++
    src_amt[$17] += m
}
END {
    ko = 0
    for (p in src_cnt) {
        sa = src_amt[p] / 100
        if (!(p in ctl_seen)) {
            printf "ECART  %-4s : present dans SRC mais absent du CTL (%d factures)\n", p, src_cnt[p]
            ko = 1
        } else {
            diff_amt = sa - ctl_amt[p]
            if (diff_amt < 0) diff_amt = -diff_amt
            if (src_cnt[p] == ctl_cnt[p] && diff_amt < 0.005) {
                printf "OK     %-4s : %5d factures, montant %.2f\n", p, src_cnt[p], sa
            } else {
                printf "ECART  %-4s : SRC=%d factures / %.2f  --  CTL=%d factures / %.2f\n", \
                       p, src_cnt[p], sa, ctl_cnt[p], ctl_amt[p]
                ko = 1
            }
        }
    }
    for (p in ctl_seen) {
        if (!(p in src_cnt)) {
            printf "ECART  %-4s : present dans CTL mais absent du SRC\n", p
            ko = 1
        }
    }
    exit ko
}' "$CTL" "$SRC"`
RC_RAPPRO=$?
echo "$RAPPRO" | sort -k2 | sed 's/\./,/g'

#-----------------------------------------------------------------------------
# 3. Factures a montant 0
#-----------------------------------------------------------------------------
echo ""
echo "--- 3. FACTURES A MONTANT 0 ---"
awk -F';' '
$7 ~ /^411/ && ($13 + 0) == 0 {
    n++
    printf "Portefeuille %-4s facture %-12s compte %s date %s\n", $17, $3, $7, $9
}
END {
    if (n == 0) print "Aucune facture a montant 0."
    else printf "TOTAL : %d facture(s) a montant 0\n", n
}' "$SRC"

#-----------------------------------------------------------------------------
# Bilan
#-----------------------------------------------------------------------------
echo ""
echo "============================================================================="
if [ "$RC_RAPPRO" -eq 0 ]; then
    echo " RESULTAT : RAPPROCHEMENT OK"
    echo "============================================================================="
    exit 0
else
    echo " RESULTAT : ECART(S) DETECTE(S) - voir section 2"
    echo "============================================================================="
    exit 1
fi
