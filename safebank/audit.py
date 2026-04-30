
import locale
locale.setlocale(locale.LC_ALL, 'C')  # Force encodage neutre AVANT psycopg2

import psycopg2
import os
from datetime import datetime

os.environ['PGCLIENTENCODING'] = 'UTF8'
os.environ['PGPASSWORD'] = 'audit123'

conn = psycopg2.connect(
    "host=localhost port=5433 dbname=banque user=audit_user password=audit123"
)
cursor = conn.cursor()

print("=" * 65)
print("  SAFEBANK - Rapport d'Audit de Securite")
print("  Genere le : " + datetime.now().strftime('%d/%m/%Y a %H:%M:%S'))
print("  Connecte  : audit_user (lecture seule)")
print("=" * 65)

print("\n  JOURNAL COMPLET\n")
cursor.execute("SELECT id, user_login, action, status, details, created_at FROM audit_logs ORDER BY created_at DESC;")
logs = cursor.fetchall()

if not logs:
    print("  Aucun evenement enregistre.")
else:
    print("  ID    Utilisateur          Action                    Statut")
    print("  " + "-" * 80)
    for log in logs:
        heure = log[5].strftime('%d/%m %H:%M:%S')
        print("  " + str(log[0]).ljust(5) + " " + str(log[1]).ljust(20) + " " + str(log[2]).ljust(25) + " " + str(log[3]).ljust(20) + " " + heure)

print("\n  STATISTIQUES\n")
cursor.execute("SELECT COUNT(*) FROM audit_logs;")
print("  Total evenements     : " + str(cursor.fetchone()[0]))

cursor.execute("SELECT COUNT(*) FROM audit_logs WHERE status = 'success';")
print("  Connexions reussies  : " + str(cursor.fetchone()[0]))

cursor.execute("SELECT COUNT(*) FROM audit_logs WHERE status LIKE 'failed%';")
print("  Echecs de connexion  : " + str(cursor.fetchone()[0]))

cursor.execute("SELECT COUNT(*) FROM audit_logs WHERE action = 'sql_injection';")
injections = cursor.fetchone()[0]
print("  Tentatives injection : " + str(injections))

if injections > 0:
    print("\n  TENTATIVES D'INJECTION DETECTEES\n")
    cursor.execute("SELECT user_login, status, details, created_at FROM audit_logs WHERE action = 'sql_injection' ORDER BY created_at DESC;")
    for a in cursor.fetchall():
        print("  [" + a[3].strftime('%d/%m %H:%M:%S') + "] Login: " + str(a[0]))
        print("  Statut  : " + str(a[1]))
        if a[2]:
            print("  Details : " + str(a[2]))

print("\n  TEST DROITS AUDIT_USER\n")
try:
    cursor.execute("INSERT INTO audit_logs (user_login, action, status) VALUES ('test', 'test', 'test');")
    print("  PROBLEME : audit_user peut ecrire dans les logs !")
except psycopg2.errors.InsufficientPrivilege:
    print("  audit_user ne peut PAS modifier les logs")
    print("  Principe du moindre privilege respecte !")
    conn.rollback()

print("\n" + "=" * 65)
print("  Fin du rapport")
print("=" * 65)

cursor.close()
conn.close()