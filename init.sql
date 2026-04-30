-- TABLES
CREATE TABLE clients (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(100) NOT NULL,
    prenom VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    telephone VARCHAR(20),
    adresse TEXT,
    date_naissance DATE,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE comptes (
    id SERIAL PRIMARY KEY,
    client_id INT NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
    numero VARCHAR(30) UNIQUE NOT NULL,
    type VARCHAR(20) CHECK (type IN ('courant','epargne','livret')) NOT NULL,
    solde NUMERIC(15,2) DEFAULT 0.00,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE transactions (
    id SERIAL PRIMARY KEY,
    compte_id INT NOT NULL REFERENCES comptes(id) ON DELETE CASCADE,
    type VARCHAR(20) CHECK (type IN ('depot','retrait','virement')) NOT NULL,
    montant NUMERIC(15,2) NOT NULL CHECK (montant > 0),
    description TEXT,
    date_operation TIMESTAMP DEFAULT NOW()
);

CREATE TABLE cartes (
    id SERIAL PRIMARY KEY,
    compte_id INT NOT NULL REFERENCES comptes(id) ON DELETE CASCADE,
    numero VARCHAR(19) UNIQUE NOT NULL,
    type VARCHAR(20) CHECK (type IN ('visa','mastercard')) NOT NULL,
    expiration DATE NOT NULL,
    bloquee BOOLEAN DEFAULT FALSE
);

CREATE TABLE app_users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(100) UNIQUE NOT NULL,
    password TEXT NOT NULL,
    role VARCHAR(50) DEFAULT 'user',
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE audit_logs (
    id SERIAL PRIMARY KEY,
    user_login VARCHAR(100),
    action VARCHAR(100),
    status VARCHAR(50),
    ip_address VARCHAR(50),
    details TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

-- DONNEES DE TEST
INSERT INTO clients (nom, prenom, email, telephone, adresse, date_naissance) VALUES
('Dupont',  'Alice', 'alice.dupont@email.fr',  '0601010101', '12 rue des Lilas, Paris', '1990-05-14'),
('Martin',  'Bob',   'bob.martin@email.fr',    '0602020202', '7 avenue Foch, Lyon', '1985-11-22'),
('Bernard', 'Clara', 'clara.bernard@email.fr', '0603030303', '3 impasse du Moulin, Bordeaux', '2000-02-08'),
('Leroy',   'David', 'david.leroy@email.fr',   '0604040404', '88 bd Haussmann, Paris', '1978-07-30'),
('Moreau',  'Emma',  'emma.moreau@email.fr',   '0605050505', '15 rue de la Paix, Nice', '1995-03-19');

INSERT INTO comptes (client_id, numero, type, solde) VALUES
(1, 'FR001-000001', 'courant', 3500.00),
(1, 'FR001-000002', 'epargne', 12000.00),
(2, 'FR002-000001', 'courant', 870.50),
(3, 'FR003-000001', 'courant', 2100.75),
(3, 'FR003-000002', 'livret',  5000.00),
(4, 'FR004-000001', 'courant', 15200.00),
(5, 'FR005-000001', 'epargne', 8300.00);

INSERT INTO transactions (compte_id, type, montant, description) VALUES
(1, 'depot',    1500.00, 'Virement salaire'),
(1, 'retrait',   200.00, 'Retrait DAB'),
(1, 'virement',  300.00, 'Loyer'),
(2, 'depot',    5000.00, 'Epargne mensuelle'),
(3, 'depot',     870.50, 'Virement entrant'),
(3, 'retrait',   150.00, 'Achat en ligne'),
(4, 'depot',    2500.00, 'Remboursement client'),
(6, 'depot',   10000.00, 'Virement salaire'),
(6, 'retrait',  1200.00, 'Facture EDF');

INSERT INTO cartes (compte_id, numero, type, expiration, bloquee) VALUES
(1, '4539-1234-5678-9012', 'visa',       '2027-06-30', FALSE),
(3, '5412-9876-5432-1098', 'mastercard', '2026-03-31', FALSE),
(4, '4111-1111-1111-1111', 'visa',       '2025-12-31', TRUE),
(6, '5500-0000-0000-0004', 'mastercard', '2028-09-30', FALSE);

INSERT INTO app_users (username, password, role) VALUES
('alice',      'password123', 'user'),
('bob_secure', 'password123', 'user');

INSERT INTO audit_logs (user_login, action, status, details) VALUES
('admin',          'login_attempt', 'success', 'Connexion initiale administrateur'),
('injection_test', 'sql_injection', 'blocked', 'Tentative injection SQL detectee');

-- ROLES ET UTILISATEURS
CREATE ROLE directeur;
CREATE ROLE conseiller;
CREATE ROLE analyste;

GRANT CONNECT ON DATABASE banque TO analyste;
GRANT USAGE ON SCHEMA public TO analyste;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO analyste;

GRANT CONNECT ON DATABASE banque TO conseiller;
GRANT USAGE ON SCHEMA public TO conseiller;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO conseiller;
GRANT INSERT ON transactions TO conseiller;
GRANT UPDATE ON comptes TO conseiller;

GRANT CONNECT ON DATABASE banque TO directeur;
GRANT USAGE ON SCHEMA public TO directeur;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO directeur;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO directeur;

CREATE USER app_user WITH PASSWORD 'appuser123';
GRANT conseiller TO app_user;

CREATE USER audit_user WITH PASSWORD 'audit123';
GRANT CONNECT ON DATABASE banque TO audit_user;
GRANT USAGE ON SCHEMA public TO audit_user;
GRANT SELECT ON audit_logs TO audit_user;

GRANT directeur TO admin;

-- FONCTION exec_sql
CREATE OR REPLACE FUNCTION public.exec_sql(query text)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    result json;
BEGIN
    EXECUTE 'SELECT json_agg(t) FROM (' || query || ') t' INTO result;
    RETURN COALESCE(result, '[]'::json);
END;
$$;