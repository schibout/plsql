-------------------------------------------------------------------------------
-- CAP GEMINI ERNST AND YOUNG
-- Projet 	  		 : DALKIA Oracle Applications
-- Auteur 			 : xxx
-- Date Création 	 :
--------------------------------------------------------------------------------
-- NOM 			     : MODELE.sql
-- DESCRIPTION       : xxxxxx
--------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -------------------------------------------------------------
--- 09/06/2008 ED  Mise à niveau de la liste des Users
--- 29/05/2012 GF  Mise à niveau de la liste des Users
--- 01/02/2012 JJA Ajout de la mise à jour de la valeur d'ouverture de TP
--- 11/06/2013 JJA [Suppression] Ajout de la mise à jour de la valeur d'ouverture de TP
--- 08/01/2014 GF  Ajout de l'accès en TP RESTREINT à S. REIGNIER, D LEBEURRE et B. JOURET 
--- 02/03/2015 GF  Ajout de l'utilisateur EAI en TP Fermé
--- 18/10/2017 JWY Ajout / Suppression d'utilisateurs suite demande L. JOVE
--- 17/01/2018 MEG Ajout / Suppression d'utilisateurs
--------------------------------------------------------------------------------
Set serveroutput On
Set verify Off

--Accept vv_function Prompt 'Desactiver (D) ou Reactiver (R): '&vv_function
--Accept vv_end_date Prompt 'Date de desactivation (DD/MM/YYYY): '&vv_end_date
Begin
	Dbms_output.Put_Line ('.');
	Dbms_output.Put_Line ('.');

	Update fnd_user
	Set end_date = To_Date ('&2', 'DD/MM/YYYY')
	Where Upper ('&1') = 'D'
	  And (   end_date Is Null
		   Or end_date >= Sysdate )
	  And user_name Not In ('SYSADMIN',
                          'ANONYMOUS',
                          'AUTOINSTALL',
                          'APPSMGR',
                          'CONCURRENT MANAGER',
                          'FEEDER SYSTEM',
                          'GUEST',
                          'INITIAL SETUP',
                          'WIZARD',
                          'DATALOAD_PRO_PLAY_DID',
                          'JJARDEZ',
                          'CDELCASSO',
                          'RIROUX',
                          'RBELAYACHI',
                          'NBOUSSEK',
                          'MAEGOT',
                          'LNAYROLL',
                          'ADESCAMPS',
                          'JWYCKAER',
                          'MTIABLIK',
                          'OBENHAYOUN',
                          'BCOPIN',
                          'EAI',
                          'EXPLOITATION',
                          'CBONHOMME',
                          'DKAEXPLOIT',
                          'NCAILLAT',
                          'MDEFLUBE',
                          'EATTIA',
                          'PFAUCHARD',
                          'YPLUMEL',
                          '60636J',
                          'AROUX',
                          'BHADDOUCHE');
                          
	Dbms_output.Put_Line (SQL%ROWCOUNT || ' users desactives au ' || '&2');
	
	Update fnd_user
	Set end_date = Null
	Where Upper ('&1') = 'R'
	  And end_date = To_Date ('&2', 'DD/MM/YYYY')
	  And user_name Not In ('SYSADMIN',
                          'ANONYMOUS',
                          'AUTOINSTALL',
                          'APPSMGR',
                          'CONCURRENT MANAGER',
                          'FEEDER SYSTEM',
                          'GUEST',
                          'INITIAL SETUP',
                          'WIZARD',
                          'DATALOAD_PRO_PLAY_DID',
                          'JJARDEZ',
                          'CDELCASSO',
                          'RIROUX',
                          'RBELAYACHI',
                          'NBOUSSEK',
                          'MAEGOT',
                          'LNAYROLL',
                          'ADESCAMPS',
                          'JWYCKAER',
                          'MTIABLIK',
                          'OBENHAYOUN',
                          'BCOPIN',
                          'EAI',
                          'EXPLOITATION',
                          'CBONHOMME',
                          'DKAEXPLOIT',
                          'NCAILLAT',
                          'MDEFLUBE',
                          'EATTIA',
                          'PFAUCHARD',
                          'YPLUMEL',
                          '60636J',
                          'AROUX',
                          'BHADDOUCHE');
                            
	Dbms_output.Put_Line (SQL%ROWCOUNT || ' users reactives');
	
End;
/

EXIT;


