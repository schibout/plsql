# =====================================================================
# Configuration connexion Oracle EBS - Controle Quotidien
# =====================================================================
# Modifier ce fichier pour changer la connexion sans toucher au script.
# Ne pas committer ce fichier dans un depot public (contient le mot de passe).
# =====================================================================

$ORA_USER    = "aroux"
$ORA_PWD     = "GAERFTXF"
$ORA_HOST    = "prdscanc1pdb03.dalkia.net"
$ORA_PORT    = "1521"
$ORA_SERVICE = "ebs_PDBFINP1"

# ---------------------------------------------------------------------
# Configuration FND (contexte Oracle EBS - APPS_INITIALIZE)
# ---------------------------------------------------------------------
# Identifie le compte EBS au nom duquel les traitements ecrivent. Alimente
# FND_GLOBAL.APPS_INITIALIZE et donc les colonnes WHO (LAST_UPDATED_BY,
# LAST_UPDATE_LOGIN) des lignes modifiees.
# Pour retrouver ces valeurs :
#   SELECT user_id FROM applsys.fnd_user WHERE user_name = 'H00035381F';
#   SELECT responsibility_id, application_id FROM applsys.fnd_responsibility_vl
#    WHERE responsibility_name = '<votre responsabilite>';
$FND_USER_NAME    = "H00035381F"  # Nom utilisateur FND (majuscules)
$FND_USER_ID      = 36313         # USER_ID dans FND_USER
$FND_RESP_ID      = 51214         # ID de la responsabilite
$FND_RESP_APPL_ID = 50001         # Application ID

# ---------------------------------------------------------------------
# Configuration email (optionnel - utilise avec -EnvoyerMail)
# ---------------------------------------------------------------------
$MAIL_SMTP_HOST  = "smtp.dalkia.net"         # Serveur SMTP
$MAIL_SMTP_PORT  = 25                         # Port (25 = sans auth, 587 = TLS)
$MAIL_FROM       = "ebs-controle@dalkia.fr"  # Expediteur
$MAIL_TO         = @("prenom.nom@dalkia.fr")  # Destinataires (tableau)
$MAIL_SSL        = $false                     # $true si TLS requis
# $MAIL_USER     = ""                         # Decommenter si authentification SMTP requise
# $MAIL_PWD      = ""                         # Decommenter si authentification SMTP requise
