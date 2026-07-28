# Nécessite le fichier product-preferences.xml de SQL Developer
# Chemin typique : %APPDATA%\sqldeveloper\<version>\system\oracle.sqldeveloper.db.DatabaseConnectionRegistry\

import base64, hashlib
from Crypto.Cipher import DES3

# Récupère db.system.id dans product-preferences.xml
db_system_id = "166b48d9-03a1-4639-a0ed-2bc0f5dd7e4d"  

encrypted = "yvNLqD3AeKPCEZGdPQYC1E/kavNUFoCi1PGHFDARR0R+WB3n"
data = base64.b64decode(encrypted)
salt = data[:8]
enc = data[8:]

key = hashlib.md5(db_system_id.encode() + b"encryption").digest()
key = key + key[:8]  # 24 bytes pour 3DES

cipher = DES3.new(key, DES3.MODE_CBC, salt)
pad = cipher.decrypt(enc)
print(pad[:-pad[-1]].decode())