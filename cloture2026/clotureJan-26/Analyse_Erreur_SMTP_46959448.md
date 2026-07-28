# Analyse Erreur SMTP - Traitement 46959448

## Résumé Exécutif

| Élément | Valeur |
|---------|--------|
| **Request ID** | 46959448 |
| **Programme** | DKA : Envoi par mail des fichiers de situation Oracle du matin |
| **Code programme** | DKA_SCTRLMOD_MOA_MAIL |
| **Date/Heure** | 02/02/2026 00:21:26 |
| **Statut** | Erreur (E) |
| **Utilisateur** | EXPLOITATION |
| **Erreur** | `ORA-29279: erreur permanente SMTP : 552 5.3.4 Error: message file too big` |

## Diagnostic

### Cause Racine

L'erreur **552 5.3.4 message file too big** indique que le serveur SMTP (Exchange) a rejeté l'email car la taille totale des pièces jointes dépasse la limite autorisée.

### Traitement Parent

Le traitement d'envoi de mail 46959448 tente d'envoyer les fichiers générés par le traitement parent :

| Élément | Valeur |
|---------|--------|
| **Request ID Parent** | 46959431 |
| **Programme Parent** | DKA : Situation Oracle du matin |
| **Module** | CSP |
| **Statut Parent** | Erreur (User-Defined Exception) |

### Fichiers Générés (trop volumineux)

Le traitement CSP 46959431 a généré **24 fichiers** avec un total de **172 812 lignes** :

| Fichier | Nb Lignes | Commentaire |
|---------|-----------|-------------|
| `46959431_CSP_Export_Dates_Avoir_FN_Litige.csv` | **104 353** | ⚠️ **Fichier principal cause de l'erreur** |
| `46959431_CSP_Export_Dates_Transfert.csv` | 29 503 | Volume important |
| `46959431_CSP_Notifs_ouvertes.csv` | 10 298 | |
| `46959431_CSP_Export_Rec_Commande_Litige.csv` | 8 056 | |
| `46959431_CSP_Relation_Factor.csv` | 6 253 | |
| `46959431_CSP_Export_Prelevement.csv` | 4 175 | |
| `46959431_CSP_OI_2.csv` | 3 200 | |
| `46959431_CSP_OI_1.csv` | 1 562 | |
| ... (16 autres fichiers) | < 1 300 | |

### Estimation de la Taille

Avec environ 104 000 lignes dans le fichier principal et une moyenne de ~200 caractères par ligne :
- **Taille estimée du fichier principal** : ~20-25 MB
- **Taille totale estimée** : ~30-40 MB
- **Limite SMTP typique Exchange** : 10-25 MB

## Historique du Problème

Ce problème est **récurrent** pour les traitements CSP avec des volumes importants :

| Date | Request ID | Total Lignes | Max Lignes/Fichier | Statut Mail |
|------|------------|--------------|---------------------|-------------|
| 02/02/26 | 46959431 | 172 812 | 104 353 | ❌ Erreur SMTP |
| 01/02/26 | 46957734 | 171 700 | 104 333 | ❌ Erreur SMTP |
| 31/01/26 | 46950801 | 171 546 | 104 333 | ❌ Erreur SMTP |
| 30/01/26 | 46938080 | 169 415 | 104 374 | ❌ Erreur SMTP |
| 10/01/26 | 46759048 | 176 231 | 104 467 | ❌ Erreur SMTP |

**Observation** : Le fichier `Export_Dates_Avoir_FN_Litige.csv` dépasse systématiquement 100 000 lignes.

## Solutions Proposées

### Solution Immédiate (Contournement)

1. **Récupérer les fichiers manuellement** sur le serveur :
   - Chemin : `/data/flf/files/PDBFINP1/logs/appl/conc/out/`
   - Fichiers : `46959431_CSP_*.csv`

## Solutions à Moyen Terme

1. **Augmenter la limite SMTP** (nécessite intervention équipe infrastructure) :
   - Limite recommandée : 50 MB
   - Contact : Équipe messagerie Exchange


### Solution Recommandée

**Priorité 1** : Contacter l'équipe infrastructure pour augmenter la limite SMTP à 50 MB.

**Priorité 2** : Demander à l'équipe développement d'ajouter une compression ZIP dans le package `DKA_SCTRLMOD_MOA_PKG`.

## Fichiers de Log

- **Log du traitement** : `/data/flf/files/PDBFINP1/logs/appl/conc/log/l46959448.req`
- **Output du traitement parent** : `/data/flf/files/PDBFINP1/logs/appl/conc/out/o46959431.out`

## Requête de Diagnostic

```sql
-- Voir les fichiers générés pour un traitement CSP
SELECT 
    REQUEST_ID,
    FILE_NAME,
    NB_LINE,
    CREATION_DATE
FROM 
    DKA.DKA_SCTRLMOD_MOA_FILE
WHERE 
    REQUEST_ID = 46959431
ORDER BY NB_LINE DESC;

-- Historique des volumes pour les traitements CSP
SELECT 
    F.REQUEST_ID,
    TO_CHAR(FCR.ACTUAL_START_DATE, 'DD/MM/YY HH24:MI') AS DEBUT,
    SUM(F.NB_LINE) AS TOTAL_LIGNES,
    MAX(F.NB_LINE) AS MAX_LIGNES
FROM 
    DKA.DKA_SCTRLMOD_MOA_FILE F
    JOIN APPS.FND_CONCURRENT_REQUESTS FCR ON F.REQUEST_ID = FCR.REQUEST_ID
WHERE 
    F.CREATION_DATE >= TRUNC(SYSDATE) - 30
GROUP BY F.REQUEST_ID, FCR.ACTUAL_START_DATE
ORDER BY FCR.ACTUAL_START_DATE DESC;
```

