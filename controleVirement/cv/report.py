"""Ecriture des rapports CSV et de la synthese markdown."""
import csv
from pathlib import Path


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

    lignes_md = [
        "# Synthese du controle des virements",
        "",
        f"- Fichiers controles : {len(fichiers)} (dont {len(fichiers_ko)} en anomalie)",
        f"- Fichiers source (totaux) : {len(totaux_source)} (dont {len(src_ko)} en ecart)",
        f"- Fichiers EDF/ACK (totaux regroupes) : {len(totaux_edf)} (dont {len(edf_ko)} en ecart)",
        f"- Virements en ecart (ligne a ligne, cote envoi) : {len(ecarts)}",
    ]
    if quartz_totaux:
        lignes_md.append(
            f"- Retour Quartz : {quartz_totaux['nb_quartz']} importe(s) vs "
            f"{quartz_totaux['nb_cible']} envoye(s) - "
            f"lignes={quartz_totaux['statut_lignes']} montant={quartz_totaux['statut_montant']} "
            f"({len(quartz_ecarts)} ecart(s))")
    else:
        lignes_md.append("- Retour Quartz : non fourni (fichier .xls absent)")
    lignes_md += [
        f"- **Resultat global : {'OK' if tout_ok else 'KO'}**",
        "",
    ]
    if fichiers_ko:
        lignes_md += ["## Fichiers en anomalie", ""]
        lignes_md += [f"- `{f['fichier']}` ({f['categorie']}) : {f['statut']}" for f in fichiers_ko]
        lignes_md.append("")
    if src_ko:
        lignes_md += ["## Fichiers source en ecart de totaux", ""]
        lignes_md += [
            f"- {t['fichier_source']} : lignes={t['statut_lignes']} montant={t['statut_montant']}"
            for t in src_ko
        ]
        lignes_md.append("")
    if edf_ko:
        lignes_md += ["## Fichiers EDF/ACK en ecart de totaux (regroupement)", ""]
        lignes_md += [
            f"- {t['fichier_edf']} : lignes={t['statut_lignes']} montant={t['statut_montant']}"
            for t in edf_ko
        ]
        lignes_md.append("")
    anomalies_euro = [t for t in totaux_source if t.get("euro_lines") not in (None, 1)]
    if anomalies_euro:
        lignes_md += ["## Anomalies ligne euros (attendu : exactement 1 par DK_FIN01)", ""]
        lignes_md += [f"- {t['fichier_source']} : {t['euro_lines']} ligne(s) euros" for t in anomalies_euro]
        lignes_md.append("")
    if quartz_ecarts:
        lignes_md += ["## Ecarts retour Quartz (envoye vs importe)", ""]
        lignes_md += [
            f"- {e['type_ecart']} montant={e['montant_cts'] / 100:.2f} EUR : {e['detail']}"
            for e in quartz_ecarts
        ]
        lignes_md.append("")

    (dossier / "synthese.md").write_text("\n".join(lignes_md), encoding="utf-8")
    return tout_ok
