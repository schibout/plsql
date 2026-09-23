# Ctrl Flux › « 🗺 Carte des flux » : tous les flux qui entrent dans Oracle et en sortent

Date : 23/09/2026 · État : **implémenté** le 23/09/2026 (`flux_ref.py`, `carte_flux.py`, `ui_carte_flux.py`,
catalogue `flux_fin01.json`). Source : `Flux-FIN01 - ORACLE.pdf` (schéma des flux autour de FIN01 - ORACLE).

## Ce que dit le schéma

Trois pages. Les deux premières dessinent, autour d'une case centrale **FIN01 - ORACLE**, les applications
qui lui envoient des données (à gauche, flèche vers Oracle) et celles qui en reçoivent (à droite, flèche
depuis Oracle). Chaque flèche porte l'objet échangé. La troisième page est la légende : la **couleur** d'une
application est son domaine (Finances, Référentiel, Opération, Ressources humaines, Partenaires externes,
Juridique / pilotage…), le **style du trait** est la nature du flux (synchrone, asynchrone batch, asynchrone
fil de l'eau, inconnue), et un statut Actif / En projet / Inactif.

Le catalogue a été extrait des dessins du PDF, pas seulement de son texte : la couleur de chaque case donne
le domaine, le pointillé de chaque trait donne la nature, la position (gauche / droite) donne le sens.
Résultat : **66 flux, 33 vers Oracle et 33 depuis Oracle, 25 applications**, 57 flux batch et 9 au fil de
l'eau. Une même application peut être des deux côtés (CELERIS envoie ses écritures et ses factures, et reçoit
le référentiel fournisseurs).

## L'écran

Un troisième sous-onglet dans Ctrl Flux, à côté de Ctrl Flux et GDR, indépendant de la GDR.

1. **Le graphe**, façon Neo4j : Oracle Finance au centre, un nœud par application (une seule fois, même
   quand elle envoie et reçoit), une flèche orientée par flux. Les nœuds portent la couleur de leur domaine
   (palette pastel inspirée de Neo4j Browser), les flèches l'**état** du flux (verte conforme, orange en
   écart, grise sans donnée) et la **nature** en pointillés (tirets longs batch, points fil de l'eau). Les
   flèches d'un même couple s'écartent pour rester lisibles. Nœuds déplaçables à la souris, zoom à la
   molette, détail au survol, objets affichables le long des flèches. Rendu par `pyvis` avec vis-network
   embarqué, donc sans accès réseau. Filtres par sens, domaine, nature et état.
2. **Les tuiles** : flux et applications, vers Oracle, depuis Oracle, conformes, en écart, sans donnée, et une
   jauge « santé des flux suivis ».
3. **La météo des flux** : un tableau, une ligne par flux, avec un pictogramme (☀️ conforme, 🌧️ écart,
   ⛅ sans donnée, 🌫️ inactif), le type, la nature, la date de dernière donnée, la volumétrie Ctrl Flux
   (fichiers, folios, pièces, montant amont, écart, liste des folios, dernier fichier transmis), le détail,
   le motif et le nombre de contacts.

   **Volumétrie dans le graphe** : l'étiquette d'un nœud donne les pièces vues, son infobulle détaille par type
   de flux (FOURNISSEURS / CLIENTS / GL) les flux, fichiers, folios, pièces, montant amont et écart, puis liste
   les folios, les motifs et le dernier fichier transmis ; l'infobulle d'une flèche ajoute le motif et la
   volumétrie du flux. Une case éclate chaque application en un nœud par type de flux.
4. **La fiche d'un flux** : tout se saisit là. Le **motif du nom de fichier** (joker `*` et `?`, ou expression
   régulière si le motif commence par `^`), testé en direct contre les fichiers transmis connus ; les
   **interlocuteurs** (nom, rôle amont / EAI / métier / Oracle, mail, téléphone) ; les **attributs libres**
   clé / valeur, sans limite ; et les colonnes du schéma (domaine, sens, objet, nature, statut), modifiables.
   La fiche affiche aussi les derniers fichiers transmis que le motif reconnaît.

## D'où vient l'état d'un flux

| Source d'état | Flux concernés | Règle |
|---|---|---|
| `ctrl_flux` | tout flux avec un motif | lignes Ctrl Flux dont le fichier transmis correspond : conforme si aucune ligne non rapprochée n'est en écart, sinon en écart (montant manquant au SI Finance) |
| `virements` | PEV01 → Virement | dernier contrôle des virements : conforme si OK sans KO ni écart |
| `prelevements` | PEV01 → Prélèvement | dernier rapprochement des prélèvements : conforme si statut OK |
| `releves` | EDF01 → Relevés de compte | dernier fichier AFB120 reçu par EBS |
| (vide) | les autres | sans donnée, jusqu'à ce qu'un motif ou une source soit renseigné |

Au chargement du catalogue, le motif des flux entrants de factures et d'écritures est déduit des fichiers
transmis déjà connus (`<APP>_SRC_FACTURESFOURNISSEURS_*`, `…FACTURESCLIENTS_*`, `…ECRITURESGL_*`), seulement
quand un fichier correspond vraiment. Les autres motifs se saisissent. Un bouton « Déclarer les fichiers
inconnus » crée une fiche par famille de fichiers transmis qu'aucun motif ne reconnaît.

## Alimentation et partage

- « Charger les flux du schéma FIN01 » ajoute les fiches manquantes sans toucher aux fiches existantes : une
  saisie manuelle survit à un rechargement.
- Export et import CSV du référentiel complet (fiches, interlocuteurs et attributs), pour partager entre
  postes. Tables : `flux_referentiel`, `flux_interlocuteurs`, `flux_attributs`.

## Ce qui a été écarté

La première ébauche (« Parcours », une ligne de métro par fichier transmis, adossée à la GDR) répondait à
une autre question, celle de l'étage où une pièce se perd. Elle a été retirée avant tout commit : la carte
demandée est celle de tous les flux autour d'Oracle, pas celle d'un fichier.

## Suite possible

- Rattacher les jobs Control-M à chaque flux (attribut `job_ctm`), pour lire dans la carte l'heure de
  passage et le statut de la dernière exécution.
- Une source d'état pour les flux du contrôle du matin déjà comptés (DSP, Notilus, Xerox, Tradeshift,
  factures AR) et pour la GDR (rejets par flux), à brancher quand vous le souhaitez.
