import subprocess
import os
from datetime import datetime

def generer_sauvegarde():
    # Configuration
    DB_NAME = "banque"
    CONTAINER_NAME = "banque_db"
    DATE_STR = datetime.now().strftime("%Y%m%d_%H%M%S")
    FILENAME = f"backup_{DB_NAME}_{DATE_STR}.sql"

    print(f"--- Démarrage de la sauvegarde de {DB_NAME} ---")

    try:
        # Commande pour exécuter pg_dump à l'intérieur du conteneur Docker
        # On utilise l'utilisateur 'admin' pour avoir les droits d'export[cite: 1]
        command = [
            "docker", "exec", CONTAINER_NAME,
            "pg_dump", "-U", "admin", DB_NAME
        ]

        # Exécution et capture du flux SQL
        with open(FILENAME, "w", encoding="utf-8") as f:
            result = subprocess.run(command, stdout=f, stderr=subprocess.PIPE, text=True)

        if result.returncode == 0:
            print(f"SUCCÈS : Sauvegarde créée avec succès : {FILENAME}")
            print(f"Taille du fichier : {os.path.getsize(FILENAME)} octets")
        else:
            print(f"ERREUR lors du backup : {result.stderr}")

    except Exception as e:
        print(f"Erreur système : {e}")

if __name__ == "__main__":
    generer_sauvegarde()