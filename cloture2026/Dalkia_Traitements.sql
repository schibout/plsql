select to_char(sysdate,'DD/MM/YYYY HH24:MI:SS') from FND_CONCURRENT_REQUESTS  ;


SELECT column_name, table_name
FROM   all_tab_cols atc
where 1 = 1 
--and table_name like '%STATUS%'
and atc.column_name like 'STATUS_CODE%'
--and column_name = 'ORG_ID'
order by TABLE_NAME
;

Select * from AS_STATUSES_B;

-- les Statuts : 
        'C','OK',
        'D','Annul�',
        'E','Erreur',
        'G','Avertissement',
        'I','Programm�',
        'Q','Programm�',
        'R','Running',

--===================-- MON USER_ID chez Dalkia = 16066 --===================--



select fcrs.REQUESTOR
,      frv.RESPONSIBILITY_NAME
,      fcrs.PROGRAM                   Nom_du_programme
,      fcr.ORG_ID
,      to_char(fcrs.REQUEST_DATE,'DD/MM/YYYY HH24:MI:SS')
,      fcrs.request_id
,      fcrs.PHASE_CODE
,      fcrs.STATUS_CODE
,      fcrs.COMPLETION_TEXT
,      fcrs.ARGUMENT_TEXT
,      fcr.ACTUAL_START_DATE
,      fcr.ACTUAL_COMPLETION_DATE
,      fcrs.PRINT_STYLE  
,      fcrs.RESPONSIBILITY_ID
,      fcrs.LAST_UPDATE_LOGIN
,      fcrs.REQUESTED_BY
,      fcrs.RESPONSIBILITY_APPLICATION_ID
,      fcrs.PROGRAM_APPLICATION_ID
,      fcrs.CONCURRENT_PROGRAM_ID
,      fcrs.PROGRAM_SHORT_NAME
,      fcr.*
from FND_CONC_REQ_SUMMARY_V fcrs
,    FND_RESPONSIBILITY_VL  frv
,    FND_CONCURRENT_REQUESTS fcr
,    FND_CONC_REQ_SUMMARY_V fcrs2
where 1 = 1
and fcrs.responsibility_id = frv.responsibility_id
and fcr.REQUEST_ID = fcrs.REQUEST_ID

and fcrs2.responsibility_id = frv.responsibility_id
and fcr.REQUEST_ID = fcrs2.REQUEST_ID

--and fcrs.REQUEST_DATE like '10/03/15' 
and trunc(fcrs.REQUEST_DATE) >= to_date('22/01/2026','DD/MM/YYYY')
and fcr.request_id >= '46098161'
--and trunc(fcrs.REQUEST_DATE) >= to_date('23/05/2022','DD/MM/YYYY')
--AND fcrs.REQUEST_DATE BETWEEN to_date('04/08/2021 19:10:00' ,'DD/MM/YYYY HH24:MI:SS') AND  to_date('04/08/2021 22:00:00' ,'DD/MM/YYYY HH24:MI:SS')
--and fcr.request_id = '41563078'  
--and fcr.request_id in ('37118767','37118780','37118810')
--and fcrs.PHASE_CODE = 'R'
--and fcrs.STATUS_CODE = 'E' -- 'Q'
--and fcrs.PROGRAM like 'DKA : Lanceur (SHELL)%'
--and fcrs.PROGRAM like 'FINDTR_J11GEN_06_EXP02_Q : DKA_ICE_BANKBRANCHES_DTR_JOB.sh (DKA : Lanceur (SHELL))'  -- DTR
--and fcrs.PROGRAM like '%HYPERION%'
--and fcrs.PROGRAM like '%DTR%'
--and fcrs.DESCRIPTION like 'FINDTR_J11%'
--and fcrs.PROGRAM like '%p�titive%'   --    '%p�titive%'   -- 
--and fcrs.PROGRAM like 'DKA : R�glements automatiques toutes soci�t�s des factures fournisseurs'
--and fcrs.PROGRAM like 'DKA%factura%'
--and fcrs.PROGRAM like 'DKA%alance%'
--and fcrs.PROGRAM like 'DKA : Etat provisoire des pr�l�vements clients%'
--and fcrs.PROGRAM like 'DKA : Etat %'
--and fcrs.PROGRAM like 'DKA : Balance �g�e fournisseurs%'
--and fcrs.PROGRAM like 'Balance �g�e fournisseurs'
--and fcrs.PROGRAM like 'Balance des fournisseurs'
--and fcrs.PROGRAM like 'DKA : Interface vers Garantie Totale%'        -- ne pas renseigner de critere de date !!
--and fcrs.PROGRAM like '%DKA%xtourne%'
--and fcrs.PROGRAM like '%imprimante%' -- 'DKA : Ech�ancier provisoire tous Soc/CdG'   -- 'Gestionnaire de donn�es des soldes de comptes non sold�s' -- 'DKA : Consolidation VECTOR' -- 'DKA : G�n�ration du fichier VECTOR' --'DKA : Etat de contr�le des retraitements IFRS'
--and fcrs.PROGRAM like 'DKA : Extraction du contr�le de flux'
--and fcrs.PROGRAM like 'DKA : Mise � jour quotidienne des sites fournisseurs dupliqu�s'
--and fcrs.PROGRAM like 'Etat relatif � la s�lection de%�ch�ancier de paiement%'
--and fcrs.PROGRAM like '%orkflow%'
--and fcrs.PROGRAM = 'Processus Workflow en arri�re-plan'
--and fcrs.PROGRAM like 'Services d%annuaire de Workflow - Validation des combinaisons utilisateur/r�le'
--and fcrs.PROGRAM like '%HECFIN_J11INT_05_%'
--and fcrs.PROGRAM like 'DKA : Import des Factures clients%'
--and fcrs.ARGUMENT_TEXT like '200,%140,%'
--and fcrs.PROGRAM like  'DKA : Cloture de la p�riode AP'
--and to_char(fcrs.REQUEST_DATE,'DD/MM/YYYY') >= '09012021'
-- Bonne nomenclature pour l'utilisation de la fonction to_date !!
--and trunc(creation_date) >= to_date('08102020','DDMMYYYY')    -- le trunc (colonne de type date) limitera forc�ment au format DDMMYYYY
--and frv.RESPONSIBILITY_NAME like 'Administrateur Exploitation Dalkia%'
--and frv.RESPONSIBILITY_NAME not in ('TOUT_FA_ADMINISTRATEUR','TOUT_AR_ADMINISTRATEUR','TOUT_PA_ADMINISTRATEUR','TOUT_AP_ADMINISTRATEUR') -- 'DEW0001_GESTION_DA/RECEPTION%'   
--and fcrs.REQUEST_ID in ('32346376','32334024','32318165','32299944','32284665') --'27959988' -- '27959941' 

--and fcrs.PROGRAM like 'DKA : Duplication en masse des sites fournisseurs'
--and fcrs.PROGRAM like 'DKA : Mise � jour quotidienne des sites fournisseurs dupliqu�s'
--and fcrs.PROGRAM like 'DKA : Import des donn�es Fournisseurs depuis iValua%'
--and fcrs.PROGRAM like 'DKA : Mise � jour quotidienne des sites fournisseurs dupliqu�s'
--and fcrs.PROGRAM like 'DKA : Export des images Factures vers iValua'

--and fcrs.PROGRAM like 'DKA : Import des commandes depuis iValua'
--and fcrs.PROGRAM like 'DKA%Mise � jour quotidienne des sites fournisseurs dupliqu�s'

--==================== Traitements RB ===============================
--and fcrs.PROGRAM like 'XXRB - Import fichier des banques%'
--and fcrs.PROGRAM like 'DKA : Contr�le des relev�s bancaires'
--and fcrs.PROGRAM like 'XXRB - Import des mouvements comptables'
--and fcrs.PROGRAM like 'XXRB - Balance de rapprochement'
--and fcrs.PROGRAM like 'XXRB - Rapprochement%'
--and fcrs.PROGRAM like 'XXRB - Rapprochement automatique%'

--==================== Traitements NGT ===============================
--and fcrs.PROGRAM like 'DKA : Interface vers Garantie Totale'
--and fcrs.PROGRAM like '%arantie%otal%'


--==================== Dalkia - controles du matin - poids des virements . Responsabilit� : Administrateur Exploitation Dalkia =======================
--and fcrs.PROGRAM like 'DKA : Campagne de r�glements - Cr�ation du fichier APIMPORT'
--and fcrs.PROGRAM like 'DKA : Campagne de r�glements - Alimentation des tables AP Import%'
--and fcrs.PROGRAM like 'DKA%irement%'
--and fcrs.PROGRAM <> 'DKA : Cr�ation du fichier avis de virement'

--==================== Ivalua vers Dalkia - PO =============================
--and fcrs.PROGRAM like 'DKA : Import des commandes depuis iValua'
--and fcrs.PROGRAM like 'DKA : Import des donn�es R�ceptions depuis iValua'
--and fcrs.PROGRAM like 'DKA : Import des codes de d�blocage Facture depuis IVALUA'
--and fcrs.PROGRAM like 'DKA : Import des donn�es Fournisseurs depuis iValua%'
--and fcrs.PROGRAM like 'DKA%alua%'


--==================== U.O. =======================
--and fcr.ORG_ID = '133'    

--==================== les jobs DTR =============================
--and fcrs.PROGRAM like '%DTR%'

--==================== les jobs Selene =============================
--and fcrs.PROGRAM like '%HYP%'

--===========================================                ==============================================
--=========================================== CLOTURE Dalkia ==============================================
--===========================================                ==============================================
--and fcrs.PROGRAM like 'Etat des exceptions de cl�ture de p�riode%'                 -- si AP
--OR fcrs.PROGRAM = 'Etat des mouvements non comptabilis�s (XML)'
--and fcrs.PROGRAM = 'Etat des exceptions de cl�ture de p�riode de livre auxiliaire'     -- si AR
--and fcrs.PROGRAM = 'Etat des%'
--and fcrs.PROGRAM = 'XXS Cl�ture des modules OA'
--and fcrs.PROGRAM = 'XXS - Etat des �carts GL - SLA - AP - AR (PDF-XLS)'
--and fcrs.PROGRAM = 'Traitement de cl�ture - Cr�er pi�ces de cl�ture du compte de r�sultats%'
--and fcrs.PROGRAM = 'Traitement de cl�ture - Cr�er des pi�ces de cl�ture du bilan%'
--and fcrs.PROGRAM = 'Traitement de cl�ture%'
--and fcrs.PROGRAM like 'XXS GL - France - Fichier d%audit des pi�ces comptables'                             --Fichier des �critures comptables FEC
--and fcrs.PROGRAM like '%alcul%raitanc%'
--and fcrs.PROGRAM like 'DKA : Extraction du contr�le de flux'


                 -- *******************CLOTURE FA (avant cloture provisoire)******************
--and fcrs.PROGRAM like 'G�n�rer des comptes'              -- regarder si STATUS_CODE = 'E' ou 'G'
--and fcrs.STATUS_CODE in ('E','G')
and fcrs.PROGRAM like 'DKA : G�n�ration des pi�ces r�p�titives'    -- regarder si STATUS_CODE = 'E' ou 'G'
--and fcrs.PROGRAM like 'DKA : G�n�ration des pi�ces r�p�titives - Compte Rendu par CdG'  -- (mieux car pour les 8 r�gions ! )regarder si STATUS_CODE = 'E' ou 'G' (=2nd passage des abonnements)
--and fcrs.PROGRAM like '%HYP%'
--and fcrs.PROGRAM like '%DTR%'
--and fcrs.PROGRAM like 'Incorporation des �critures d%amortissement%'

                  -- ******************* CLOTURE PROVISOIRE *********************
/* Statuts : 'C','OK',
             'D','Annul�',
             'E','Erreur',
             'G','Avertissement',
             'I','Programm�',
             'Q','Programm�',
             'R','Running'
*/                  
                  
--           and   fcrs.STATUS_CODE not in ('C','Q')
--and fcrs.PROGRAM like 'DKA%facturation%'                                                        -- cf cloture provisoire
--and fcrs.PROGRAM like 'DKA : G�n�ration des OD CAP multi-soci�t�'                                -- cf cloture provisoire
--and fcrs.PROGRAM like 'DKA : traitement de g�n�ration du CUT OFF%'                               -- cf cloture provisoire ou aussi le shell suivant : 
--  and fcrs.PROGRAM like 'FINFIN_C15TRT_04_WRK01_M : DKA_SPOCUTOFF_JOB.sh%'                         -- cf cloture provisoire
--and fcrs.PROGRAM like 'DKA : Calcul des TEC et PCA'                                              -- cf cloture provisoire ou aussi le shell suivant : 
  --and fcrs.PROGRAM like 'FINFIN_C19TRT_04_WRK01_M : DKA_SPATRAVCOURS_JOB.sh%'                      -- cf cloture provisoire
--and fcrs.PROGRAM like 'DKA : Gestion des CCA sur sinistres'                                      -- cf cloture provisoire
--and fcrs.PROGRAM like 'DKA : Equilibre comptable par centre de gestion'                          -- cf cloture provisoire
--and fcrs.PROGRAM like '%TVA%'   -- cf cloture provisoire

--and fcrs.PROGRAM like 'DKA : Export du d�tail de sous-traitance pour HYPERION'
--and fcrs.PROGRAM like 'DKA�: Extraction des donn�es PO pour HYPERION'
--and fcrs.PROGRAM like 'DKA%Extraction%donn�es%HYPERION%'


                         ---------- nuit suivante -----------
--and fcrs.PROGRAM like '%mputa%'
--and fcrs.PROGRAM = 'DKA : Extourne des TEC et PCA'                                               -- cf cloture provisoire
--and fcrs.PROGRAM like 'D%(DKA : Extourne CCA sur sinistre)'                                       -- cf cloture provisoire
--and fcrs.PROGRAM like '%mputa%'

--and fcrs.PROGRAM like '%POST%'
--and fcrs.PROGRAM like '%DKA : TVA Collectee : �tat pr�paratoire%'                                -- cf cloture provisoire
--and fcrs.PROGRAM like 'DKA%TVA%'

                  -- ******************* CLOTURE DEFINITIVE *********************
 --         and   fcrs.STATUS_CODE not in ('C','Q')
--and fcrs.PROGRAM like 'DKA : Equilibre comptable par centre de gestion'                          -- cf cloture d�finitive
--and fcrs.PROGRAM like 'DKA : Automate Etat d�claratif de la TVA dans GL%'                        -- cf cloture d�finitive

--and fcrs.PROGRAM like 'Mettre � jour les soldes de comptabilit� auxiliaire'                      -- cf cloture d�finitive
--and fcrs.PROGRAM like 'Gestionnaire de donn�es des soldes de comptes non sold�s'                 -- cf cloture d�finitive
--and fcrs.PROGRAM like 'DKA : Ech�ancier provisoire tous Soc/CdG'                                 -- cf cloture d�finitive


--and fcrs.PROGRAM like 'DKA : Etat de contr�le des retraitements IFRS'                -- pour IFRS      -- cf cloture d�finitive
--and fcrs.PROGRAM like 'DKA%VECTOR'                                                   -- pour Magnitude -- cf cloture d�finitive
    --and fcrs.PROGRAM like 'DKA : Balance VECTOR'                                                     -- cf cloture d�finitive
    --and fcrs.PROGRAM like 'DKA : G�n�ration du fichier VECTOR'                                       -- cf cloture d�finitive
    --and fcrs.PROGRAM like 'DKA : Consolidation VECTOR'                                               -- cf cloture d�finitive

-------and fcrs.PROGRAM like 'DKA : Automatisation de l%�tat d�finitif des pr�l�vements clients%'


--==================== XEROX =======================
--and fcrs.PROGRAM like 'DKA : Chargement des donn�es du controle de flux Xerox (Jeu d%�tats)'   -- le 1er de la s�rie
--and fcrs.PROGRAM like 'DKA : Chargement du fichier du CDF Xerox dans la table tmp'
--and fcrs.PROGRAM like '%DKA : Alimentation des tables factures Xerox%'
--and fcrs.PROGRAM like '%Xerox%'


--==================== Autres Traitements AP =======================
--and fcrs.ARGUMENT_TEXT LIKE '200,%Payables%'
--and fcrs.ARGUMENT_TEXT LIKE '%D�tail%'
--and fcrs.PROGRAM like 'DKA : Export du r�f�rentiel employ� vers NOTILUS%'                  -- NOTILUS
--and fcrs.PROGRAM like 'DKA : Interface Employes vers Oracle'                               -- GXP vers Oracle ?
--and fcrs.PROGRAM like 'DKA : Import des donn�es Fournisseurs depuis iValua'
--and fcrs.PROGRAM like '%%'

--==================== TVA ===============================
--and fcrs.PROGRAM like 'DKA%Automa%TVA%'
--and fcrs.PROGRAM like 'DKA : Automate TVA Collectee : �tat pr�paratoire
--and fcrs.PROGRAM like 'DKA : TVA Collectee : �tat pr�paratoire'
--and fcrs.PROGRAM like 'DKA : Automate France - D�claration d�taill�e de la TVA d�ductible
--and fcrs.PROGRAM like 'DKA : Etat d�claratif de la TVA dans GL' 
--and fcrs.PROGRAM like 'DKA : France - D�claration de la TVA d�ductible
--and fcrs.PROGRAM like 'DKA : France - D�claration d�taill�e de la TVA d�ductible'
--and fcrs.PROGRAM like 'DKA : Automate France - D�claration de la TVA d�ductible             -- cf cloture d�finitive
--and fcrs.PROGRAM like 'DKA : Automate Etat justificatif des comptes de TVA sur d�caissement.
--and fcrs.PROGRAM like 'DKA : Etat justificatif des comptes de TVA sur d�caissement.'
--and fcrs.PROGRAM like 'DKA : Automate Etat justificatif de l%en-cours de TVA sur encaissement
--and fcrs.PROGRAM like 'DKA : Etat justificatif de l'en-cours de TVA sur encaissement'
--and fcrs.PROGRAM like 'DKA : Compression et envoi des �tats de TVA aux r�gions


--================================================================================================================
--================================================================================================================
--==================== VCOM ===============================
--and fcr.CONCURRENT_PROGRAM_ID in ('59375','59374','77557','59374','47066','52355','47073','59375','59374')  
--and fcr.CONCURRENT_PROGRAM_ID in ('47073','59374')  
--and fcrs.ARGUMENT_TEXT like '%VCOM%'
--and fcrs.PROGRAM like 'Auto Select (XXS AP - Programme de demande de traitement des r�glements)'    -- concurrent_program_id = '59375'
--and fcrs.PROGRAM like 'XXS AP - Registre des propositions de r�glements'                            -- concurrent_program_id = '59374'
--and fcrs.PROGRAM like 'Apply Changes, Recalculate Amounts and Submit Request (XXS AP - Demande de traitement pour recalculer les r�glements)'       -- concurrent_program_id = '77557'
--and fcrs.PROGRAM like 'XXS AP - Registre des propositions de r�glements'                            -- concurrent_program_id = '59374'
--and fcrs.PROGRAM like 'Cr�er des r�glements%'                                                       -- concurrent_program_id = '47066'
--and (fcrs.PROGRAM like 'Formater les instructions de r�glement avec sortie texte%' or fcrs.PROGRAM like 'XXS AP - Registre des propositions de r�glements')                   -- concurrent_program_id = '52355'
--and fcrs.PROGRAM like 'Registre des instructions de r�glement%'                                     -- concurrent_program_id = '47073'
--and concurrent_program_id in ('59374','47073','52355')
--and fcrs.PROGRAM like 'Auto Select (XXS AP - Programme de demande de traitement des r�glements)'    -- concurrent_program_id = '59375'
--==================== POST - VCOM ===============================
--and fcrs.PROGRAM like 'XXS AP - Etat des �ch�anciers de paiement (PDF- XLS)'                        -- concurrent_program_id = '
--and fcrs.PROGRAM like 'XXS AP - Etat des Effets Fournisseurs'                                       -- concurrent_program_id = '
--and fcrs.PROGRAM = 'XXS AP - Mettre � jour le statut des effets � payer exigibles'
--and fcrs.PROGRAM = 'XXS AP - Etat des Effets Fournisseurs'
--and fcrs.PROGRAM = 'Envoyer des avis de paiement s�par�s'
--and fcrs.PROGRAM like '%avis%virement%'
--and fcrs.ARGUMENT_TEXT LIKE '%, Manual,%'
--and fcrs.COMPLETION_TEXT like 'Le GTS%'
--and fcrs.PROGRAM like 'XXS AP - Centralisation Fournisseurs (PDF - XLS)'
--and fcrs.PROGRAM like 'XXS AP - Journal des achats'
--and fcrs.PROGRAM like 'XXS AP - Journal des r�glements'
--and fcrs.PROGRAM like 'XXS AP - Etat des factures bloqu�es (PDF)'
--and fcrs.PROGRAM like 'XXS AP - Liste des fournisseurs (XLS)'    
--and fcrs.PROGRAM like 'XXS%AR%Conso%'

--==================== Campagne r�glements AP ===============================
--and fcrs.ARGUMENT_TEXT like 'DKA_SAPAUTORGT_JOB.sh%' -- 'DKA_IEOAPSAT01_APIMP_JOB.sh%'
--and  fcrs.request_id >= '28195999' --  '28194702'-- '28193603' -- '27952900' -- '27961119'  --  '27956661'  --  '27960235' -- '27960226' --  '27952900' --  '27948839' --  '27952743' --    '27948839'
--and fcrs.PROGRAM like 'DKA%glements automatiques toutes soc%des factures fournisseurs'  
--and fcrs.PROGRAM like 'Etat relatif � la s�lection de%�ch�ancier de paiement%'
--and fcrs.PROGRAM like 'Cr�er des r�glements'
--and fcrs.PROGRAM like 'Formater les instructions de r�glement avec sortie texte' 
--and fcrs.PROGRAM like 'Programme de demande de traitement des r�glements'  -- ATTENTION � la responsablit� (mais sans trop d'interet)
--and fcrs.PROGRAM like 'DKA : Campagne de r�glements - Alimentation des tables AP Import'
--and fcrs.PROGRAM like 'DKA : Campagne de r�glements - Cr�ation du fichier APIMPORT'
--and fcrs.PROGRAM like 'DKA : Cr�ation du fichier de pr�vision de tr�sorerie'           -- ====================== POURQUOI JE NE TROUVE PAS CE PUTAIN DE TRAITEMENT DE MERDE !!!!!!
--and fcrs.PROGRAM like 'DKA%Demande%traitement%recalculer%glements%'  -- ?????     -- ne semble pas etre lanc� par le 1er shell ...
--and fcrs.PROGRAM like 'DKA%'
--and fcrs.PROGRAM like 'Etat relatif%la s�lection de%ch�ancier de paiement'
--and fcrs.PROGRAM <> 'Processus Workflow en arri�re-plan'
--and fcrs.ARGUMENT_TEXT like 'DKA_IEOAPSAT01_APIMP_JOB.sh%'
--and fcrs.ARGUMENT_TEXT like '200, D%'  --    SWTIERSVIR0368%' --     '200, DRWTIERSVIR0712%'   --     '200, DMSTIERSVIR0363%'  --     

--==================== COMPTABILISATION AP ===============================
--and fcrs.CONCURRENT_PROGRAM_ID in ('48126','48093','20215','46932','48078','48096','53612')        -- �quivalent aux lignes ci-dessous
--and fcrs.PROGRAM like 'Cr�er une comptabilisation'                                                                              -- concurrent_program_id = '48126'
--and fcrs.PROGRAM like 'Programme de comptabilisation'                                                                           -- concurrent_program_id = '48093'
--and fcrs.PROGRAM like 'EasyLink'                                                                                                -- concurrent_program_id = '20215'
--and fcrs.PROGRAM like 'Imputation : Livre unique'                                                                               -- concurrent_program_id = '46932'
--and fcrs.PROGRAM like 'Gestionnaire de donn�es des soldes de comptes non sold�s'                                                -- concurrent_program_id = '48078'
--and fcrs.PROGRAM like 'TB Worker 1 (Traitement de processeur du gestionnaire de donn�es des soldes de comptes non sold�s)'      -- concurrent_program_id = '48096'
--and fcrs.PROGRAM like 'Mettre � jour les soldes de comptabilit� auxiliaire'                                                     -- concurrent_program_id = '53612'
--and fcrs.PROGRAM like '%onorai%'   
--==================== cot� AP =======================
--and fcrs.PROGRAM = 'Mettre � jour les soldes de comptabilit� auxiliaire' or fcrs.PROGRAM = 'Cr�er une comptabilisation' or fcrs.PROGRAM = 'Centraliser des pi�ces dans GL' or fcrs.PROGRAM = 'Mise � jour des soldes de comptabilit� auxiliaire'--=========
--and CONCURRENT_PROGRAM_ID in ('53612','48126','48102','48092')        -- �quivalent � la ligne ci-dessus
--and CONCURRENT_PROGRAM_ID = '48092'
--and fcrs.PROGRAM like 'DKA : Export des donn�es Factures vers iValua%'
--and fcrs.PROGRAM like 'DKA : Export des images Factures vers iValua'


--==================== COMPTABILISATION AR ===============================
--and fcrs.CONCURRENT_PROGRAM_ID in ('48126','48093','20215','46932','48078','48096','53612')        -- �quivalent aux lignes ci-dessous
--and fcrs.PROGRAM like 'Cr�er une comptabilisation'                                                                              -- concurrent_program_id = '48126'
--and fcrs.PROGRAM like 'Programme de comptabilisation'                                                                           -- concurrent_program_id = '48093'
--and fcrs.PROGRAM like 'EasyLink'                                                                                                -- concurrent_program_id = '20215'
--and fcrs.PROGRAM like 'Imputation : Livre unique'                                                                               -- concurrent_program_id = '46932'
--and fcrs.PROGRAM like 'Gestionnaire de donn�es des soldes de comptes non sold�s'                                                -- concurrent_program_id = '48078'
--and fcrs.PROGRAM like 'TB Worker 1 (Traitement de processeur du gestionnaire de donn�es des soldes de comptes non sold�s)'      -- concurrent_program_id = '48096'
--and fcrs.PROGRAM like 'Mettre � jour les soldes de comptabilit� auxiliaire'                                                     -- concurrent_program_id = '53612'
--and fcrs.PROGRAM like '%onorai%'   
--and fcrs.PROGRAM like 'XXS%'
--==================== cot� AR =======================
--and fcrs.PROGRAM = 'Mettre � jour les soldes de comptabilit� auxiliaire' --or fcrs.PROGRAM = 'Cr�er une comptabilisation' or fcrs.PROGRAM = 'Centraliser des pi�ces dans GL'  --=========
--and CONCURRENT_PROGRAM_ID in ('48102','48126','53612')        --  � la ligne ci-dessus
--and fcrs.PROGRAM like 'XXS AR - Balance client par compte'                    -- CONCURRENT_PROGRAM_ID = '131554'
--and fcrs.PROGRAM like 'XXS AR - Factures clients impay�es par client (PDF-XLS)'
--and fcrs.PROGRAM like 'XXS - Balance �g�e par compte 7 cat�gories (PDF - XLS)'
--and fcrs.PROGRAM like 'XXS GL - Balance - Grand format ( PDF - EXCEL )'        -- CONCURRENT_PROGRAM_ID = '60569'
--and fcrs.PROGRAM like 'XXS AR - Factures clients impay�es par RA (PDF-XLS)' 
--and fcrs.PROGRAM like 'XXS AR - Etat de TVA sur encaissement lettr�s'
--and fcrs.PROGRAM like '%FNP%'
--and fcrs.PROGRAM like 'XXS AR - Liste des factures clients (PDF - XLS)'
--and fcrs.PROGRAM like 'XXS AR - Journal des encaissements'
--and fcrs.PROGRAM like 'R�glements en attente de remise en banque'
--and fcrs.PROGRAM like 'Programme d%exigibilit� et de risque des effets � recevoir'
--and fcrs.PROGRAM like 'Apurement automatique des r�glements'
--and fcrs.PROGRAM = 'Centraliser des pi�ces dans GL'
--and fcrs.PROGRAM = 'Mise � jour des soldes de comptabilit� auxiliaire'     
--and fcrs.PROGRAM = 'Mettre � jour les soldes de comptabilit� auxiliaire'
--and fcrs.PROGRAM = 'Registre des r�glements non lettr�s et non r�solus'
--and fcrs.PROGRAM like '%ompte%'
--and fcrs.PROGRAM like 'DKA : Import des Factures clients'



--and fcrs.PROGRAM like 'DKA : Etat provisoire des pr�l�vements clients' 
--and fcrs.PROGRAM like  'DKA%tat%'

--==================== cot� GL =======================
--and fcrs.PROGRAM like 'Pi�ces - Total'
--and fcrs.PROGRAM like 'Soldes des p�riodes ouvertes%'

--==================== cot� FA =======================
--and fcrs.PROGRAM like 'XXS FA - Cr�er des pi�ces%'
--and fcrs.PROGRAM like 'Centraliser les pi�ces dans %'

--==================== GESTION DES PERIODES ===============================
--and fcrs.PROGRAM like '%TVA%'

--and fcrs.COMPLETION_TEXT like 'Warning%'

--and fcrs.REQUESTOR not in ('EXPLOITATION','SYSADMIN')  --  'NCHALGHAF' --  'JCANY ' --'PGRALL' --'35113B' --'04024W' --'61585H' '64643F'  '61499W' --'35113B'
--and fcrs.REQUESTOR = '35113B' -- '12797N' -- 'CTOUCHAIS' -- 'PGRALL' -- '35113B'-- '35113B' --   'EXPLOITATION' --  '57269D' --'BAC-PW03-001'
--and fcrs.User_Id = '35113B' -- '2321'

--order by frv.RESPONSIBILITY_NAME --fcrs.REQUEST_ID desc, frv.RESPONSIBILITY_NAME
order by fcrs.REQUEST_ID 
;



Select * from IMPRIMANTE_CSP_REGISTRE ;

-- Bonne nomenclature pour l'utilisation de la fonction to_date !!
select company, context, creation_date from xxspec_param_org
where trunc(creation_date) >= to_date('01012015','DDMMYYYY')    -- le trunc (colonne de type date) limitera forc�ment au format DDMMYYYY
;

--------------------- Requete SQL des traitements Chez Dalkia (J�r�me)----------------------------

SELECT Fcr.Request_Id AS Request_Id,
       fcr.parent_request_id as traitement_parent,
       Ltrim(Phase.Meaning) AS Phase,
       Ltrim(Status.Meaning) AS Statut,
       Fcp.Concurrent_Program_Name AS Nom_court,
       (SELECT DECODE(R.DESCRIPTION,
                      NULL,
                      PT.USER_CONCURRENT_PROGRAM_NAME,
                      R.DESCRIPTION || ' (' ||
                      PT.USER_CONCURRENT_PROGRAM_NAME || ')') PROGRAM
          FROM FND_CONCURRENT_PROGRAMS_TL PT,
               FND_CONCURRENT_PROGRAMS    PB,
               FND_USER                   U,
               FND_PRINTER_STYLES_TL      S,
               FND_CONCURRENT_REQUESTS    R
         WHERE PB.APPLICATION_ID = R.PROGRAM_APPLICATION_ID
           AND PB.CONCURRENT_PROGRAM_ID = R.CONCURRENT_PROGRAM_ID
           AND PB.APPLICATION_ID = PT.APPLICATION_ID
           AND PB.CONCURRENT_PROGRAM_ID = PT.CONCURRENT_PROGRAM_ID
           AND PT.LANGUAGE = USERENV('LANG')
           AND U.USER_ID = R.REQUESTED_BY
           AND S.PRINTER_STYLE_NAME(+) = R.PRINT_STYLE
           AND S.LANGUAGE(+) = USERENV('LANG')
           and R.REQUEST_ID = Fcr.Request_Id) AS Programme,

       Fcr.Argument_Text AS Parametres,
       Fcr.Actual_Start_Date AS Debute,
       Fcr.Actual_Completion_Date AS Termine,
       round((Fcr.Actual_Completion_Date - Fcr.Actual_Start_Date) * 24, 2) Duree,
       Fu.User_Name AS Demandeur,
       fr.responsibility_name,
       hou.name uo,
       fcr.logfile_name,
       fcr.outfile_name

  FROM Fnd_Concurrent_Requests    Fcr,
       Fnd_Concurrent_Programs    Fcp,
       Fnd_Concurrent_Programs_Tl Fcpt,
       Fnd_User                   Fu,
       Fnd_Lookups                Phase,
       Fnd_Lookups                Status,
       hr_operating_units         hou,
       fnd_responsibility_vl      fr

WHERE Phase.Lookup_Type = 'CP_PHASE_CODE'
   AND Phase.Lookup_Code = Fcr.Phase_Code
   AND Status.Lookup_Type = 'CP_STATUS_CODE'
   AND Status.Lookup_Code = Fcr.Status_Code
   AND Fcr.Program_Application_Id = Fcp.Application_Id
   AND Fcr.Concurrent_Program_Id = Fcp.Concurrent_Program_Id
   AND Fcp.Concurrent_Program_Name != 'FNDOAMCOL'
   AND Fcp.Application_Id = Fcpt.Application_Id
   AND Fcp.Concurrent_Program_Id = Fcpt.Concurrent_Program_Id
   AND Fcpt.LANGUAGE = 'F'
   and fcr.RESPONSIBILITY_ID = fr.responsibility_id
   AND Fu.User_Id = Fcr.Requested_By

      --AND Upper(Ltrim(Phase.Meaning)) = 'EN COURS'
      --AND status.meaning not like '%Normal%'

   AND Fcr.actual_Start_Date >=
       to_date('08/07/2021 17:00:00', 'DD/MM/YYYY HH24:MI:SS')
      --AND Fcp.Concurrent_Program_Name = 'DKA_SLAUNCHER'
   AND fcp.concurrent_program_name != 'FNDWFBG'
   AND fcr.org_id = hou.organization_id(+)
   
   --and Fcpt.USER_CONCURRENT_PROGRAM_NAME like 'Etat relatif � la s�lection de%�ch�ancier de paiement'
order by 1 desc
;
