-------------------------------------
-- Verifications qutidiennes
-------------------------------------
---------------------------------------
-- DSP
---------------------------------------
-- 5 flux sont normalement int�gr�s tous les jours ouvr�s: 2 fournisseurs (SUP), 1 commande, 1 reception, 1 deblocage 
-- Fournisseurs
select distinct trunc(dih.creation_date) as date_creation,
                to_char(
                   dih.creation_date,
                   'Day'
                ) as jour_creation,
                dih.file_name
  from dka_ipofrs_hist_entetes dih
 where dih.creation_date > sysdate - 3
union all 

-- Commandes DSP
select distinct trunc(dih.creation_date) as date_creation,
                to_char(
                   dih.creation_date,
                   'Day'
                ) as jour_creation,
                dih.file_name
  from dka_ipocde_hist_headers dih
 where dih.creation_date > sysdate - 3
union all 

-- R�ceptions
select distinct trunc(dih.creation_date) as date_creation,
                to_char(
                   dih.creation_date,
                   'Day'
                ) as jour_creation,
                dih.file_name
  from dka_iporec_hist_interface dih
 where dih.creation_date > sysdate - 3
union all 

-- D�blocage
select distinct trunc(dih.creation_date) as date_creation,
                to_char(
                   dih.creation_date,
                   'Day'
                ) as jour_creation,
                dih.file_name
  from dka_iapfac_debloc_hist_interf dih
 where dih.creation_date > sysdate - 3
 order by date_creation desc,
          jour_creation,
          file_name;


---------------------------------------
-- Notes de frais
---------------------------------------
-- Des Ndf sont "normalement" cr��es tous les jours ouvr�s
select trunc(creation_date),
       to_char(
          creation_date,
          'DAY'
       ) "Jour d'int�gration",
       count(*)
  from ap_invoices_all
 where attribute9 = 'NOT'
 group by trunc(creation_date),
          to_char(
             creation_date,
             'DAY'
          )
 order by trunc(creation_date) desc;

---------------------------------------
-- Factures Xerox et Tradeshift
---------------------------------------
-- Inventaire des factures charg�es dans l'interface sur les 4 derniers jours
-- 3 fichiers par jours ouvr�s (XEROX, TRADESHIFT & DSP)
-- 1 fichier TRADESHIFT le samedi et qqfois le dimanche
select date_creation,
       decode(
          substr(
             imagefile,
             1,
             3
          ),
          'VE1',
          'XEROX',
          'L56',
          'TRADESHIFT',
          'DSP',
          'DSP',
          'AUTRES'
       ) source,
       count(*)
  from dka_iapfacxgs_reporting_all
 where to_date(date_creation,
        'YYYYMMDD') > sysdate - 4
 group by date_creation,
          decode(
             substr(
                imagefile,
                1,
                3
             ),
             'VE1',
             'XEROX',
             'L56',
             'TRADESHIFT',
             'DSP',
             'DSP',
             'AUTRES'
          )
 order by date_creation desc;

-- Factures Xerox du jour avec des images rattach�es 
-- Les images sont normalement envoy�es avec les factures et elles sont rattach�es � la suite (la m�me nuit) de la cr�ation des factures
select count(*)
          -- dir.date_creation, dir.num_fact, dir.reference_lad, dir.*
  from dka_iapfacxgs_reporting_all dir,
       ap_invoices_all aia,
       fnd_documents fd
 where dir.nom_fichier like 'VE1_DAL%'
   and dir.date_creation = to_char(
   sysdate - 1,
   'YYYYMMDD'
) -- '20251215' -- '20251120'
   and aia.creation_date > sysdate - 30
   and aia.invoice_num = dir.num_fact
   and fd.creation_date > sysdate - 30
   and ( substr(
   fd.file_name,
   1,
   length(fd.file_name) - 4
) = aia.attribute3
    or fd.file_name = aia.attribute3 );


-- Factures Xerox du jour sans images rattach�es 
select dir.date_creation,
       dir.num_fact,
       dir.reference_lad,
       dir.*
  from dka_iapfacxgs_reporting_all dir,
       ap_invoices_all aia
 where dir.nom_fichier like 'VE1_DAL%'
   and dir.date_creation = to_char(
   sysdate - 1,
   'YYYYMMDD'
) -- '20251208' -- '20251120'
   and aia.creation_date > sysdate - 30
   and aia.invoice_num = dir.num_fact
   and not exists (
   select *
     from fnd_documents fd
    where fd.creation_date > sysdate - 30
      and ( substr(
      fd.file_name,
      1,
      length(fd.file_name) - 4
   ) = aia.attribute3
       or fd.file_name = aia.attribute3 )
)
  --       AND dir.reference_lad = 'VE1-00119-20251117-1234-297-002-FMU-001-ED1Flux.TIF'
                                --  VE1-00119-20251117-1234-297-002-FMU-001-ED1Flux.TIF
;
  
  
------------------------------
-- Ecritures GL 
------------------------------

-- Lignes d'�critures charg�es dans l'interface GL
select attribute10,
       attribute9
-- , accounting_date
       ,
       status,
       count(*),
       sum(entered_dr)
  from gl_interface 
-- where attribute9 = 'THO'
--where date_created > trunc(sysdate - 3)
 group by attribute10,
          attribute9
-- , accounting_date
          ,
          status
 order by attribute10,
          attribute9
--, status
          ;

-- Ligne d'�critures cr��es les 3 derbiers jours
select trunc(creation_date),
       attribute10--, attribute9
       ,
       count(*),
       sum(entered_dr)
  from gl_je_lines
 where creation_date > sysdate - 3
 group by trunc(creation_date),
          attribute10 -- , attribute9
 order by trunc(creation_date) desc,
          attribute10 desc;



------------------------------------------------
-- Traitement de la nuit
------------------------------------------------
-- Fermeture du service = 19h / Ouverture du service = 7h
select fcr.request_id,
       fcp.user_concurrent_program_name as programme,
       to_char(
          fcr.actual_start_date,
          'DD/MM/YYYY HH24:MI:SS'
       ) as heure_debut,
       to_char(
          fcr.actual_completion_date,
          'DD/MM/YYYY HH24:MI:SS'
       ) as heure_fin,
       case fcr.status_code
          when 'C' then
             'Normal'
          when 'E' then
             'Erreur'
          when 'G' then
             'Warning'
          when 'X' then
             'Termin�'
          when 'R' then
             'En cours'
          when 'W' then
             'En attente'
          else
             'Autre ('
             || fcr.status_code
             || ')'
       end as statut,
       case
          when fcr.status_code in ( 'E',
                                    'X',
                                    'D',
                                    'U' ) then
             'KO'
          when fcr.status_code = 'G' then
             'WARNING'
          when fcr.status_code = 'C' then
             'OK'
          else
             'EN_COURS'
       end as resultat,
       round(
          (fcr.actual_completion_date - fcr.actual_start_date) * 24,
          2
       ) as duree_heures,
       round(
          (fcr.actual_completion_date - fcr.actual_start_date) * 24 * 60,
          2
       ) as duree_minutes,
       fcr.argument_text as parametres,
       fcr.completion_text as message
  from fnd_concurrent_requests fcr
  join fnd_concurrent_programs_vl fcp
on fcr.concurrent_program_id = fcp.concurrent_program_id
 where fcr.actual_start_date >= trunc(sysdate - 1) + 19 / 24  -- Hier � 19h00
   and fcr.actual_start_date < trunc(sysdate) + 7 / 24       -- Aujourd'hui � 07h00
        -- Traitemennts en erreur
   and fcr.status_code = 'E'
        -- Traitement de dur�e > 1h
        -- AND round((fcr.actual_completion_date - fcr.actual_start_date) * 24, 2) > 1
 order by fcr.actual_start_date desc;

Traitement  en Erreur  DKA : Imputation des charges d'achats  à  31/01/2026 01:33:36 et DKA : Clôture de la période AR  à 01/02/2026 00:55:24

---------------------------
-- RB
---------------------------
-- Derniers chargements / nb de compte impact�s
-- Les chargement sont r�alis�s le matin vers 8h30
-- Des relev�s sont charg�s automatiquement tous les jours sauf le dimanche et le lundi
-- PS: La SG nous envoie un fichier le lundi matin. Il doit �tre charg� manuellement (rattrapage)
select import_date,
       count(*)
  from rb_batch_import
 where import_date > sysdate - 3
 group by import_date
 order by import_date desc;