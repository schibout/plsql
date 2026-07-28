Bonjour la  TMA, 

pour une raison indéterminée, il arrive - dans Oracle - que le numéro de société rattaché à un employé disparaisse, alors qu’il était bien renseigné antérieurement.

Cela se produit depuis qqs mois maintenant.

Exemple : 

Matricule  : Grégory EUDE 38704B
Il est rattaché à la 001 dans Kador, et idem dans Notilus (pour l’instant).

Mais il n’est plus rattaché à la 0001 dans Oracle : 

'****** cf pièce jointe ****** 

Autre exemple : Matricule 10800K : Claude RENOUF

Il n’est plus rattaché ni dans Notilus, ni dans Oracle. 

ou encore matricule  57577J  Bruno LE LOUTRE qui, également, n’est plus rattaché non plus.



Pouvez-vous regarder ce qui provoque ces anomalies, svp ?
Cela engendre de très nombreux plantage lors de l’envoi du fichier des notes de frais dans Oracle, et oblige à d’incessantes corrections manuelles.

Cordialement,

voici la réponse de la TMA

Bonjour @PHILIPPE GRALL ,

Après vérification côté Oracle, la mise à jour des données employés ne peut pas être réalisée sans réception préalable des flux en provenance de Kador. Les créations et mises à jour des employés (rattachement société, affectations, etc.) sont effectuées uniquement via les tables d’interfaces EAI.

À ce jour, aucune trace n’a été trouvée dans la table XXEAI_HR_ASSIGNMENT_INT pour le matricule 38704B, ce qui ne permet pas à analyser ce comportement , idem pour les autres matricules cités dans le ticket.

Nous restons disponibles pour poursuivre l’analyse dès réception des éléments côté Kador, afin de bien tracer cette problématique.

Cordialement,

Anas

alors il y a : FINEXT_J13INT_05_IMP01_Q pour l'importation des employés depuis GXP
et il y a aussi FINEXT_J12GEN_06_EXP01_Q pour l'export du référentiel employés vers Notilus
