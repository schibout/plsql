# Procédure de Contrôle des Prélèvements Oracle (RPA / Robot)

Ce document décrit le processus opérationnel et les points de contrôle liés à la campagne de prélèvements automatisés menée dans Oracle eBS, de la génération de la campagne jusqu'à la confirmation de chargement.

---

## 📅 Chronologie du Processus

### 1. Nuit de J à J+1 : Campagne de prélèvement dans Oracle
[cite_start]Le processus débute par l'extraction des données de la dernière campagne de prélèvement dans Oracle[cite: 1].

* [cite_start]**Vérification de la date de la dernière campagne[cite: 2]:**
  ```sql
  SELECT MAX(CREATION_DATE)
  FROM dka_sarautoprelev_tmp;