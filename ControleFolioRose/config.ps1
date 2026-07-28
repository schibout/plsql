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
# Configuration email (optionnel - utilise avec -EnvoyerMail)
# ---------------------------------------------------------------------
$MAIL_SMTP_HOST  = "smtp.dalkia.net"         # Serveur SMTP
$MAIL_SMTP_PORT  = 25                         # Port (25 = sans auth, 587 = TLS)
$MAIL_FROM       = "ebs-controle@dalkia.fr"  # Expediteur
$MAIL_TO         = @("prenom.nom@dalkia.fr")  # Destinataires (tableau)
$MAIL_SSL        = $false                     # $true si TLS requis
# $MAIL_USER     = ""                         # Decommenter si authentification SMTP requise
# $MAIL_PWD      = ""                         # Decommenter si authentification SMTP requise
