Constat:

Les avoirs ne sont pas pris en compte à l’identique de ce qui est fait par les amonts pour les flux de factures clients.

De fait, le contrôle des flux sur les factures client est très souvent en écart sans raison.



Objectif;

Cette demande vise à synchroniser le contrôle Oracle (programme “DKA : Extraction du contrôle de flux“) avec celui qui est réalisé par les amonts.

Compte tenu de la charge induite côté DSIN pour la régularisation du contrôle des flux sur ces flux de factures clients, la demande est créée en P1.



Exemple d'écart non justifié ci-après pour les folios IGP et SVD:

Contrôle dans l’outil contrôle des flux:



Le nombre de factures intégrées dans Oracle eBS est identique à celui envoyé par les amonts.

En revanche, il y a un écart sur les montants.



Détail de l'écart sur IGP:



Contrôle directe par requête sql dans Oracle:



Pour le fichier concerné par l'écart, le nombre de factures et les montants constatés dans Oracle eBS sont, cette fois, identiques à ceux envoyés par les amonts. 