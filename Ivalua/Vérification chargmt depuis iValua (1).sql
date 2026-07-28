--ces requêtes permettent de voir les fichiers qui ont réellement été intégrés
--commandes, réceptions, fournisseurs

--------------------------
-- Recherche de commandes
--------------------------

select  distinct TRUNC(dih.creation_date),dih.file_name
from    DKA_IPOCDE_hist_HEADERS dih 
order by 1 DESC
;

-------------------------------
-- Fournisseurs
-------------------------------
SELECT  distinct dih.creation_date,dih.file_name
FROM    DKA_IPOFRS_hist_ENTETES dih
order by dih.creation_date DESC
;


-----------------------------------------------
-- RECEPTIONS
-----------------------------------------------

SELECT distinct dii.creation_date, dii.file_name 
FROM   DKA_IPOREC_hist_INTERFACE dii
order by dii.creation_date DESC
;