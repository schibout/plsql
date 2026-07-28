--ORA_DONNEES_BLOCAGES_FACTURES_ANNEE_EN_COURS.csv
SELECT DISTINCT
       aha.invoice_id                             id_et_facture,
       aha.hold_id                                hold_id,
       aha.line_location_id                       id_ligne_livr_comm,
       aha.hold_lookup_code                       code_blocage,
       REPLACE (aha.hold_reason, '"', ' ')        raison_blocage,
       (SELECT fu.user_name
          FROM apps.fnd_user fu
         WHERE fu.user_id = aha.held_by)          bloquee_par,
       aha.hold_date                              date_blocage,
       aha.last_update_date                       derniere_modif_blocage,
       aha.attribute2                             id_wkf_facture,
       CASE
           WHEN aha.attribute4 = 'Y' THEN 'OUI'
           WHEN NVL (aha.attribute4, 'N') = 'N' THEN 'NON'
       END                                        a_traiter_ivalua,
       aha.attribute5                             type_blocage_en_attente,
       (SELECT DISTINCT ppf.employee_number
          FROM apps.per_people_f ppf
         WHERE ppf.person_id = aha.attribute6)    notifiee_iva_blc_en_attente,
         aha.release_lookup_code                       code_deblocage,
       REPLACE (aha.release_reason, '"', ' ')        raison_deblocage,
         (SELECT fu.user_name
          FROM apps.fnd_user fu
         WHERE fu.user_id = aha.last_updated_by)          debloquee_par,
         
         case when c.hold_id is  null
         then a.approver_name
         else
          ( select d.full_name from  per_people_f d
          where c.response_code ='DKA_REFUSE_IVALUA' and c.invoice_id = aha.invoice_id
           and Upper(d.email_address) =substr(c.commentaire, instr(c.commentaire, ':') +1, instr(c.commentaire,'/') -instr(c.commentaire, ':') -1) and rownum =1)
         end as Mise_en_litige_par,
         
          case when c.hold_id  is null
         then 
         (select distinct ppf.employee_number from  per_people_f ppf  where 
              ppf.full_name = a.approver_name and rownum =1)
         else
         ( select d.employee_number from  per_people_f d
          where  Upper(d.email_address) =substr(c.commentaire, instr(c.commentaire, ':') +1, instr(c.commentaire,'/') -instr(c.commentaire, ':') -1) and rownum=1
          )
         end as Matricule_Mise_en_litige,
         
         case when c.hold_id  is null
         then
          a.creation_date 
         else
         aha.creation_date
         end as Mise_en_litige_le,
         
          case when c.hold_id  is null
         then
           a.approver_comments
         else 
          c.commentaire 
         end as Commentaire_litige,
        
        case when aha.release_lookup_code is not null
         then aha.last_update_date
         else null
         end as Débloquée_le,
		 aha.attribute9 as Poseur_litige
       
  FROM apps.ap_holds_all aha
  left outer join ap_inv_aprvl_hist_all a on a.invoice_id = aha.invoice_id
  and a.response ='DKA_REFUS' 
  and decode(substr(a.approver_comments, 1, instr(a.approver_comments, '-')-2), 'Ecart de prix', 'En litige Prix', 'QTY_REC', 'En litige Quantité REC','QTY_CDE', 'En litige Quantité CDE' ) = aha.hold_lookup_code
  left outer join dka_iapfac_debloc_repor_interf c on  c.response_code ='DKA_REFUSE_IVALUA' and c.invoice_id = aha.invoice_id
         and c.hold_id = aha.hold_id
 WHERE     1 = 1 and EXISTS (select 'X' from ap_holds_all aha2 where aha2.invoice_id = aha.invoice_id
 and aha2.hold_lookup_code like 'En litige%');