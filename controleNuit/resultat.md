
Procédure PL/SQL terminée.


Date du co Jour     Jours historique Plage nuit                                                                           
---------- -------- ---------------- -------------------------------------------------------------------------------------
04/02/2026 MERCREDI                3 19h - 7h                                                                             

=====================================================
RAPPORT DE CONTRÔLE QUOTIDIEN - 04/02/2026
Jour : MERCREDI
=====================================================

¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿
¿              SYNTHÈSE DU JOUR                   ¿
¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿
¿ Flux DSP (fichiers)         :     5            ¿
¿ Notes de frais Notilus      :   787            ¿
¿ Factures Xerox              :  2832            ¿
¿ Factures Tradeshift         :   130            ¿
¿ Factures DSP                :     0            ¿
¿ Écritures GL (interface)    :    66            ¿
¿ Lignes GL créées            : 15803            ¿
¿ Imports RB                  :   363            ¿
¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿
¿ Traitements nuit            : 10248            ¿
¿ *** ERREURS ***             :     4            ¿
¿ Avertissements              :    23            ¿
¿ *** IMAGES MANQUANTES ***   :    12            ¿
¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿

¿¿  ALERTE : 4 traitement(s) en ERREUR - Voir Section 6
¿¿  ALERTE : 12 factures Xerox sans image - Voir Section 4


Procédure PL/SQL terminée.


=== DSP - Détail des flux (fichiers) ===


Procédure PL/SQL terminée.


CON DATE_CRE JOUR_CRE TYPE_FLUX    FILE_NAME                                                                                           
--- -------- -------- ------------ ----------------------------------------------------------------------------------------------------
DSP 04/02/26 MERCREDI FOURNISSEURS DSP01_SUP_ENTETE_20260204102316_ST_DSP01-SUP_2372785.csv                                            
DSP 03/02/26 MARDI    AUTRE        DSP01_PO_ENTETE_20260203172316_ST_DSP01-PO_2370820.csv                                              
DSP 03/02/26 MARDI    DEBLOCAGE    DSP01_INV_DEBLOCAGE_20260203184316_ST_2370882.csv                                                   
DSP 03/02/26 MARDI    FOURNISSEURS DSP01_SUP_ENTETE_20260203102316_ST_DSP01-SUP_2370168.csv                                            
DSP 03/02/26 MARDI    FOURNISSEURS DSP01_SUP_ENTETE_20260203154316_ST_DSP01-SUP_2370681.csv                                            
DSP 03/02/26 MARDI    RECEPTIONS   DSP01_REC_RECEPTIONS_20260203173316_ST_DSP01-REC_2370828.csv                                        
DSP 02/02/26 LUNDI    AUTRE        DSP01_PO_ENTETE_20260202172316_ST_DSP01-PO_2368836.csv                                              
DSP 02/02/26 LUNDI    DEBLOCAGE    DSP01_INV_DEBLOCAGE_20260202184316_ST_2368891.csv                                                   
DSP 02/02/26 LUNDI    FOURNISSEURS DSP01_SUP_ENTETE_20260202102316_ST_DSP01-SUP_2367978.csv                                            
DSP 02/02/26 LUNDI    FOURNISSEURS DSP01_SUP_ENTETE_20260202154316_ST_DSP01-SUP_2368703.csv                                            
DSP 02/02/26 LUNDI    RECEPTIONS   DSP01_REC_RECEPTIONS_20260202173316_ST_DSP01-REC_2368844.csv                                        

11 lignes sélectionnées. 


=== DSP - Synthèse par jour et type ===


Procédure PL/SQL terminée.


DATE_CRE JOUR_CRE     NB_SUP     NB_CDE     NB_REC     NB_DEB      TOTAL
-------- -------- ---------- ---------- ---------- ---------- ----------
04/02/26 MERCREDI          1          0          0          0          1
03/02/26 MARDI             1          1          1          1          4
02/02/26 LUNDI             1          1          1          1          4


=== NOTILUS - Comptage des notes de frais ===


Procédure PL/SQL terminée.


CONTROL DATE_CRE JOUR         NB_NDF MONTANT_TOTAL
------- -------- -------- ---------- -------------
NOTILUS 03/02/26 MARDI           787     135187,76
NOTILUS 02/02/26 LUNDI            17        495,65


=== FACTURES - Synthèse par source ===


Procédure PL/SQL terminée.


CONTROLE DATE_CRE SOURCE     NB_FACTURES
-------- -------- ---------- -----------
FACTURES 20260203 TRADESHIFT         130
FACTURES 20260203 XEROX             2832
FACTURES 20260202 TRADESHIFT        2084
FACTURES 20260202 XEROX             2541


=== XEROX - Factures SANS images (ALERTE) ===


Procédure PL/SQL terminée.


ALERTE           DATE_CRE NUM_FACT                       REFERENCE_LAD                                                                                                                                                                                                                                                   INVOICE_ID  VENDOR_ID
---------------- -------- ------------------------------ --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- ---------- ----------
XEROX_SANS_IMAGE 20260203 MA4261873                      VE1-40438-20260202-0820-702-001-FMU-001-ED1Flux.TIF                                                                                                                                                                                                               11154747       1139
XEROX_SANS_IMAGE 20260203 8869194/1023555                VE1-10039-20260202-0606-829-001-FMU-001-ED1Flux.TIF                                                                                                                                                                                                               11191824       1520
XEROX_SANS_IMAGE 20260203 2147173429                     VE1-18531-20260130-1031-418-001-FMU-002-ED1Flux.TIF                                                                                                                                                                                                               11174752       1728
XEROX_SANS_IMAGE 20260203 12911609                       VE1-91190-20260202-0903-831-001-FMU-001-ED1Flux.TIF                                                                                                                                                                                                               11173723       2988
XEROX_SANS_IMAGE 20260203 1301538100                     VE1-10039-20260202-1403-006-015-FMU-002-JHPTZ44.TIF                                                                                                                                                                                                               11165836     362001
XEROX_SANS_IMAGE 20260203 20260109                       VE1-91190-20260130-1034-429-001-FMU-001-ED1Flux.TIF                                                                                                                                                                                                               11100921    2016028
XEROX_SANS_IMAGE 20260203 7002600005                     VE1-50403-20260130-1301-014-001-FMU-002-ED1Flux.TIF                                                                                                                                                                                                               11168837      10207
XEROX_SANS_IMAGE 20260203 2026-01-29-15117               VE1-30446-20260202-0806-654-001-FMU-002-ED1Flux.TIF                                                                                                                                                                                                               11165882    1105031
XEROX_SANS_IMAGE 20260203 FA260098                       VE1-80424-20260202-0509-294-001-FMU-001-ED1Flux.TIF                                                                                                                                                                                                               11191790    2827038
XEROX_SANS_IMAGE 20260203 26014486                       VE1-10435-20260202-1403-006-027-FMU-003-JHPTZ44.TIF                                                                                                                                                                                                               11153734       2394
XEROX_SANS_IMAGE 20260203 26014487                       VE1-10435-20260202-1403-006-028-FMU-003-JHPTZ44.TIF                                                                                                                                                                                                               11160960       2394

ALERTE           DATE_CRE NUM_FACT                       REFERENCE_LAD                                                                                                                                                                                                                                                   INVOICE_ID  VENDOR_ID
---------------- -------- ------------------------------ --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- ---------- ----------
XEROX_SANS_IMAGE 20260203 FR6IY4ABEC                     VE1-10039-20260202-0527-759-001-FMU-002-ED1Flux.TIF                                                                                                                                                                                                               11184787    2345036

12 lignes sélectionnées. 


=== XEROX - Factures AVEC images (OK) ===


Procédure PL/SQL terminée.


STATUT                NB_OK
---------------- ----------
XEROX_AVEC_IMAGE       2528


=== GL - Interface (en attente) ===


Procédure PL/SQL terminée.


CONTROLE     SOURCE                                                                                                                                                 TYPE                                                                                                                                                   STATUS                                              NB_LIGNES TOTAL_DEBIT TOTAL_CREDIT
------------ ------------------------------------------------------------------------------------------------------------------------------------------------------ ------------------------------------------------------------------------------------------------------------------------------------------------------ -------------------------------------------------- ---------- ----------- ------------
GL_INTERFACE FAC02_SRC_ECRITURESGL_040226-024002                                                                                                                    FGE                                                                                                                                                    NEW                                                        23      2810,4       2810,4
GL_INTERFACE FAC02_SRC_ECRITURESGL_040226-024002                                                                                                                    GER                                                                                                                                                    NEW                                                        43    12465,62     12465,62


=== GL - Lignes créées ===


Procédure PL/SQL terminée.


CONTROLE DATE_CRE SOURCE                                                                                                                                                  NB_LIGNES TOTAL_DEBIT
-------- -------- ------------------------------------------------------------------------------------------------------------------------------------------------------ ---------- -----------
GL_CREES 04/02/26                                                                                                                                                               946  54460388,4
GL_CREES 03/02/26                                                                                                                                                            156122  1543212658
GL_CREES 03/02/26 FAC02_SRC_ECRITURESGL_030226-021242                                                                                                                           182    61019,64
GL_CREES 03/02/26 dlk_gse20260203153037                                                                                                                                        1734   267920766
GL_CREES 02/02/26                                                                                                                                                            141432  1060008057
GL_CREES 02/02/26 PRN01_SRC_ECRITURESGL_20260128-093335                                                                                                                        1650  11142905,3
GL_CREES 02/02/26 PRN01_SRC_ECRITURESGL_20260128-093236                                                                                                                          26   4945844,2
GL_CREES 02/02/26 FAC02_SRC_ECRITURESGL_310126-014821                                                                                                                            31     4483,22
GL_CREES 02/02/26 FAC02_SRC_ECRITURESGL_300126-020310                                                                                                                            72    10409,99
GL_CREES 02/02/26 FAC02_SRC_ECRITURESGL_290126-015918                                                                                                                            99    26796,15
GL_CREES 02/02/26 FAC02_SRC_ECRITURESGL_280126-045743                                                                                                                           125    120694,6

CONTROLE DATE_CRE SOURCE                                                                                                                                                  NB_LIGNES TOTAL_DEBIT
-------- -------- ------------------------------------------------------------------------------------------------------------------------------------------------------ ---------- -----------
GL_CREES 02/02/26 dlk_gse20260202153112                                                                                                                                        4010   634837824
GL_CREES 02/02/26 dlk_gse20260130153040                                                                                                                                          36   1586734,1
GL_CREES 01/02/26                                                                                                                                                              4369   881953,86

14 lignes sélectionnées. 


=== NUIT - Synthèse par statut ===


Procédure PL/SQL terminée.


CONTROLE      STATUT                 NB
------------- -------------- ----------
NUIT_SYNTHESE WARNING                23
NUIT_SYNTHESE *** ERREUR ***          4
NUIT_SYNTHESE OK                  10221


=== NUIT - Détail des ERREURS ===


Procédure PL/SQL terminée.


ALERTE REQUEST_ID PROGRAMME                                                                                                                                                                                                                                        DEBUT          FIN             DUREE_MIN MESSAGE                                                                                             
------ ---------- ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ -------------- -------------- ---------- ----------------------------------------------------------------------------------------------------
ERREUR   46988592 DKA : Envoi par mail des fichiers de situation Oracle du matin                                                                                                                                                                                   04/02 04:47:07 04/02 04:47:08          0 ERREUR : ORA-29279: erreur permanente SMTP : 552 5.3.4 Error: message file too big                  
ERREUR   46988581 DKA : Situation Oracle du matin                                                                                                                                                                                                                  04/02 04:34:15 04/02 04:47:25       13,2 ERREUR : User-Defined Exception                                                                     
ERREUR   46988573 DKA : Lanceur (SHELL)                                                                                                                                                                                                                            04/02 04:34:14 04/02 04:47:33       13,3 Program exited with status 2                                                                        
ERREUR   46980047 Programme d'importation de l'interface coopérative d'Oracle Payables                                                                                                                                                                             03/02 19:27:36 03/02 19:27:41 ,1         Le GTS a rencontré une erreur pendant l'exécution d'Oracle*Report pour votre traitement simultané 46


=== NUIT - Détail des WARNINGS ===


Procédure PL/SQL terminée.


ALERTE  REQUEST_ID PROGRAMME                                                                                                                                                                                                                                        DEBUT           DUREE_MIN MESSAGE                                                                                             
------- ---------- ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ -------------- ---------- ----------------------------------------------------------------------------------------------------
WARNING   46985714 Jeu d'états                                                                                                                                                                                                                                      04/02 03:57:04        1,9                                                                                                     
WARNING   46985715 Phase du jeu de traitements                                                                                                                                                                                                                      04/02 03:57:04 ,4                                                                                                             
WARNING   46985716 DKA : Imputation GL                                                                                                                                                                                                                              04/02 03:57:04 ,4                                                                                                             
WARNING   46985713 DKA : Lanceur (SHELL)                                                                                                                                                                                                                            04/02 03:57:03        2,1 Fin Anormale                                                                                        
WARNING   46983225 Traitement du processeur enfant de validation de factures                                                                                                                                                                                        03/02 21:36:51        6,3                                                                                                     
WARNING   46982923 Validation de factures                                                                                                                                                                                                                           03/02 21:34:42       13,9 Fin normale                                                                                         
WARNING   46982366 DKA : Import des codes de déblocage Facture depuis IVALUA                                                                                                                                                                                        03/02 21:23:24          2                                                                                                     
WARNING   46982365 DKA : Lanceur (SHELL)                                                                                                                                                                                                                            03/02 21:23:21        2,4 Fin Anormale                                                                                        
WARNING   46982364 DKA : Contrôle des flux XEROX                                                                                                                                                                                                                    03/02 21:23:20          0                                                                                                     
WARNING   46982362 DKA : Lanceur (SHELL)                                                                                                                                                                                                                            03/02 21:23:19 ,4         Fin Anormale                                                                                        
WARNING   46982363 DKA : Contrôle des flux IVALUA                                                                                                                                                                                                                   03/02 21:23:19          0                                                                                                     

ALERTE  REQUEST_ID PROGRAMME                                                                                                                                                                                                                                        DEBUT           DUREE_MIN MESSAGE                                                                                             
------- ---------- ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ -------------- ---------- ----------------------------------------------------------------------------------------------------
WARNING   46982361 DKA : Lanceur (SHELL)                                                                                                                                                                                                                            03/02 21:23:18 ,4         Fin Anormale                                                                                        
WARNING   46982008 DKA : Import des données Réceptions depuis iValua                                                                                                                                                                                                03/02 19:55:54       11,9                                                                                                     
WARNING   46982007 DKA : Lanceur (SHELL)                                                                                                                                                                                                                            03/02 19:55:53       12,3 Fin Anormale                                                                                        
WARNING   46980593 Copie en haut volume périodique                                                                                                                                                                                                                  03/02 19:35:00          0 Programme simultané n'a renvoyé aucun motif d'échec.                                                
WARNING   46980578 Copie en haut volume périodique                                                                                                                                                                                                                  03/02 19:34:59          0 Programme simultané n'a renvoyé aucun motif d'échec.                                                
WARNING   46980309 DKA : Copie en haut volume périodique                                                                                                                                                                                                            03/02 19:34:36 ,7                                                                                                             
WARNING   46980308 Phase du jeu de traitements                                                                                                                                                                                                                      03/02 19:34:36 ,7                                                                                                             
WARNING   46980214 DKA : Import des commandes depuis iValua                                                                                                                                                                                                         03/02 19:25:09       27,4                                                                                                     
WARNING   46980213 DKA : Lanceur (SHELL)                                                                                                                                                                                                                            03/02 19:25:07       27,7 Fin Anormale                                                                                        
WARNING   46979957 DKA : Import des données Fournisseurs depuis iValua                                                                                                                                                                                              03/02 19:14:57        8,6                                                                                                     
WARNING   46979879 DKA : Lanceur (SHELL)                                                                                                                                                                                                                            03/02 19:14:54        8,9 Fin Anormale                                                                                        

ALERTE  REQUEST_ID PROGRAMME                                                                                                                                                                                                                                        DEBUT           DUREE_MIN MESSAGE                                                                                             
------- ---------- ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ -------------- ---------- ----------------------------------------------------------------------------------------------------
WARNING   46979463 EasyLink                                                                                                                                                                                                                                         03/02 19:03:13          0 Données introuvables dans la table GL_INTERFACE.                                                    

23 lignes sélectionnées. 


=== NUIT - Traitements longs (> 30 min) ===


Procédure PL/SQL terminée.


TYPE REQUEST_ID PROGRAMME                                                                                                                                                                                                                                        DEBUT       FIN          DUREE_MIN STATUT 
---- ---------- ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ ----------- ----------- ---------- -------
LONG   46988572 DKA : Lanceur (SHELL)                                                                                                                                                                                                                            04/02 04:34 04/02 06:56        142 OK     
LONG   46988580 DKA : Situation Oracle du matin                                                                                                                                                                                                                  04/02 04:34 04/02 06:55      141,7 OK     
LONG   46982368 DKA : Lanceur (SHELL)                                                                                                                                                                                                                            03/02 21:26 03/02 23:07      100,3 OK     
LONG   46982369 Jeu d'états                                                                                                                                                                                                                                      03/02 21:26 03/02 23:07      100,3 OK     
LONG   46984940 DKA : Lanceur (SHELL)                                                                                                                                                                                                                            04/02 01:11 04/02 02:40       88,7 OK     
LONG   46984941 DKA : Règlements automatiques toutes sociétés des factures fournisseurs                                                                                                                                                                          04/02 01:11 04/02 02:39       88,5 OK     
LONG   46983228 Phase du jeu de traitements                                                                                                                                                                                                                      03/02 22:00 03/02 23:03         63 OK     
LONG   46983229 DKA : Comptabilisation AP                                                                                                                                                                                                                        03/02 22:00 03/02 23:03       62,9 OK     
LONG   46983322 Créer une comptabilisation                                                                                                                                                                                                                       03/02 22:02 03/02 23:03         61 OK     
LONG   46983565 Programme de comptabilisation                                                                                                                                                                                                                    03/02 22:02 03/02 23:02       60,5 OK     
LONG   46983568 Programme de comptabilisation                                                                                                                                                                                                                    03/02 22:02 03/02 23:02       60,4 OK     

TYPE REQUEST_ID PROGRAMME                                                                                                                                                                                                                                        DEBUT       FIN          DUREE_MIN STATUT 
---- ---------- ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ ----------- ----------- ---------- -------
LONG   46984443 DKA : Lanceur (SHELL)                                                                                                                                                                                                                            04/02 00:06 04/02 01:07       60,4 OK     
LONG   46983566 Programme de comptabilisation                                                                                                                                                                                                                    03/02 22:02 03/02 23:02       60,4 OK     
LONG   46984444 DKA : Création des règlements pour la campagne de prélèvement AP - RB                                                                                                                                                                            04/02 00:06 04/02 01:07       60,2 OK     
LONG   46983564 Programme de comptabilisation                                                                                                                                                                                                                    03/02 22:02 03/02 23:02       60,1 OK     
LONG   46983567 Programme de comptabilisation                                                                                                                                                                                                                    03/02 22:02 03/02 23:02         60 OK     
LONG   46985566 DKA : Lanceur (SHELL)                                                                                                                                                                                                                            04/02 03:01 04/02 03:48       46,8 OK     
LONG   46985567 DKA : Règlements automatiques toutes sociétés des factures fournisseurs                                                                                                                                                                          04/02 03:01 04/02 03:48       46,7 OK     
LONG   46982199 DKA : Lanceur (SHELL)                                                                                                                                                                                                                            03/02 20:36 03/02 21:22       46,1 OK     
LONG   46982200 DKA : Intégration des factures XEROX                                                                                                                                                                                                             03/02 20:36 03/02 21:21       45,7 OK     
LONG   46988578 DKA : Lanceur (SHELL)                                                                                                                                                                                                                            04/02 04:34 04/02 05:18       44,7 OK     
LONG   46988586 DKA : Extraction du contrôle de flux                                                                                                                                                                                                             04/02 04:34 04/02 05:18       44,4 OK     

TYPE REQUEST_ID PROGRAMME                                                                                                                                                                                                                                        DEBUT       FIN          DUREE_MIN STATUT 
---- ---------- ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ ----------- ----------- ---------- -------
LONG   46978366 DKA : Lanceur (SHELL)                                                                                                                                                                                                                            03/02 19:02 03/02 19:44       42,7 OK     
LONG   46978373 Jeu d'états                                                                                                                                                                                                                                      03/02 19:02 03/02 19:44       42,6 OK     
LONG   46982744 Phase du jeu de traitements                                                                                                                                                                                                                      03/02 21:27 03/02 22:00       32,9 OK     
LONG   46982745 DKA : Approbation toutes sociétés des factures fournisseurs                                                                                                                                                                                      03/02 21:27 03/02 22:00       32,9 OK     
LONG   46979878 DKA : Lanceur (SHELL)                                                                                                                                                                                                                            03/02 19:14 03/02 19:47       32,4 OK     
LONG   46979898 DKA : Import des donnees depuis l'open Interface AP                                                                                                                                                                                              03/02 19:14 03/02 19:47       32,1 OK     
LONG   46978985 Phase du jeu de traitements                                                                                                                                                                                                                      03/02 19:02 03/02 19:34       32,1 OK     
LONG   46978989 DKA : Calculer les plus- et moins-values                                                                                                                                                                                                         03/02 19:02 03/02 19:34       32,1 OK     
LONG   46979950 DKA : Import des donnees depuis l'open Interface AP                                                                                                                                                                                              03/02 19:14 03/02 19:45       30,1 OK     

31 lignes sélectionnées. 


=== NUIT - Traitements en cours ===


Procédure PL/SQL terminée.

aucune ligne sélectionnée

=== RAPPROCHEMENT BANCAIRE (RB) ===


Procédure PL/SQL terminée.


CONTROLE   DATE_IMP JOUR     NB_COMPTES
---------- -------- -------- ----------
RB_IMPORTS 04/02/26 MERCREDI        342
RB_IMPORTS 03/02/26 MARDI           363
RB_IMPORTS 02/02/26 LUNDI           210


=====================================================
FIN DU CONTRÔLE QUOTIDIEN - 15:51:33
=====================================================


Procédure PL/SQL terminée.

