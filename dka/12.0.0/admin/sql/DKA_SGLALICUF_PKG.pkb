CREATE OR REPLACE PACKAGE BODY DKA_SGLALICUF_PKG AS
--------------------------------------------------------------------------------
-- Programme           : Corps du package DKA_SGLALICUF_PKG
-- Version             : 1.0
-- Date de création    : 18/12/2018
-- Auteur              : Capgemini
-- Objet               : Alimenter les CUF Projet + Tâche + Type de dépense dans GL  en provenance
--                       des auxiliaires et FA
--                       Ce package est appele par le package gl_import_hook_pkg
--
-- Remarques           :
------------------------------------------------------------------------------
--                INFORMATION RELATIVE A LA MAINTENANCE
------------------------------------------------------------------------------
--    Date         Ver  |      Nom      |   Description de l'intervention
------------------------------------------------------------------------------
--                      |               |                                    |
------------------------------------------------------------------------------
--  18/12/2018     1.0  |     Capgemini | Version creation                   |
--  25/05/2019     1.1  |     NBO       | INC0306494 : EasyLink en erreur    |
--                                        dans la génération des OD de provisions |
--                                        sur commande multi société         |
--  24/12/2020     1.2  |     SELO	      EDB275 
------------------------------------------------------------------------------
G_PKG_NAME      CONSTANT VARCHAR2(30) := 'DKA_SGLALICUF_PKG';
G_MODULE_PREFIX CONSTANT VARCHAR2(50) := 'gl.plsql.'|| G_PKG_NAME|| '.';

FUNCTION MAIN (batch_ids  IN     VARCHAR2,
               separator  IN     VARCHAR2,
               last_set   IN     BOOLEAN,
               errbuf     IN OUT NOCOPY VARCHAR2) RETURN BOOLEAN IS

--  25/05/2019 1.1 NBO INC0306494 : EasyLink en erreur dans la génération des OD de provisions sur commande multi société
 --l_api_name              CONSTANT VARCHAR2(100) := 'MAIN ('||batch_ids||','||separator||','||Hr_APi.boolean_to_constant(last_set)||')';
 l_api_name              CONSTANT VARCHAR2(1000) := 'MAIN ('||batch_ids||','||separator||','||Hr_APi.boolean_to_constant(last_set)||')';
 
-- l_module                FND_LOG_MESSAGES.MODULE%TYPE := G_MODULE_PREFIX || l_api_name;
 l_module                FND_LOG_MESSAGES.MODULE%TYPE := SUBSTR(G_MODULE_PREFIX || l_api_name,1,255);

 l_mesg                  VARCHAR2(80);
 l_nbre                  NUMBER;
 l_project_id            NUMBER;
 l_task_id               NUMBER;
 l_projet_invest         VARCHAR2(25);
 l_projet_parent         VARCHAR2(25);
 l_tache_invest          VARCHAR2(25);
 l_tache_parente         VARCHAR2(25);
 l_batch_id_list         fnd_flex_ext.SegmentArray;
 l_nombre_batch_id       NUMBER;
 

CURSOR CUR_MAIN (p_batch_id number) IS
                SELECT gll.je_header_id, gll.je_line_num, gll.description, dd.param3_value type_depense, dd.return_value compte_lettrage,
                       dd.param1_value,dd.param2_value,
                       gcc.segment1||'.'||gcc.segment2||'.'||gcc.segment3||'.'||gcc.segment4||'.'||gcc.segment5 Compte
                FROM    GL_JE_headers glh, 
                        gl_je_lines gll, 
                        gl_code_combinations gcc,
                (SELECT param1_value, param2_value, param3_value, return_value
                                                        FROM DKA_STRANSCO_LINES 
                                                        WHERE set_id=(SELECT SET_ID
                                                                      FROM DKA_STRANSCO_HEADERS 
                                                                      WHERE  UPPER(SET_NAME) = 'DKA_LOCAL_GROUPE_TYPE_DEPENSE')) DD
                WHERE                      1=1
                AND glh.je_header_id        = gll.je_header_id
                AND glh.je_batch_id         = p_batch_id
                AND gcc.code_combination_id = gll.code_combination_id
                AND gcc.segment3            = dd.param1_value
                AND gcc.segment4            = dd.param2_value
                AND glh.je_source           = 'Assets';

-- SELO EDB275 DEBUT
CURSOR CUR_EVENT (p_batch_id number) IS
                SELECT gll.je_header_id, gll.je_line_num, gll.description, dd.param3_value type_event, dd.return_value compte_lettrage,
                       dd.param1_value,dd.param2_value,
                       gcc.segment1||'.'||gcc.segment2||'.'||gcc.segment3||'.'||gcc.segment4||'.'||gcc.segment5 Compte
                FROM    GL_JE_headers glh, 
                        gl_je_lines gll, 
                        gl_code_combinations gcc,
                (SELECT param1_value, param2_value, param3_value, return_value
                                                        FROM DKA_STRANSCO_LINES 
                                                        WHERE set_id=(SELECT SET_ID
                                                                      FROM DKA_STRANSCO_HEADERS 
                                                                      WHERE  UPPER(SET_NAME) = 'DKA_LOCAL_GROUPE_TYPE_EVENT')) DD
                WHERE                      1=1
                AND glh.je_header_id        = gll.je_header_id
                AND glh.je_batch_id         = p_batch_id
                AND gcc.code_combination_id = gll.code_combination_id
                AND gcc.segment3            = dd.param1_value
                AND gcc.segment4            = dd.param2_value
                AND glh.je_source           = 'Assets';
-- SELO EDB275 FIN

 BEGIN
     
	 IF (FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL) THEN
	 Fnd_Log.String (LOG_LEVEL   => Fnd_Log.LEVEL_STATEMENT
                    ,MODULE      => l_module
                    ,MESSAGE     => '->IN '||l_module);   
	 END IF;
	 
     l_nombre_batch_id := fnd_flex_ext.breakup_segments (concatenated_segs => batch_ids
                                                       ,delimiter => separator
                                                       ,segments => l_batch_id_list );
     
	 IF (FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL) THEN
     Fnd_Log.String (LOG_LEVEL => Fnd_Log.LEVEL_STATEMENT
                  ,MODULE    => l_module
                  ,MESSAGE   => 'l_nombre_batch_id '||l_nombre_batch_id);
	 END IF;
	 
	FOR I IN l_batch_id_list.FIRST..l_batch_id_list.LAST
    LOOP

       IF (FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL) THEN
	   Fnd_Log.String (LOG_LEVEL => Fnd_Log.LEVEL_STATEMENT
                      ,MODULE    => l_module
                      ,MESSAGE   => '+++Batch_id '||l_batch_id_list(I));
       END IF;
	   
       IF l_batch_id_list(I) IS NOT NULL
       THEN
        FOR R0 IN CUR_MAIN (l_batch_id_list(I))
        LOOP
         
	    BEGIN
		SELECT DISTINCT fai.project_id, fai.task_id
		INTO    l_project_id,   l_task_id
        FROM FA.fa_asset_invoices fai,
             GL_IMPORT_REFERENCES GIR,
             XLA.XLA_AE_LINES XAL,
             XLA.XLA_AE_HEADERS XAH,
             FA_TRANSACTION_HEADERS FTH,
             fa_adjustments fas
        WHERE                      1=1
        AND     GIR.JE_HEADER_ID    = R0.je_header_id
        AND     GIR.JE_LINE_NUM     = R0.je_line_num
        AND     GIR.GL_SL_LINK_ID   = XAL.GL_SL_LINK_ID
        AND     XAL.AE_HEADER_ID    = XAH.AE_HEADER_ID
        AND     XAH.event_id        = FTH.event_id
        AND     FTH.transaction_header_id  =  fas.transaction_header_id
        AND     fai.asset_id        = fas.asset_id
        UNION ALL
        SELECT DISTINCT fai.project_id, fai.task_id
        FROM FA.fa_asset_invoices fai,
             GL_IMPORT_REFERENCES GIR,
             XLA.XLA_AE_LINES XAL,
             XLA.XLA_AE_HEADERS XAH,
             fa_deprn_summary FTH
        WHERE                      1=1
        AND     GIR.JE_HEADER_ID    = R0.je_header_id
        AND     GIR.JE_LINE_NUM     = R0.je_line_num
        AND     GIR.GL_SL_LINK_ID   = XAL.GL_SL_LINK_ID
        AND     XAL.AE_HEADER_ID    = XAH.AE_HEADER_ID
        AND     XAH.event_id        = FTH.event_id
        AND     FTH.asset_id        =  fai.asset_id;
		EXCEPTION
              WHEN NO_DATA_FOUND THEN
               l_project_id := NULL;
			   l_task_id    := NULL;
              WHEN OTHERS THEN
               errbuf  := SQLERRM;
			   fnd_file.put_line(fnd_file.log, 'Erreur recherche project_id et task_id : '||errbuf);
			   RETURN FALSE;
	    END;

        IF R0.compte_lettrage = 'O' THEN
		
           BEGIN
           SELECT project_id  
           INTO   l_projet_invest
           FROM PA.pa_projects_all
           WHERE project_id = l_project_id;
           EXCEPTION
                 WHEN NO_DATA_FOUND THEN
                  l_projet_invest := NULL;
                 WHEN OTHERS THEN
                  errbuf  := SQLERRM;
				  fnd_file.put_line(fnd_file.log, 'Erreur projet d''inverstissement : '||errbuf);
           END;
           
           BEGIN
           SELECT task_id 
           INTO   l_tache_invest
           FROM pa_tasks
           WHERE task_id = l_task_id;
           EXCEPTION
                 WHEN NO_DATA_FOUND THEN
                  l_tache_invest := NULL;
                 WHEN OTHERS THEN
                  errbuf  := SQLERRM;
				  fnd_file.put_line(fnd_file.log, 'Erreur tâche d''inverstissement : '||errbuf);
           END;
           
           IF (FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL) THEN
		   Fnd_Log.String (LOG_LEVEL => Fnd_Log.LEVEL_STATEMENT
                         ,MODULE    => l_module
                         ,MESSAGE   => '+++FA');
           END IF;
		   
           UPDATE Gl_Je_Lines
           SET ATTRIBUTE11 = l_projet_invest,
               ATTRIBUTE17 = l_tache_invest,
               ATTRIBUTE13 = R0.type_depense,
		   	CONTEXT3    = 'Y.E.X',
		   	CONTEXT2    = 'No'
           WHERE je_header_id = R0.je_header_id
           AND   je_line_num  = R0.je_line_num;
        
           l_nbre := SQL%ROWCOUNT;
		   
           IF (FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL) THEN
		   Fnd_Log.String (LOG_LEVEL => Fnd_Log.LEVEL_STATEMENT
                         ,MODULE     => l_module
                         ,MESSAGE    => 'l_nbre:'||l_nbre);
           END IF;
		   
		   IF (FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL) THEN
           Fnd_Log.String (LOG_LEVEL => Fnd_Log.LEVEL_STATEMENT
                         ,MODULE     => l_module
                         ,MESSAGE    => '---FA');
		   END IF;
		   
        ELSE
        
           BEGIN
           SELECT pp.project_id		
           INTO   l_projet_parent
           FROM pa_tasks pt, pa_projects_all pp
           WHERE pt.task_id =(SELECT attribute7
                              FROM pa.pa_tasks
                              WHERE task_id = (SELECT task_id
                                               FROM pa_tasks
                                               WHERE task_id = l_task_id))
           AND pt.PROJECT_ID = pp.project_id;
           EXCEPTION
                 WHEN NO_DATA_FOUND THEN
                  l_projet_parent := NULL;
                 WHEN OTHERS THEN
                  errbuf  := SQLERRM;
				  fnd_file.put_line(fnd_file.log, 'Erreur projet parent : '||errbuf);
           END;
           
           BEGIN
           SELECT task_id 
           INTO   l_tache_parente
           FROM pa_tasks
           WHERE task_id = (SELECT attribute7
                            FROM pa.pa_tasks
                            WHERE task_id = (SELECT task_id
                                             FROM pa_tasks
                                             WHERE task_id = l_task_id));
           EXCEPTION
                 WHEN NO_DATA_FOUND THEN
                  l_tache_parente := NULL;
                 WHEN OTHERS THEN
                  errbuf  := SQLERRM;
				  fnd_file.put_line(fnd_file.log, 'Erreur tâche parente : '||errbuf);
           END;
		   
           IF (FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL) THEN
           Fnd_Log.String (LOG_LEVEL => Fnd_Log.LEVEL_STATEMENT
                         ,MODULE    => l_module
                         ,MESSAGE   => '+++FA');
           END IF;
		   
           UPDATE Gl_Je_Lines
           SET ATTRIBUTE11 = l_projet_parent,
               ATTRIBUTE17 = l_tache_parente,
               ATTRIBUTE13 = R0.type_depense,
		   	CONTEXT3    = 'Y.E.X',
		   	CONTEXT2    = 'No'
           WHERE je_header_id = R0.je_header_id
           AND   je_line_num  = R0.je_line_num;
           
           l_nbre := SQL%ROWCOUNT;
           
		   IF (FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL) THEN
		   Fnd_Log.String (LOG_LEVEL => Fnd_Log.LEVEL_STATEMENT
                     ,MODULE     => l_module
                     ,MESSAGE    => 'l_nbre:'||l_nbre);
           END IF;
		   
		   IF (FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL) THEN
           Fnd_Log.String (LOG_LEVEL => Fnd_Log.LEVEL_STATEMENT
                         ,MODULE     => l_module
                         ,MESSAGE    => '---FA');
		   END IF;
           
        END IF;

     END LOOP;
     
	 -- SELO EDB275 DEBUT
     FOR R1 IN CUR_EVENT (l_batch_id_list(I))
        LOOP
         
	    BEGIN
		SELECT DISTINCT fai.project_id, fai.task_id
		INTO    l_project_id,   l_task_id
        FROM FA.fa_asset_invoices fai,
             GL_IMPORT_REFERENCES GIR,
             XLA.XLA_AE_LINES XAL,
             XLA.XLA_AE_HEADERS XAH,
             FA_TRANSACTION_HEADERS FTH,
             fa_adjustments fas
        WHERE                      1=1
        AND     GIR.JE_HEADER_ID    = R1.je_header_id
        AND     GIR.JE_LINE_NUM     = R1.je_line_num
        AND     GIR.GL_SL_LINK_ID   = XAL.GL_SL_LINK_ID
        AND     XAL.AE_HEADER_ID    = XAH.AE_HEADER_ID
        AND     XAH.event_id        = FTH.event_id
        AND     FTH.transaction_header_id  =  fas.transaction_header_id
        AND     fai.asset_id        = fas.asset_id
        UNION ALL
        SELECT DISTINCT fai.project_id, fai.task_id
        FROM FA.fa_asset_invoices fai,
             GL_IMPORT_REFERENCES GIR,
             XLA.XLA_AE_LINES XAL,
             XLA.XLA_AE_HEADERS XAH,
             fa_deprn_summary FTH
        WHERE                      1=1
        AND     GIR.JE_HEADER_ID    = R1.je_header_id
        AND     GIR.JE_LINE_NUM     = R1.je_line_num
        AND     GIR.GL_SL_LINK_ID   = XAL.GL_SL_LINK_ID
        AND     XAL.AE_HEADER_ID    = XAH.AE_HEADER_ID
        AND     XAH.event_id        = FTH.event_id
        AND     FTH.asset_id        =  fai.asset_id;
		EXCEPTION
              WHEN NO_DATA_FOUND THEN
               l_project_id := NULL;
			   l_task_id    := NULL;
              WHEN OTHERS THEN
               errbuf  := SQLERRM;
			   fnd_file.put_line(fnd_file.log, 'Erreur recherche project_id et task_id : '||errbuf);
			   RETURN FALSE;
	    END;

        IF R1.compte_lettrage = 'O' THEN
		
           BEGIN
           SELECT project_id  
           INTO   l_projet_invest
           FROM PA.pa_projects_all
           WHERE project_id = l_project_id;
           EXCEPTION
                 WHEN NO_DATA_FOUND THEN
                  l_projet_invest := NULL;
                 WHEN OTHERS THEN
                  errbuf  := SQLERRM;
				  fnd_file.put_line(fnd_file.log, 'Erreur projet d''inverstissement : '||errbuf);
           END;
           
           BEGIN
           SELECT task_id 
           INTO   l_tache_invest
           FROM pa_tasks
           WHERE task_id = l_task_id;
           EXCEPTION
                 WHEN NO_DATA_FOUND THEN
                  l_tache_invest := NULL;
                 WHEN OTHERS THEN
                  errbuf  := SQLERRM;
				  fnd_file.put_line(fnd_file.log, 'Erreur tâche d''inverstissement : '||errbuf);
           END;
           
           IF (FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL) THEN
		   Fnd_Log.String (LOG_LEVEL => Fnd_Log.LEVEL_STATEMENT
                         ,MODULE    => l_module
                         ,MESSAGE   => '+++FA');
           END IF;
		   
           UPDATE Gl_Je_Lines
           SET ATTRIBUTE11 = l_projet_invest,
               ATTRIBUTE17 = l_tache_invest,
               ATTRIBUTE12 = R1.type_EVENT,
		   	CONTEXT3    = 'Y.R.X',
		   	CONTEXT2    = 'No'
           WHERE je_header_id = R1.je_header_id
           AND   je_line_num  = R1.je_line_num;
        
           l_nbre := SQL%ROWCOUNT;
		   
           IF (FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL) THEN
		   Fnd_Log.String (LOG_LEVEL => Fnd_Log.LEVEL_STATEMENT
                         ,MODULE     => l_module
                         ,MESSAGE    => 'l_nbre:'||l_nbre);
           END IF;
		   
		   IF (FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL) THEN
           Fnd_Log.String (LOG_LEVEL => Fnd_Log.LEVEL_STATEMENT
                         ,MODULE     => l_module
                         ,MESSAGE    => '---FA');
		   END IF;
		   
        ELSE
        
           BEGIN
           SELECT pp.project_id		
           INTO   l_projet_parent
           FROM pa_tasks pt, pa_projects_all pp
           WHERE pt.task_id =(SELECT attribute7
                              FROM pa.pa_tasks
                              WHERE task_id = (SELECT task_id
                                               FROM pa_tasks
                                               WHERE task_id = l_task_id))
           AND pt.PROJECT_ID = pp.project_id;
           EXCEPTION
                 WHEN NO_DATA_FOUND THEN
                  l_projet_parent := NULL;
                 WHEN OTHERS THEN
                  errbuf  := SQLERRM;
				  fnd_file.put_line(fnd_file.log, 'Erreur projet parent : '||errbuf);
           END;
           
           BEGIN
           SELECT task_id 
           INTO   l_tache_parente
           FROM pa_tasks
           WHERE task_id = (SELECT attribute7
                            FROM pa.pa_tasks
                            WHERE task_id = (SELECT task_id
                                             FROM pa_tasks
                                             WHERE task_id = l_task_id));
           EXCEPTION
                 WHEN NO_DATA_FOUND THEN
                  l_tache_parente := NULL;
                 WHEN OTHERS THEN
                  errbuf  := SQLERRM;
				  fnd_file.put_line(fnd_file.log, 'Erreur tâche parente : '||errbuf);
           END;
		   
           IF (FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL) THEN
           Fnd_Log.String (LOG_LEVEL => Fnd_Log.LEVEL_STATEMENT
                         ,MODULE    => l_module
                         ,MESSAGE   => '+++FA');
           END IF;
		   
           UPDATE Gl_Je_Lines
           SET ATTRIBUTE11 = l_projet_parent,
               ATTRIBUTE17 = l_tache_parente,
               ATTRIBUTE12 = R1.type_EVENT,
		   	CONTEXT3    = 'Y.R.X',
		   	CONTEXT2    = 'No'
           WHERE je_header_id = R1.je_header_id
           AND   je_line_num  = R1.je_line_num;
           
           l_nbre := SQL%ROWCOUNT;
           
		   IF (FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL) THEN
		   Fnd_Log.String (LOG_LEVEL => Fnd_Log.LEVEL_STATEMENT
                     ,MODULE     => l_module
                     ,MESSAGE    => 'l_nbre:'||l_nbre);
           END IF;
		   
		   IF (FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL) THEN
           Fnd_Log.String (LOG_LEVEL => Fnd_Log.LEVEL_STATEMENT
                         ,MODULE     => l_module
                         ,MESSAGE    => '---FA');
		   END IF;
           
        END IF;

     END LOOP;  -- SELO EDB275 FIN


		
	END IF; /* l_batch_id_list(I) IS NOT NULL */
	
       IF (FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL) THEN
       Fnd_Log.String (LOG_LEVEL => Fnd_Log.LEVEL_STATEMENT
                      ,MODULE    => l_module
                      ,MESSAGE   => '---Batch_id '||l_batch_id_list(I));
       END IF;
	   
    END LOOP; /*I IN l_batch_id_list.FIRST... */
	
    IF (FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL) THEN
    Fnd_Log.String (LOG_LEVEL => Fnd_Log.LEVEL_STATEMENT
                  ,MODULE    => l_module
                  ,MESSAGE   => '<-OUT '||l_module);
	END IF;

    RETURN(TRUE);
    EXCEPTION WHEN OTHERS THEN
       l_mesg := SUBSTR(SQLERRM,1,80);
	   IF (FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL) THEN
       Fnd_Log.String (LOG_LEVEL => Fnd_Log.LEVEL_STATEMENT
                  ,MODULE    => l_module
                  ,MESSAGE   => 'l_mesg '||l_mesg);
	   END IF;
	   
       errbuf := l_mesg;
	   fnd_file.put_line(fnd_file.log,'Erreur DKA_SGLALICUF_PKG.MAIN : '|| errbuf);
       RETURN FALSE;
 END MAIN;

 END DKA_SGLALICUF_PKG;

  /
SHOW ERRORS;

EXIT