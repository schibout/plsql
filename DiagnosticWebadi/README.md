# Diagnostic Oracle / WebADI

Mode d'emploi du lanceur autonome [DiagnosticWebadi.bat](DiagnosticWebadi.bat).

## Objectif

Ce diagnostic collecte les informations utiles pour analyser un poste WebADI / Oracle EBS :

- présence et bitness du client Oracle
- résolution DNS du SCAN Oracle
- tests de ping et de port TCP 1521
- vérification de la configuration Excel / WebADI
- contrôles réseau et navigateurs liés à EBS
- génération d'un fichier journal complet

## Contenu

- [DiagnosticWebadi.bat](DiagnosticWebadi.bat) : point d'entrée unique
- [DiagnosticWebadi.ps1](DiagnosticWebadi.ps1) : ancien script PowerShell séparé, conservé uniquement si vous voulez comparer avec la version embarquée

Le `.bat` est maintenant autonome. Il extrait la partie PowerShell embarquée vers un fichier temporaire, l'exécute, puis le supprime.

Aucune action utilisateur n'est requise pendant l'exécution. Le script se lance et se termine tout seul.

## Prérequis

- Windows avec PowerShell disponible
- Un client Oracle installé si vous voulez les tests `tnsping` / `sqlplus`
- Excel installé sur le poste pour les contrôles WebADI
- Accès réseau vers le SCAN Oracle et le portail EBS

## Lancement

### Méthode recommandée

Double-cliquer sur [DiagnosticWebadi.bat](DiagnosticWebadi.bat).

### Depuis une console

```bat
cd /d C:\Users\schibout\Documents\plsql\DiagnosticWebadi
DiagnosticWebadi.bat
```

## Fichiers générés

Un fichier log est créé dans le même dossier que le script :

- `Diagnostic_DBFINP1_YYYYMMDD_HHMMSS.log`

Le journal contient toute la sortie du diagnostic.

## Paramètres modifiables

Les paramètres principaux sont définis en tête du `.bat` :

- `HOTE` : nom SCAN / hôte Oracle
- `PORT` : port TCP Oracle
- `TNS_ALIAS` : alias TNS à tester
- `SERVICE` : service Oracle pour EZCONNECT
- `URL_EBS` : URL du portail EBS
- `HOST_EBS` : nom d'hôte utilisé pour les contrôles de zones de confiance

Si votre environnement change, modifiez uniquement ces variables.

## Déroulement du diagnostic

Le script enchaîne notamment les étapes suivantes :

1. contexte poste et réseau local
2. vérification du client Oracle
3. contrôle de la version Excel
4. résolution DNS du SCAN
5. ping et test TCP du port Oracle
6. tests `tnsping` sur l'alias et en EZCONNECT
7. traceroute
8. contrôles WebADI complémentaires : proxy, macros Excel, Edge IE Mode, Java, Excel ouvert
9. contrôles avancés : HTTPS EBS, zones de confiance, Protected View, COM Excel, MTU, NTP

## Lecture du résultat

À la fin, un récapitulatif affiche l'état global des contrôles, par exemple :

- `OK` : contrôle satisfaisant
- `KO` : anomalie détectée
- `?` : résultat non déterminé ou partiel

Les détails complets sont toujours dans le fichier log.

## Dépannage rapide

### Le script ne démarre pas

- Vérifiez que vous lancez bien [DiagnosticWebadi.bat](DiagnosticWebadi.bat)
- Vérifiez que PowerShell n'est pas bloqué par une stratégie locale

### `tnsping` ou `sqlplus` introuvables

- Le client Oracle n'est pas dans le `PATH`
- Ou l'installation Oracle n'est pas présente sur le poste

### Excel 64 bits

- Le diagnostic indique une incompatibilité WebADI si Excel est en 64 bits
- WebADI nécessite généralement Excel 32 bits

### Tests réseau en échec

- Vérifiez le VPN, le proxy, le DNS et l'accès au SCAN Oracle
- Consultez le log pour savoir si l'échec vient du ping, du port TCP ou de `tnsping`

## Remarque technique

L'ancienne séparation `.bat` / `.ps1` n'est plus nécessaire pour exécuter le diagnostic. La version actuelle garde tout dans le `.bat` pour simplifier le lancement.
