create or replace PACKAGE DKA_IEOMTL_CODARTINT_PKG
AS
------------------------------------------------------------------------
-- $Id: DKA_IEOMTL_CODARTINT_PKG.pks
-- Capgemini
-- Nom              : DKA_IEOMTL_CODARTINT_PKG.pks
-- Description      : Spécification du package DKA_IEOMTL_CODARTINT_PKG
-- Auteur           : F.Siham
-- Date de création : 01/11/2018
-- Doc. associée    :
-- Commentaires     : A exécuter sous SQLPLUS avec l'utilisateur APPS
------------------------------------------------------------------------
-- Historique
-- Date       Qui Description
-- ---------- --- ------------------------------------------------------
-- 14/01/2019 CDE Ajustement paramètres de certaines fonctions
-- ---------- --- ------------------------------------------------------


--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PUBLIQUES
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PUBLIQUES
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

-- fonction pour alimenation de la table temporaire DKA_IEOMTL_SYSTEM_ITEMS_TMP--

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

FUNCTION chgt_file_cod_artint(        
        access_id          IN NUMBER,
        pv_file_id         OUT VARCHAR2,
        pv_message_erreur  OUT VARCHAR2) 
	RETURN VARCHAR2;


PROCEDURE controle_nbr_enreg_file(p_errbuf        OUT NOCOPY VARCHAR2,
									  p_retcode       OUT NOCOPY NUMBER) ;

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

-- fonction de contrôle de format des enregistremets--

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

FUNCTION CONTROL_FORMAT_CODES(p_code in varchar2)

return varchar2;


--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

-- procédure de contrôle d'unicité de code article pour les enregistremets--

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

function  CONTROLE_UNICITE 
return number;

 --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

-- procédure de contrôle de cohérance des enregistrements--

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

PROCEDURE  CONTROLE_DONNEES(p_errbuf        	IN OUT  VARCHAR2,
							p_retcode       	OUT  NUMBER);

PROCEDURE init(
        pv_errbuf    OUT      VARCHAR2,
        pn_retcode   OUT      NUMBER
        );

 --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

-- procédure de suppression des enregistrements en statut compléte--

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROCEDURE delete_complete_records (
        p_errbuf    OUT      VARCHAR2,
        p_retcode   OUT      NUMBER
        );                 

 --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

-- function de récuperation de l'identifiant de l'article--

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

 FUNCTION get_inventory_item_id (
        p_segment           IN VARCHAR2,
        p_organization_id   IN NUMBER
    ) RETURN NUMBER;

 /*--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

-- function de vérification de l'article dans oracle--

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

FUNCTION check_items_oi (
                         p_segment              varchar2,
                         p_description          varchar2,
                         p_statut               varchar2,
                         p_organization_id      NUMBER,
                         p_organization_id1     NUMBER,
                         p_inventory_item_id    NUMBER
                        )
RETURN VARCHAR2;
*/
FUNCTION get_category_id (
        p_structure_id       IN NUMBER,
        p_category           IN VARCHAR2
    ) RETURN NUMBER;


 --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

-- function de récuperation de la catégorie de l'article--

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   FUNCTION get_item_category (
        p_inventory_item_id IN NUMBER,
        p_item_category_set_id   IN NUMBER,
        p_structure_id       IN NUMBER
    ) RETURN VARCHAR2;

    FUNCTION get_item_category_sec (
        p_inventory_item_id IN NUMBER,
        p_item_category_set_id   IN NUMBER,
        p_structure_id       IN NUMBER,
        p_category        IN VARCHAR2
    ) RETURN NUMBER;

    PROCEDURE insert_assign_category_item (
        p_errbuf    OUT VARCHAR2,
        p_retcode   OUT NUMBER
    );
    
    PROCEDURE  launch_item_category (
                                      p_errbuf    OUT      VARCHAR2,
                                      p_retcode   OUT      NUMBER
                                    );                 

 --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

-- procédure de chargement ou mise à jour des valeurs des jeux de valeurs
    ---DKA_ARTICLE_FAMILLE_TECH et DKA_ARTICLE_COMPL_TECH_ALL--

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


Procedure alimentation_jeux_valeurs (p_errbuf        IN 	 OUT  VARCHAR2,
								     p_retcode       	OUT  NUMBER);


 --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

-- procédure d'insertion dans la table d'interfaces des articles--

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROCEDURE insert_items_interface (
        p_type_org          IN VARCHAR2,
        p_statut            IN VARCHAR2,
        p_errbuf            OUT VARCHAR2,
        p_retcode           OUT NUMBER
    );
PROCEDURE Launch_Items_OI(       
        p_mode             IN NUMBER,
        p_type_org         IN VARCHAR2,
        p_errbuf           OUT VARCHAR2,
        p_retcode          OUT NUMBER
                            ) ;   
procedure check_items_oi (
                            p_request_id       NUMBER,
                            p_type_org         VARCHAR2,
						              	p_status_old		   VARCHAR2,
                            p_status_new       VARCHAR2
                          );                       
procedure check_category_items_oi ;

/*// procédure principale   //*/

procedure main (p_errbuf 	 IN  OUT  VARCHAR2,
			    p_retcode       	OUT  NUMBER);

procedure bilan(P_Errbuf            OUT VARCHAR2,
                 P_Retcode           OUT NUMBER);
				 
FUNCTION check_code_isNumeric (p_code VARCHAR2)
	RETURN VARCHAR2;				 

END DKA_IEOMTL_CODARTINT_PKG;

/
SHOW ERRORS
EXIT
