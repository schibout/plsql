# =====================================================================
# Configuration connexion Oracle EBS - Controle FAC02 Factures Clients
# =====================================================================
# Modifier ce fichier pour changer la connexion sans toucher au script.
# Ne pas committer ce fichier dans un depot public (contient le mot de passe).
# Memes valeurs que ControleFolioRose\config.ps1 : a adapter sur le
# poste qui execute reellement le controle.
# =====================================================================

$ORA_USER    = "aroux"
$ORA_PWD     = "GAERFTXF"
$ORA_HOST    = "prdscanc1pdb03.dalkia.net"
$ORA_PORT    = "1521"
$ORA_SERVICE = "ebs_PDBFINP1"
