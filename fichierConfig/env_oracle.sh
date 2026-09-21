# =====================================================================
# Configuration Oracle EBS Production - Connection oracleProd
# =====================================================================
# Ce fichier contient les informations de connexion à Oracle EBS
# NE PAS COMMITTER ce fichier avec des mots de passe réels
# =====================================================================

# Oracle EBS Production
export ORACLE_USER=aroux
export ORACLE_PASSWORD=GAERFTXF
export ORACLE_HOST=prdscanc1pdb03.dalkia.net
export ORACLE_PORT=1521
export ORACLE_SERVICE=ebs_PDBFINP1
export ORACLE_DSN=${ORACLE_HOST}:${ORACLE_PORT}/${ORACLE_SERVICE}

# Connexion complète (format SQLcl)
export ORACLE_PROD_CONNECTION=${ORACLE_USER}/${ORACLE_PASSWORD}@${ORACLE_DSN}

# Paramètres de session
export NLS_LANG=AMERICAN_AMERICA.AL32UTF8
export NLS_DATE_FORMAT="DD/MM/YYYY HH24:MI:SS"

# Environnement
export ENVIRONMENT=PRODUCTION
export DB_VERSION=19.25.0.0.0
export EBS_VERSION=12.2.13