/*
--- Description : Script de MAJ des valeurs historiques pour alimenter les nouvelles valeurs d’attribut de ligne sur les dépenses et événements
--- Auteur      : SELO
--- Date        : 18/03/2020
--- EDB259
*/

update PA_EXPENDITURE_ITEMS_ALL
   set attribute8=substr(attribute4,instr(attribute4,'_')+1, length(attribute4))
     , attribute4=substr(attribute4,1, instr(attribute4,'_')-1)
 where attribute4 is not null
 --and attribute4='10320_3'
 ;
 
commit;

 update PA_EVENTS
   set attribute8=substr(attribute5,instr(attribute5,'_')+1, length(attribute5))
     , attribute5=substr(attribute5,1, instr(attribute5,'_')-1)
 where attribute5 is not null
 --and attribute5='24820_2'
 ;
 
 Commit;
/

SHOW ERRORS;

EXIT
 