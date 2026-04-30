"""
injectionsql.py
================
Demonstration de la vulnerabilite d'injection SQL.
Le script simule un vrai formulaire de connexion bancaire
sans aucune protection - l'utilisateur tape lui-meme les entrees.
"""

import psycopg2

conn = psycopg2.connect(
    host="localhost", port=5433,
    database="banque", user="admin", password="admin123"
)
cursor = conn.cursor()

# Creer utilisateur de test avec mot de passe en clair
cursor.execute("""
    INSERT INTO app_users (username, password, role)
    VALUES ('alice', 'password123', 'user')
    ON CONFLICT (username) DO NOTHING;
""")
conn.commit()

def login_vulnerable(username, password):
    # DANGEREUX : concatenation directe
    query = ("SELECT * FROM app_users WHERE username = '"
             + username + "' AND password = '" + password + "'")
    print(f"\n  Requete executee : {query}")
    cursor.execute(query)
    return cursor.fetchone()

print("=" * 55)
print("  SAFEBANK - Formulaire de connexion (NON SECURISE)")
print("=" * 55)
print("  Compte de test : alice / password123")
print("  Essaie aussi  : ' OR '1'='1' --  comme username")
print("=" * 55)

while True:
    print("\n" + "-" * 55)
    username = input("  Nom d'utilisateur : ")
    password = input("  Mot de passe      : ")

    if username.lower() == 'exit':
        print("\n  Au revoir !")
        break

    try:
        user = login_vulnerable(username, password)
        if user:
            print(f"\n  ACCES OBTENU : {user[1]} (role: {user[3]})")
            if "OR" in username.upper():
                print("  INJECTION SQL REUSSIE - acces sans mot de passe !")
        else:
            print("\n  Acces refuse - identifiants incorrects")
    except Exception as e:
        print(f"\n  Erreur SQL : {e}")
        conn.rollback()

cursor.close()
conn.close()