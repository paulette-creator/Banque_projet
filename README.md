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