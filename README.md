# 🏦 BanqueDB — Base de données bancaire sécurisée

Projet réalisé dans le cadre d'un cours de **sécurité des données**.  
L'objectif est de créer une base de données bancaire PostgreSQL avec une gestion des utilisateurs, des rôles et des droits d'accès, le tout avec **Docker Compose**.

---

## 📋 Sommaire

- [Prérequis](#prérequis)
- [Installation et lancement](#installation-et-lancement)
- [Structure de la base de données](#structure-de-la-base-de-données)
- [Gestion des utilisateurs et des rôles](#gestion-des-utilisateurs-et-des-rôles)
- [Utilisation de l'interface](#utilisation-de-linterface)
- [Services disponibles](#services-disponibles)

---

### Services Docker

| Service | Image | Rôle | Port |
|---|---|---|---|
| `banque_db` | postgres:16 | Base de données PostgreSQL | 5433 |
| `banque_pgadmin` | dpage/pgadmin4 | Interface graphique PostgreSQL | 5050 |
| `banque_interface` | nginx:alpine | Interface web custom | 8080 |
| `banque_api` | postgrest/postgrest | API REST entre l'interface et la BDD | 3000 |

---

## ✅ Prérequis

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) installé et lancé
- Un navigateur web (Chrome, Firefox, Edge...)

---

## 🚀 Installation et lancement

### 1. Cloner le dépôt

```bash
git clone https://github.com/tonnom/banque-projet.git
cd banque-projet
```

### 2. Configurer les variables d'environnement

Copie le fichier exemple et remplis tes valeurs :

```bash
# Windows (PowerShell)
copy .env.example .env
notepad .env

# Mac / Linux
cp .env.example .env
nano .env
```

Contenu du fichier `.env` à remplir :

```env
POSTGRES_DB=
POSTGRES_USER=
POSTGRES_PASSWORD=

PGADMIN_EMAIL=
PGADMIN_PASSWORD=
```

### 3. Lancer tous les services

```bash
docker compose up -d
```

### 4. Vérifier que tout tourne

```bash
docker compose ps
```

Tu dois voir les 4 conteneurs avec le statut `running`.

### 5. Arrêter le projet

```bash
docker compose down
```

---

## 🗄️ Structure de la base de données

La base contient 4 tables liées entre elles :

### Table `clients`
| Colonne | Type | Description |
|---|---|---|
| id | SERIAL PK | Identifiant unique |
| nom | VARCHAR | Nom du client |
| prenom | VARCHAR | Prénom du client |
| email | VARCHAR UNIQUE | Adresse email |
| telephone | VARCHAR | Numéro de téléphone |
| adresse | TEXT | Adresse postale |
| date_naissance | DATE | Date de naissance |
| created_at | TIMESTAMP | Date de création |

### Table `comptes`
| Colonne | Type | Description |
|---|---|---|
| id | SERIAL PK | Identifiant unique |
| client_id | INT FK | Référence vers clients |
| numero | VARCHAR UNIQUE | Numéro de compte |
| type | VARCHAR | courant / epargne / livret |
| solde | NUMERIC | Solde du compte |
| created_at | TIMESTAMP | Date de création |

### Table `transactions`
| Colonne | Type | Description |
|---|---|---|
| id | SERIAL PK | Identifiant unique |
| compte_id | INT FK | Référence vers comptes |
| type | VARCHAR | depot / retrait / virement |
| montant | NUMERIC | Montant de l'opération |
| description | TEXT | Description de l'opération |
| date_operation | TIMESTAMP | Date de l'opération |

### Table `cartes`
| Colonne | Type | Description |
|---|---|---|
| id | SERIAL PK | Identifiant unique |
| compte_id | INT FK | Référence vers comptes |
| numero | VARCHAR UNIQUE | Numéro de carte |
| type | VARCHAR | visa / mastercard |
| expiration | DATE | Date d'expiration |
| bloquee | BOOLEAN | Carte bloquée ou non |

### Schéma relationnel

```
clients (1) ──< comptes (1) ──< transactions
                    │
                    └──< cartes
```

---

## 👥 Gestion des utilisateurs et des rôles

### Principe du moindre privilège

Chaque utilisateur n'a accès qu'aux données strictement nécessaires à son travail.

### Rôles créés

| Rôle | Droits |
|---|---|
| `directeur` | Accès complet (SELECT, INSERT, UPDATE, DELETE sur toutes les tables) |
| `conseiller` | Lecture de toutes les tables + ajout de transactions + modification des comptes |
| `analyste` | Lecture seule sur toutes les tables |

### Utilisateurs créés

| Utilisateur | Rôle assigné | Description |
|---|---|---|
| `admin` | directeur | Gestion technique complète de la base |
| `app_user` | conseiller | Utilisateur de l'application bancaire |

### Commandes SQL utilisées

```sql
-- Création des rôles
CREATE ROLE directeur;
CREATE ROLE conseiller;
CREATE ROLE analyste;

-- Attribution des droits (exemple pour analyste)
GRANT CONNECT ON DATABASE banque TO analyste;
GRANT USAGE ON SCHEMA public TO analyste;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO analyste;

-- Création des utilisateurs
CREATE USER admin WITH PASSWORD '****';
CREATE USER app_user WITH PASSWORD '****';

-- Association utilisateur → rôle
GRANT directeur TO admin;
GRANT conseiller TO app_user;
```

---

## 🖥️ Utilisation de l'interface

L'interface web est accessible sur **http://localhost:8080**


### Fonctionnalités

**Panneau gauche — Schéma**
- Visualise toutes les tables et leurs colonnes
- Clique sur une table pour voir ses colonnes, types et clés

**Panneau gauche — Requêtes rapides**
- Des boutons pré-configurés pour les requêtes les plus courantes
- Clique sur un bouton pour charger la requête dans l'éditeur

**Éditeur SQL (centre-haut)**
- Tape ou colle n'importe quelle requête SQL
- Raccourci clavier : `Ctrl + Entrée` pour exécuter
- Bouton **▶ Exécuter** pour lancer la requête
- Bouton **✕ Effacer** pour vider l'éditeur

**Résultats (centre-bas)**
- Affiche les résultats sous forme de tableau
- Indique le nombre de lignes retournées
- Affiche le temps d'exécution
- En cas d'erreur SQL, affiche le message d'erreur en rouge

### Exemples de requêtes à tester

```sql
-- Lister tous les clients
SELECT * FROM clients;

-- Voir les comptes avec leurs propriétaires
SELECT c.nom, c.prenom, co.numero, co.type, co.solde
FROM clients c
JOIN comptes co ON co.client_id = c.id;

-- Total des dépôts par client
SELECT c.nom, c.prenom, SUM(t.montant) AS total_depots
FROM clients c
JOIN comptes co ON co.client_id = c.id
JOIN transactions t ON t.compte_id = co.id
WHERE t.type = 'depot'
GROUP BY c.id
ORDER BY total_depots DESC;

-- Cartes bloquées
SELECT * FROM cartes WHERE bloquee = TRUE;
```

---

## 🌐 Services disponibles

| Service | URL | Identifiants |
|---|---|---|
| Interface SQL custom | http://localhost:8080 | — |
| pgAdmin | http://localhost:5050 | Email et mot de passe du `.env` |
| API PostgREST | http://localhost:3000 | — |

### Connexion à pgAdmin

1. Ouvre **http://localhost:5050**
2. Connecte-toi avec les identifiants de ton `.env`
3. Clique sur **Add New Server**
4. Onglet **General** → Name : `banque`
5. Onglet **Connection** :
   - Host : `postgres`
   - Port : `5432`
   - Database : `banque`
   - Username : `admin`
   - Password : celui de ton `.env`

---

## 🔒 Sécurité

- Les mots de passe ne sont jamais écrits en dur dans le code
- Le fichier `.env` est exclu du dépôt Git via `.gitignore`
- Le principe du **moindre privilège** est appliqué à chaque utilisateur
- Chaque rôle n'a accès qu'aux opérations nécessaires à sa fonction


# 🔒 SafeBank — Sécurisation Avancée de la Base de Données

Projet réalisé dans le cadre d'un cours de **sécurité des données** — TP2.  
L'objectif est de protéger l'application bancaire contre les accès non autorisés et de garantir la **traçabilité** des actions sensibles.

---

## 📋 Sommaire

- [Contexte](#contexte)
- [Architecture de sécurité](#architecture-de-sécurité)
- [Livrables techniques](#livrables-techniques)
- [Installation et lancement](#installation-et-lancement)
- [Démonstration des scripts](#démonstration-des-scripts)
- [Sauvegarde automatique](#sauvegarde-automatique)

---

## 🎯 Contexte

Ce TP s'appuie sur la base de données bancaire créée au TP1 (PostgreSQL + Docker Compose).  
Deux axes de sécurité sont mis en place :

| Axe | Objectif |
|---|---|
| **Prévention** | Bloquer les attaques avant qu'elles n'atteignent la base |
| **Surveillance** | Enregistrer et analyser les tentatives d'intrusion |

---

## 🛡️ Architecture de sécurité

### 1. Sécurité Applicative (Prévention)

#### Requêtes préparées
La concaténation directe de chaînes SQL est remplacée par des paramètres `%s`.  
Les entrées utilisateurs sont traitées comme du **texte pur** — l'injection SQL devient impossible.

```python
# VULNERABLE — concatenation directe
query = "SELECT * FROM app_users WHERE username = '" + username + "'"

# SECURISE — requete preparee
cursor.execute("SELECT * FROM app_users WHERE username = %s", (username,))
```

#### Hachage Bcrypt
Les mots de passe ne sont plus stockés en clair. Bcrypt transforme chaque mot de passe en une **empreinte irréversible** avec un sel aléatoire.  
En cas de vol de la base, les mots de passe restent illisibles.

```python
import bcrypt

# Stockage : hachage avant insertion
hash_mdp = bcrypt.hashpw(b"password123", bcrypt.gensalt()).decode()

# Vérification : comparaison sécurisée
is_valid = bcrypt.checkpw(password_saisi.encode('utf-8'), hash_stocke.encode('utf-8'))
```

---

### 2. Surveillance & Résilience (Audit)

#### Audit Logging
Chaque tentative de connexion est automatiquement enregistrée dans la table `audit_logs` :

| Champ | Description |
|---|---|
| `user_login` | Identifiant utilisé lors de la tentative |
| `action` | Type d'action (`login_attempt`, `sql_injection`...) |
| `status` | Résultat (`success`, `failed_wrong_password`, `failed_user_not_found`) |
| `details` | Informations complémentaires |
| `created_at` | Horodatage automatique |

#### Principe du moindre privilège
Un compte dédié `audit_user` est créé avec des droits **strictement limités à la lecture** de `audit_logs`.  
Il ne peut ni écrire, ni modifier, ni accéder aux autres tables.

```sql
CREATE USER audit_user WITH PASSWORD 'audit123';
GRANT CONNECT ON DATABASE banque TO audit_user;
GRANT USAGE ON SCHEMA public TO audit_user;
GRANT SELECT ON audit_logs TO audit_user;  -- Lecture seule, rien d'autre
```

---

## 📁 Livrables techniques

| Fichier | Rôle |
|---|---|
| `injectionsql.py` | Démonstration de la vulnérabilité (formulaire NON sécurisé) |
| `test_securite.py` | Validation de la protection par requêtes préparées + bcrypt |
| `audit.py` | Visualisation des traces d'attaques via `audit_user` |
| `backup.py` | Génération automatique d'une sauvegarde SQL complète |

---

## 🚀 Installation et lancement

### Prérequis

- Docker Desktop lancé avec les conteneurs du TP1 actifs
- Python 3.x installé
- Dépendances Python :

```bash
pip install psycopg2-binary bcrypt
```

### Vérifier que Docker tourne

```bash
docker compose ps
```

Tu dois voir `banque_db` avec le statut `running`.

---

## 🎬 Démonstration des scripts

### 1. `injectionsql.py` — La vulnérabilité

Simule un formulaire de connexion **sans aucune protection**.

```bash
python injectionsql.py
```

**Compte de test :** `alice` / `password123`

**Injection à tester :** entre `' OR '1'='1' --` comme nom d'utilisateur avec n'importe quel mot de passe.

```
Nom d'utilisateur : ' OR '1'='1' --
Mot de passe      : nimportequoi

→ ACCES OBTENU : alice (role: user)
→ INJECTION SQL REUSSIE - acces sans mot de passe !
```

La requête construite devient :
```sql
SELECT * FROM app_users WHERE username = '' OR '1'='1' --' AND password = '...'
```
La condition `'1'='1'` est toujours vraie — tous les comptes sont accessibles.

---

### 2. `test_securite.py` — La protection

Même formulaire mais **sécurisé** : requêtes préparées + bcrypt.

```bash
python test_securite.py
```

**Compte de test :** `bob_secure` / `password123`

**La même injection est bloquée :**

```
Nom d'utilisateur : ' OR '1'='1' --
Mot de passe      : nimportequoi

→ ACCES REFUSE : Utilisateur introuvable
→ INJECTION BLOQUEE - la requete preparee a traite l'injection comme du texte pur !
```

La requête préparée traite l'entrée comme une valeur littérale — les caractères spéciaux perdent leur sens SQL.  
Chaque tentative est automatiquement enregistrée dans `audit_logs`.

---

### 3. `audit.py` — Le rapport d'audit

Se connecte avec `audit_user` (lecture seule) et affiche un rapport complet des événements.

```bash
python audit.py
```

**Exemple de sortie :**

```
=================================================================
  SAFEBANK - Rapport d'Audit de Securite
  Genere le : 19/01/2026 a 11:41:00
  Connecte  : audit_user (lecture seule)
=================================================================

  JOURNAL COMPLET

  ID    Utilisateur          Action                    Statut
  -------------------------------------------------------------------------
  2     injection_test       sql_injection             blocked

  STATISTIQUES

  Total evenements     : 2
  Connexions reussies  : 1
  Echecs de connexion  : 0
  Tentatives injection : 1

  TEST DROITS AUDIT_USER

  audit_user ne peut PAS modifier les logs
  Principe du moindre privilege respecte !
=================================================================
```
---

## 💾 Sauvegarde automatique

### `backup.py` — Génération du fichier de secours

Exécute un `pg_dump` à l'intérieur du conteneur Docker et génère un fichier `.sql` horodaté dans le dossier courant.

```bash
python backup.py
```

**Exemple de sortie :**

```
--- Démarrage de la sauvegarde de banque ---
SUCCÈS : Sauvegarde créée avec succès : backup_banque_20260119_114100.sql
Taille du fichier : 8432 octets
```

**Fichier généré :** `backup_banque_YYYYMMDD_HHMMSS.sql`

Ce fichier contient l'intégralité de la structure et des données de la base — il permet une restauration complète après incident.

### Restaurer depuis une sauvegarde

```bash
# Copier le fichier dans le conteneur
docker cp backup_banque_20260119_114100.sql banque_db:/tmp/

# Restaurer
docker exec -it banque_db psql -U admin -d banque -f /tmp/backup_banque_20260119_114100.sql
```

---

## 🔐 Tableau récapitulatif des protections

| Menace | Sans protection | Avec protection |
|---|---|---|
| Injection SQL | Accès total à la base | Bloquée par les requêtes préparées |
| Vol de la base | Mots de passe lisibles en clair | Empreintes bcrypt illisibles |
| Accès aux logs | N'importe quel utilisateur | Limité à `audit_user` en lecture seule |
| Perte de données | Données perdues définitivement | Restauration depuis `backup_*.sql` |