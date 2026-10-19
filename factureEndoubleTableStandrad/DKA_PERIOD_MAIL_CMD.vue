CREATE OR REPLACE PACKAGE BODY IBY_ASSIGNEXT_PUB AS
/*$Header: ibyasgnextb.pls 120.1 2009/06/25 09:20:42 jnallam noship $*/

-- -----------------------------------------------------------------------------
-- $$
-- Capgemini
-- PROJET           : DALKIA Oracle Applications
-- NOM              : IBY_ASSIGNEXT_PUB
-- DESCRIPTION      : IBY_ASSIGNEXT_PUB Package Body
--
-- AUTEUR           : J.JARDEZ (Capgemini)
-- DATE DE CREATION : 02/10/2017
-- COMMENTAIRES     : A exécuter sous SQLPLUS avec le user apps
-- -----------------------------------------------------------------------------
--
-- -----------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
-- Date       Qui Description
-- ---------- --- --------------------------------------------------------------
-- 02/10/2017 JJA SPE118 : Campagne de Prelevement AP
-- 28/03/2018 RBE Correction : artf2470765: INC0191103 : SPE118 - Correctif sur lancement campagne Prelevement AP
-- 23/09/2021 NBO INC0583872 - Possible régression des prélèvements automatiques classique - EDB279
-- -----------------------------------------------------------------------------



 --
 -- Declare global variables
 --
 G_PKG_NAME CONSTANT VARCHAR2(30) := 'IBY_ASSIGNEXT_PUB';
 G_LEVEL_STATEMENT CONSTANT NUMBER := FND_LOG.LEVEL_STATEMENT;
 G_CUR_RUNTIME_LEVEL CONSTANT NUMBER := FND_LOG.G_CURRENT_RUNTIME_LEVEL;
 G_LEVEL_UNEXPECTED CONSTANT NUMBER := FND_LOG.LEVEL_UNEXPECTED;
 G_LEVEL_ERROR CONSTANT NUMBER := FND_LOG.LEVEL_ERROR;
 G_LEVEL_EXCEPTION CONSTANT NUMBER := FND_LOG.LEVEL_EXCEPTION;
 G_LEVEL_EVENT CONSTANT NUMBER := FND_LOG.LEVEL_EVENT;
 G_LEVEL_PROCEDURE CONSTANT NUMBER := FND_LOG.LEVEL_PROCEDURE;

 --
 -- Forward declarations
 --
 PROCEDURE print_debuginfo(
              p_module      IN VARCHAR2,
              p_debug_text  IN VARCHAR2,
              p_debug_level IN VARCHAR2  DEFAULT FND_LOG.LEVEL_STATEMENT
              );

 /*--------------------------------------------------------------------
 | NAME:
 |      hookForAssignments
 |
 | PURPOSE:
 |      The assignment flow will call this hook with a list of
 |      unassigned documents (documents that do not have account/
 |      profile even after the assignment flow attempted to default
 |      them).
 |
 |      The customer can implement custom assignment logic here to
 |      assign defaults to the unassigned documents. The assignment
 |      flow will use these custom assignments to update the individual
 |      documents.
 |
 |      This hook will ship with an empty body from Oracle. The customer
 |      may implement this hook on their environment if they wish.
 |
 | PARAMETERS:
 |     IN
 |
 |     OUT
 |
 |
 | RETURNS:
 |
 | NOTES:
 |
 *---------------------------------------------------------------------*/
 PROCEDURE hookForAssignments(
     x_unassgnDocsTab IN OUT NOCOPY IBY_ASSIGN_PUB.unassignedDocsTabType
     )
 IS
 l_module_name CONSTANT VARCHAR2(200) := G_PKG_NAME || '.hookForAssignments';

 vn_pay_profil_id IBY_PAYMENT_PROFILES.PAYMENT_PROFILE_ID%TYPE;
 vn_pay_profil_id2 IBY_PAYMENT_PROFILES.PAYMENT_PROFILE_ID%TYPE;
 vn_bank_acct_id  NUMBER;
 vn_bank_acct_id2  NUMBER;
 ln_count NUMBER;

 BEGIN

     IF (G_LEVEL_STATEMENT >= G_CUR_RUNTIME_LEVEL) THEN
     print_debuginfo(l_module_name, 'ENTER');
     END IF;

     IF (G_LEVEL_STATEMENT >= G_CUR_RUNTIME_LEVEL) THEN
       FOR i in x_unassgnDocsTab.first..x_unassgnDocsTab.last LOOP
            print_debuginfo(l_module_name, 'DKA - hookForAssignments : ' || x_unassgnDocsTab(i).payment_method_code || ':' || x_unassgnDocsTab(i).pay_proc_ttype_cd
            ||':'|| x_unassgnDocsTab(i).document_id||':'|| x_unassgnDocsTab(i).pay_profile_id||':'|| x_unassgnDocsTab(i).calling_app_doc_id1
            || ':' ||  x_unassgnDocsTab(i).calling_app_doc_id2);
       END LOOP;
     END IF;

     /* SPE118 - DKA CAMPAGNE DE PRELEVEMENT */

     /*Recherche du compte bancaire interne du traitement*/
     IF (G_LEVEL_STATEMENT >= G_CUR_RUNTIME_LEVEL) THEN
     print_debuginfo(l_module_name, 'Recherche du compte bancaire interne du traitement');
     END IF;
     BEGIN
         SELECT COUNT(1)
         INTO ln_count
         FROM
          fnd_concurrent_requests fcr,
         fnd_concurrent_programs_vl fcp
         WHERE
             fcr.concurrent_program_id = fcp.concurrent_program_id
         AND fcp.concurrent_program_name = 'DKA_PREL_AP_RB_CREA'
         AND fcr.PHASE_CODE IN ('R') --En cours
         AND fcr.STATUS_CODE IN ('I','R','C') --Normal
         ORDER BY request_id DESC;

       IF ln_count = 0 THEN
         SELECT argument6 -- RBE artf2470765
         INTO vn_bank_acct_id
         FROM (
           SELECT fcr.argument6 -- RBE artf2470765
           FROM
            fnd_concurrent_requests fcr,
           fnd_concurrent_programs_vl fcp
           WHERE
               fcr.concurrent_program_id = fcp.concurrent_program_id
           AND fcp.concurrent_program_name = 'DKA_SAPCAMPPREL_PKG'
           -- 23/09/2021 NBO INC0583872 - Possible régression des prélèvements automatiques classique - EDB279
           AND fcr.PHASE_CODE IN ('R','C') --En cours
           --AND fcr.PHASE_CODE IN ('R') --En cours
           AND fcr.STATUS_CODE IN ('I','R','C') --Normal
           ORDER BY request_id DESC)
         WHERE ROWNUM =1;
       END IF;

     EXCEPTION
       WHEN NO_DATA_FOUND THEN
        print_debuginfo(l_module_name, 'Traitement DKA_SAPCAMPPREL_PKG ou DKA_PREL_AP_RB_CREA non trouvé');
        RETURN;
       WHEN OTHERS THEN
        print_debuginfo(l_module_name, 'ERREUR : '||SQLERRM);
        RAISE;
     END;

     IF (G_LEVEL_STATEMENT >= G_CUR_RUNTIME_LEVEL) THEN
     print_debuginfo(l_module_name, 'Recherche du profil');
     END IF;
     SELECT PAYMENT_PROFILE_ID
     INTO vn_pay_profil_id
     FROM IBY_PAYMENT_PROFILES
     WHERE PAYMENT_PROFILE_NAME = 'DKA_PRELEVEMENT';

     --Pour tous les documents en attente
     IF (G_LEVEL_STATEMENT >= G_CUR_RUNTIME_LEVEL) THEN
     print_debuginfo(l_module_name, 'Pour tous les documents en attente: vn_bank_acct_id : '||vn_bank_acct_id||
                                    ' / vn_pay_profil_id : '||vn_pay_profil_id);
     END IF;


     FOR i in x_unassgnDocsTab.first..x_unassgnDocsTab.last LOOP

       BEGIN
         
         BEGIN
         select id_compte_bancaire
         INTO vn_bank_acct_id2
         FROM dka_prel_ap_rb where id_facture_ap = x_unassgnDocsTab(i).calling_app_doc_id2
         AND statut_etape = 'E2';
         
         EXCEPTION
           WHEN TOO_MANY_ROWS THEN
             vn_bank_acct_id2 := NULL;             
             print_debuginfo(l_module_name, 'TOO_MANY_ROWS sur la facture : '||x_unassgnDocsTab(i).calling_app_doc_id2);

         END;

         SELECT PAYMENT_PROFILE_ID
         INTO vn_pay_profil_id2
         FROM IBY_PAYMENT_PROFILES
         WHERE PAYMENT_PROFILE_NAME = 'DKA_PREL_AUTO_FRN';

         IF (G_LEVEL_STATEMENT >= G_CUR_RUNTIME_LEVEL) THEN
           print_debuginfo(l_module_name, 'vn_bank_acct_id2 : '||vn_bank_acct_id2||
                                          ' / vn_pay_profil_id2 : '||vn_pay_profil_id2);
         END IF;

         x_unassgnDocsTab(i).int_bank_acct_id := vn_bank_acct_id2;
         x_unassgnDocsTab(i).pay_profile_id   := vn_pay_profil_id2;
       EXCEPTION
       WHEN NO_DATA_FOUND THEN
         x_unassgnDocsTab(i).int_bank_acct_id := vn_bank_acct_id;
         x_unassgnDocsTab(i).pay_profile_id   := vn_pay_profil_id;
       END;

     END LOOP;


     /* SPE118 - DKA CAMPAGNE DE PRELEVEMENT - FIN*/

     IF (G_LEVEL_STATEMENT >= G_CUR_RUNTIME_LEVEL) THEN
     print_debuginfo(l_module_name, 'EXIT');
     END IF;

 END hookForAssignments;

 /*--------------------------------------------------------------------
 | NAME:
 |     print_debuginfo
 |
 | PURPOSE:
 |     This procedure prints the debug message to the concurrent manager
 |     log file.
 |
 | PARAMETERS:
 |     IN
 |      p_debug_text - The debug message to be printed
 |
 |     OUT
 |
 |
 | RETURNS:
 |
 | NOTES:
 |
 *---------------------------------------------------------------------*/
 PROCEDURE print_debuginfo(
     p_module      IN VARCHAR2,
     p_debug_text  IN VARCHAR2,
     p_debug_level IN VARCHAR2  DEFAULT FND_LOG.LEVEL_STATEMENT
     )
 IS
 l_default_debug_level VARCHAR2(200) := FND_LOG.LEVEL_STATEMENT;
 BEGIN

     /*
      * Set the debug level to the value passed in
      * (provided this value is not null).
      */
     IF (p_debug_level IS NOT NULL) THEN
         l_default_debug_level := p_debug_level;
     END IF;

     /*
      * Write the debug message to the concurrent manager log file.
      */
     IF (l_default_debug_level >= G_CUR_RUNTIME_LEVEL) THEN
         iby_build_utils_pkg.print_debuginfo(p_module, p_debug_text,
             p_debug_level);
     END IF;

 END print_debuginfo;

 END IBY_ASSIGNEXT_PUB;
 /
SHOW ERROR PACKAGE BODY IBY_ASSIGNEXT_PUB
EXIT