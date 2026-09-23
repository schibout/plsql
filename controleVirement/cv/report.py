"""Ecriture des rapports CSV et de la synthese markdown.

La synthese markdown est destinee aux equipes fonctionnelles (MOA) : elle est
volontairement redigee en langage metier, sans jargon technique, et explique ce
que chaque controle verifie ainsi que la portee de chaque ecart constate.
"""
import csv
from pathlib import Path


# Traduction des codes d'ecart en langage comprehensible par un fonctionnel.
# Pour chaque code : (libelle court, explication de ce que cela signifie concretement)
LIBELLES_ECARTS = {
    "ABSENT_ACK": (
        "Virement preparé mais absent de l'envoi à la banque",
        "Le virement figure dans le fichier préparé en amont, mais il ne se retrouve pas "
        "dans le fichier réellement transmis à la banque. Le bénéficiaire risque donc de "
        "ne pas être payé.",
    ),
    "ABSENT_DK_FIN01": (
        "Virement envoyé à la banque sans préparation correspondante",
        "Le virement figure dans le fichier transmis à la banque alors qu'il n'apparaît pas "
        "dans le fichier préparé en amont. Un paiement pourrait être exécuté sans avoir été "
        "demandé.",
    ),
    "NOM_DIFFERENT": (
        "Nom du bénéficiaire différent d'une étape à l'autre",
        "Le montant correspond bien, mais le nom du bénéficiaire n'est pas identique entre "
        "les deux étapes comparées. Le paiement peut être rejeté par la banque ou versé au "
        "mauvais destinataire.",
    ),
    "BIC_DIFFERENT": (
        "Banque du bénéficiaire différente d'une étape à l'autre",
        "Le bénéficiaire et le montant correspondent, mais l'établissement bancaire indiqué "
        "diffère entre les deux étapes comparées.",
    ),
    "ABSENT_QUARTZ": (
        "Virement envoyé mais non repris par la trésorerie",
        "Le virement a bien été transmis à la banque, mais il n'apparaît pas dans l'import "
        "réalisé par la trésorerie. Il s'agit le plus souvent d'un décalage de reprise "
        "(le virement remontera sur une journée suivante), à confirmer avec la trésorerie.",
    ),
    "ABSENT_CIBLE": (
        "Virement repris par la trésorerie sans envoi correspondant du jour",
        "La trésorerie a importé un virement qui ne fait pas partie des virements émis sur la "
        "journée contrôlée. Il s'agit le plus souvent d'un virement d'une journée précédente "
        "repris avec du retard, à confirmer avec la trésorerie.",
    ),
}


def _euros(cts):
    """Formate un montant en centimes vers un affichage francais : 115 462,33 EUR."""
    if cts is None:
        return "n/a"
    texte = f"{cts / 100:,.2f}".replace(",", " ").replace(".", ",")
    return f"{texte} EUR"


def _somme(lignes, champ):
    total = 0
    trouve = False
    for ligne in lignes:
        valeur = ligne.get(champ)
        if valeur is not None:
            total += int(valeur)
            trouve = True
    return total if trouve else None


def _ecrit_csv(chemin, lignes):
    if not lignes:
        chemin.write_text("", encoding="utf-8")
        return
    champs = list(lignes[0].keys())
    with open(chemin, "w", newline="", encoding="utf-8") as fh:
        writer = csv.DictWriter(fh, fieldnames=champs, delimiter=";")
        writer.writeheader()
        writer.writerows(lignes)


# Controles complementaires (cle dans `extras`) -> (nom du CSV, titre metier, explication)
CONTROLES_PLUS = {
    "chevauchements": ("controle_doublons_croises.csv", "Envois se recouvrant partiellement",
                       "Deux envois vers la banque, pour le même compte payeur, contiennent des lignes de virement "
                       "identiques caractère pour caractère sans être strictement identiques. "
                       "Cela ressemble à un rejeu partiel : les virements communs risquent d'être payés deux fois."),
    "virements_multi": ("controle_doublons_virements_jour.csv", "Virements présents dans plusieurs envois du jour",
                        "Une même ligne de virement, identique caractère pour caractère (payeur, date, bénéficiaire, "
                        "IBAN, montant, lot, référence, site), figure dans plusieurs envois distincts de la journée. "
                        "Le bénéficiaire sera payé plusieurs fois."),
    "intra": ("controle_doublons_intra_envoi.csv", "Virements en double au sein d'un même envoi",
              "Une même ligne de virement est répétée à l'identique, caractère pour caractère, dans un même "
              "envoi : le bénéficiaire sera payé plusieurs fois. Des lignes qui diffèrent d'un seul "
              "caractère (référence, lot…) ne sont pas des doublons et ne sont pas signalées."),
    "historique": ("controle_doublons_historique.csv", "Envois ou virements déjà transmis un jour précédent",
                   "Les envois de la journée ont été comparés aux journées précédentes disponibles dans le "
                   "dossier de contrôle. Un envoi identique, un fichier de même nom ou une ligne de virement "
                   "identique caractère pour caractère (date, lot et référence compris) déjà transmis est "
                   "bloquant. Un paiement récurrent n'a pas la même ligne : il n'est pas signalé."),
    "sources": ("controle_doublons_sources.csv", "Fichiers d'origine rejoués",
                "Un fichier préparé (DK_FIN01) apparaît dans plusieurs instances du flux, ou est référencé "
                "plusieurs fois par Oracle, ou deux fichiers de noms différents ont exactement les mêmes "
                "lignes, caractère pour caractère : le flux amont a probablement été relancé."),
    "sanite": ("controle_sanite.csv", "Contrôles de forme sur les envois",
               "Signature PGP présente, compte payeur conforme à Oracle, date de l'envoi, pied de fichier, "
               "code retour du traitement, montants positifs, IBAN valides, BIC renseignés."),
}


def _gravite(lignes, gravite):
    return [l for l in lignes if l.get("gravite") == gravite]


def _table_plus(lignes):
    """Tableau markdown generique d'un controle complementaire (montants *_cts en euros)."""
    champs = [c for c in lignes[0].keys() if c != "gravite"]
    out = ["| " + " | ".join(champs) + " |", "|" + "---|" * len(champs)]
    for l in lignes[:200]:
        cellules = []
        for c in champs:
            v = l.get(c, "")
            if c.endswith("_cts") and v not in ("", None):
                v = _euros(int(v))
            cellules.append(str(v).replace("|", "/"))
        out.append("| " + " | ".join(cellules) + " |")
    if len(lignes) > 200:
        out.append(f"| … | {len(lignes) - 200} ligne(s) supplémentaire(s) dans le CSV |")
    return out + [""]


def write_reports(dossier, fichiers, totaux_source, totaux_edf, ecarts,
                  quartz_totaux=None, quartz_ecarts=None, doublons=None, doublons_detail=None,
                  extras=None):
    quartz_ecarts = quartz_ecarts or []
    doublons = doublons or []
    doublons_detail = doublons_detail or []
    extras = extras or {}
    cible_seul = bool(extras.get("cible_seul"))
    plus = {cle: list(extras.get(cle) or []) for cle in CONTROLES_PLUS}
    plus_ko = {cle: _gravite(l, "KO") for cle, l in plus.items()}
    plus_verif = {cle: _gravite(l, "A_VERIFIER") for cle, l in plus.items()}
    nb_plus_ko = sum(len(l) for l in plus_ko.values())
    nb_plus_verif = sum(len(l) for l in plus_verif.values())
    dossier = Path(dossier)
    dossier.mkdir(parents=True, exist_ok=True)
    for cle, (nom_csv, _, _) in CONTROLES_PLUS.items():
        _ecrit_csv(dossier / nom_csv, plus[cle])

    _ecrit_csv(dossier / "controle_fichiers.csv", fichiers)
    _ecrit_csv(dossier / "controle_totaux_source.csv", totaux_source)
    _ecrit_csv(dossier / "controle_totaux_edf.csv", totaux_edf)
    _ecrit_csv(dossier / "controle_lignes_ecarts.csv", ecarts)
    _ecrit_csv(dossier / "controle_quartz_ecarts.csv", quartz_ecarts)
    _ecrit_csv(dossier / "controle_doublons_ack.csv", doublons)
    _ecrit_csv(dossier / "controle_doublons_virements.csv", doublons_detail)

    # Les doublons ont leur propre section : on ne les presente pas comme des fichiers manquants
    fichiers_ko = [f for f in fichiers if f["statut"] not in ("OK", "DOUBLON")]
    src_ko = [t for t in totaux_source if t["statut_lignes"] != "OK" or t["statut_montant"] != "OK"]
    edf_ko = [t for t in totaux_edf if t["statut_lignes"] != "OK" or t["statut_montant"] != "OK"]
    quartz_ko = bool(quartz_totaux) and (
        quartz_totaux["statut_lignes"] != "OK" or quartz_totaux["statut_montant"] != "OK"
        or bool(quartz_ecarts))
    tout_ok = (not fichiers_ko and not src_ko and not edf_ko and not ecarts and not quartz_ko
               and not doublons and not nb_plus_ko)
    nb_doublons_vir = sum(int(d["nb_virements"]) for d in doublons)
    montant_doublons = sum(int(d["montant_cts"]) for d in doublons)

    anomalies_euro = [t for t in totaux_source if t.get("euro_lines") not in (None, 1)]
    fichiers_ack = [f for f in fichiers if f["categorie"] == "ACK"]
    montant_envoye = _somme(totaux_edf, "montant_ack_footer")
    nb_envoye = _somme(totaux_edf, "nb_ack_footer")

    def statut(en_ecart):
        return "**Conforme**" if not en_ecart else f"**À examiner** ({en_ecart})"

    lignes_md = [
        "# Synthèse du contrôle des virements",
        "",
        "Ce document restitue, en langage métier, le résultat du contrôle automatique de la "
        "chaîne des virements sur la journée analysée. Il est destiné aux équipes "
        "fonctionnelles : chaque contrôle y est expliqué, et chaque écart est accompagné de "
        "sa signification concrète et de la suite à donner.",
        "",
        "---",
        "",
        "## Résultat global",
        "",
    ]
    if tout_ok:
        lignes_md += [
            "> ### ✅ Conforme",
            ">",
            "> Aucune anomalie n'a été détectée. Tous les virements préparés ont été transmis "
            "à la banque, sans perte, sans doublon et sans écart de montant, à chacune des "
            "étapes du traitement. Aucune action n'est attendue.",
        ]
    else:
        lignes_md += [
            "> ### ⚠️ Points d'attention détectés",
            ">",
            "> Le contrôle a relevé au moins un écart. Le détail figure dans les sections "
            "« Points d'attention » ci-dessous, avec pour chacun son explication et la "
            "vérification à mener.",
        ]
    if cible_seul:
        lignes_md += [
            "",
            "> ℹ️ **Contrôle réalisé sur le dossier cible seul** : le dossier source (fichiers DK en "
            "euros) n'a pas été fourni. Les vérifications portent sur les fichiers préparés (DK_FIN01), "
            "les envois à la banque, le CSV Oracle et, le cas échéant, le retour de la trésorerie.",
        ]
    if nb_plus_verif and tout_ok:
        lignes_md += [
            "",
            f"> 🟠 **{nb_plus_verif} point(s) à vérifier** ont toutefois été relevés (non bloquants) : "
            "voir la section « Points à vérifier » ci-dessous.",
        ]
    lignes_md += ["", "---", "", "## 1. Ce que vérifie ce contrôle", ""]
    lignes_md += [
        "Le contrôle suit chaque virement tout au long de son parcours et s'assure qu'à aucune "
        "étape un virement n'a été perdu, ajouté, ou modifié. Il se déroule en trois temps.",
        "",
        "**Premier temps — les fichiers sont-ils tous présents ?** On vérifie que chaque "
        "fichier attendu dans la journée est bien présent, complet et lisible, à toutes les "
        "étapes : le fichier tel qu'il est produit à l'origine, le fichier transformé, le "
        "fichier effectivement transmis à la banque, et l'accusé de réception renvoyé par "
        "cette dernière.",
        "",
        "**Deuxième temps — les montants et les volumes sont-ils conservés ?** On compare, "
        "fichier par fichier, le nombre de virements et le montant total à chaque étape : un "
        "fichier contenant 40 virements pour 100 000 € au départ doit toujours contenir 40 "
        "virements pour 100 000 € à l'arrivée. La vérification est faite sur les fichiers "
        "d'origine, puis sur les envois regroupés réellement transmis à la banque (plusieurs "
        "fichiers d'origine sont souvent réunis en un seul envoi). Le contrôle descend enfin "
        "au niveau du virement individuel : chaque bénéficiaire, chaque montant et chaque "
        "coordonnée bancaire sont comparés un à un.",
        "",
        "**Troisième temps — la trésorerie a-t-elle bien tout reçu ?** On compare la liste des "
        "virements transmis à la banque avec la liste des virements que la trésorerie a "
        "importés dans son outil (Quartz) le même jour.",
        "",
        "**En parallèle — un même envoi a-t-il été transmis plusieurs fois ?** Tous les "
        "fichiers transmis à la banque sur la journée sont comparés entre eux : deux envois "
        "portant le même compte payeur et exactement les mêmes virements sont signalés comme "
        "un doublon, car les bénéficiaires seraient alors payés deux fois. La recherche de doublons "
        "est complétée par : les envois qui se recouvrent partiellement, les virements présents dans "
        "plusieurs envois du jour, les virements répétés dans un même envoi, les envois déjà transmis "
        "un jour précédent, et les fichiers d'origine rejoués. Des contrôles de forme (signature, "
        "compte payeur, IBAN, montants) complètent l'ensemble.",
        "",
        "---",
        "",
        "## 2. Résultat détaillé",
        "",
        "| Étape contrôlée | Volume concerné | Résultat |",
        "|---|---|---|",
        f"| Présence et complétude des fichiers | {len(fichiers)} fichiers | {statut(len(fichiers_ko))} |",
        f"| Montants et volumes sur les fichiers d'origine | {len(totaux_source)} fichiers | {statut(len(src_ko))} |",
        f"| Montants et volumes sur les envois regroupés vers la banque | {len(totaux_edf)} envois | {statut(len(edf_ko))} |",
        f"| Comparaison virement par virement (bénéficiaire, montant, banque) | "
        f"{nb_envoye if nb_envoye is not None else len(totaux_edf)} virements | {statut(len(ecarts))} |",
        f"| Envois transmis plusieurs fois à la banque | {len(fichiers_ack)} envois | {statut(len(doublons))} |",
    ]
    for cle, (_, titre, _) in CONTROLES_PLUS.items():
        if cle == "historique" and not extras.get("historique_jours"):
            lignes_md.append(f"| {titre} | — | *Non réalisé : aucune journée précédente disponible* |")
            continue
        volume = (f"{extras.get('historique_jours')} journée(s) comparée(s)" if cle == "historique"
                  else f"{len(fichiers_ack)} envois")
        res = statut(len(plus_ko[cle]))
        if plus_verif[cle]:
            res += f" — 🟠 {len(plus_verif[cle])} à vérifier"
        lignes_md.append(f"| {titre} | {volume} | {res} |")
    if quartz_totaux:
        lignes_md.append(
            f"| Rapprochement avec le retour de la trésorerie | "
            f"{quartz_totaux['nb_quartz']} repris / {quartz_totaux['nb_cible']} envoyés | "
            f"{statut(len(quartz_ecarts))} |")
    else:
        lignes_md.append(
            "| Rapprochement avec le retour de la trésorerie | — | "
            "*Non réalisé : l'export de la trésorerie n'a pas été fourni* |")
    lignes_md.append("")
    if montant_envoye is not None:
        complement = ""
        if doublons:
            complement = (f", auxquels s'ajoutent **{nb_doublons_vir} virements** pour "
                          f"**{_euros(montant_doublons)}** transmis en double (voir ci-dessous)")
        lignes_md += [
            f"Montant total transmis à la banque sur la journée : **{_euros(montant_envoye)}** "
            f"pour **{nb_envoye} virements**{complement}.",
            "",
        ]
    if quartz_totaux:
        ecart_montant = quartz_totaux["montant_quartz_cts"] - quartz_totaux["montant_cible_cts"]
        ecart_lignes = quartz_totaux["nb_quartz"] - quartz_totaux["nb_cible"]
        lignes_md += [
            f"Montant total repris par la trésorerie : **{_euros(quartz_totaux['montant_quartz_cts'])}** "
            f"pour **{quartz_totaux['nb_quartz']} virements**.",
            "",
        ]
        if ecart_lignes or ecart_montant:
            lignes_md += [
                f"Différence entre les deux : **{ecart_lignes:+d} virement(s)** et "
                f"**{_euros(abs(ecart_montant))}** "
                f"{'de plus' if ecart_montant > 0 else 'de moins'} côté trésorerie. "
                "Cette différence est détaillée dans la section correspondante ci-dessous.",
                "",
            ]
        else:
            lignes_md += [
                "Les deux listes correspondent exactement, en nombre de virements comme en "
                "montant.",
                "",
            ]

    if not tout_ok:
        lignes_md += ["---", "", "## 3. Points d'attention", ""]

    for cle, (nom_csv, titre, explication) in CONTROLES_PLUS.items():
        if plus_ko[cle]:
            total = _somme(plus_ko[cle], "montant_cts") if cle != "sanite" else None
            lignes_md += [f"### {titre}", "", explication, "",
                          f"**{len(plus_ko[cle])} constat(s) bloquant(s)**"
                          + (f", pour **{_euros(total)}**" if total else "")
                          + f" — détail complet dans `{nom_csv}`.", ""]
            lignes_md += _table_plus(plus_ko[cle])

    if doublons:
        lignes_md += [
            "### Envois transmis en double à la banque",
            "",
            f"**{len(doublons)} envoi(s)** ont été transmis à la banque alors qu'un envoi "
            "strictement identique (même compte payeur, mêmes bénéficiaires, mêmes montants) "
            f"avait déjà été transmis sur la journée. Cela représente **{nb_doublons_vir} "
            f"virements** pour **{_euros(montant_doublons)}** susceptibles d'avoir été payés "
            "deux fois. Il faut vérifier sans délai avec la banque si le second envoi a été "
            "exécuté et, le cas échéant, engager les demandes de retour de fonds.",
            "",
            "| Envoi en double | Identique à l'envoi | Nombre de virements | Montant |",
            "|---|---|---|---|",
        ]
        lignes_md += [
            f"| `{d['fichier']}` | `{d['fichier_original']}` | {d['nb_virements']} | "
            f"{_euros(int(d['montant_cts']))} |"
            for d in doublons
        ]
        lignes_md.append("")
        if doublons_detail:
            lignes_md += [
                "#### Bénéficiaires concernés par les envois en double",
                "",
                "Pour chaque envoi en double, la liste des virements qu'il contient — donc des "
                "bénéficiaires susceptibles d'avoir été payés deux fois. Cette même liste est "
                "fournie au format Excel dans `controle_doublons_virements.csv` pour être "
                "transmise à la trésorerie ou à la banque.",
                "",
            ]
            for d in doublons:
                lignes_d = [l for l in doublons_detail
                            if l["guid"] == d["guid"] and l["fichier"] == d["fichier"]]
                lignes_md += [
                    f"**Envoi `{d['fichier']}`** — {len(lignes_d)} virement(s), "
                    f"{_euros(int(d['montant_cts']))}",
                    "",
                    "| Bénéficiaire | IBAN | BIC | Montant |",
                    "|---|---|---|---|",
                ]
                lignes_md += [
                    f"| {l['nom']} | {l['iban']} | {l['bic']} | {_euros(int(l['montant_cts']))} |"
                    for l in lignes_d
                ]
                lignes_md.append("")
    if fichiers_ko:
        lignes_md += [
            "### Fichiers manquants ou incomplets",
            "",
            "Les fichiers ci-dessous étaient attendus dans la journée mais n'ont pas été "
            "trouvés, ou n'ont pas pu être exploités. Tant que ce point n'est pas levé, une "
            "partie des virements de la journée n'est pas contrôlée : il faut vérifier avec "
            "l'exploitation que le traitement s'est bien déroulé jusqu'au bout.",
            "",
            "| Fichier | Étape concernée | Constat |",
            "|---|---|---|",
        ]
        lignes_md += [
            f"| `{f['fichier']}` | {f['categorie']} | {f['statut']}"
            f"{' — ' + f['detail'] if f.get('detail') else ''} |"
            for f in fichiers_ko
        ]
        lignes_md.append("")
    if src_ko:
        lignes_md += [
            "### Écarts de totaux sur les fichiers d'origine",
            "",
            "Pour les fichiers ci-dessous, le nombre de virements ou le montant total ne se "
            "retrouve pas à l'identique d'une étape à l'autre de la préparation. Cela signifie "
            "qu'un virement a pu être perdu, dupliqué, ou que son montant a été modifié lors "
            "de la transformation du fichier.",
            "",
            "| Fichier d'origine | Nombre de virements | Montant total |",
            "|---|---|---|",
        ]
        lignes_md += [
            f"| {t['fichier_source']} | "
            f"{'cohérent' if t['statut_lignes'] == 'OK' else '**écart**'} | "
            f"{'cohérent' if t['statut_montant'] == 'OK' else '**écart**'} |"
            for t in src_ko
        ]
        lignes_md.append("")
    if edf_ko:
        lignes_md += [
            "### Écarts de totaux sur les envois regroupés vers la banque",
            "",
            "Plusieurs fichiers d'origine sont réunis en un seul envoi vers la banque. Pour "
            "les envois ci-dessous, le total de l'envoi ne correspond pas à la somme des "
            "fichiers qui le composent, ou ne correspond pas à l'accusé de réception de la "
            "banque. Le montant réellement débité peut donc différer du montant attendu.",
            "",
            "| Envoi vers la banque | Nombre de virements | Montant total |",
            "|---|---|---|",
        ]
        lignes_md += [
            f"| {t['fichier_edf']} | "
            f"{'cohérent' if t['statut_lignes'] == 'OK' else '**écart**'} | "
            f"{'cohérent' if t['statut_montant'] == 'OK' else '**écart**'} |"
            for t in edf_ko
        ]
        lignes_md.append("")
    if ecarts:
        lignes_md += [
            "### Écarts constatés virement par virement",
            "",
            "Chaque virement préparé a été comparé au virement effectivement transmis à la "
            "banque, sur le nom du bénéficiaire, le montant et les coordonnées bancaires. Les "
            "différences relevées sont listées ci-dessous.",
            "",
            "| Nature de l'écart | Montant | Détail |",
            "|---|---|---|",
        ]
        lignes_md += [
            f"| {LIBELLES_ECARTS.get(e['type_ecart'], (e['type_ecart'], ''))[0]} | "
            f"{_euros(e.get('montant_cts'))} | {e.get('detail', '')} |"
            for e in ecarts
        ]
        lignes_md.append("")
    if quartz_ecarts:
        lignes_md += [
            "### Écarts avec le retour de la trésorerie",
            "",
            "Les virements ci-dessous n'ont pas pu être appariés entre ce que nous avons "
            "transmis à la banque et ce que la trésorerie a importé sur la même journée.",
            "",
            "| Nature de l'écart | Montant | Détail |",
            "|---|---|---|",
        ]
        lignes_md += [
            f"| {LIBELLES_ECARTS.get(e['type_ecart'], (e['type_ecart'], ''))[0]} | "
            f"{_euros(e.get('montant_cts'))} | {e.get('detail', '')} |"
            for e in quartz_ecarts
        ]
        lignes_md.append("")
    if anomalies_euro:
        lignes_md += [
            "### Anomalie de devise",
            "",
            "Chaque fichier préparé doit comporter une et une seule référence à la devise "
            "euro. Les fichiers ci-dessous n'en comportent pas exactement une, ce qui peut "
            "traduire un mélange de devises ou un fichier mal formé.",
            "",
        ]
        lignes_md += [
            f"- {t['fichier_source']} : {t['euro_lines']} référence(s) à l'euro au lieu d'une seule"
            for t in anomalies_euro
        ]
        lignes_md.append("")

    if nb_plus_verif:
        lignes_md += ["---", "", "## Points à vérifier (non bloquants)", "",
                      "Les constats ci-dessous ne sont pas des écarts avérés : ils correspondent à des "
                      "situations qui peuvent être légitimes (retour Talend absent, date ou BIC à "
                      "confirmer) mais qui méritent un regard. Ils n'empêchent pas la clôture du contrôle.", ""]
        for cle, (nom_csv, titre, explication) in CONTROLES_PLUS.items():
            if plus_verif[cle]:
                lignes_md += [f"### {titre}", "", explication, "",
                              f"**{len(plus_verif[cle])} constat(s) à vérifier** — détail dans `{nom_csv}`.", ""]
                lignes_md += _table_plus(plus_verif[cle])

    types_presents = {e["type_ecart"] for e in list(ecarts) + list(quartz_ecarts)}
    types_connus = [t for t in types_presents if t in LIBELLES_ECARTS]
    if types_connus:
        lignes_md += [
            "---",
            "",
            "## 4. Comprendre les écarts relevés",
            "",
            "Pour chaque nature d'écart apparaissant ci-dessus, voici ce que cela signifie "
            "concrètement et l'impact potentiel.",
            "",
        ]
        for code in sorted(types_connus):
            libelle, explication = LIBELLES_ECARTS[code]
            lignes_md += [f"**{libelle}**", "", explication, ""]

    if not tout_ok:
        lignes_md += [
            "---",
            "",
            "## 5. Suite à donner",
            "",
            "Les écarts listés ci-dessus doivent être qualifiés avant de pouvoir clôturer le "
            "contrôle de la journée. Deux issues sont possibles pour chacun d'eux.",
            "",
            "**L'écart est expliqué** — par exemple un virement d'une journée précédente repris "
            "avec du retard par la trésorerie, ou un décalage de reprise connu. Dans ce cas "
            "aucune correction n'est nécessaire : le contrôle peut être clôturé en « écart "
            "expliqué », en conservant la trace de la justification.",
            "",
            "**L'écart n'est pas expliqué** — un virement reste introuvable, ou un montant ne "
            "se justifie pas. Il faut alors ouvrir une analyse avec l'exploitation et, selon "
            "le cas, avec la trésorerie ou la banque, avant toute nouvelle émission.",
            "",
        ]

    lignes_md += [
        "---",
        "",
        "## Annexe — documents détaillés du dossier",
        "",
        "Les fichiers ci-dessous accompagnent cette synthèse et contiennent le détail complet "
        "de chaque vérification. Ils s'ouvrent dans Excel.",
        "",
        "- **`controle_fichiers.csv`** — la liste de tous les fichiers vérifiés dans la "
        "journée, avec pour chacun son statut.",
        "- **`controle_totaux_source.csv`** — pour chaque fichier d'origine, le nombre de "
        "virements et le montant total constatés à chaque étape de la préparation.",
        "- **`controle_totaux_edf.csv`** — pour chaque envoi regroupé vers la banque, le "
        "nombre de virements et le montant total, comparés à l'accusé de réception bancaire.",
        "- **`controle_lignes_ecarts.csv`** — les différences relevées virement par virement "
        "lors de la préparation. **Un fichier vide signifie qu'aucun écart n'a été détecté**, "
        "et constitue donc un bon résultat.",
        "- **`controle_quartz_ecarts.csv`** — les virements qui n'ont pas pu être appariés "
        "avec le retour de la trésorerie. **Un fichier vide signifie que le rapprochement est "
        "parfait**.",
        "- **`controle_doublons_ack.csv`** — les envois vers la banque dont le contenu est "
        "identique à un envoi déjà transmis sur la journée. **Un fichier vide signifie "
        "qu'aucun envoi n'a été transmis en double**.",
        "- **`controle_doublons_virements.csv`** — le détail, virement par virement "
        "(bénéficiaire, IBAN, BIC, montant), des envois transmis en double : la liste à "
        "communiquer à la banque pour les demandes de retour de fonds.",
    ]
    lignes_md += [f"- **`{nom_csv}`** — {titre.lower()}. **Un fichier vide est un bon résultat.**"
                  for nom_csv, titre, _ in CONTROLES_PLUS.values()]
    lignes_md.append("")

    (dossier / "synthese.md").write_text("\n".join(lignes_md), encoding="utf-8")

    # Version courte : resultat, chiffres cles, un point d'attention par ligne, sans detail
    simple = ["# Contrôle des virements — synthèse rapide", ""]
    simple.append("**Résultat : ✅ Conforme**" if tout_ok else "**Résultat : ⚠️ À examiner**")
    if cible_seul:
        simple.append("*(contrôle sur le dossier cible seul : dossier source non fourni)*")
    simple.append("")
    if montant_envoye is not None:
        simple.append(f"- Transmis à la banque : **{nb_envoye} virements** pour "
                      f"**{_euros(montant_envoye)}**")
    if quartz_totaux:
        simple.append(f"- Repris par la trésorerie : **{quartz_totaux['nb_quartz']} virements** "
                      f"pour **{_euros(quartz_totaux['montant_quartz_cts'])}**")
    else:
        simple.append("- Retour trésorerie : non fourni (rapprochement non réalisé)")
    simple.append("")
    points = []
    if doublons:
        points.append(f"**{len(doublons)} envoi(s) transmis en double** à la banque : "
                      f"{nb_doublons_vir} virements pour {_euros(montant_doublons)} "
                      "susceptibles d'avoir été payés deux fois — à vérifier avec la banque.")
    if fichiers_ko:
        points.append(f"**{len(fichiers_ko)} fichier(s) manquant(s) ou non exploitable(s)** : "
                      "une partie de la journée n'est pas contrôlée — à vérifier avec l'exploitation.")
    if src_ko:
        points.append(f"**{len(src_ko)} fichier(s) d'origine** avec un écart de nombre ou de montant.")
    if edf_ko:
        points.append(f"**{len(edf_ko)} envoi(s) vers la banque** avec un écart de nombre ou de montant.")
    if ecarts:
        points.append(f"**{len(ecarts)} écart(s) virement par virement** (bénéficiaire, montant ou banque).")
    if quartz_ko:
        points.append(f"**{len(quartz_ecarts)} écart(s) avec le retour de la trésorerie** "
                      f"({quartz_totaux['nb_quartz'] - quartz_totaux['nb_cible']:+d} virement(s), "
                      f"{_euros(abs(quartz_totaux['montant_quartz_cts'] - quartz_totaux['montant_cible_cts']))}).")
    if anomalies_euro:
        points.append(f"**{len(anomalies_euro)} fichier(s)** avec une anomalie de devise.")
    for cle, (_, titre, _) in CONTROLES_PLUS.items():
        if plus_ko[cle]:
            points.append(f"**{titre}** : {len(plus_ko[cle])} constat(s) bloquant(s).")
    if points:
        simple += ["## Points d'attention", ""] + [f"- {pt}" for pt in points] + [""]
        simple.append("Chaque point est détaillé dans `synthese.md` et dans les fichiers CSV du dossier.")
    else:
        simple.append("Aucune anomalie : tous les virements préparés ont été transmis une seule fois, "
                      "sans perte ni écart. Aucune action attendue.")
    a_verifier = [f"- {titre} : {len(plus_verif[cle])}" for cle, (_, titre, _) in CONTROLES_PLUS.items()
                  if plus_verif[cle]]
    if a_verifier:
        simple += ["", "## Points à vérifier (non bloquants)", ""] + a_verifier
    simple.append("")
    (dossier / "synthese_simple.md").write_text("\n".join(simple), encoding="utf-8")
    return tout_ok
