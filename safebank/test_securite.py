"""
test_securite.py
=================
Validation de la protection par requetes preparees.
Meme formulaire que injectionsql.py mais securise :
- Requetes preparees (parametres separes du SQL)
- Hachage bcrypt des mots de passe
- Enregistrement dans audit_logs
"""

import psycopg2
import bcrypt

conn = psycopg2.connect(
    host="localhost", port=5433,
    database="banque", user="admin", password="admin123"
)
cursor = conn.cursor()

# Creer utilisateur avec mot de passe HACHE
hash_mdp = bcrypt.hashpw(b"password123", bcrypt.gensalt()).decode()
cursor.execute("""
    INSERT INTO app_users (username, password, role)
    VALUES ('bob_secure', %s, 'user')
    ON CONFLICT (username) DO UPDATE SET password = EXCLUDED.password;
""", (hash_mdp,))
conn.commit()

def enregistrer_audit(username, action, status, details=None):
    cursor.execute("""
        INSERT INTO audit_logs (user_login, action, status, details)
        VALUES (%s, %s, %s, %s)
    """, (username, action, status, details))
    conn.commit()

def login_securise(username, password_saisi):
    # SECURISE : requete preparee, parametre separe
    cursor.execute(
        "SELECT * FROM app_users WHERE username = %s",
        (username,)
    )
    user = cursor.fetchone()

    if user is None:
        enregistrer_audit(username, "login_attempt", "failed_user_not_found")
        return None, "Utilisateur introuvable"

    # Verification bcrypt
    try:
        is_valid = bcrypt.checkpw(
            password_saisi.encode('utf-8'),
            user[2].encode('utf-8')
        )
    except Exception:
        is_valid = False

    if is_valid:
        enregistrer_audit(username, "login_attempt", "success")
        return user, "Succes"
    else:
        enregistrer_audit(username, "login_attempt", "failed_wrong_password")
        return None, "Mot de passe incorrect"

print("=" * 55)
print("  SAFEBANK - Formulaire de connexion (SECURISE)")
print("=" * 55)
print("  Compte de test : bob_secure / password123")
print("  Essaie aussi  : ' OR '1'='1' --  comme username")
print("  Tu verras que l'injection est BLOQUEE !")
print("=" * 55)
print(f"\n  Mot de passe stocke en base (bcrypt) :")
print(f"  {hash_mdp[:50]}...")

while True:
    print("\n" + "-" * 55)
    username = input("  Nom d'utilisateur : ")
    password = input("  Mot de passe      : ")

    if username.lower() == 'exit':
        print("\n  Au revoir !")
        break

    user, msg = login_securise(username, password)
    if user:
        print(f"\n  ACCES ACCORDE : {user[1]} (role: {user[3]})")
        print(f"  Statut : {msg}")
    else:
        print(f"\n  ACCES REFUSE : {msg}")
        if "OR" in username.upper():
            print("  INJECTION BLOQUEE - la requete preparee a traite")
            print("  l'injection comme du texte pur !")
    print("  (tentative enregistree dans audit_logs)")

cursor.close()
conn.close()