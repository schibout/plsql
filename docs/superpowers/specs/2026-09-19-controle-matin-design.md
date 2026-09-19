# ODAT Watch — onglet « Matin » (contrôle quotidien générique)

Date : 19/09/2026. Statut : validé avec l'utilisateur, prêt pour le plan d'implémentation.

## Objectif

Intégrer dans ODAT Watch le contrôle du matin aujourd'hui porté par
`ControleMatinGenerique/Controle_Quotidien_Complet.sql` (SQL*Plus, lancé par
`Lancer_Controle_Quotidien.ps1`, sortie = log texte). L'utilisateur veut :

1. un onglet dédié dans l'application, qui exécute les contrôles à la demande ;
2. un bouton qui génère un **rapport HTML** envoyable par mail (téléchargement) ;
3. un **historique** des indicateurs de synthèse dans SQLite pour comparer avec la veille.

Décisions prises :

- Les requêtes sont **portées en Python** (`oracledb`), pas d'appel au `.ps1` ni à sqlplus.
  Le `.sql` d'origine reste la référence métier et n'est pas modifié ; le `.ps1` continue de
  fonctionner indépendamment.
- Rapport = fichier HTML + `st.download_button`. Pas d'envoi mail ni d'Outlook en V1.
- Historique = une ligne de synthèse par exécution dans `odat.db`.

## Architecture

Trois nouveaux modules dans `odat_watch/`, une migration dans `db.py`, une ligne dans `app.py`.

### `controle_matin.py` — moteur

- Réutilise `oracle_refresh._connect_oracle(cfg)`, `_schema(cfg)` et `load_config()`.
- Un `dataclass Section(cle, titre, df: DataFrame | None, erreur: str | None, alerte: bool)`.
- Une fonction par section du SQL, chacune retournant un DataFrame. Les 15 sections, dans
  l'ordre du `.sql` :

  | clé | titre | source SQL (section / PROMPT) |
  |---|---|---|
  | `dsp_detail` | DSP — Détail des flux (fichiers) | S3 |
  | `dsp_jour` | DSP — Synthèse par jour et type | S3 |
  | `notilus` | NOTILUS — Notes de frais | S4 |
  | `fact_source` | FACTURES — Synthèse par source | S5 |
  | `xerox_sans_img` | XEROX — Factures sans images | S5 (alerte si ≥ 1 ligne) |
  | `xerox_avec_img` | XEROX — Factures avec images | S5 |
  | `gl_interface` | GL — Interface (en attente) | S6 |
  | `gl_lignes` | GL — Lignes créées | S6 |
  | `nuit_synthese` | NUIT — Synthèse par statut | S7 |
  | `nuit_err_prog` | NUIT — Erreurs par programme | S7 (alerte si ≥ 1) |
  | `nuit_err_detail` | NUIT — Détail des erreurs (30) | S7 |
  | `nuit_warnings` | NUIT — Détail des warnings | S7 (alerte si ≥ 1) |
  | `nuit_longs` | NUIT — Traitements > 30 min | S7 |
  | `nuit_en_cours` | NUIT — En cours (potentiellement bloqués) | S7 (alerte si ≥ 1) |
  | `rb` | Rapprochement bancaire | S8 |

  Les binds `:v_nb_jours_histo`, `:v_heure_fermeture`, `:v_heure_ouverture` deviennent des
  paramètres Python. `NLS_DATE_LANGUAGE=FRENCH` conservé. Les dates sont renvoyées typées
  (le `TO_CHAR` d'affichage est fait côté Python) pour que pandas trie correctement.
- `synthese(con, h_fermeture, h_ouverture) -> dict` : les 12 compteurs de la SECTION 2
  (`nb_flux_dsp, nb_ndf, nb_fac_xerox, nb_fac_tradeshift, nb_fac_dsp, nb_gl_interface,
  nb_gl_lignes, nb_traitements, nb_erreurs, nb_warnings, nb_rb_imports, nb_images_manq`)
  + `date_rb_max`.
- `statuts(compteurs) -> dict[str, "OK"|"W"]` : mêmes seuils que le SQL
  (DSP ≥ 5 ; NDF, Xerox, Tradeshift, GL interface, GL lignes, RB > 0 ;
  factures DSP OK si `nb_fac_dsp == 0 and nb_flux_dsp >= 5`).
- `statut_global(compteurs, sections) -> "OK"|"WARNING"|"ALERTE"|"ERREUR"` :
  `ERREUR` si une section a levé une exception Oracle ; sinon `ALERTE` si
  `nb_erreurs > 0` ou `nb_images_manq > 0` ; sinon `WARNING` si `nb_warnings > 0`, ou un
  statut à `W`, ou une section « en cours » non vide ; sinon `OK`. Même esprit que le `.ps1`.
- `executer(nb_jours_histo=3, h_fermeture=19, h_ouverture=7) -> Resultat` :
  ouvre une connexion, exécute synthèse + 15 sections **chacune dans un try/except**
  (une section en erreur n'arrête pas les autres ; l'erreur est portée par `Section.erreur`),
  mesure la durée, enrichit `nuit_err_detail` et `nuit_en_cours` avec le `job_name`
  Control-M lu dans `ora_requests` (jointure sur `request_id`, colonne vide si inconnu),
  puis `enregistrer_histo(resultat)` dans SQLite.
- `Resultat` : `executed_at, params, compteurs, statuts, statut_global, sections: list[Section],
  duree_s, fichier_rapport: str | None`.
- `delta_veille(compteurs) -> dict` : différence avec la dernière ligne d'historique d'une date
  antérieure (pour les tuiles).

### `db.py` — nouvelle table

```sql
CREATE TABLE IF NOT EXISTS controle_matin_histo (
    id                INTEGER PRIMARY KEY AUTOINCREMENT,
    date_ctrl         TEXT NOT NULL,      -- AAAA-MM-JJ (jour de l'exécution)
    executed_at       TEXT NOT NULL,      -- AAAA-MM-JJ HH:MM:SS
    statut_global     TEXT NOT NULL,
    nb_flux_dsp       INTEGER, nb_ndf INTEGER, nb_fac_xerox INTEGER, nb_fac_tradeshift INTEGER,
    nb_fac_dsp        INTEGER, nb_gl_interface INTEGER, nb_gl_lignes INTEGER,
    nb_traitements    INTEGER, nb_erreurs INTEGER, nb_warnings INTEGER,
    nb_rb_imports     INTEGER, nb_images_manq INTEGER,
    duree_s           REAL,
    fichier_rapport   TEXT
);
```

Une ligne par exécution ; `fichier_rapport` mis à jour quand le rapport est généré.

### `rapport_matin.py` — générateur HTML

- Calqué sur `FichierControleFluxCoteUnix/rapport_reconciliation.py` : même `STYLE`
  (charte `#003366`, bandeau `.ok/.warn/.ko`, tuiles, tableaux), mêmes helpers `_t`, `_nb`,
  `_tuile`.
- `construire(resultat: Resultat) -> str` : `<h1>` « Contrôle quotidien FIN-FINANCE — JJ/MM/AAAA »,
  `.meta` (jour, paramètres, durée, heure), bandeau selon `statut_global` (ALERTE et ERREUR →
  `.ko`, WARNING → `.warn`), rappel lundi (« fichier SG à charger manuellement ») si
  `executed_at` est un lundi, grille de tuiles = synthèse avec statut OK/W, puis un `<h2>` +
  tableau par section dans l'ordre ; section vide → « Aucune ligne » ; section en erreur →
  encadré rouge avec le message Oracle. Toutes les valeurs passent par `html.escape`.
- `ecrire(resultat, dossier=odat_watch/rapports) -> Path` :
  `Controle_Matin_AAAAMMJJ_HHMM.html`, UTF-8. Le dossier est créé si absent et ajouté au
  `.gitignore` du projet.
- Module pur : ne lit ni Oracle ni SQLite.

### `ui_matin.py` — onglet Streamlit « ☀️ Matin »

`render(now, kpi, badge)` appelé depuis `app.py`, onglet inséré après « 🔴 Maintenant ».

1. **Paramètres** sur une ligne : historique (j, défaut 3), heure fermeture (19),
   heure ouverture (7), bouton **▶ Lancer le contrôle**. Le résultat est gardé en
   `st.session_state["matin"]`. Spinner pendant l'exécution, durée affichée ensuite.
2. **Bandeau** de statut global (vert / jaune / rouge) + rappel lundi.
3. **Tuiles** via `kpi()` : les 12 compteurs, ton selon statut OK/W (erreurs / images
   manquantes en rouge si > 0), delta vs. veille en légende (`+3 vs 18/09`).
4. **Sections** en `st.expander`, ouvertes automatiquement si `alerte` ou `erreur` ;
   DataFrame en `st.dataframe`, erreur Oracle en `st.error`.
5. **Rapport** : bouton **📄 Générer le rapport HTML** → `rapport_matin.ecrire`, mise à jour de
   `fichier_rapport` dans l'historique, `st.download_button` sur le fichier, chemin affiché.
   En dessous : les 10 derniers fichiers de `rapports/`, chacun avec un bouton de
   téléchargement.
6. **Tendance** : `st.line_chart` des 30 derniers jours (`nb_erreurs, nb_warnings,
   nb_flux_dsp, nb_images_manq`) depuis `controle_matin_histo`, une ligne par jour
   (dernière exécution de chaque jour).

Si `config.ini` n'a pas de section `[oracle]`, l'onglet affiche le même message d'aide que
l'onglet Oracle et le bouton est désactivé.

## Gestion des erreurs

- Connexion Oracle impossible → `st.error` avec le message, rien d'écrit dans l'historique.
- Requête d'une section en échec → section marquée `erreur`, les autres continuent,
  `statut_global = ERREUR`, la ligne d'historique est quand même enregistrée.
- Génération du rapport impossible (droits, disque) → `st.error`, l'exécution reste en session.

## Tests

`odat_watch/tests/test_controle_matin.py` (pytest, sans Oracle) :

- `statuts()` et `statut_global()` sur des compteurs injectés (cas OK, W sur DSP < 5, ALERTE
  sur erreurs, ALERTE sur images manquantes, ERREUR quand une section porte une exception).
- `rapport_matin.construire()` sur un `Resultat` factice : présence des 15 `<h2>`, classe du
  bandeau, « Aucune ligne » pour une section vide, échappement d'un `<` dans une valeur.
- `db.connect()` sur une base temporaire : table créée, `enregistrer_histo` + `delta_veille`.

Validation manuelle : lancer l'onglet et le `.ps1` le même matin, les compteurs de la synthèse
doivent coïncider.

## Hors périmètre V1

Envoi mail (SMTP), brouillon Outlook, planification automatique, modification du `.sql` ou du
`.ps1`.
