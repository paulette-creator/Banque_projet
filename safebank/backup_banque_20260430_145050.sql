--
-- PostgreSQL database dump
--

\restrict 8kVGPJoD2TnlT3NM0yVULhC5SA0vh0YQWjsDtehfkhgk0pk2w5YsLrTuAafwK84

-- Dumped from database version 16.13 (Debian 16.13-1.pgdg13+1)
-- Dumped by pg_dump version 16.13 (Debian 16.13-1.pgdg13+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: exec_sql(text); Type: FUNCTION; Schema: public; Owner: admin
--

CREATE FUNCTION public.exec_sql(query text) RETURNS json
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    result json;
BEGIN
    EXECUTE 'SELECT json_agg(t) FROM (' || query || ') t' INTO result;
    RETURN COALESCE(result, '[]'::json);
END;
$$;


ALTER FUNCTION public.exec_sql(query text) OWNER TO admin;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: app_users; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.app_users (
    id integer NOT NULL,
    username character varying(100) NOT NULL,
    password text NOT NULL,
    role character varying(50) DEFAULT 'user'::character varying,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.app_users OWNER TO admin;

--
-- Name: app_users_id_seq; Type: SEQUENCE; Schema: public; Owner: admin
--

CREATE SEQUENCE public.app_users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.app_users_id_seq OWNER TO admin;

--
-- Name: app_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: admin
--

ALTER SEQUENCE public.app_users_id_seq OWNED BY public.app_users.id;


--
-- Name: audit_logs; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.audit_logs (
    id integer NOT NULL,
    user_login character varying(100),
    action character varying(100),
    status character varying(50),
    ip_address character varying(50),
    details text,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.audit_logs OWNER TO admin;

--
-- Name: audit_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: admin
--

CREATE SEQUENCE public.audit_logs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.audit_logs_id_seq OWNER TO admin;

--
-- Name: audit_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: admin
--

ALTER SEQUENCE public.audit_logs_id_seq OWNED BY public.audit_logs.id;


--
-- Name: cartes; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.cartes (
    id integer NOT NULL,
    compte_id integer NOT NULL,
    numero character varying(19) NOT NULL,
    type character varying(20) NOT NULL,
    expiration date NOT NULL,
    bloquee boolean DEFAULT false,
    CONSTRAINT cartes_type_check CHECK (((type)::text = ANY ((ARRAY['visa'::character varying, 'mastercard'::character varying])::text[])))
);


ALTER TABLE public.cartes OWNER TO admin;

--
-- Name: cartes_id_seq; Type: SEQUENCE; Schema: public; Owner: admin
--

CREATE SEQUENCE public.cartes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.cartes_id_seq OWNER TO admin;

--
-- Name: cartes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: admin
--

ALTER SEQUENCE public.cartes_id_seq OWNED BY public.cartes.id;


--
-- Name: clients; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.clients (
    id integer NOT NULL,
    nom character varying(100) NOT NULL,
    prenom character varying(100) NOT NULL,
    email character varying(150) NOT NULL,
    telephone character varying(20),
    adresse text,
    date_naissance date,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.clients OWNER TO admin;

--
-- Name: clients_id_seq; Type: SEQUENCE; Schema: public; Owner: admin
--

CREATE SEQUENCE public.clients_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.clients_id_seq OWNER TO admin;

--
-- Name: clients_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: admin
--

ALTER SEQUENCE public.clients_id_seq OWNED BY public.clients.id;


--
-- Name: comptes; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.comptes (
    id integer NOT NULL,
    client_id integer NOT NULL,
    numero character varying(30) NOT NULL,
    type character varying(20) NOT NULL,
    solde numeric(15,2) DEFAULT 0.00,
    created_at timestamp without time zone DEFAULT now(),
    CONSTRAINT comptes_type_check CHECK (((type)::text = ANY ((ARRAY['courant'::character varying, 'epargne'::character varying, 'livret'::character varying])::text[])))
);


ALTER TABLE public.comptes OWNER TO admin;

--
-- Name: comptes_id_seq; Type: SEQUENCE; Schema: public; Owner: admin
--

CREATE SEQUENCE public.comptes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.comptes_id_seq OWNER TO admin;

--
-- Name: comptes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: admin
--

ALTER SEQUENCE public.comptes_id_seq OWNED BY public.comptes.id;


--
-- Name: transactions; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.transactions (
    id integer NOT NULL,
    compte_id integer NOT NULL,
    type character varying(20) NOT NULL,
    montant numeric(15,2) NOT NULL,
    description text,
    date_operation timestamp without time zone DEFAULT now(),
    CONSTRAINT transactions_montant_check CHECK ((montant > (0)::numeric)),
    CONSTRAINT transactions_type_check CHECK (((type)::text = ANY ((ARRAY['depot'::character varying, 'retrait'::character varying, 'virement'::character varying])::text[])))
);


ALTER TABLE public.transactions OWNER TO admin;

--
-- Name: transactions_id_seq; Type: SEQUENCE; Schema: public; Owner: admin
--

CREATE SEQUENCE public.transactions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.transactions_id_seq OWNER TO admin;

--
-- Name: transactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: admin
--

ALTER SEQUENCE public.transactions_id_seq OWNED BY public.transactions.id;


--
-- Name: app_users id; Type: DEFAULT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.app_users ALTER COLUMN id SET DEFAULT nextval('public.app_users_id_seq'::regclass);


--
-- Name: audit_logs id; Type: DEFAULT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.audit_logs ALTER COLUMN id SET DEFAULT nextval('public.audit_logs_id_seq'::regclass);


--
-- Name: cartes id; Type: DEFAULT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.cartes ALTER COLUMN id SET DEFAULT nextval('public.cartes_id_seq'::regclass);


--
-- Name: clients id; Type: DEFAULT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.clients ALTER COLUMN id SET DEFAULT nextval('public.clients_id_seq'::regclass);


--
-- Name: comptes id; Type: DEFAULT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.comptes ALTER COLUMN id SET DEFAULT nextval('public.comptes_id_seq'::regclass);


--
-- Name: transactions id; Type: DEFAULT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.transactions ALTER COLUMN id SET DEFAULT nextval('public.transactions_id_seq'::regclass);


--
-- Data for Name: app_users; Type: TABLE DATA; Schema: public; Owner: admin
--

COPY public.app_users (id, username, password, role, created_at) FROM stdin;
1	alice	password123	user	2026-04-30 09:43:38.619773
2	bob_secure	password123	user	2026-04-30 09:43:38.619773
\.


--
-- Data for Name: audit_logs; Type: TABLE DATA; Schema: public; Owner: admin
--

COPY public.audit_logs (id, user_login, action, status, ip_address, details, created_at) FROM stdin;
1	admin	login_attempt	success	\N	Connexion initiale administrateur	2026-04-30 09:43:38.620488
2	injection_test	sql_injection	blocked	\N	Tentative injection SQL detectee	2026-04-30 09:43:38.620488
\.


--
-- Data for Name: cartes; Type: TABLE DATA; Schema: public; Owner: admin
--

COPY public.cartes (id, compte_id, numero, type, expiration, bloquee) FROM stdin;
1	1	4539-1234-5678-9012	visa	2027-06-30	f
2	3	5412-9876-5432-1098	mastercard	2026-03-31	f
3	4	4111-1111-1111-1111	visa	2025-12-31	t
4	6	5500-0000-0000-0004	mastercard	2028-09-30	f
\.


--
-- Data for Name: clients; Type: TABLE DATA; Schema: public; Owner: admin
--

COPY public.clients (id, nom, prenom, email, telephone, adresse, date_naissance, created_at) FROM stdin;
1	Dupont	Alice	alice.dupont@email.fr	0601010101	12 rue des Lilas, Paris	1990-05-14	2026-04-30 09:43:38.614123
2	Martin	Bob	bob.martin@email.fr	0602020202	7 avenue Foch, Lyon	1985-11-22	2026-04-30 09:43:38.614123
3	Bernard	Clara	clara.bernard@email.fr	0603030303	3 impasse du Moulin, Bordeaux	2000-02-08	2026-04-30 09:43:38.614123
4	Leroy	David	david.leroy@email.fr	0604040404	88 bd Haussmann, Paris	1978-07-30	2026-04-30 09:43:38.614123
5	Moreau	Emma	emma.moreau@email.fr	0605050505	15 rue de la Paix, Nice	1995-03-19	2026-04-30 09:43:38.614123
\.


--
-- Data for Name: comptes; Type: TABLE DATA; Schema: public; Owner: admin
--

COPY public.comptes (id, client_id, numero, type, solde, created_at) FROM stdin;
1	1	FR001-000001	courant	3500.00	2026-04-30 09:43:38.615237
2	1	FR001-000002	epargne	12000.00	2026-04-30 09:43:38.615237
3	2	FR002-000001	courant	870.50	2026-04-30 09:43:38.615237
4	3	FR003-000001	courant	2100.75	2026-04-30 09:43:38.615237
5	3	FR003-000002	livret	5000.00	2026-04-30 09:43:38.615237
6	4	FR004-000001	courant	15200.00	2026-04-30 09:43:38.615237
7	5	FR005-000001	epargne	8300.00	2026-04-30 09:43:38.615237
\.


--
-- Data for Name: transactions; Type: TABLE DATA; Schema: public; Owner: admin
--

COPY public.transactions (id, compte_id, type, montant, description, date_operation) FROM stdin;
1	1	depot	1500.00	Virement salaire	2026-04-30 09:43:38.616477
2	1	retrait	200.00	Retrait DAB	2026-04-30 09:43:38.616477
3	1	virement	300.00	Loyer	2026-04-30 09:43:38.616477
4	2	depot	5000.00	Epargne mensuelle	2026-04-30 09:43:38.616477
5	3	depot	870.50	Virement entrant	2026-04-30 09:43:38.616477
6	3	retrait	150.00	Achat en ligne	2026-04-30 09:43:38.616477
7	4	depot	2500.00	Remboursement client	2026-04-30 09:43:38.616477
8	6	depot	10000.00	Virement salaire	2026-04-30 09:43:38.616477
9	6	retrait	1200.00	Facture EDF	2026-04-30 09:43:38.616477
\.


--
-- Name: app_users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: admin
--

SELECT pg_catalog.setval('public.app_users_id_seq', 2, true);


--
-- Name: audit_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: admin
--

SELECT pg_catalog.setval('public.audit_logs_id_seq', 2, true);


--
-- Name: cartes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: admin
--

SELECT pg_catalog.setval('public.cartes_id_seq', 4, true);


--
-- Name: clients_id_seq; Type: SEQUENCE SET; Schema: public; Owner: admin
--

SELECT pg_catalog.setval('public.clients_id_seq', 5, true);


--
-- Name: comptes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: admin
--

SELECT pg_catalog.setval('public.comptes_id_seq', 7, true);


--
-- Name: transactions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: admin
--

SELECT pg_catalog.setval('public.transactions_id_seq', 9, true);


--
-- Name: app_users app_users_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.app_users
    ADD CONSTRAINT app_users_pkey PRIMARY KEY (id);


--
-- Name: app_users app_users_username_key; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.app_users
    ADD CONSTRAINT app_users_username_key UNIQUE (username);


--
-- Name: audit_logs audit_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (id);


--
-- Name: cartes cartes_numero_key; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.cartes
    ADD CONSTRAINT cartes_numero_key UNIQUE (numero);


--
-- Name: cartes cartes_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.cartes
    ADD CONSTRAINT cartes_pkey PRIMARY KEY (id);


--
-- Name: clients clients_email_key; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.clients
    ADD CONSTRAINT clients_email_key UNIQUE (email);


--
-- Name: clients clients_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.clients
    ADD CONSTRAINT clients_pkey PRIMARY KEY (id);


--
-- Name: comptes comptes_numero_key; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.comptes
    ADD CONSTRAINT comptes_numero_key UNIQUE (numero);


--
-- Name: comptes comptes_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.comptes
    ADD CONSTRAINT comptes_pkey PRIMARY KEY (id);


--
-- Name: transactions transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_pkey PRIMARY KEY (id);


--
-- Name: cartes cartes_compte_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.cartes
    ADD CONSTRAINT cartes_compte_id_fkey FOREIGN KEY (compte_id) REFERENCES public.comptes(id) ON DELETE CASCADE;


--
-- Name: comptes comptes_client_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.comptes
    ADD CONSTRAINT comptes_client_id_fkey FOREIGN KEY (client_id) REFERENCES public.clients(id) ON DELETE CASCADE;


--
-- Name: transactions transactions_compte_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_compte_id_fkey FOREIGN KEY (compte_id) REFERENCES public.comptes(id) ON DELETE CASCADE;


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: pg_database_owner
--

GRANT USAGE ON SCHEMA public TO analyste;
GRANT USAGE ON SCHEMA public TO conseiller;
GRANT USAGE ON SCHEMA public TO directeur;
GRANT USAGE ON SCHEMA public TO audit_user;


--
-- Name: TABLE app_users; Type: ACL; Schema: public; Owner: admin
--

GRANT SELECT ON TABLE public.app_users TO analyste;
GRANT SELECT ON TABLE public.app_users TO conseiller;
GRANT ALL ON TABLE public.app_users TO directeur;


--
-- Name: SEQUENCE app_users_id_seq; Type: ACL; Schema: public; Owner: admin
--

GRANT ALL ON SEQUENCE public.app_users_id_seq TO directeur;


--
-- Name: TABLE audit_logs; Type: ACL; Schema: public; Owner: admin
--

GRANT SELECT ON TABLE public.audit_logs TO analyste;
GRANT SELECT ON TABLE public.audit_logs TO conseiller;
GRANT ALL ON TABLE public.audit_logs TO directeur;
GRANT SELECT ON TABLE public.audit_logs TO audit_user;


--
-- Name: SEQUENCE audit_logs_id_seq; Type: ACL; Schema: public; Owner: admin
--

GRANT ALL ON SEQUENCE public.audit_logs_id_seq TO directeur;


--
-- Name: TABLE cartes; Type: ACL; Schema: public; Owner: admin
--

GRANT SELECT ON TABLE public.cartes TO analyste;
GRANT SELECT ON TABLE public.cartes TO conseiller;
GRANT ALL ON TABLE public.cartes TO directeur;


--
-- Name: SEQUENCE cartes_id_seq; Type: ACL; Schema: public; Owner: admin
--

GRANT ALL ON SEQUENCE public.cartes_id_seq TO directeur;


--
-- Name: TABLE clients; Type: ACL; Schema: public; Owner: admin
--

GRANT SELECT ON TABLE public.clients TO analyste;
GRANT SELECT ON TABLE public.clients TO conseiller;
GRANT ALL ON TABLE public.clients TO directeur;


--
-- Name: SEQUENCE clients_id_seq; Type: ACL; Schema: public; Owner: admin
--

GRANT ALL ON SEQUENCE public.clients_id_seq TO directeur;


--
-- Name: TABLE comptes; Type: ACL; Schema: public; Owner: admin
--

GRANT SELECT ON TABLE public.comptes TO analyste;
GRANT SELECT,UPDATE ON TABLE public.comptes TO conseiller;
GRANT ALL ON TABLE public.comptes TO directeur;


--
-- Name: SEQUENCE comptes_id_seq; Type: ACL; Schema: public; Owner: admin
--

GRANT ALL ON SEQUENCE public.comptes_id_seq TO directeur;


--
-- Name: TABLE transactions; Type: ACL; Schema: public; Owner: admin
--

GRANT SELECT ON TABLE public.transactions TO analyste;
GRANT SELECT,INSERT ON TABLE public.transactions TO conseiller;
GRANT ALL ON TABLE public.transactions TO directeur;


--
-- Name: SEQUENCE transactions_id_seq; Type: ACL; Schema: public; Owner: admin
--

GRANT ALL ON SEQUENCE public.transactions_id_seq TO directeur;


--
-- PostgreSQL database dump complete
--

\unrestrict 8kVGPJoD2TnlT3NM0yVULhC5SA0vh0YQWjsDtehfkhgk0pk2w5YsLrTuAafwK84

