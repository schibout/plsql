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


def write_reports(dossier, fichiers, totaux_source, totaux_edf, ecarts,
                  quartz_totaux=None, quartz_ecarts=None):
    quartz_ecarts = quartz_ecarts or []
    dossier = Path(dossier)
    dossier.mkdir(parents=True, exist_ok=True)

    _ecrit_csv(dossier / "controle_fichiers.csv", fichiers)
    _ecrit_csv(dossier / "controle_totaux_source.csv", totaux_source)
    _ecrit_csv(dossier / "controle_totaux_edf.csv", totaux_edf)
    _ecrit_csv(dossier / "controle_lignes_ecarts.csv", ecarts)
    _ecrit_csv(dossier / "controle_quartz_ecarts.csv", quartz_ecarts)

    fichiers_ko = [f for f in fichiers if f["statut"] != "OK"]
    src_ko = [t for t in totaux_source if t["statut_lignes"] != "OK" or t["statut_montant"] != "OK"]
    edf_ko = [t for t in totaux_edf if t["statut_lignes"] != "OK" or t["statut_montant"] != "OK"]
    quartz_ko = bool(quartz_totaux) and (
        quartz_totaux["statut_lignes"] != "OK" or quartz_totaux["statut_montant"] != "OK"
        or bool(quartz_ecarts))
    tout_ok = (not fichiers_ko and not src_ko and not edf_ko and not ecarts and not quartz_ko)

    anomalies_euro = [t for t in totaux_source if t.get("euro_lines") not in (None, 1)]
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
    ]
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
        lignes_md += [
            f"Montant total transmis à la banque sur la journée : **{_euros(montant_envoye)}** "
            f"pour **{nb_envoye} virements**.",
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
        "",
    ]

    (dossier / "synthese.md").write_text("\n".join(lignes_md), encoding="utf-8")
    return tout_ok
