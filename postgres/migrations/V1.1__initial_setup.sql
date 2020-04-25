--
-- PostgreSQL database dump
--

-- Dumped from database version 10.4
-- Dumped by pg_dump version 10.4

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: menubulkadd(json[]); Type: FUNCTION; Schema: public; Owner: gmarshall
--

CREATE FUNCTION public.menubulkadd(nodes json[]) RETURNS integer
    LANGUAGE plpgsql
    AS $_$

  DECLARE
    node json;
    id text;
    labelStr text;
    parentid integer;
    pos integer;
    id_val integer;
    tmp text;

  BEGIN
    CREATE TEMP TABLE lookup(origid VARCHAR, id INTEGER);

    FOREACH node IN ARRAY nodes
    LOOP
      id       := node->'id';
      labelStr := node->'label';
      labelStr := substring(labelStr, 2, char_length(labelStr)-2);
      tmp      := node->'parentid';
      pos      := node->'itemposition';

      IF (tmp ~ '^([0-9]*)$') THEN
        parentid := CAST(tmp as integer);
      ELSE
        SELECT lookup.id INTO parentid FROM lookup WHERE lookup.origid = tmp;
      END IF;

      RAISE NOTICE 'node: id: %  label: %  parentid: %  pos: %' , id, labelStr, parentid, pos;
      EXECUTE 'INSERT INTO menuitems (id, label, parentid, position, routerpath) VALUES' ||
              '(DEFAULT, ''' || labelStr || ''', ' || parentid || ', ' || pos ||', ''undefined'') ' ||
              'RETURNING menuitems.id;'
      INTO id_val;

      INSERT INTO lookup (origid, id) VALUES (id, id_val);
    END LOOP;

    DROP TABLE lookup;

    RETURN array_length(nodes, 1);
  END;
$_$;


ALTER FUNCTION public.menubulkadd(nodes json[]) OWNER TO gmarshall;

--
-- Name: menubulkdelete(json[]); Type: FUNCTION; Schema: public; Owner: gmarshall
--

CREATE FUNCTION public.menubulkdelete(nodes json[]) RETURNS integer
    LANGUAGE plpgsql
    AS $$

  DECLARE
    node json;
    delid integer;
    labelStr text;
    parentid integer;

  BEGIN
    FOREACH node IN ARRAY nodes
    LOOP
      delid    := node->'id';
      labelStr := node->'label';
      labelStr := substring(labelStr, 2, char_length(labelStr)-2);
      parentid := node->'parentid';

      RAISE NOTICE 'node: id: %  label: %  parentid: %' , delid, labelStr, parentid;
      DELETE FROM metadata.menuitems where menuitems.id = delid;

    END LOOP;

    RETURN array_length(nodes, 1);
  END;
$$;


ALTER FUNCTION public.menubulkdelete(nodes json[]) OWNER TO gmarshall;

--
-- Name: menubulkupdate(json[]); Type: FUNCTION; Schema: public; Owner: gmarshall
--

CREATE FUNCTION public.menubulkupdate(nodes json[]) RETURNS integer
    LANGUAGE plpgsql
    AS $_$

  DECLARE
    node json;
    id integer;
    labelStr text;
    parentid integer;
    pos integer;

  BEGIN

    FOREACH node IN ARRAY nodes
    LOOP
      id       := node->'id';
      labelStr := node->'label';
      labelStr := substring(labelStr, 2, char_length(labelStr)-2);
      parentid := node->'parentid';
      pos      := node->'itemposition';

      RAISE NOTICE 'node: id: %  label: %  parentid: %  pos: %' , id, labelStr, parentid, pos;
      EXECUTE 'UPDATE menuitems SET label = $2, parentid = $3, position = $4 WHERE id = $1'
      USING id, labelStr, parentid, pos;
    END LOOP;

    RETURN array_length(nodes, 1);
  END;
$_$;


ALTER FUNCTION public.menubulkupdate(nodes json[]) OWNER TO gmarshall;

--
-- Name: menuitemadd(json); Type: FUNCTION; Schema: public; Owner: gmarshall
--

CREATE FUNCTION public.menuitemadd(item json) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    id_val integer;
    appid integer;
    parentid integer;
    pos integer;
    appname text;
    shortname text;

  BEGIN
    appid := item->'id';
    parentid := item->'parentid';
    pos := item->'position';
    appname := item->>'name';
    shortname := item->>'shortname';

    RAISE NOTICE 'appid: %  label: %  parentid: %  position: %  routerpath: %' , appid, appname, parentid, pos, shortname;

--     INSERT INTO menuitems (id, parentid, label, appid, active, position, routerpath) VALUES (DEFAULT, )
      EXECUTE 'INSERT INTO menuitems (id, appid, label, parentid, position, routerpath) VALUES' ||
              '(DEFAULT, ' || appid || ', ''' || appname || ''', ' || parentid || ', ' || pos ||', ''' || shortname || ''') ' ||
              'RETURNING menuitems.id;'
      INTO id_val;

    RETURN id_val;
  END;
$$;


ALTER FUNCTION public.menuitemadd(item json) OWNER TO gmarshall;

--
-- Name: menusfindall(); Type: FUNCTION; Schema: public; Owner: gmarshall
--

CREATE FUNCTION public.menusfindall() RETURNS TABLE(id integer, parentid integer, label character varying, routerpath character varying, icon character varying, appid integer, pageid integer, active integer, itemposition integer, syspath character varying, subitems integer[])
    LANGUAGE plpgsql
    AS $$
	BEGIN
		RETURN QUERY
		SELECT
      items.id,
      items.parentid,
      items.label,
      items.routerpath,
      (select icons.icon from menuicons icons where icons.id = items.iconid),
      items.appid,
      items.pageid,
      items.active,
      items.position as itemposition,
      (select mp.syspath from menupaths mp where mp.id = items.pathid) as syspath,
      array(select subs.id from menuitems subs where subs.parentid = items.id) as subitems
		FROM menuitems items
    ORDER BY syspath, itemposition;
	END;
$$;


ALTER FUNCTION public.menusfindall() OWNER TO gmarshall;

--
-- Name: pageformsfindbyid(numeric, numeric); Type: FUNCTION; Schema: public; Owner: gmarshall
--

CREATE FUNCTION public.pageformsfindbyid(idapp numeric, idpage numeric) RETURNS TABLE(appid integer, pageid integer, title character varying, formid integer, columnname character varying, formtitle character varying, formjson jsonb, pageactions json)
    LANGUAGE plpgsql
    AS $$

  DECLARE
    actions JSON := pageFormsGetActionsByPage(idpage);

	BEGIN
		RETURN QUERY
		SELECT
      page.appid,
      page.id as pageid,
      page.title,
      pf.id as formid,
      pf.columnname,
      pf.title as formtitle,
      pf.jsondata as formjson,
      actions as pageactions
    FROM
      pages page
      LEFT OUTER JOIN
        (
          SELECT
            pf.pageid,
            pf.id,
            pf.systemcategoryid,
            col.columnname,
            pf.title,
            pf.jsondata
          FROM
            pageforms pf
            LEFT OUTER JOIN appcolumns as col ON pf.appcolumnid = col.id
        ) as pf
      ON
        pf.pageid = page.id
    WHERE
      page.appid = idapp AND page.id = idpage;
	END;
$$;


ALTER FUNCTION public.pageformsfindbyid(idapp numeric, idpage numeric) OWNER TO gmarshall;

--
-- Name: quotesfindall(); Type: FUNCTION; Schema: public; Owner: gmarshall
--

CREATE FUNCTION public.quotesfindall() RETURNS TABLE(id integer, version integer, author_first_name text, author_last_name text, updatedat timestamp with time zone, quote_string text, categoryid integer, formatid integer, comment text, graphic_url text, source text, formatname character varying, categoryname character varying)
    LANGUAGE plpgsql
    AS $$
	BEGIN
		RETURN QUERY
		SELECT
			quotes.id,
			quotes.version,
			quotes.author_first_name,
			quotes.author_last_name,
			quotes.updatedat,
			quotes.quote_string,
      quotes.categoryid,
			quotes.formatid,
			jsondata ->> 'comment' as comment,
			jsondata ->> 'graphic_url' as graphic_url,
			jsondata ->> 'source' as source,
      format.name as formatname,
      cat.name as categoryname
		FROM quotes
    LEFT OUTER JOIN quoteformats as format ON format.id = quotes.formatid
    LEFT OUTER JOIN quotecategories as cat ON cat.id = quotes.categoryid;
	END;
$$;


ALTER FUNCTION public.quotesfindall() OWNER TO gmarshall;

--
-- Name: quotesfindbyid(integer); Type: FUNCTION; Schema: public; Owner: gmarshall
--

CREATE FUNCTION public.quotesfindbyid(findid integer) RETURNS TABLE(id integer, version integer, author_first_name text, author_last_name text, updatedat timestamp with time zone, quote_string text, categoryid integer, formatid integer, comment text, graphic_url text, source text, formatname character varying, categoryname character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
		RETURN QUERY
		SELECT
			quotes.id,
			quotes.version,
			quotes.author_first_name,
			quotes.author_last_name,
			quotes.updatedat,
			quotes.quote_string,
			quotes.categoryid,
			quotes.formatid,
			jsondata ->> 'comment' as comment,
			jsondata ->> 'graphic_url' as graphic_url,
			jsondata ->> 'source' as source,
      format.name as formatname,
      cat.name as categoryname
		FROM quotes
			LEFT OUTER JOIN quoteformats as format ON format.id = quotes.formatid
			LEFT OUTER JOIN quotecategories as cat ON cat.id = quotes.categoryid
		WHERE quotes.id = findId;
	END;
$$;


ALTER FUNCTION public.quotesfindbyid(findid integer) OWNER TO gmarshall;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: applications; Type: TABLE; Schema: public; Owner: gmarshall
--

CREATE TABLE public.applications (
    id integer NOT NULL,
    name character varying(40) NOT NULL,
    shortname character varying(20),
    description character varying(60)
);


ALTER TABLE public.applications OWNER TO gmarshall;

--
-- Name: menuicons; Type: TABLE; Schema: public; Owner: gmarshall
--

CREATE TABLE public.menuicons (
    id integer NOT NULL,
    icon character varying(32),
    iconname character varying(20)
);


ALTER TABLE public.menuicons OWNER TO gmarshall;

--
-- Name: menuicons_id_seq; Type: SEQUENCE; Schema: public; Owner: gmarshall
--

CREATE SEQUENCE public.menuicons_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.menuicons_id_seq OWNER TO gmarshall;

--
-- Name: menuicons_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gmarshall
--

ALTER SEQUENCE public.menuicons_id_seq OWNED BY public.menuicons.id;


--
-- Name: menuitems; Type: TABLE; Schema: public; Owner: gmarshall
--

CREATE TABLE public.menuitems (
    id integer NOT NULL,
    label character varying(20),
    iconid integer,
    appid integer,
    pageid integer,
    active integer,
    "position" integer,
    pathid integer,
    routerpath character varying(20),
    parentid integer
);


ALTER TABLE public.menuitems OWNER TO gmarshall;

--
-- Name: menuitems_id_seq; Type: SEQUENCE; Schema: public; Owner: gmarshall
--

CREATE SEQUENCE public.menuitems_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.menuitems_id_seq OWNER TO gmarshall;

--
-- Name: menuitems_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gmarshall
--

ALTER SEQUENCE public.menuitems_id_seq OWNED BY public.menuitems.id;


--
-- Name: menupaths; Type: TABLE; Schema: public; Owner: gmarshall
--

CREATE TABLE public.menupaths (
    id integer NOT NULL,
    syspath character varying(256),
    sysname character varying(60),
    shortname character varying(20)
);


ALTER TABLE public.menupaths OWNER TO gmarshall;

--
-- Name: menupaths_id_seq; Type: SEQUENCE; Schema: public; Owner: gmarshall
--

CREATE SEQUENCE public.menupaths_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.menupaths_id_seq OWNER TO gmarshall;

--
-- Name: menupaths_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gmarshall
--

ALTER SEQUENCE public.menupaths_id_seq OWNED BY public.menupaths.id;


--
-- Name: notes; Type: TABLE; Schema: public; Owner: gmarshall
--

CREATE TABLE public.notes (
    id integer NOT NULL,
    comment character varying(128),
    topicid integer,
    notetext character varying(1000),
    jsondata jsonb,
    createdat timestamp without time zone,
    updatedat timestamp without time zone DEFAULT now()
);


ALTER TABLE public.notes OWNER TO gmarshall;

--
-- Name: notes_id_seq; Type: SEQUENCE; Schema: public; Owner: gmarshall
--

CREATE SEQUENCE public.notes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.notes_id_seq OWNER TO gmarshall;

--
-- Name: notes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gmarshall
--

ALTER SEQUENCE public.notes_id_seq OWNED BY public.notes.id;


--
-- Name: pages; Type: TABLE; Schema: public; Owner: gmarshall
--

CREATE TABLE public.pages (
    id integer NOT NULL,
    appid integer NOT NULL,
    title character varying(30) NOT NULL,
    name character varying(30),
    description character varying(60)
);


ALTER TABLE public.pages OWNER TO gmarshall;

--
-- Name: pages_id_seq; Type: SEQUENCE; Schema: public; Owner: gmarshall
--

CREATE SEQUENCE public.pages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pages_id_seq OWNER TO gmarshall;

--
-- Name: pages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gmarshall
--

ALTER SEQUENCE public.pages_id_seq OWNED BY public.pages.id;


--
-- Name: quotecategories; Type: TABLE; Schema: public; Owner: gmarshall
--

CREATE TABLE public.quotecategories (
    id integer NOT NULL,
    name character varying(40),
    description character varying(128)
);


ALTER TABLE public.quotecategories OWNER TO gmarshall;

--
-- Name: quotecategories_id_seq; Type: SEQUENCE; Schema: public; Owner: gmarshall
--

CREATE SEQUENCE public.quotecategories_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.quotecategories_id_seq OWNER TO gmarshall;

--
-- Name: quotecategories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gmarshall
--

ALTER SEQUENCE public.quotecategories_id_seq OWNED BY public.quotecategories.id;


--
-- Name: quoteformats; Type: TABLE; Schema: public; Owner: gmarshall
--

CREATE TABLE public.quoteformats (
    id integer NOT NULL,
    name character varying(40)
);


ALTER TABLE public.quoteformats OWNER TO gmarshall;

--
-- Name: quoteformat_id_seq; Type: SEQUENCE; Schema: public; Owner: gmarshall
--

CREATE SEQUENCE public.quoteformat_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.quoteformat_id_seq OWNER TO gmarshall;

--
-- Name: quoteformat_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gmarshall
--

ALTER SEQUENCE public.quoteformat_id_seq OWNED BY public.quoteformats.id;


--
-- Name: quotes; Type: TABLE; Schema: public; Owner: gmarshall
--

CREATE TABLE public.quotes (
    id integer NOT NULL,
    version integer DEFAULT 0,
    author_first_name text,
    author_last_name text,
    updatedat timestamp with time zone DEFAULT now() NOT NULL,
    quote_string text NOT NULL,
    jsondata jsonb,
    createdat timestamp without time zone,
    categoryid integer,
    formatid integer DEFAULT 1
);


ALTER TABLE public.quotes OWNER TO gmarshall;

--
-- Name: quotes_id_seq; Type: SEQUENCE; Schema: public; Owner: gmarshall
--

CREATE SEQUENCE public.quotes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.quotes_id_seq OWNER TO gmarshall;

--
-- Name: quotes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gmarshall
--

ALTER SEQUENCE public.quotes_id_seq OWNED BY public.quotes.id;


--
-- Name: topics; Type: TABLE; Schema: public; Owner: gmarshall
--

CREATE TABLE public.topics (
    id integer NOT NULL,
    name character varying(20),
    parentid integer
);


ALTER TABLE public.topics OWNER TO gmarshall;

--
-- Name: topics_id_seq; Type: SEQUENCE; Schema: public; Owner: gmarshall
--

CREATE SEQUENCE public.topics_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.topics_id_seq OWNER TO gmarshall;

--
-- Name: topics_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gmarshall
--

ALTER SEQUENCE public.topics_id_seq OWNED BY public.topics.id;


--
-- Name: menuicons id; Type: DEFAULT; Schema: public; Owner: gmarshall
--

ALTER TABLE ONLY public.menuicons ALTER COLUMN id SET DEFAULT nextval('public.menuicons_id_seq'::regclass);


--
-- Name: menuitems id; Type: DEFAULT; Schema: public; Owner: gmarshall
--

ALTER TABLE ONLY public.menuitems ALTER COLUMN id SET DEFAULT nextval('public.menuitems_id_seq'::regclass);


--
-- Name: menupaths id; Type: DEFAULT; Schema: public; Owner: gmarshall
--

ALTER TABLE ONLY public.menupaths ALTER COLUMN id SET DEFAULT nextval('public.menupaths_id_seq'::regclass);


--
-- Name: notes id; Type: DEFAULT; Schema: public; Owner: gmarshall
--

ALTER TABLE ONLY public.notes ALTER COLUMN id SET DEFAULT nextval('public.notes_id_seq'::regclass);


--
-- Name: pages id; Type: DEFAULT; Schema: public; Owner: gmarshall
--

ALTER TABLE ONLY public.pages ALTER COLUMN id SET DEFAULT nextval('public.pages_id_seq'::regclass);


--
-- Name: quotecategories id; Type: DEFAULT; Schema: public; Owner: gmarshall
--

ALTER TABLE ONLY public.quotecategories ALTER COLUMN id SET DEFAULT nextval('public.quotecategories_id_seq'::regclass);


--
-- Name: quoteformats id; Type: DEFAULT; Schema: public; Owner: gmarshall
--

ALTER TABLE ONLY public.quoteformats ALTER COLUMN id SET DEFAULT nextval('public.quoteformat_id_seq'::regclass);


--
-- Name: quotes id; Type: DEFAULT; Schema: public; Owner: gmarshall
--

ALTER TABLE ONLY public.quotes ALTER COLUMN id SET DEFAULT nextval('public.quotes_id_seq'::regclass);


--
-- Name: topics id; Type: DEFAULT; Schema: public; Owner: gmarshall
--

ALTER TABLE ONLY public.topics ALTER COLUMN id SET DEFAULT nextval('public.topics_id_seq'::regclass);


--
-- Data for Name: applications; Type: TABLE DATA; Schema: public; Owner: gmarshall
--

COPY public.applications (id, name, shortname, description) FROM stdin;
3	System		Application Factory System
0	System	System	Applications System
1	Quotes	Quotes	Quotes
2	Notes	Notes	Notes Application
\.


--
-- Data for Name: menuicons; Type: TABLE DATA; Schema: public; Owner: gmarshall
--

COPY public.menuicons (id, icon, iconname) FROM stdin;
11	home	Home
10		Globe
8	flag	Flag - Blue
13	navigation	PaperPlane
9	settings	Gear
23	visibility	Eye
22	build	Wrench
20	wifi	Signal
7	insert_drive_file	File
5	clear	Crosshairs
16	airplanemode_active	Plane
25	outlined_flag	Flag - White 
12	info	Info
24		Asterisk
15	edit	Pencil
19	search	Search
4	check	Check
14	attach_file	Paperclip
17	add	Plus
3		Certificate
21	star	Star
1		Binoculars
6	dashboard	Dashboard
18	help	Question
2	offline_bolt	Bolt
26	contact_support	Contact Support
27	domain	Domain
28	print	Print
\.


--
-- Data for Name: menuitems; Type: TABLE DATA; Schema: public; Owner: gmarshall
--

COPY public.menuitems (id, label, iconid, appid, pageid, active, "position", pathid, routerpath, parentid) FROM stdin;
30	VTAMP Ad-Hoc Report	19	1	12	1	1	9	\N	28
25	Pub List	\N	2	23	1	6	7	\N	18
24	Module Settings	\N	2	22	1	5	7	\N	18
32	Settings	9	1	14	1	1	6	\N	29
34	Simple Search	\N	1	11	1	3	3	\N	8
18	Admin Pages	9	2	0	1	3	4	admin	9
29	Admin	\N	1	0	1	4	3	admin	8
28	Reports	28	1	0	1	3	3	reports	8
21	Cost Settings	\N	2	19	1	2	7	\N	18
23	Buno List	\N	2	21	1	4	7	\N	18
20	LCN List	\N	2	18	1	1	7	\N	18
22	Serial Number List	\N	2	20	1	3	7	\N	18
19	AdHoc	19	2	17	1	4	4	\N	9
31	PBL Report	28	1	13	1	2	9	\N	28
6	Help	18	0	8	1	6	1	\N	\N
2	Home	11	0	1	1	1	1	\N	\N
4	Administration	9	0	6	1	4	1	\N	\N
3	Applications	27	0	0	1	3	1	apps	\N
9	Notes	\N	2	0	1	2	2	notes	3
8	Quotes	16	1	0	1	1	2	quotes	3
35	Contact Us	26	0	0	1	2	10	contactus	4
37	Menu Tree	\N	0	33	1	2	10	menutree	1
36	Menu Maintenance	\N	0	32	1	1	10	menuedit	1
1	Menu Maintenance	\N	0	0	1	1	10	sysadmin	4
26	Quote Maintenance	\N	1	9	1	1	3	quotemaint	8
38	Quotes List	\N	1	9	1	2	3	quoteslist	8
16	Note Maintenance	\N	2	15	1	1	4	notemaint	9
39	Notes List	\N	2	34	1	2	4	noteslist	9
\.


--
-- Data for Name: menupaths; Type: TABLE DATA; Schema: public; Owner: gmarshall
--

COPY public.menupaths (id, syspath, sysname, shortname) FROM stdin;
1	/	root	Main
2	/apps	apps	Applications
5	/apps/dcn	dcn	DCN
6	/apps/vtamp/admin	admin	VTAMP Admin
8	/apps/dcn/admin	admin	DCN Admin
7	/apps/ecp/admin	admin	ECP Admin
9	/apps/vtamp/reports	reports	VTAMP Reports
10	/Administration	sysadmin	Form Builder
11	/Administration/contact	sysadmincontact	Admin Contact
12	/Administration/menu	sysadminmenu	Menu Maintenance
3	/apps/quotes	quotes	Quotes
4	/apps/notes	notes	Notes
\.


--
-- Data for Name: notes; Type: TABLE DATA; Schema: public; Owner: gmarshall
--

COPY public.notes (id, comment, topicid, notetext, jsondata, createdat, updatedat) FROM stdin;
3	Get the address of the default VM.	6	docker-machine ip default	{"tags": ["vm", "ip", "default"], "attachments": []}	2019-06-01 16:15:14.013	2019-06-01 16:15:33.618
\.


--
-- Data for Name: pages; Type: TABLE DATA; Schema: public; Owner: gmarshall
--

COPY public.pages (id, appid, title, name, description) FROM stdin;
4	3	Dashboard	dashboard	system dashboard
8	3	Help	help	system help
7	3	Support	support	system support
1	3	Home	home	system home
6	3	Administration	administration	system administration
10	1	Active Requests	activerequests	vtamp active requests
11	1	Simple Search	simplesearch	vtamp simple search
12	1	VTAMP Ad-Hoc Report	adhocreport	vtamp ad-hoc report
13	1	PBL Report	pblreport	vtamp pbl report
14	1	Settings	settings	vtamp admin settings
17	2	AdHoc	adhoc	ecp adhoc
18	2	LCN List	lcnlist	ecp lcn list
20	2	Serial Number List	serialnumberlist	ecp serial number list
19	2	Cost Settings	costsettings	ecp cost settings
21	2	Buno List	bunolist	ecp buno list
22	2	Module Settings	modulesettings	ecp module settings
23	2	Pub List	publist	ecp pub list
0	3	NONE	nopage	empty page
29	3	Form Builder	formbuilder	Form Builder Page
30	3	Contact Us	emailadmins	Admin contact email
31	3	Create Change Request	websiteissues	Admin website issues
32	0	Menu Item Maintenance	menumaint	Add/Edit Menu Item
33	0	Menu Tree	menutree	Show menu items as a tree
9	1	Quote Maintenance	quotemaint	Quotes add/edit
15	2	Note Maintenance	notemaint	Notes maintenance
34	2	Notes List	noteslist	Notes list
\.


--
-- Data for Name: quotecategories; Type: TABLE DATA; Schema: public; Owner: gmarshall
--

COPY public.quotecategories (id, name, description) FROM stdin;
1	Philosophy	Philosophy or religion
2	Comedy	Funny quotes
3	Eastern	Zen, chinese, and buddhism
\.


--
-- Data for Name: quoteformats; Type: TABLE DATA; Schema: public; Owner: gmarshall
--

COPY public.quoteformats (id, name) FROM stdin;
2	Html
3	RTF
1	Text
\.


--
-- Data for Name: quotes; Type: TABLE DATA; Schema: public; Owner: gmarshall
--

COPY public.quotes (id, version, author_first_name, author_last_name, updatedat, quote_string, jsondata, createdat, categoryid, formatid) FROM stdin;
142	0	Test	Test	2018-12-09 11:17:16.444-05	A test record	\N	2018-12-09 16:17:16.444	\N	1
150	1	Thich Nhat	Hanh	2018-12-09 11:40:01.791-05	The deepest happiness you can have comes from that capacity to help relieve the suffering of others.	{"source": "", "comment": null, "graphic_url": null}	2018-12-09 16:39:41.203	3	1
154	1		Upanishads	2018-12-21 17:45:06.689-05	One who knows the Self puts death to death.	{"source": ""}	2018-12-21 22:45:06.689	3	1
158	1			2018-12-21 17:47:36.879-05	Life is but a journey; death is returning home.	{"source": "Chinese proverb"}	2018-12-21 22:47:36.879	3	1
58	0	\N	Zen saying	2006-12-05 01:07:55-05	Just this.	\N	\N	\N	1
151	1	Chuang	Tzu	2018-12-09 11:42:05.308-05	The purpose of words is to convey ideas.  When the ideas are grasped, the words are forgotten.  Where can I find a man who has forgotten the words?  He is the one I would like to talk to.	{"source": "", "comment": null, "graphic_url": null}	2018-12-09 16:41:42.408	3	1
155	1			2018-12-21 17:45:47.584-05	Mischief all comes from much opening of the mouth.	{"source": "Chinese proverb"}	2018-12-21 22:45:47.584	3	1
159	1	My	Test	2018-12-31 10:06:29.784-05	<test>:;junk	{"source": "", "comment": ""}	2018-12-31 15:06:29.782	\N	1
60	0	Rabindranath	Tagore	2006-12-05 17:35:00-05	Let us not pray to be sheltered from dangers but to be fearless in facing them.  Let us not beg for the stilling of the pain but for the heart to conquer it.	\N	\N	\N	1
64	0	Mahatma	Gandhi	2006-12-06 00:30:33-05	Faith is not something to grasp, it is a state to grow into.	\N	\N	\N	1
1	0	D.T.	Suzuki	2003-11-09 17:00:00-05	Zen has no business with ideas.	\N	\N	\N	1
2	0	\N	Chinese proverb	2003-11-13 18:59:49-05	Only a vessel that is half-full can be shaken.	\N	\N	\N	1
3	0	\N	Samurai Maxim	2003-11-13 18:59:49-05	The angry man will defeat himself in battle as well as in life.	\N	\N	\N	1
4	0	\N	Chinese proverb	2003-11-13 18:59:49-05	He who carves the Buddha never worships him.	\N	\N	\N	1
5	0	\N	Zen saying	2003-11-13 18:59:49-05	You cannot enter a place you never left.	\N	\N	\N	1
6	0	\N	Chinese proverb	2003-11-13 18:27:16-05	Better to argue with a wise man than prattle with a fool.	\N	\N	\N	1
152	1		Lao-tzu	2018-12-09 11:44:10.382-05	Fill your bowl to the brim and it will spill.  Keep sharpening your knife and it will blunt.  Chase after money and security and your heart will never unclench.  Care about people's approval and you will be their prisoner.	{"source": ""}	2018-12-09 16:44:10.382	3	1
156	1	J	Krishnamurti	2018-12-21 17:46:21.266-05	Memory is incomplete experience.	{"source": ""}	2018-12-21 22:46:21.266	3	1
7	0	Sri	Aurobindo	2003-11-13 18:32:33-05	By your stumbling, the world is perfected.	\N	\N	\N	1
8	0	\N	Chinese proverb	2003-11-17 21:55:19-05	Only by learning do we discover how ignorant we are.	\N	\N	\N	1
118	0	Ernest	Hemingway	2018-07-18 11:15:25.109-04	Never confuse movement with action.	{"source": "sample source", "comment": "test comment", "category": 0, "graphic_url": "http://test.com", "quote_format": 0}	\N	\N	1
132	0	Hannah	Arendt	2018-07-19 09:16:08.072-04	The most radical revolutionary will become a conservative the day after the revolution.	{"source": "Test Add"}	\N	\N	1
133	0	Sir Arthur	Conan Doyle	2018-07-19 09:21:37.148-04	Mediocrity knows nothing higher than itself, but talent instantly recognizes genius.	{"source": "Test Add Source"}	\N	\N	1
9	0	\N	Zen saying	2003-11-19 21:22:28-05	How you do anything is how you do everything.	\N	\N	\N	1
10	0	Mark	Twain	2003-11-19 21:32:21-05	Be good and you will be lonely.	\N	\N	\N	1
11	0	\N	Tao te Ching	2003-11-19 21:37:07-05	Act without doing; work without effort.	\N	\N	\N	1
12	0	\N	Seneca	2003-11-20 17:30:31-05	Let us train our minds to desire what the situation demands.	\N	\N	\N	1
13	0	\N	Chinese proverb	2003-11-20 20:44:04-05	Only distance tests the strength of horses; only time reveals the hearts of men.	\N	\N	\N	1
14	0	\N	Zen saying	2003-11-20 23:15:10-05	Those in a hurry do not arrive.	\N	\N	\N	1
15	0	\N	Japanese proverb	2005-11-30 21:44:50-05	The person who confesses ignorance shows it once; the person who conceals it shows it many times.	\N	\N	\N	1
16	0	Sun	Tzu	2005-11-30 22:35:38-05	If you are inconsistent in your feelings, you will lose dignity and trust.	\N	\N	\N	1
17	0	\N	Chinese proverb	2005-12-28 23:58:20-05	Everything in the past died yesterday; everything in the future was born today.	\N	\N	\N	1
18	0	\N	Buddha	2005-12-28 23:58:20-05	There is nothing more dreadful than the habit of doubt.  Doubt separates people.  It is a poison that disintegrates friendships and breaks up pleasant relations.  It is a thorn that irritates and hurts; it is a sword that kills.	\N	\N	\N	1
19	0	\N	Chinese saying	2005-12-29 00:01:29-05	Please slow down, I'm in a hurry.	\N	\N	\N	1
20	0	Baba Ram	Dass	2006-01-06 00:25:29-05	The quieter you become, the more you can hear.	\N	\N	\N	1
21	0	Mahatma	Gandhi	2006-01-06 01:40:02-05	There is more to life than increasing its speed.	\N	\N	\N	1
22	0	\N	African Proverb	2006-01-24 16:33:16-05	No one shows a child the sky.	\N	\N	\N	1
23	0	Dennis 	Miller	2006-01-24 16:36:33-05	If you sold your soul in the eighties, at least you got out at the height of the market.	\N	\N	\N	1
24	0	Charles	Darwin	2006-01-24 16:36:33-05	It is not the strongest species that survive, nor the most intelligent, but the one most responsive to change.	\N	\N	\N	1
25	0	\N	Bhagavad Gita	2006-01-25 16:05:32-05	Let not the fruit of action be your motive to action.  Your business is with action alone, not with the fruit of action.	\N	\N	\N	1
26	0	\N	Chinese proverb	2006-01-25 16:05:57-05	At birth we bring nothing with us; at death we take nothing away.	\N	\N	\N	1
27	0	\N	Lao-tzu	2006-01-25 16:06:41-05	In thinking, keep to the simple.  In conflict, be fair and generous.  In governing, don't try to control.  In work, do what you enjoy.  In family life, be completely present.	\N	\N	\N	1
28	0	\N	Tao te Ching	2006-01-25 16:06:41-05	A great tailor cuts little.	\N	\N	\N	1
29	0	Josh 	Billings	2006-01-25 16:08:05-05	As scarce as truth is, the supply has always been in excess of the demand.	\N	\N	\N	1
30	0	Kevin 	Kelly	2006-01-25 16:08:05-05	To scale a higher peak -- a potentially greater gain -- often means crossing a valley of less fitness first.  A clear view of the future should not be mistaken for a short distance.	\N	\N	\N	1
31	0	\N	Anonymous	2006-01-25 16:08:05-05	Ideas are like children; your own are always wonderful.	\N	\N	\N	1
32	0	Marcus 	Aurelius	2006-01-25 16:08:05-05	The art of living is more like wrestling than dancing.	\N	\N	\N	1
33	0	Samuel 	Butler	2006-01-25 16:09:22-05	Life is like playing a violin in public and learning the instrument as one goes along.	\N	\N	\N	1
34	0	Jake 	Sturm	2006-01-25 16:09:22-05	Often the hardest part of finding a solution is not finding the right answer, but finding the right question.	\N	\N	\N	1
35	0	Elbert 	Hubbard	2006-01-25 16:09:22-05	Do not take life too seriously.  You will never get out of it alive.	\N	\N	\N	1
136	0	Record1	Test	2018-07-19 09:29:20.425-04	A test record	{"source": "sample source", "comment": "test comment", "category": 1, "graphic_url": "http://test.com", "quote_format": 2}	\N	\N	1
137	0	Mignon	McLaughlin	2018-07-19 09:30:32.565-04	No one really listens to anyone else, and if you try it for a while you'll see why.	{"source": "testing source"}	\N	\N	1
140	0	Arthur C.	Clarke	2018-07-19 09:41:45.796-04	The only way to discover the limits of the possible is to go beyond them into the impossible.	{"source": "test source"}	\N	\N	1
36	0	Alfred North 	Whitehead	2006-01-25 16:10:23-05	We think in generalities, but we live in detail.	\N	\N	\N	1
37	0	\N	Zen saying	2006-01-25 16:10:23-05	For others to approve me is easy; for me to approve myself is hard.	\N	\N	\N	1
38	0	\N	Genro	2006-01-25 16:10:23-05	The bellows blew high the flaming forge, The sword was hammered on the anvil.  It was the same steel as in the beginning, But how different was its edge!	\N	\N	\N	1
39	0	\N	Buddha	2006-01-25 16:10:23-05	Carpenters bend wood; fletchers bend arrows; wise men fashion themselves.	\N	\N	\N	1
40	0	\N	The Dhammapada	2006-01-25 16:10:23-05	The one who has conquered himself is a far greater hero than he who has defeated a thousand times a thousand men.	\N	\N	\N	1
41	0	Sri	Sarada Devi	2006-01-31 00:14:31-05	I tell you one thing ---- if you want peace of mind do not find fault with others.	\N	\N	\N	1
42	0	Lin	Yutang	2006-01-31 13:06:04-05	The secret of contentment is knowing how to enjoy what you have, and to be able to lose all desire for things beyond your reach.	\N	\N	\N	1
43	0	John	Lennon	2006-02-17 13:11:16-05	Life is what happens when you are busy making plans.	\N	\N	\N	1
44	0	\N	Anonymous	2006-02-17 13:10:59-05	Life is what happens when you are waiting for it to happen.	\N	\N	\N	1
45	0	\N	Nanak	2006-03-25 16:05:40-05	Man is not born free.  He is born to free himself.	\N	\N	\N	1
46	0	\N	Confucius	2006-03-25 16:06:16-05	To be wronged is nothing unless you continue to remember it.	\N	\N	\N	1
47	0	Shu	Ching	2006-04-13 16:52:38-04	Heaven-sent calamities you may stand up against, but you cannot survive those brought on by yourself.	\N	\N	\N	1
48	0	\N	Buddhist proverb	2006-04-13 16:53:18-04	When the student is ready, the teacher will appear.	\N	\N	\N	1
49	0	Kahlil	Gibran	2006-04-13 16:54:39-04	You give but little when you give of your possessions.  It is when you give of yourself that you truly give.	\N	\N	\N	1
50	0	Friedrich	Nietzsche	2006-05-25 11:34:46-04	When you look long into an abyss, the abyss looks into you.	\N	\N	\N	1
51	0	\N	Chinese proverb	2006-10-21 16:45:44-04	A lion uses all its might in attacking a rabbit.	\N	\N	\N	1
52	0	\N	Japanese saying	2006-10-21 16:46:46-04	He who pursues two hares catches neither.	\N	\N	\N	1
53	0	\N	Mencius	2006-10-21 17:19:58-04	Never has a man who has bent himself been able to make others straight.	\N	\N	\N	1
54	0	\N	Zen saying	2006-10-21 17:21:11-04	Before enlightenment I chopped wood and carried water; after enlightenment, I chopped wood and carried water.	\N	\N	\N	1
55	0	\N	Chinese proverb	2006-10-25 11:17:17-04	Your teacher can open the door, but you must enter by yourself.	\N	\N	\N	1
56	0	\N	Sengtsan	2006-11-27 23:56:39-05	Do not search for Truth.  Just stop having opinions.	\N	\N	\N	1
57	0	\N	Krishnamurti	2006-12-04 23:48:59-05	If we can really understand the problem, the answer will come out of it, because the answer is not separate from the problem.	\N	\N	\N	1
59	0	\N	Ramakrishna	2006-12-05 17:42:48-05	When the flower blooms, the bees come uninvited.	\N	\N	\N	1
61	0	\N	Buddhist proverb	2006-12-05 23:06:10-05	If we are facing in the right direction, all we have to do is keep on walking.	\N	\N	\N	1
62	0	\N	His-tang	2006-12-05 23:01:09-05	Although gold dust is precious, when it gets in your eyes it obstructs your vision.	\N	\N	\N	1
63	0	Chogyam	Trunpa	2006-12-05 23:07:37-05	Compassion automatically invites you to relate with people because you no longer regard people as a drain on your energy.	\N	\N	\N	1
65	0	\N	The Upanishads	2006-12-06 00:30:09-05	Speech is not what one should desire to understand.  One should know the speaker.	\N	\N	\N	1
66	0	\N	Buddha	2006-12-06 00:32:32-05	You will not be punished for your anger, you will be punished by your anger ... Let a man overcome anger by love.	\N	\N	\N	1
67	0	\N	Basho	2006-12-06 00:36:27-05	Do not seek to follow in the footsteps of the wise.  Seek what they sought.  	\N	\N	\N	1
68	0	Dalai	Lama	2006-12-06 00:36:27-05	The enemy teaches you inner strength.	\N	\N	\N	1
69	0	\N	Mencius	2006-12-07 23:49:15-05	The disease of men is this; that they neglect their own field, and go weed the fields of others, and what they require from others is great, while what they lay upon themselves is light.	\N	\N	\N	1
70	0	Kahlil	Gibran	2006-12-08 00:19:29-05	The biggest thing in today's sorrow is the memory of yesterday's joy.	\N	\N	\N	1
71	0	\N	Confucius	2006-12-08 00:43:06-05	The wise man looks for what is within, the fool for what is without.	\N	\N	\N	1
72	0	\N	Mencius	2006-12-08 01:12:07-05	Friendship is one mind in two bodies.	\N	\N	\N	1
73	0	\N	I Ching	2006-12-08 01:12:07-05	When the way comes to an end, then change -- having changed, you pass through.	\N	\N	\N	1
74	0	Mahatma	Gandhi	2006-12-08 01:30:38-05	In matters of conscience, the law of the majority has no place.	\N	\N	\N	1
75	0	\N	Chinese proverb	2006-12-08 01:38:50-05	A bit of fragrance always clings to the hand that gives you roses.	\N	\N	\N	1
76	0	Hui	Neng	2006-12-08 01:38:50-05	What I tell you is not [a] secret.  The secret is in you.	\N	\N	\N	1
77	0	\N	Chinese proverb	2006-12-08 01:51:57-05	When the heart is at ease, the body is healthy.	\N	\N	\N	1
78	0	Thich Nat	Hanh	2006-12-08 01:51:57-05	I vow to let go of all worries and anxiety in order to be light and free.	\N	\N	\N	1
79	0	Taisen	Deshimaru	2006-12-08 01:50:11-05	Time is not a line, but a series of now points.	\N	\N	\N	1
80	0	\N	Zen saying	2006-12-08 16:16:02-05	First thought, best thought.	\N	\N	\N	1
81	0	\N	Buddha	2006-12-08 16:21:12-05	Do not look at the faults of others, or what others have not done; observe what you yourself have done and not done.	\N	\N	\N	1
82	0	\N	Bodhidharma	2006-12-08 16:22:31-05	All know the way, few actually walk it.	\N	\N	\N	1
83	0	\N	Wumen	2006-12-08 17:29:38-05	If your mind isn't clouded by unnecessary things, this is the best season of your life.	\N	\N	\N	1
84	0	Mahatma	Gandhi	2006-12-08 22:02:25-05	The weak can never forgive.  Forgiveness is the attribute of the strong.	\N	\N	\N	1
85	0	Shunryu	Suzuki	2006-12-08 22:23:18-05	If your mind is empty, it is always ready for anything; it is open to everything.  In the beginner's mind there are many possibilities; in the expert's mind there are few.	\N	\N	\N	1
86	0	\N	Shinso	2006-12-08 22:24:42-05	No matter what road I travel, I'm going home.	\N	\N	\N	1
87	0	\N	Lao-tzu	2006-12-22 21:23:08-05	I observe myself and I come to know others.	\N	\N	\N	1
88	0	\N	Chinese proverb	2009-11-06 13:42:25-05	Learning is like rowing upstream; To not advance is to fall back.	\N	\N	\N	1
89	0	Alfred	Neuman	2016-01-12 15:47:16.622-05	What Me Worry?	\N	\N	\N	1
96	0	\N	Chinese proverb	2018-06-14 10:58:19.394-04	Learning is like rowing upstream: To not advace is to fall back.	\N	\N	\N	1
97	0	\N	Ryokan	2018-06-14 11:01:01.258-04	A single disturbed thought, creates ten thousand distractions.	\N	\N	\N	1
99	0	\N	Chinese proverb	2018-06-14 15:20:29.842-04	Tell me, I'll forget.  Show me, I may remember.  But involve me and I'll understand.	\N	\N	\N	1
100	0	\N	Zen saying	2018-06-14 15:21:45.329-04	First thought, best thought.	\N	\N	\N	1
101	0	\N	Ramakrishna	2018-06-15 10:44:14.54-04	When the flower blooms, the bees come uninvited.	\N	\N	\N	1
102	0	\N	Bodhidharma	2018-06-15 10:44:43.894-04	All know the way, few actually walk it.	\N	\N	\N	1
104	0	\N	Buddhist proverb	2018-06-15 15:54:17.974-04	If we are facing in the right direction, all we have to do is keep on walking.	\N	\N	\N	1
105	0	\N	Krishnamurti	2018-06-15 15:56:29.413-04	If we can really understand the problem, the answer will come out of it because the answer is not separate from the problem.	\N	\N	\N	1
106	0	\N	Wumen	2018-06-15 15:58:47.385-04	If your mind isn't clouded by unnecessary things, this is the best season of your life.	\N	\N	\N	1
108	0	Kahlil	Gibran	2018-07-17 17:08:00.761-04	The biggest thing in today's sorrow is the memory of yesterday's joy.	\N	\N	\N	1
107	0	Hui	Neng	2018-07-17 17:01:02.173-04	What I tell you is not secret.  The secret is in you.	{}	\N	\N	1
115	0	Clarence	Darrow	2018-07-18 08:04:00.787-04	The first half of our lives is ruined by our parents, and the second half by our children.	{"source": "unknown", "comment": "test comment", "category": 0, "graphic_url": "http://test.com", "quote_format": 0}	\N	\N	1
109	0	\N	His-tang	2018-07-17 17:23:37.486-04	Although gold dust is precious, when it gets in your eyes it obstructs your vision.	{"source": null, "comment": "test comment"}	\N	\N	1
111	0	Doug	Larson	2018-07-18 07:55:55.592-04	Accomplishing the impossible means only that the boss will add it to your regular duties.	{}	\N	\N	1
112	0	Doris	Egan	2018-07-18 07:57:53.604-04	You talk to God, you're religious. God talks to you, you're psychotic.	{"comment": "test comment"}	\N	\N	1
113	0	Harry S.	Truman	2018-07-18 07:59:11.586-04	It's a recession when your neighbor loses his job; it's a depression when you lose yours.	{"source": "unknown", "comment": "test comment"}	\N	\N	1
114	0	David	Russell	2018-07-18 08:00:18.869-04	The hardest thing to learn in life is which bridge to cross and which to burn.	{"source": "unknown", "comment": "test comment", "quote_format": 0}	\N	\N	1
116	0	Jean-Paul	Sartre	2018-07-18 10:24:30.996-04	Three o'clock is always too late or too early for anything you want to do.	{"source": "unknown", "comment": "test comment", "category": 0, "graphic_url": "http://test.com", "quote_format": 0}	\N	\N	1
117	0	P.J.	O'Rourke	2018-07-18 10:40:28.076-04	Drugs have taught an entire generation of Americans the metric system.	{"source": "unknown", "comment": "test comment", "category": 0, "graphic_url": "http://test.com", "quote_format": 0}	\N	\N	1
131	0	New	Testname	2018-07-19 10:14:59.055-04	A test record 2	{"source": "did change", "comment": "test comment", "category": 1, "graphic_url": "http://test.com", "quote_format": 2}	\N	\N	1
157	1			2018-12-21 17:47:06.167-05	When someone's character is not clear to you, look at that person's friends.	{"source": "Japanese proverb"}	2018-12-21 22:47:06.167	3	1
\.


--
-- Data for Name: topics; Type: TABLE DATA; Schema: public; Owner: gmarshall
--

COPY public.topics (id, name, parentid) FROM stdin;
1	Database	\N
2	User Interface	\N
3	Git	\N
4	Postgresql	1
5	Oracle	1
6	Container	\N
7	Docker	6
\.


--
-- Name: menuicons_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gmarshall
--

SELECT pg_catalog.setval('public.menuicons_id_seq', 29, false);


--
-- Name: menuitems_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gmarshall
--

SELECT pg_catalog.setval('public.menuitems_id_seq', 39, true);


--
-- Name: menupaths_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gmarshall
--

SELECT pg_catalog.setval('public.menupaths_id_seq', 12, true);


--
-- Name: notes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gmarshall
--

SELECT pg_catalog.setval('public.notes_id_seq', 3, true);


--
-- Name: pages_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gmarshall
--

SELECT pg_catalog.setval('public.pages_id_seq', 34, true);


--
-- Name: quotecategories_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gmarshall
--

SELECT pg_catalog.setval('public.quotecategories_id_seq', 3, true);


--
-- Name: quoteformat_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gmarshall
--

SELECT pg_catalog.setval('public.quoteformat_id_seq', 3, true);


--
-- Name: quotes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gmarshall
--

SELECT pg_catalog.setval('public.quotes_id_seq', 159, true);


--
-- Name: topics_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gmarshall
--

SELECT pg_catalog.setval('public.topics_id_seq', 7, true);


--
-- Name: applications applications_pkey; Type: CONSTRAINT; Schema: public; Owner: gmarshall
--

ALTER TABLE ONLY public.applications
    ADD CONSTRAINT applications_pkey PRIMARY KEY (id);


--
-- Name: menuicons menuicons_pkey; Type: CONSTRAINT; Schema: public; Owner: gmarshall
--

ALTER TABLE ONLY public.menuicons
    ADD CONSTRAINT menuicons_pkey PRIMARY KEY (id);


--
-- Name: menuitems menuitems_pkey; Type: CONSTRAINT; Schema: public; Owner: gmarshall
--

ALTER TABLE ONLY public.menuitems
    ADD CONSTRAINT menuitems_pkey PRIMARY KEY (id);


--
-- Name: menupaths menupaths_pkey; Type: CONSTRAINT; Schema: public; Owner: gmarshall
--

ALTER TABLE ONLY public.menupaths
    ADD CONSTRAINT menupaths_pkey PRIMARY KEY (id);


--
-- Name: notes notes_pkey; Type: CONSTRAINT; Schema: public; Owner: gmarshall
--

ALTER TABLE ONLY public.notes
    ADD CONSTRAINT notes_pkey PRIMARY KEY (id);


--
-- Name: pages pages_pkey; Type: CONSTRAINT; Schema: public; Owner: gmarshall
--

ALTER TABLE ONLY public.pages
    ADD CONSTRAINT pages_pkey PRIMARY KEY (id);


--
-- Name: quotecategories quotecategories_pkey; Type: CONSTRAINT; Schema: public; Owner: gmarshall
--

ALTER TABLE ONLY public.quotecategories
    ADD CONSTRAINT quotecategories_pkey PRIMARY KEY (id);


--
-- Name: quoteformats quoteformat_pkey; Type: CONSTRAINT; Schema: public; Owner: gmarshall
--

ALTER TABLE ONLY public.quoteformats
    ADD CONSTRAINT quoteformat_pkey PRIMARY KEY (id);


--
-- Name: quotes quotes_pkey; Type: CONSTRAINT; Schema: public; Owner: gmarshall
--

ALTER TABLE ONLY public.quotes
    ADD CONSTRAINT quotes_pkey PRIMARY KEY (id);


--
-- Name: topics topics_pkey; Type: CONSTRAINT; Schema: public; Owner: gmarshall
--

ALTER TABLE ONLY public.topics
    ADD CONSTRAINT topics_pkey PRIMARY KEY (id);


--
-- Name: menuicons_id_uindex; Type: INDEX; Schema: public; Owner: gmarshall
--

CREATE UNIQUE INDEX menuicons_id_uindex ON public.menuicons USING btree (id);


--
-- Name: menuitems_id_uindex; Type: INDEX; Schema: public; Owner: gmarshall
--

CREATE UNIQUE INDEX menuitems_id_uindex ON public.menuitems USING btree (id);


--
-- Name: menupaths_id_uindex; Type: INDEX; Schema: public; Owner: gmarshall
--

CREATE UNIQUE INDEX menupaths_id_uindex ON public.menupaths USING btree (id);


--
-- Name: notes_id_uindex; Type: INDEX; Schema: public; Owner: gmarshall
--

CREATE UNIQUE INDEX notes_id_uindex ON public.notes USING btree (id);


--
-- Name: quotecategories_id_uindex; Type: INDEX; Schema: public; Owner: gmarshall
--

CREATE UNIQUE INDEX quotecategories_id_uindex ON public.quotecategories USING btree (id);


--
-- Name: quoteformat_id_uindex; Type: INDEX; Schema: public; Owner: gmarshall
--

CREATE UNIQUE INDEX quoteformat_id_uindex ON public.quoteformats USING btree (id);


--
-- Name: topics_id_uindex; Type: INDEX; Schema: public; Owner: gmarshall
--

CREATE UNIQUE INDEX topics_id_uindex ON public.topics USING btree (id);


--
-- Name: pages fk_pages_applications; Type: FK CONSTRAINT; Schema: public; Owner: gmarshall
--

ALTER TABLE ONLY public.pages
    ADD CONSTRAINT fk_pages_applications FOREIGN KEY (appid) REFERENCES public.applications(id);


--
-- Name: menuitems menuitems_menuicons_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: gmarshall
--

ALTER TABLE ONLY public.menuitems
    ADD CONSTRAINT menuitems_menuicons_id_fk FOREIGN KEY (iconid) REFERENCES public.menuicons(id);


--
-- Name: menuitems menuitems_menupaths_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: gmarshall
--

ALTER TABLE ONLY public.menuitems
    ADD CONSTRAINT menuitems_menupaths_id_fk FOREIGN KEY (pathid) REFERENCES public.menupaths(id);


--
-- Name: quotes quotes_quotecategories_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: gmarshall
--

ALTER TABLE ONLY public.quotes
    ADD CONSTRAINT quotes_quotecategories_id_fk FOREIGN KEY (categoryid) REFERENCES public.quotecategories(id);


--
-- Name: quotes quotes_quoteformat_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: gmarshall
--

ALTER TABLE ONLY public.quotes
    ADD CONSTRAINT quotes_quoteformat_id_fk FOREIGN KEY (formatid) REFERENCES public.quoteformats(id);


--
-- Name: topics topics_topics_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: gmarshall
--

ALTER TABLE ONLY public.topics
    ADD CONSTRAINT topics_topics_id_fk FOREIGN KEY (parentid) REFERENCES public.topics(id);


--
-- PostgreSQL database dump complete
--

