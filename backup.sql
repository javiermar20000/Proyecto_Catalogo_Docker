--
-- PostgreSQL database dump
--

\restrict YbDeCqi9JaaLm6tbvi8qnoTjQB1HAPklw9OrLDpxR7wcammYbHiV6XcS7ibVcqV

-- Dumped from database version 16.10
-- Dumped by pg_dump version 16.10

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

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: items; Type: TABLE; Schema: public; Owner: catalogo
--

CREATE TABLE public.items (
    id integer NOT NULL,
    name text NOT NULL,
    price numeric(12,2) DEFAULT 0 NOT NULL
);


ALTER TABLE public.items OWNER TO catalogo;

--
-- Name: items_id_seq; Type: SEQUENCE; Schema: public; Owner: catalogo
--

CREATE SEQUENCE public.items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.items_id_seq OWNER TO catalogo;

--
-- Name: items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: catalogo
--

ALTER SEQUENCE public.items_id_seq OWNED BY public.items.id;


--
-- Name: items id; Type: DEFAULT; Schema: public; Owner: catalogo
--

ALTER TABLE ONLY public.items ALTER COLUMN id SET DEFAULT nextval('public.items_id_seq'::regclass);


--
-- Data for Name: items; Type: TABLE DATA; Schema: public; Owner: catalogo
--

COPY public.items (id, name, price) FROM stdin;
1	Cafetera	39990.00
2	Auriculares	25990.00
3	Teclado	54990.00
4	Mouse	12990.00
5	SSD	59990.00
\.


--
-- Name: items_id_seq; Type: SEQUENCE SET; Schema: public; Owner: catalogo
--

SELECT pg_catalog.setval('public.items_id_seq', 5, true);


--
-- Name: items items_pkey; Type: CONSTRAINT; Schema: public; Owner: catalogo
--

ALTER TABLE ONLY public.items
    ADD CONSTRAINT items_pkey PRIMARY KEY (id);


--
-- PostgreSQL database dump complete
--

\unrestrict YbDeCqi9JaaLm6tbvi8qnoTjQB1HAPklw9OrLDpxR7wcammYbHiV6XcS7ibVcqV

