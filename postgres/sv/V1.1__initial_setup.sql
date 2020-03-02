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
-- Name: attachmentaddlink(text, integer, integer); Type: FUNCTION; Schema: app; Owner: appowner
--

CREATE FUNCTION app.attachmentaddlink(uname text, idapptable integer, idtablerecord integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$

  DECLARE
    attachmentId integer;
    execStr text;
    newRecordId integer;

  BEGIN

    -- get attachment
    SELECT attach.id INTO attachmentId FROM app.attachments as attach WHERE attach.uniquename = uName;
    RAISE NOTICE 'attachmentId: %' , attachmentId;

    -- attachments record
    execStr := 'INSERT INTO app.tableattachments (id, apptableid, recordid, attachmentid, createdat, updatedat) VALUES ' ||
            '(DEFAULT, ' || idapptable || ', ' || idtablerecord || ', ' || attachmentId || ', now(), now()) ' ||
            'RETURNING app.tableattachments.id;';
    EXECUTE execStr INTO newRecordId;

    RAISE NOTICE '***** insert complete';

    RETURN newRecordId;
  END;
$$;


ALTER FUNCTION app.attachmentaddlink(uname text, idapptable integer, idtablerecord integer) OWNER TO appowner;

--
-- Name: attachmentaddupload(integer, text, text, text, integer); Type: FUNCTION; Schema: app; Owner: appowner
--

CREATE FUNCTION app.attachmentaddupload(iduser integer, path text, uniquename text, name text, size integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$

  DECLARE
    recordId integer;
    execStr text;

  BEGIN

    RAISE NOTICE 'userid: %' , iduser;
    -- attachments record
    execStr := 'INSERT INTO app.attachments (id, path, uniquename, name, size, createdat, updatedat) VALUES ' ||
               '(DEFAULT, ''' || path || ''', ''' || uniqueName || ''', ''' || name || ''', ' ||
               size || ', now(), now()) RETURNING app.attachments.id;';
    RAISE NOTICE 'execStr: %', execStr;
    EXECUTE execStr INTO recordId;

    -- user attachment
    EXECUTE 'INSERT INTO app.userattachments (id, userid, attachmentid, createdat, updatedat) VALUES ' ||
            '(DEFAULT, ' || iduser || ', ' || recordId || ', now(), now());';


    RETURN recordId;
  END;
$$;


ALTER FUNCTION app.attachmentaddupload(iduser integer, path text, uniquename text, name text, size integer) OWNER TO appowner;

--
-- Name: attachmentdeleteupload(text); Type: FUNCTION; Schema: app; Owner: appowner
--

CREATE FUNCTION app.attachmentdeleteupload(uname text) RETURNS integer
    LANGUAGE plpgsql
    AS $$

  DECLARE
    recordId integer;
     execStr text;

  BEGIN

    SELECT attach.id INTO recordId FROM app.attachments as attach WHERE attach.uniquename = uName;

    -- user attachment
    EXECUTE 'DELETE FROM app.userattachments WHERE attachmentid = ' || recordId || ';';

    -- attachments record
    execStr := 'DELETE FROM app.attachments WHERE id = ' || recordId || ';';
    EXECUTE execStr;

    RETURN recordId;
  END;
$$;


ALTER FUNCTION app.attachmentdeleteupload(uname text) OWNER TO appowner;

--
-- Name: attachmentupdate(integer, text, text, integer, integer); Type: FUNCTION; Schema: app; Owner: appowner
--

CREATE FUNCTION app.attachmentupdate(iduser integer, uniquename text, location text, idapptable integer, idtablerecord integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$

  DECLARE
    recordId integer;
    execStr text;

  BEGIN

    RAISE NOTICE 'userid: %' , iduser;

    -- update attachment location
    execStr := 'UPDATE app.attachments SET path = ''' || location ||
        ''' WHERE uniquename = ''' || uniqueName || ''' RETURNING app.attachments.id;';
    EXECUTE execStr INTO recordId;
    RAISE NOTICE 'recordId: %' , recordId;

    -- remove user attachment
    EXECUTE 'DELETE FROM app.userattachments WHERE userid = ' || iduser || ' AND attachmentid = ' || recordId || ';';

    -- attachments record
    -- user attachment
    EXECUTE 'INSERT INTO app.tableattachments (id, apptableid, recordid, attachmentid, createdat, updatedat) VALUES ' ||
            '(DEFAULT, ' || idapptable || ', ' || idtablerecord || ', ' || recordId || ', now(), now());';

    RAISE NOTICE '***** update complete';

    RETURN recordId;
  END;
$$;


ALTER FUNCTION app.attachmentupdate(iduser integer, uniquename text, location text, idapptable integer, idtablerecord integer) OWNER TO appowner;

--
-- Name: findbunos(jsonb); Type: FUNCTION; Schema: app; Owner: appowner
--

CREATE FUNCTION app.findbunos(jsonarray jsonb) RETURNS text[]
    LANGUAGE plpgsql
    AS $$

  DECLARE
    result text[] := ARRAY[]::text[];
    rec_field RECORD;
    name TEXT;
    cur_fields CURSOR(jsonarray JSON)
    FOR SELECT id from json_array_elements(jsonarray) as id;

  BEGIN

    IF (jsonarray::text = '[null]') THEN
      RETURN result;
    END IF;

    OPEN cur_fields(jsonarray);

    LOOP
      FETCH cur_fields into rec_field;
      EXIT WHEN NOT FOUND;

      IF (not rec_field.id is NULL) THEN
        raise notice 'id: %', rec_field.id;

        select buno.identifier INTO name from app.bunos buno where buno.id = rec_field.id::text::integer;
        result := array_append(result, name);
      END IF;

    END LOOP;  -- cursor records

    CLOSE cur_fields;

    raise notice 'result: %', array_to_string(result, ',');

   	RETURN result;
  END;
$$;


ALTER FUNCTION app.findbunos(jsonarray jsonb) OWNER TO appowner;

--
-- Name: findmls(jsonb); Type: FUNCTION; Schema: app; Owner: appowner
--

CREATE FUNCTION app.findmls(jsonarray jsonb) RETURNS text[]
    LANGUAGE plpgsql
    AS $$

  DECLARE
    result text[] := ARRAY[]::text[];
    rec_field RECORD;
    name TEXT;
    cur_fields CURSOR(jsonarray JSON)
    FOR SELECT id from json_array_elements(jsonarray) as id;

  BEGIN

    IF (jsonarray::text = '[null]') THEN
      RETURN result;
    END IF;

    OPEN cur_fields(jsonarray);

    LOOP
      FETCH cur_fields into rec_field;
      EXIT WHEN NOT FOUND;

      IF (not rec_field.id is NULL) THEN
        raise notice 'id: %', rec_field.id;

        select md.name INTO name from app.masterdata md where md.id = rec_field.id::text::integer;
        result := array_append(result, name);
      END IF;

    END LOOP;  -- cursor records

    CLOSE cur_fields;

    raise notice 'result: %', array_to_string(result, ',');

   	RETURN result;
  END;
$$;


ALTER FUNCTION app.findmls(jsonarray jsonb) OWNER TO appowner;

--
-- Name: findrolesbystatetransition(integer, integer); Type: FUNCTION; Schema: app; Owner: appowner
--

CREATE FUNCTION app.findrolesbystatetransition(idtable integer, idstatetransition integer) RETURNS SETOF integer[]
    LANGUAGE plpgsql
    AS $$

  BEGIN

    RETURN QUERY
      select ARRAY(
            select (tbl.jsondata->>'roleid')::integer
            from app.appdata tbl
            where tbl.apptableid = idtable
              and (tbl.jsondata @> '{"statetransitionid": null}' or (tbl.jsondata->>'statetransitionid')::integer = idstatetransition)
          )
      ;

  END;
$$;


ALTER FUNCTION app.findrolesbystatetransition(idtable integer, idstatetransition integer) OWNER TO appowner;

--
-- Name: findtransitionnotificationusers(integer, integer); Type: FUNCTION; Schema: app; Owner: appowner
--

CREATE FUNCTION app.findtransitionnotificationusers(idtable integer, idstatetransition integer) RETURNS TABLE(userid integer, firstname character varying, mi character varying, lastname character varying, email character varying)
    LANGUAGE plpgsql
    AS $$

  DECLARE
    execStr text;
    roles integer[];

  BEGIN
    execStr := 'select * from app.findRolesByStateTransition(' || idtable || ', ' || idstatetransition || ');';

    EXECUTE execStr INTO roles;
    RAISE NOTICE 'roles: %', roles;

    RETURN QUERY
    select * from app.getUsersInRoles(roles);

  END
$$;


ALTER FUNCTION app.findtransitionnotificationusers(idtable integer, idstatetransition integer) OWNER TO appowner;

--
-- Name: getappusers(integer); Type: FUNCTION; Schema: app; Owner: appowner
--

CREATE FUNCTION app.getappusers(idapp integer) RETURNS TABLE(userid integer, firstname character varying, mi character varying, lastname character varying, email character varying, roleid integer, rolename character varying, appname character varying)
    LANGUAGE plpgsql
    AS $$

  DECLARE

  BEGIN
    RETURN QUERY
    select u.id as userid, u.firstname, u.mi, u.lastname, u.email, role.id as roleid, role.name as rolename, app.name as appname
    from metadata.applications app,
         app.roles role,
         app.roleassignments ra,
         app.users as u
    where app.id = idapp
    and role.appid = app.id
    and ra.roleid = role.id
    and u.id = ra.userid
    UNION
    select u.id as userid, u.firstname, u.mi, u.lastname, u.email, role.id as roleid, role.name as rolename, app.name as appname
    from metadata.applications app,
         app.roles role,
         app.roleassignments ra,
         app.groups g,
         app.usergroups ug,
         app.users as u
    where app.id = idapp
    and role.appid = app.id
    and ra.roleid = role.id
    and g.id = ra.groupid
    and ug.groupid = g.id
    and u.id = ug.userid
    order by roleid, userid;
  END
$$;


ALTER FUNCTION app.getappusers(idapp integer) OWNER TO appowner;

--
-- Name: getcolumnvalues(integer, integer); Type: FUNCTION; Schema: app; Owner: appowner
--

CREATE FUNCTION app.getcolumnvalues(idcolumn integer, iduser integer DEFAULT NULL::integer) RETURNS json
    LANGUAGE plpgsql
    AS $$

  DECLARE
    rec RECORD;
    tbl RECORD;
    resp JSON;
    result JSON;
    colSelect TEXT;
    colLabel TEXT;
    relationColName TEXT;
    execStr text;
    selectStr TEXT;
    tableName TEXT;
    fromStr TEXT;
    whereStr TEXT := '';
    whereStr2 TEXT;
	  userRoles integer[] := metadata.getUserRolesArray(iduser);

  BEGIN
--     CREATE TEMP TABLE lookup(tablename VARCHAR);

    SELECT id, apptableid, columnname, label, datatypeid, length, jsonfield, createdat, updatedat, mastertable,
           mastercolumn, name, regexp_replace(masterdisplay, '''', '''''', 'g') as masterdisplay,
           displayorder, active, allowedroles
           INTO rec FROM metadata.appcolumns WHERE id = idcolumn;

    RAISE NOTICE 'userRoles: %', userRoles;
    RAISE NOTICE 'allowedroles: %  intersection: %', rec.allowedroles, (rec.allowedroles && userRoles);
    IF(rec.allowedroles is not null AND rec.allowedroles <> '{}' AND (rec.allowedroles && userRoles) = false) THEN
      RETURN '[]';
    END IF;

    SELECT * INTO tbl FROM metadata.apptables tbl WHERE id = rec.apptableid;
    tableName := tbl.tablename;
    RAISE NOTICE 'tableName: %', tableName;
    IF (tableName = 'appdata' OR tableName = 'masterdata') THEN
      whereStr := ' tbl.apptableid = ' || rec.apptableid;
    ELSIF (tableName != 'users') THEN
      whereStr := ' tbl.appid = ' || tbl.appid;
    END IF;

    SELECT row_to_json(rec) INTO result;
--     result := regexp_replace(result, '''', '''''', 'g');
    RAISE NOTICE 'result:';
    RAISE NOTICE '%', result;

  RAISE NOTICE 'start call ------------------------------------------------------------';
    execStr := 'SELECT * from app.getQueryParamsForColumn(''' || result || ''', true);';
    EXECUTE execStr INTO resp;
  RAISE NOTICE 'done call ------------------------------------------------------------';

    selectStr := resp->>'selectStr';
    fromStr := resp->>'fromStr';
    whereStr2 := resp->>'whereStr';
    colSelect := resp->>'colSelect';
    colLabel := resp->>'colLabel';
    relationColName := resp->>'relationColName';

    RAISE NOTICE '======================================';
    RAISE NOTICE 'selectStr: %', selectStr;
    RAISE NOTICE 'fromStr: %', fromStr;
    RAISE NOTICE 'whereStr2: %', whereStr2;
    RAISE NOTICE 'colSelect: %', colSelect;
    RAISE NOTICE 'colLabel: %', colLabel;
    RAISE NOTICE 'relationColName: %', relationColName;
    RAISE NOTICE '======================================';

--     DROP TABLE lookup;

    IF (rec.masterTable IS NOT NULL) THEN
      selectStr := relationColName || ' as value, ' || regexp_replace(selectStr, colLabel, ' as name', 'g');
      IF (length(whereStr2) > 0) THEN
        whereStr := whereStr || ' and ' || whereStr2;
      END IF;
    ELSE
      selectStr := colSelect || ' as value, ' || colSelect || ' as name';
    END IF;
    IF(whereStr != '') THEN
      whereStr := ' WHERE ' || whereStr;
    END IF;

    RAISE NOTICE '======================================';
    RAISE NOTICE 'tableName: %', tableName;
    RAISE NOTICE 'selectStr: %', selectStr;
    RAISE NOTICE 'fromStr: %', fromStr;
    RAISE NOTICE 'whereStr: %', whereStr;
    RAISE NOTICE '======================================';

    execStr := 'SELECT DISTINCT ON (name) ' || selectStr ||
      ' FROM app.' || tableName || ' as tbl' || fromStr || whereStr ||
      ' ORDER BY name';

    RAISE NOTICE 'execStr:';
    RAISE NOTICE '%', execStr;

    EXECUTE 'SELECT array_to_json(array_agg(row_to_json(t))) FROM (' || execStr || ') t;' INTO result;
    RETURN result;
  END;
$$;


ALTER FUNCTION app.getcolumnvalues(idcolumn integer, iduser integer) OWNER TO appowner;

--
-- Name: getqueryparamsforcolumn(json, boolean); Type: FUNCTION; Schema: app; Owner: appowner
--

CREATE FUNCTION app.getqueryparamsforcolumn(recobj json, idandref boolean DEFAULT false) RETURNS json
    LANGUAGE plpgsql
    AS $$
DECLARE
  tableName        TEXT;
  columnName       TEXT;
  masterTable      TEXT;
  masterColumn     TEXT;
  masterDisplay    TEXT;
  datatype         TEXT;
  isJsonfield      BOOLEAN;
  colLabel         TEXT;
  colTable         TEXT;
  colSelect        TEXT;
  selectStr        TEXT := '';
  fromStr          TEXT := '';
  whereStr         TEXT := '';
  relationColName  TEXT;
  coalesceStr      TEXT;
  masterTableCount INTEGER;
  masterTableName  TEXT;
  masterdisplayPos INTEGER;
  attrKeys         text[];
  attrVals         text[];

BEGIN
  CREATE TEMP TABLE lookup(tablename VARCHAR);

  columnName := recObj ->> 'columnname';
  masterTable := recObj ->> 'mastertable';
  masterColumn := recObj ->> 'mastercolumn';
  masterDisplay := recObj ->> 'masterdisplay';
  datatype := recObj ->> 'datatype';
  isJsonfield := CAST(recObj ->> 'jsonfield' AS BOOLEAN);
  RAISE NOTICE '------------------------------------------------------------';
  RAISE NOTICE 'columnname: %', columnName;
  RAISE NOTICE 'recObj: %', recObj;
  RAISE NOTICE 'recObj->jsonfield: %', isJsonfield;
  colLabel := '';
  colSelect := '';
  colTable := 'tbl.';

  IF (isJsonfield = true) THEN
    -- =========================================================
    -- json column
    -- =========================================================
    colTable := '';
    colSelect := 'tbl.jsondata->>''' || columnName || '''';
    colLabel := ' as ' || columnName;

    IF (masterTable IS NOT NULL) THEN
      IF (idAndRef) THEN
        -- add ID information
        selectStr := colTable || colSelect || colLabel;
        -- strip id from end of columnname
        colLabel := left(colLabel, -2);
      END IF;

      -- =========================================================
      -- related table
      -- =========================================================
      IF (datatype = 'integer[]') THEN
        -- =========================================================
        -- array of references
        -- =========================================================
        RAISE NOTICE '************************* datatype: %', datatype;
        -- ARRAY( SELECT name FROM app.masterdata WHERE id IN ( SELECT jsonb_array_elements_text(tbl.jsondata->'mls')::integer ) ) as mls,
        colTable := 'ARRAY(SELECT ' || masterDisplay ||
                    ' FROM app.' || masterTable ||
                    ' WHERE id IN ( SELECT jsonb_array_elements_text(tbl.jsondata->''' || columnName ||
                    ''')::integer ) )';
        RAISE NOTICE 'colTable: %', colTable;
        colSelect := '';
      ELSE
        -- =========================================================
        -- single reference
        -- =========================================================
        -- check for whether there are multiple references to the same table
--          INSERT INTO lookup (tablename) VALUES (masterTable);
        EXECUTE 'INSERT INTO lookup (tablename) VALUES (''' || masterTable || ''');';
        masterTableName := masterTable;
--          SELECT COUNT(*) INTO masterTableCount FROM lookup WHERE lookup.tablename = rec_field.mastertable;
        EXECUTE 'SELECT COUNT(*) FROM lookup WHERE lookup.tablename = ''' || masterTable ||
                ''';' INTO masterTableCount;
        RAISE NOTICE '************* count: %', masterTableCount;
        IF (masterTableCount > 1) THEN
          -- there are multiple references to the same table so make them unique using the Count
          masterTableName := masterTableName || masterTableCount;
        END IF;
        IF (masterDisplay ~ '||') THEN
          -- TODO: process compound display: add mastertable to each column, create procedure, provide logic for standard columns as well
          colSelect := regexp_replace(masterDisplay, masterTable, masterTableName, 'g');
        ELSE
          colTable := masterTableName || '.';
          colSelect := regexp_replace(masterDisplay, masterTable, masterTableName, 'g');
        END IF;
        relationColName = 'tbl.jsondata->>''' || columnName || '''';
        coalesceStr := 'CAST(coalesce(' || relationColName || ', ''0'') AS INTEGER)';
        fromStr := fromStr || ' LEFT OUTER JOIN app.' || masterTable || ' as ' || masterTableName ||
                   ' ON ' || masterTableName || '.' || masterColumn || ' = ' || coalesceStr;
        whereStr := masterTableName || '.id = ' || coalesceStr;
      END IF;
    END IF;

  ELSE
    -- =========================================================
    -- standard column
    -- =========================================================
    colSelect := columnName;
    colLabel := ' as ' || columnName;

    IF (masterTable IS NOT NULL) THEN
      IF (idAndRef) THEN
        -- add ID information
        selectStr := colTable || colSelect || colLabel;
        -- strip id from end of columnname
        colLabel := left(colLabel, -2);
      END IF;

      IF (datatype = 'integer[]') THEN
        -- =========================================================
        -- array of references
        -- =========================================================
        RAISE NOTICE '************************* datatype: %', datatype;
        -- ARRAY( SELECT name FROM app.masterdata WHERE id IN ( SELECT jsonb_array_elements_text(tbl.jsondata->'mls')::integer ) ) as mls,
        colTable := 'ARRAY(SELECT ' || masterDisplay ||
                    ' FROM app.' || masterTable ||
                    ' WHERE id IN ( SELECT unnest(tbl.' || columnName || ') ) )';
        RAISE NOTICE 'colTable: %', colTable;
        colSelect := '';
      ELSE
        -- =========================================================
        -- single reference
        -- =========================================================
--         INSERT INTO lookup (tablename) VALUES (rec_field.mastertable);
        EXECUTE 'INSERT INTO lookup (tablename) VALUES (''' || masterTable || ''');';
        masterTableName := masterTable;
--         SELECT COUNT(*) INTO masterTableCount FROM lookup WHERE lookup.tablename = masterTable;
        EXECUTE 'SELECT COUNT(*) FROM lookup WHERE lookup.tablename = ''' || masterTable ||
                ''';' INTO masterTableCount;
        IF (masterTableCount > 1) THEN
          masterTableName := masterTableName || masterTableCount;
        END IF;
        -- =========================================================
        -- related table
        -- =========================================================
        IF (masterTable = 'apptables') THEN
          RAISE NOTICE '**** mastertable = apptables';
        ELSE
          colTable := masterTableName || '.';

          colSelect := regexp_replace(masterDisplay, masterTable, masterTableName, 'g');
          relationColName := 'tbl.' || columnName;
          fromStr := fromStr || ' LEFT OUTER JOIN app.' || masterTable || ' as ' || masterTableName ||
                     ' ON ' || masterTableName || '.' || masterColumn || ' = ' || relationColName;
          IF (POSITION('.' in masterDisplay) > 0) THEN
            RAISE NOTICE '****************** masterdisplay: %  pos: %', masterDisplay, masterdisplayPos;
            colTable := '';
          END IF;
        END IF;
      END IF;
    END IF;

  END IF;

  IF (columnName != 'jsondata') THEN
    selectStr := colTable || colSelect || colLabel;
  END IF;

  DROP TABLE lookup;

  RAISE NOTICE '***** columnName: %', columnName;
  attrKeys := ARRAY ['tableName', 'selectStr', 'fromStr', 'whereStr', 'colSelect', 'colLabel', 'relationColName'];
  attrVals := ARRAY [tableName, selectStr, fromStr, whereStr, colSelect, colLabel, relationColName];
  return json_object(attrKeys::text[], attrVals::text[]);
END;
$$;


ALTER FUNCTION app.getqueryparamsforcolumn(recobj json, idandref boolean) OWNER TO appowner;

--
-- Name: getuserroles(integer); Type: FUNCTION; Schema: app; Owner: appowner
--

CREATE FUNCTION app.getuserroles(iduser integer) RETURNS TABLE(roleid integer, rolename character varying, userid integer, groupid integer, groupname character varying, appid integer)
    LANGUAGE plpgsql
    AS $$

  DECLARE

  BEGIN
    RETURN QUERY
    select ra.roleid, r.name as rolename, ra.userid, ra.groupid, null as groupname, r.appid
    from app.roleassignments ra,
         app.roles r
    where ra.userid = iduser
    and r.id = ra.roleid
    UNION
    select ra.roleid, r.name as rolename, ra.userid, ra.groupid, g.name as groupname, r.appid
    from app.usergroups ug,
         app.groups g,
         app.roleassignments ra,
         app.roles r
    where ug.userid = iduser
    and g.id = ug.groupid
    and ra.groupid = g.id
    and r.id = ra.roleid
    order by roleid;
  END
$$;


ALTER FUNCTION app.getuserroles(iduser integer) OWNER TO appowner;

--
-- Name: getuserrolesasarray(integer); Type: FUNCTION; Schema: app; Owner: appowner
--

CREATE FUNCTION app.getuserrolesasarray(iduser integer) RETURNS integer[]
    LANGUAGE plpgsql
    AS $$

  DECLARE
	  userRoles integer[] := ARRAY[]::integer[];
	  user_role RECORD;
	  user_roles CURSOR(id INTEGER) FOR SELECT * FROM app.getUserRoles(id);

  BEGIN
    IF (iduser IS NOT NULL) THEN
      OPEN user_roles(iduser);
      LOOP
        FETCH user_roles INTO user_role;
        EXIT WHEN NOT FOUND;
        RAISE NOTICE 'roleid: %', user_role.roleid;
        userRoles := array_append(userRoles, user_role.roleid);
      END LOOP;
    END IF;

    RETURN userRoles;
  END
$$;


ALTER FUNCTION app.getuserrolesasarray(iduser integer) OWNER TO appowner;

--
-- Name: getusersinroles(integer[]); Type: FUNCTION; Schema: app; Owner: appowner
--

CREATE FUNCTION app.getusersinroles(roleids integer[]) RETURNS TABLE(userid integer, firstname character varying, mi character varying, lastname character varying, email character varying)
    LANGUAGE plpgsql
    AS $$

  DECLARE

  BEGIN
    RETURN QUERY
    select
      ra.userid as userid,
      u.firstname,
      u.mi,
      u.lastname,
      u.email
    from
      app.roleassignments ra,
      app.users u
    where
      ra.roleid = ANY(roleids)
      and u.id = ra.userid
    UNION
    select
      ug.userid as userid,
      u.firstname,
      u.mi,
      u.lastname,
      u.email
    from
      app.roleassignments ra,
      app.usergroups ug,
      app.users u
    where
      ra.roleid = ANY(roleids)
      and ug.groupid = ra.groupid
      and u.id = ug.userid
    order by lastname, firstname, mi;
  END
$$;


ALTER FUNCTION app.getusersinroles(roleids integer[]) OWNER TO appowner;

--
-- Name: issuetypesselectvalues(numeric); Type: FUNCTION; Schema: app; Owner: appowner
--

CREATE FUNCTION app.issuetypesselectvalues(idapp numeric) RETURNS TABLE(label character varying, value integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
		RETURN QUERY
		SELECT
      it.label,
      it.id as value
    FROM
      app.issuetypes it
    WHERE
      it.appid = idapp
    ORDER BY it.label;
	END;
$$;


ALTER FUNCTION app.issuetypesselectvalues(idapp numeric) OWNER TO appowner;

--
-- Name: roleassignmentsbulkupdate(integer, integer[], integer[], integer[], integer[]); Type: FUNCTION; Schema: app; Owner: appowner
--

CREATE FUNCTION app.roleassignmentsbulkupdate(idrole integer, addgroupids integer[], removegroupids integer[], adduserids integer[], removeuserids integer[]) RETURNS json
    LANGUAGE plpgsql
    AS $$

  DECLARE
    result JSON;
    groupid integer;
    userid integer;

  BEGIN
    -- add groups
    FOREACH groupid IN ARRAY addgroupids
    LOOP
      RAISE NOTICE 'insert roleid: %  groupid: %' , idrole, groupid;
      EXECUTE 'INSERT INTO app.roleassignments (id, roleid, groupid, createdat, updatedat) VALUES' ||
              '(DEFAULT, ' || idrole || ', ' || groupid || ', ''' || now() || ''', ''' || now() || ''');';
    END LOOP;

    -- remove groups
    FOREACH groupid IN ARRAY removegroupids
    LOOP
      RAISE NOTICE 'remove roleid: %  groupid: %' , idrole, groupid;
      EXECUTE 'DELETE FROM app.roleassignments WHERE roleid = ' || idrole || ' AND groupid = ' || groupid || ';';
    END LOOP;

    -- add users
    FOREACH userid IN ARRAY adduserids
    LOOP
      RAISE NOTICE 'insert roleid: %  userid: %' , idrole, userid;
      EXECUTE 'INSERT INTO app.roleassignments (id, roleid, userid, createdat, updatedat) VALUES' ||
              '(DEFAULT, ' || idrole || ', ' || userid || ', ''' || now() || ''', ''' || now() || ''');';

    END LOOP;

    -- remove users
    FOREACH userid IN ARRAY removeuserids
    LOOP
      RAISE NOTICE 'remove roleid: %  userid: %' , idrole, userid;
      EXECUTE 'DELETE FROM app.roleassignments WHERE roleid = ' || idrole || ' AND userid = ' || userid || ';';
    END LOOP;

    EXECUTE 'SELECT row_to_json(t) FROM ( SELECT COUNT(*) FROM app.roleassignments WHERE roleid = ' || idrole || ') t;' INTO result;
	  RETURN result;
  END;
$$;


ALTER FUNCTION app.roleassignmentsbulkupdate(idrole integer, addgroupids integer[], removegroupids integer[], adduserids integer[], removeuserids integer[]) OWNER TO appowner;

--
-- Name: supportfindall(integer); Type: FUNCTION; Schema: app; Owner: appowner
--

CREATE FUNCTION app.supportfindall(iduser integer DEFAULT NULL::integer) RETURNS TABLE(id integer, title character varying, value character varying, hours character varying, appid integer, appname character varying, userid integer, displayorder integer, firstname character varying, mi character varying, lastname character varying, phone character varying, email character varying)
    LANGUAGE plpgsql
    AS $$

DECLARE
  userRoles integer[] := ARRAY []::integer[];
  user_role RECORD;
  user_roles CURSOR (id INTEGER) FOR SELECT * FROM app.getUserRoles(id);
  apps CURSOR (userRoles INTEGER[]) FOR
    SELECT DISTINCT ON (items.appid)
      items.appid
    FROM metadata.menuitems items
           LEFT OUTER JOIN metadata.pages as page ON items.pageid = page.id
    WHERE items.pageid <> 0 AND (page.allowedroles is null OR page.allowedroles = '{}' OR page.allowedroles && userRoles);
  app_rec RECORD;
  userApps integer[] := ARRAY []::integer[];

BEGIN
  IF (iduser IS NOT NULL) THEN
    OPEN user_roles(iduser);
    LOOP
      FETCH user_roles INTO user_role;
      EXIT WHEN NOT FOUND;
      userRoles := array_append(userRoles, user_role.roleid);
    END LOOP;
    CLOSE user_roles;
  END IF;
  RAISE NOTICE 'userRoles: %', userRoles;

  OPEN apps(userRoles);
  LOOP
    FETCH apps INTO app_rec;
    EXIT WHEN NOT FOUND;
    userApps := array_append(userApps, app_rec.appid);
  END LOOP;
  CLOSE apps;
  RAISE NOTICE 'userApps: %', userApps;

  RETURN QUERY
    SELECT support.id,
           support.title,
           support.value,
           support.hours,
           support.appid,
           apps.name as appname,
           support.userid,
           support.displayorder,
           users.firstname,
           users.mi,
           users.lastname,
           users.phone,
           users.email
    FROM app.support support
         LEFT OUTER JOIN app.users ON users.id = support.userid
         LEFT OUTER JOIN metadata.applications as apps on apps.id = support.appid
    WHERE support.appid = ANY(userApps)
    ORDER BY support.appid, support.displayorder;
END;
$$;


ALTER FUNCTION app.supportfindall(iduser integer) OWNER TO appowner;

--
-- Name: tdfindallwithdeps(numeric, numeric); Type: FUNCTION; Schema: app; Owner: appowner
--

CREATE FUNCTION app.tdfindallwithdeps(idtable numeric, iddeps numeric) RETURNS json
    LANGUAGE plpgsql
    AS $$

  DECLARE
    result JSON;
    execStr TEXT;

	BEGIN

    execStr := 'select
      td.jsondata->>''td'' as TD,
      td.jsondata->>''tcto'' as TCTO,
      td.jsondata->>''ecp'' as ECP,
      td.jsondata->>''subject'' as Subject,
      td.jsondata->>''mls'' as ml_ids,
      (select * from app.findMls(td.jsondata->''mls'')) as mls,
      link.jsondata->''tdid'' as tdid,
      link.jsondata->''dependencyid'' as depid,
      link.jsondata->''complianceid'' as complianceid,
      comp.name as compliance,
      comp.jsondata->''displayorder'' as complianceorder,
      link.jsondata->''purpose'' as link_purpose,
      dep.jsondata->>''td'' as dep_td,
      dep.jsondata->>''tcto'' as dep_tcto,
      dep.jsondata->>''subject'' as dep_subject,
      dep.jsondata->>''mls'' as dep_ml_ids,
      (select * from app.findMls(dep.jsondata->''mls'')) as dep_mls,
      link.jsondata->>''reference'' as ref,
      link.jsondata->>''notes'' as notes,
      (select * from app.findBunos(link.jsondata->''bunos'')) as bunos
      from
      app.appdata td
      left outer join app.appdata as link on link.apptableid = ' || iddeps || ' and CAST(link.jsondata->>''tdid'' AS INTEGER) = td.id
      left outer join app.appdata as dep on dep.apptableid = ' || idtable || ' and dep.id = CAST(link.jsondata->>''dependencyid'' AS INTEGER)
      left outer join app.masterdata as comp on comp.id = CAST(link.jsondata->>''complianceid'' AS INTEGER)
      where
      td.apptableid = ' || idtable || '
      order by TD, complianceorder';

    RAISE NOTICE '----------------------------------------';
    RAISE NOTICE 'execStr: %', execStr;
    RAISE NOTICE '----------------------------------------';
    EXECUTE 'SELECT array_to_json(array_agg(row_to_json(t))) FROM (' || execStr || ') t;' INTO result;
    RAISE NOTICE 'result: %', result;

    IF (result is null) THEN
  		RETURN '{}';
    ELSE
    	RETURN result;
	  END IF;

  END;
$$;


ALTER FUNCTION app.tdfindallwithdeps(idtable numeric, iddeps numeric) OWNER TO appowner;

--
-- Name: usergroupsbulkupdate(integer, integer[], integer[]); Type: FUNCTION; Schema: app; Owner: appowner
--

CREATE FUNCTION app.usergroupsbulkupdate(iduser integer, addids integer[], removeids integer[]) RETURNS json
    LANGUAGE plpgsql
    AS $$

  DECLARE
    result JSON;
    groupid integer;

  BEGIN
    FOREACH groupid IN ARRAY addids
    LOOP

      RAISE NOTICE 'insert userid: %  groupid: %' , iduser, groupid;
      EXECUTE 'INSERT INTO app.usergroups (id, userid, groupid, createdat, updatedat) VALUES' ||
              '(DEFAULT, ' || iduser || ', ' || groupid || ', ''' || now() || ''', ''' || now() || ''');';

    END LOOP;

    FOREACH groupid IN ARRAY removeids
    LOOP

      RAISE NOTICE 'remove userid: %  groupid: %' , iduser, groupid;
      EXECUTE 'DELETE FROM app.usergroups WHERE userid = ' || iduser || ' AND groupid = ' || groupid || ';';

    END LOOP;

--     RETURN array_length(groupids, 1);
    EXECUTE 'SELECT row_to_json(t) FROM ( SELECT COUNT(*) FROM app.usergroups WHERE userid = ' || iduser || ') t;' INTO result;
	  RETURN result;
  END;
$$;


ALTER FUNCTION app.usergroupsbulkupdate(iduser integer, addids integer[], removeids integer[]) OWNER TO appowner;

--
-- Name: workflowstatebyid(numeric); Type: FUNCTION; Schema: app; Owner: appowner
--

CREATE FUNCTION app.workflowstatebyid(idissuetype numeric) RETURNS TABLE(issuetype character varying, status character varying, wf_stat character varying, id integer, name character varying, description character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
		RETURN QUERY
    select
      iss.label as issuetype,
      stat.label as status,
      wf_stat.name as wf_stat,
      s.id,
      s.name,
      s.description
    from app.workflow_states as s
    left join app.issuetypes as iss on iss.id = s.issuetypeid
    left join app.status as stat on stat.id = s.statusid
    left join app.workflow_status wf_stat on wf_stat.id = s.workflowstatusid
    where issuetypeid = idissuetype
    order by status, wf_stat;
	END;
$$;


ALTER FUNCTION app.workflowstatebyid(idissuetype numeric) OWNER TO appowner;

--
-- Name: workflowstatetransitionbyid(numeric); Type: FUNCTION; Schema: app; Owner: appowner
--

CREATE FUNCTION app.workflowstatetransitionbyid(idissuetype numeric) RETURNS TABLE(issuetype integer, status character varying, ws_status character varying, sinname character varying, stateinid integer, initialstate boolean, action character varying, stateoutid integer, soutname character varying, label character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
		RETURN QUERY
      select
        sin.issuetypeid as issuetype,
        stat.label as status,
        ws.name as ws_status,
        sin.name as sinname,
        st.stateinid,
        sin.initialstate,
        a.name as action,
        st.stateoutid,
        sout.name as soutname,
        st.label
      from
        app.workflow_statetransitions st
        left join app.workflow_states as sin on sin.id = st.stateinid
        left join app.workflow_states as sout on sout.id = st.stateoutid
        left join app.workflow_actions as a on a.id = st.actionid
        left join app.status as stat on stat.id = sin.statusid
        left join app.workflow_status ws on ws.id = sin.workflowstatusid
      where sin.issuetypeid = idissuetype
      order by st.stateinid, st.stateoutid;
	END;
$$;


ALTER FUNCTION app.workflowstatetransitionbyid(idissuetype numeric) OWNER TO appowner;

--
-- Name: actionfindall(); Type: FUNCTION; Schema: metadata; Owner: appowner
--

CREATE FUNCTION metadata.actionfindall() RETURNS TABLE(pageformid integer, pagedescr character varying, eventid integer, eventname character varying, actionid integer, actionname character varying, actiondata jsonb)
    LANGUAGE plpgsql
    AS $$
BEGIN
		RETURN QUERY
		SELECT
      fea.pageformid,
      pf.description as pagedescr,
      fea.eventid,
      e.name as eventname,
      fea.actionid,
      a.name as actionname,
      fea.actiondata
    FROM
      metadata.formeventactions fea,
      metadata.pageforms pf,
      metadata.events e,
      metadata.actions a
    WHERE pf.id = fea.pageformid
      AND e.id = fea.eventid
      AND a.id = fea.actionid
    ORDER BY fea.pageformid;
	END;
$$;


ALTER FUNCTION metadata.actionfindall() OWNER TO appowner;

--
-- Name: addtablecolumns(numeric, text); Type: FUNCTION; Schema: metadata; Owner: appowner
--

CREATE FUNCTION metadata.addtablecolumns(idtbl numeric, tblname text) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
  records_added integer := 0;
  tabletype text;
  rec_field RECORD;
  temp_rec RECORD;
  cur_fields CURSOR(tname TEXT)
  FOR SELECT column_name as columnname, data_type as datatype from information_schema.columns WHERE table_schema = 'app' AND table_name = tblname;

  BEGIN

    RAISE NOTICE 'id: %  tablename: %', idtbl, tblname;

    select type.name into tabletype from metadata.systemtables tbl, metadata.systemtabletypes type where tbl.tablename = tblname and type.id = tbl.systemtabletypeid;

    RAISE NOTICE 'tabletype: %', tabletype;

--     IF (tabletype = 'lookup' OR tabletype = 'issue' OR tabletype = 'customLookup') THEN
      OPEN cur_fields(tblname);

      LOOP
        FETCH cur_fields into rec_field;
        EXIT WHEN NOT FOUND;

        CASE rec_field.columnname
          WHEN 'appid' THEN
          WHEN 'createdat' THEN
          WHEN 'updatedat' THEN
          ELSE
            RAISE NOTICE 'columnname: %  datatype: %', rec_field.columnname, rec_field.datatype;
            select * into temp_rec from metadata.columntemplate where metadata.columntemplate.tablename = tblname and metadata.columntemplate.columnname = rec_field.columnname;
            RAISE NOTICE 'tablename: %  columnname: %', temp_rec.tablename, temp_rec.columnname;
            IF (temp_rec.columnname = rec_field.columnname) THEN
              INSERT INTO metadata.appcolumns (id, apptableid, columnname, label, datatypeid, length, jsonfield, createdat,
                                               updatedat, mastertable, mastercolumn, name, masterdisplay, displayorder, active)
              VALUES (DEFAULT, idtbl, rec_field.columnname, temp_rec.label, temp_rec.datatypeid, temp_rec.length, temp_rec.jsonfield,
                         now(), now(), temp_rec.mastertable, temp_rec.mastercolumn, temp_rec.name, temp_rec.masterdisplay, null, true);
              records_added := records_added + 1;
            END IF;
        END CASE;
      END LOOP;
--     END IF;

    RETURN records_added;
  END;
$$;


ALTER FUNCTION metadata.addtablecolumns(idtbl numeric, tblname text) OWNER TO appowner;

--
-- Name: appbunosbulkadd(integer, integer[]); Type: FUNCTION; Schema: metadata; Owner: appowner
--

CREATE FUNCTION metadata.appbunosbulkadd(idapp integer, bunoids integer[]) RETURNS integer
    LANGUAGE plpgsql
    AS $$

  DECLARE
    bunoid integer;

  BEGIN
    FOREACH bunoid IN ARRAY bunoids
    LOOP

      RAISE NOTICE 'appid: %  bunoid: %' , idapp, bunoid;
      EXECUTE 'INSERT INTO app.appbunos (id, appid, bunoid, createdat, updatedat) VALUES' ||
              '(DEFAULT, ' || idapp || ', ' || bunoid || ', ''' || now() || ''', ''' || now() || ''');';

    END LOOP;

    RETURN array_length(bunoids, 1);
  END;
$$;


ALTER FUNCTION metadata.appbunosbulkadd(idapp integer, bunoids integer[]) OWNER TO appowner;

--
-- Name: appdataadd(integer, integer[], text[]); Type: FUNCTION; Schema: metadata; Owner: appowner
--

CREATE FUNCTION metadata.appdataadd(idtable integer, fieldids integer[], fieldvals text[]) RETURNS json
    LANGUAGE plpgsql
    AS $$

  DECLARE
    resp JSON;
    result JSON;
    id_val integer;
    execStr text;
    tableName text;
    tableCol text;
    appId integer;
    fieldsStr text := '';
    valuesStr text := '';
    apptableFieldStr text := '';
    apptableValueStr text := '';

    cur_fields CURSOR(idtable INTEGER)
    FOR SELECT
      tbl.id as apptableid,
      tbl.tablename,
      tbl.appid,
      col.columnname as tableidcolumn,
      coldetails.id as appcolumnid,
      coldetails.columnname,
      coldetails.length,
      coldetails.jsonfield,
      coldetails.name as datatype
    FROM
      metadata.appcolumns col,
      metadata.apptables tbl
      LEFT OUTER JOIN
        (
          SELECT
            col_details.apptableid,
            col_details.id,
            col_details.columnname,
            col_details.length,
            col_details.jsonfield,
            dt.name
          FROM
            metadata.appcolumns col_details,
            metadata.datatypes dt
          WHERE
            dt.id = col_details.datatypeid
        ) as coldetails
      ON
        coldetails.apptableid = tbl.id
    WHERE
      tbl.id = idtable
    AND
      col.apptableid = tbl.id
    AND
      col.columnname = 'id'
    ORDER BY appcolumnid;

  BEGIN
    OPEN cur_fields(idtable);

    execStr := 'SELECT * from metadata.getColumnElementsFromFieldData(''' || cur_fields || ''', ''' || fieldids::text || ''', ''' || fieldvals::text || ''');';
    EXECUTE execStr INTO resp;

    CLOSE cur_fields;

    tableName := resp->>'tableName';
    tableCol := resp->>'tableCol';
    fieldsStr := resp->>'fieldsStr';
    apptableFieldStr := resp->>'apptableFieldStr';
    apptableValueStr := resp->>'apptableValueStr';
    appId := resp->>'appId';
    valuesStr := resp->>'valuesStr';

    execStr := 'INSERT INTO app.' || tableName ||
      '(' || tableCol || ', createdat, appId' || fieldsStr || apptableFieldStr || ') ' ||
      'VALUES ' ||
      '(DEFAULT, now(), ' || appid || valuesStr || apptableValueStr || ') ' ||
      'RETURNING app.' || tableName || '.' || tableCol || ';';

     RAISE NOTICE 'execStr';
     RAISE NOTICE '%', execStr;

     EXECUTE
       execStr
     INTO id_val;

--     EXECUTE 'SELECT row_to_json(t) FROM ( SELECT * FROM app.' || tableName || ' WHERE id = ' || id_val || ' ) t;' INTO result;
    EXECUTE 'SELECT row_to_json(t) FROM ( SELECT * FROM metadata.appdataFindById(' || idtable || ', ' || id_val || ')) t;' INTO result;
    RETURN result;
  END;
$$;


ALTER FUNCTION metadata.appdataadd(idtable integer, fieldids integer[], fieldvals text[]) OWNER TO appowner;

--
-- Name: appdatadelete(integer, integer); Type: FUNCTION; Schema: metadata; Owner: appowner
--

CREATE FUNCTION metadata.appdatadelete(idtable integer, idrec integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$

  DECLARE
    apptableName TEXT;

  BEGIN
    SELECT
      tbl.tablename into apptableName
    FROM
      metadata.apptables tbl
    WHERE
      tbl.id = idtable;

    RAISE NOTICE 'tablename: %', apptableName;
    EXECUTE 'DELETE FROM app.' || apptableName || ' WHERE id = ' || idrec || ';';

    RETURN idrec;
  END;
$$;


ALTER FUNCTION metadata.appdatadelete(idtable integer, idrec integer) OWNER TO appowner;

--
-- Name: appdatafindall(numeric, integer); Type: FUNCTION; Schema: metadata; Owner: appowner
--

CREATE FUNCTION metadata.appdatafindall(idtable numeric, iduser integer DEFAULT NULL::integer) RETURNS json
    LANGUAGE plpgsql
    AS $$

  DECLARE
    resp JSON;
    result JSON;
    execStr TEXT;
    tableName TEXT;
    tableIdColumn TEXT := 'id';
    selectStr TEXT := '';
    fromStr TEXT := '';
    whereStr TEXT := '';
    idx INTEGER;

    cur_fields CURSOR(id INTEGER)
    FOR SELECT * FROM metadata.appformGetFields(id, iduser);

	BEGIN
    OPEN cur_fields(idtable);

    execStr := 'SELECT * from metadata.getColumnElementsFromRecord(''' || cur_fields || ''', 0);';
    EXECUTE execStr INTO resp;

    CLOSE cur_fields;

    tableName := resp->>'tableName';
    tableIdColumn := 'id';
    selectStr := resp->>'selectStr';
    fromStr := resp->>'fromStr';
    idx := strpos(resp->>'whereStr', 'and');
    whereStr := substring(resp->>'whereStr', 0, idx);

--     RAISE NOTICE '----------------------------------------';
--     RAISE NOTICE 'tableIdColumn: %  tableName:  %', tableIdColumn, tableName;
--     RAISE NOTICE '';
--     RAISE NOTICE 'selectStr: .%.', selectStr;
--     RAISE NOTICE '';
--     RAISE NOTICE 'fromStr: .%.', fromStr;
--     RAISE NOTICE '';
--     RAISE NOTICE 'whereStr: .%.', whereStr;
--     RAISE NOTICE '';
--     RAISE NOTICE '----------------------------------------';

    execStr := 'SELECT ' || selectStr ||
               ' FROM app.' || tableName || ' tbl' || fromStr ||
               ' WHERE ' || whereStr ||
               ' ORDER BY ' || 'tbl.' || tableIdColumn;
    RAISE NOTICE '----------------------------------------';
    RAISE NOTICE 'execStr: %', execStr;
    RAISE NOTICE '----------------------------------------';
    EXECUTE 'SELECT array_to_json(array_agg(row_to_json(t))) FROM (' || execStr || ') t;' INTO result;
    RAISE NOTICE 'result: %', result;

    IF (result is null) THEN
  		RETURN '[]';
    ELSE
    	RETURN result;
	  END IF;

  END;
$$;


ALTER FUNCTION metadata.appdatafindall(idtable numeric, iduser integer) OWNER TO appowner;

--
-- Name: appdatafindbyid(integer, integer); Type: FUNCTION; Schema: metadata; Owner: appowner
--

CREATE FUNCTION metadata.appdatafindbyid(idtable integer, idrec integer) RETURNS json
    LANGUAGE plpgsql
    AS $$

  DECLARE
    resp JSON;
    result JSON;
    execStr TEXT;
    tableName TEXT;
    selectStr TEXT := 'tbl.id as id';
    fromStr TEXT := '';
    whereStr TEXT := '';
    tableId INTEGER;

    cur_fields CURSOR(id INTEGER)
    FOR SELECT * FROM metadata.appformGetFields(id);

  BEGIN
--     select tbl.id into tableId from metadata.pageforms pf, metadata.appcolumns col, metadata.apptables tbl
--     where pf.id = idform and col.id = pf.appcolumnid and tbl.id = col.apptableid;

    RAISE NOTICE '********** tableId: %', idtable;

    OPEN cur_fields(idtable);

    execStr := 'SELECT * from metadata.getColumnElementsFromRecord(''' || cur_fields || ''', ' || idrec || ');';
    EXECUTE execStr INTO resp;

    CLOSE cur_fields;

    tableName := resp->>'tableName';
    selectStr := resp->>'selectStr';
    fromStr := resp->>'fromStr';
    whereStr := resp->>'whereStr';

    execStr := 'SELECT ' || selectStr ||
      ' FROM app.' || tableName || ' as tbl ' || fromStr ||
      ' WHERE ' || whereStr;

    RAISE NOTICE 'execStr:';
    RAISE NOTICE '%', execStr;

    EXECUTE 'SELECT row_to_json(t) FROM ( ' || execStr || ' ) t;' INTO result;
    RETURN result;
  END;
$$;


ALTER FUNCTION metadata.appdatafindbyid(idtable integer, idrec integer) OWNER TO appowner;

--
-- Name: appdataupdate(integer, integer, integer[], text[]); Type: FUNCTION; Schema: metadata; Owner: appowner
--

CREATE FUNCTION metadata.appdataupdate(idtable integer, idrec integer, fieldids integer[], fieldvals text[]) RETURNS json
    LANGUAGE plpgsql
    AS $$

  DECLARE
    resp JSON;
    result JSON;
    id_val integer;
    execStr text;
    tableName text;
    tableCol text;
    appId integer;
    setStr text := '';

    cur_fields CURSOR(idtable INTEGER)
    FOR SELECT
      tbl.id as apptableid,
      tbl.tablename,
      tbl.appid,
      col.columnname as tableidcolumn,
      coldetails.id as appcolumnid,
      coldetails.columnname,
      coldetails.length,
      coldetails.jsonfield,
      coldetails.name as datatype
    FROM
      metadata.appcolumns col,
      metadata.apptables tbl
      LEFT OUTER JOIN
        (
          SELECT
            col_details.apptableid,
            col_details.id,
            col_details.columnname,
            col_details.length,
            col_details.jsonfield,
            dt.name
          FROM
            metadata.appcolumns col_details,
            metadata.datatypes dt
          WHERE
            dt.id = col_details.datatypeid
        ) as coldetails
      ON
        coldetails.apptableid = tbl.id
    WHERE
       tbl.id = idtable
    AND
      col.apptableid = tbl.id
    AND
      col.columnname = 'id'
    ORDER BY appcolumnid;
  BEGIN
    OPEN cur_fields(idtable);

    execStr := 'SELECT * from metadata.getColumnElementsFromFieldData(''' || cur_fields || ''', ''' || fieldids::text || ''', ''' || fieldvals::text || ''');';
    EXECUTE execStr INTO resp;
    CLOSE cur_fields;

    tableName := resp->>'tableName';
    tableCol := resp->>'tableCol';
    setStr := resp->>'setStr';
    appId := resp->>'appId';

    execStr := 'UPDATE app.' || tableName || ' SET ' || setStr || ' WHERE id = ' || idrec ||
               ' RETURNING app.' || tableName || '.' || tableCol || ';';

    RAISE NOTICE 'execStr';
    RAISE NOTICE '%', execStr;

    EXECUTE
      execStr
    INTO id_val;

    EXECUTE 'SELECT row_to_json(t) FROM ( SELECT * FROM metadata.appdataFindById(' || idtable || ', ' || id_val || ')) t;' INTO result;
    RETURN result;
  END;
$$;


ALTER FUNCTION metadata.appdataupdate(idtable integer, idrec integer, fieldids integer[], fieldvals text[]) OWNER TO appowner;

--
-- Name: appformfindbyid(numeric); Type: FUNCTION; Schema: metadata; Owner: appowner
--

CREATE FUNCTION metadata.appformfindbyid(idrec numeric) RETURNS json
    LANGUAGE plpgsql
    AS $$
  DECLARE
    results RECORD;
    execStr text;
    selectStr text;
    fromStr text;
    whereStr text;

	BEGIN
    selectStr := 'issue.id, app.name as appname, isstype.label as isstype, issue.subject, activity.label as activity, priority.label as priority, status.label as status, issue.jsondata, issue.createdat, issue.updatedat';
    fromStr   := 'app.issues issue, metadata.applications app, app.issuetypes isstype, app.activity activity, app.priority priority, app.status status';
    whereStr  := 'issue.id = ' || idrec || ' AND app.id = issue.appid AND isstype.id = issue.issueid AND activity.id = issue.activityid AND priority.id = issue.priorityid AND status.id = issue.statusid';

    execStr := 'SELECT ' || selectStr ||
      ' FROM ' || fromStr ||
      ' WHERE ' || whereStr || ';';

    EXECUTE execStr INTO results;

		RETURN to_json(results);
	END;
$$;


ALTER FUNCTION metadata.appformfindbyid(idrec numeric) OWNER TO appowner;

--
-- Name: appformgetdatatable(numeric, integer); Type: FUNCTION; Schema: metadata; Owner: appowner
--

CREATE FUNCTION metadata.appformgetdatatable(idtable numeric, iduser integer DEFAULT NULL::integer) RETURNS json
    LANGUAGE plpgsql
    AS $$

  DECLARE
    result JSON;
    headerResult JSON;
    execStr TEXT;
    headerStr TEXT;
    userArrayStr TEXT;
    userIdStr TEXT := '';
	  userRoles integer[] := metadata.getUserRolesArray(iduser);

	BEGIN
    userArrayStr := '''{' || array_to_string(userRoles, ',') || '}''';

    headerStr :=
    'select col.label as text, col.columnname as value, col.displayorder, dt.name as datatype
    from metadata.appcolumns as col
    left outer join metadata.datatypes as dt on dt.id = col.datatypeid
    where apptableid = ' || idtable || '
    and (col.allowedroles is null OR col.allowedroles = ''{}'' OR col.allowedroles && ' || userArrayStr || ')
    order by displayorder';
--     RAISE NOTICE 'headerStr: %', headerStr;
    EXECUTE 'SELECT array_to_json(array_agg(row_to_json(t))) FROM (' || headerStr || ') t;' INTO headerResult;

    IF(iduser is not null) THEN
      userIdStr := ', ' || iduser;
    END IF;

    execStr := 'SELECT * from metadata.appdataFindAll(' || idtable || userIdStr || ');';
    EXECUTE execStr INTO result;
		RETURN json_build_object('data', result, 'headers', headerResult);
	END;
$$;


ALTER FUNCTION metadata.appformgetdatatable(idtable numeric, iduser integer) OWNER TO appowner;

--
-- Name: appformgetfields(numeric, integer); Type: FUNCTION; Schema: metadata; Owner: appowner
--

CREATE FUNCTION metadata.appformgetfields(idtable numeric, iduser integer DEFAULT NULL::integer) RETURNS TABLE(apptableid integer, tablename character varying, appid integer, appcolumnid integer, columnname character varying, length integer, jsonfield boolean, name character varying, mastertable character varying, mastercolumn character varying, masterdisplay character varying, datatype character varying)
    LANGUAGE plpgsql
    AS $$

  DECLARE
    userRoles integer[] := metadata.getUserRolesArray(iduser);

	BEGIN
    RETURN QUERY
    SELECT
      tbl.id as apptableid,
      tbl.tablename,
      tbl.appid,
      col.id as appcolumnid,
      col.columnname,
      col.length,
      col.jsonfield,
      col.name,
      col.mastertable,
      col.mastercolumn,
      col.masterdisplay,
      dt.name as datatype
    FROM
      metadata.apptables as tbl,
      metadata.datatypes  as dt,
      metadata.appcolumns as col
    WHERE tbl.id = idtable
    AND col.apptableid = tbl.id
    AND dt.id = col.datatypeid
    AND (col.allowedroles is null OR col.allowedroles = '{}' OR col.allowedroles && userRoles)
    ORDER BY appcolumnid;
	END;
$$;


ALTER FUNCTION metadata.appformgetfields(idtable numeric, iduser integer) OWNER TO appowner;

--
-- Name: appformgetformtables(); Type: FUNCTION; Schema: metadata; Owner: appowner
--

CREATE FUNCTION metadata.appformgetformtables() RETURNS TABLE(formid integer, appid integer, appcolumnid integer, apptableid integer, tablename character varying, hasworkflowstate boolean)
    LANGUAGE plpgsql
    AS $$

	BEGIN
    RETURN QUERY
    select
      form.id as formid,
      tbl.appid as appid,
      col.id as appcolumnid,
      col.apptableid as apptableid,
      tbl.tablename as tablename,
      col2.columnname is not null as hasworkflowstate
    from
      metadata.pageforms form,
      metadata.appcolumns col,
      metadata.apptables tbl
      left outer join metadata.appcolumns as col2 on col2.apptableid = tbl.id and col2.columnname = 'workflowstateid'
    where col.id = form.appcolumnid and tbl.id = col.apptableid
    order by form.id;
	END;
$$;


ALTER FUNCTION metadata.appformgetformtables() OWNER TO appowner;

--
-- Name: applicationsfindall(); Type: FUNCTION; Schema: metadata; Owner: appowner
--

CREATE FUNCTION metadata.applicationsfindall() RETURNS TABLE(id integer, name character varying, shortname character varying, description character varying)
    LANGUAGE plpgsql
    AS $$
	BEGIN
		RETURN QUERY
		SELECT
      app.id,
      app.name,
      app.shortname,
      app.description
		FROM metadata.applications app
    ORDER BY name;
	END;
$$;


ALTER FUNCTION metadata.applicationsfindall() OWNER TO appowner;

--
-- Name: applicationsgetselections(); Type: FUNCTION; Schema: metadata; Owner: appowner
--

CREATE FUNCTION metadata.applicationsgetselections() RETURNS TABLE(label character varying, value integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
  RETURN QUERY
  SELECT
      name as label,
      id as value
    FROM
      metadata.applications
    WHERE name <> 'System'
    ORDER BY label;
 END;
$$;


ALTER FUNCTION metadata.applicationsgetselections() OWNER TO appowner;

--
-- Name: appusersbulkadd(integer, integer[]); Type: FUNCTION; Schema: metadata; Owner: appowner
--

CREATE FUNCTION metadata.appusersbulkadd(idapp integer, userids integer[]) RETURNS integer
    LANGUAGE plpgsql
    AS $$

  DECLARE
    userid integer;

  BEGIN
    FOREACH userid IN ARRAY userids
    LOOP

      RAISE NOTICE 'appid: %  userid: %' , idapp, userid;
      EXECUTE 'INSERT INTO app.appusers (id, appid, userid, createdat, updatedat) VALUES' ||
              '(DEFAULT, ' || idapp || ', ' || userid || ', ''' || now() || ''', ''' || now() || ''');';

    END LOOP;

    RETURN array_length(userids, 1);
  END;
$$;


ALTER FUNCTION metadata.appusersbulkadd(idapp integer, userids integer[]) OWNER TO appowner;

--
-- Name: datamapgetcategories(); Type: FUNCTION; Schema: metadata; Owner: appowner
--

CREATE FUNCTION metadata.datamapgetcategories() RETURNS TABLE(label character varying, value integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
		RETURN QUERY
		SELECT
      fc.label,
      fc.id as value
    FROM
      metadata.fieldcategories fc
    ORDER BY label;
	END;
$$;


ALTER FUNCTION metadata.datamapgetcategories() OWNER TO appowner;

--
-- Name: datamapgetfields(numeric); Type: FUNCTION; Schema: metadata; Owner: appowner
--

CREATE FUNCTION metadata.datamapgetfields(idtable numeric) RETURNS TABLE(label character varying, value integer)
    LANGUAGE plpgsql
    AS $$

  BEGIN
		RETURN QUERY
		SELECT
      cols.label,
      cols.id as value
    FROM
      metadata.appcolumns cols
    WHERE
      cols.apptableid = idtable
    ORDER BY label;
	END;
$$;


ALTER FUNCTION metadata.datamapgetfields(idtable numeric) OWNER TO appowner;

--
-- Name: datamapgettableoptions(numeric); Type: FUNCTION; Schema: metadata; Owner: appowner
--

CREATE FUNCTION metadata.datamapgettableoptions(idapp numeric) RETURNS TABLE(label character varying, value integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
		RETURN QUERY
		SELECT
      at.label,
      at.id as value
    FROM
      metadata.apptables at
    WHERE at.appid = idapp
    ORDER BY label;
	END;
$$;


ALTER FUNCTION metadata.datamapgettableoptions(idapp numeric) OWNER TO appowner;

--
-- Name: fetchdatamodel(numeric, integer); Type: FUNCTION; Schema: metadata; Owner: appowner
--

CREATE FUNCTION metadata.fetchdatamodel(idapp numeric, iduser integer DEFAULT NULL::integer) RETURNS TABLE(id integer, appid integer, label character varying, tablename character varying, description character varying, createdat timestamp without time zone, updatedat timestamp without time zone, appcolumns json)
    LANGUAGE plpgsql
    AS $$

  DECLARE
	  userRoles integer[] := metadata.getUserRolesArray(iduser);

  BEGIN
		RETURN QUERY
      SELECT
        tbl.id,
        tbl.appid,
        tbl.label,
        tbl.tablename,
        tbl.description,
        tbl.createdat,
        tbl.updatedat,
        (
          select array_to_json(array_agg(row_to_json(t))) from (
            select
            cols.id,
            cols.columnname,
            cols.label,
            cols.datatypeid,
            cols.mastertable,
            cols.apptableid,
            cols.jsonfield,
            dt.name as datatype,
            (select row_to_json(t) from (
              select
              t.id,
              t.tablename,
              c.id,
              c.columnname,
              d.name as datatype
              from
              metadata.apptables t,
              metadata.appcolumns c
              left outer join metadata.datatypes as d on d.id = c.datatypeid
              where
              t.tablename = cols.mastertable
              and c.apptableid = t.id
              and c.columnname = metadata.getColumnFromDisplayName(cols.masterdisplay::text)
              ) t
            ) as refcol
            from metadata.appcolumns as cols
            left outer join metadata.datatypes as dt on dt.id = cols.datatypeid
            where cols.apptableid = tbl.id
              AND (cols.columnname != 'apptableid' AND cols.columnname != 'jsondata')
              AND (cols.allowedroles is null OR cols.allowedroles = '{}' OR cols.allowedroles && userRoles)
          ) t
        ) as appcolumns
      FROM metadata.apptables AS tbl
      WHERE tbl.appid = idapp
      ORDER BY tbl.label ASC;
	END;
$$;


ALTER FUNCTION metadata.fetchdatamodel(idapp numeric, iduser integer) OWNER TO appowner;

--
-- Name: findrelatedrecords(integer, integer, integer, text); Type: FUNCTION; Schema: metadata; Owner: appowner
--

CREATE FUNCTION metadata.findrelatedrecords(appcolumnid integer, idrec integer, iduser integer DEFAULT NULL::integer, serverurl text DEFAULT ''::text) RETURNS json
    LANGUAGE plpgsql
    AS $$
DECLARE
    rec_field RECORD;
    resp      JSON;
    result    JSON;
    execStr   TEXT;
    tableName TEXT;
    selectStr TEXT := 'tbl.id as id';
    fromStr   TEXT := '';
    whereStr  TEXT := '';
    tableId   INTEGER;
    tableAppId INTEGER;
    relatedColumn TEXT;
    cur_fields scroll CURSOR (id INTEGER) FOR SELECT * FROM metadata.appformGetFields(id, iduser);

BEGIN
    select * into rec_field from metadata.appcolumns where id = appcolumnid;
    tableId := rec_field.apptableid;
    select appid into tableAppId from metadata.apptables where id = tableId;
    RAISE NOTICE '********** appId: %  tableId: %', tableAppId, tableId;
    IF(rec_field.jsonfield) THEN
      relatedColumn := 'CAST(coalesce(tbl.jsondata->>''' || rec_field.columnname || ''', ''0'') AS INTEGER)';
    ELSE
      relatedColumn := 'tbl.' || rec_field.columnname;
    END IF;

    OPEN cur_fields(tableId);
    execStr := 'SELECT * from metadata.getColumnElementsFromRecord(''' || cur_fields || ''', ' || idrec || ');';
    EXECUTE execStr INTO resp;
    CLOSE cur_fields;

    tableName := resp ->> 'tableName';
    selectStr := resp ->> 'selectStr';
    fromStr := resp ->> 'fromStr';
    whereStr := resp ->> 'whereStr';

    RAISE NOTICE 'tableName: %', tableName;
    RAISE NOTICE 'selectStr: %', selectStr;
    RAISE NOTICE 'fromStr: %', fromStr;
    RAISE NOTICE 'whereStr: %', whereStr;

    execStr := 'SELECT ' || selectStr || ', users.firstname, users.mi, users.lastname, users.email, users.phone, ' ||
               'array(
                select json_build_object(
                    ''path'', attach.path,
                    ''uniquename'', attach.uniquename,
                    ''name'', attach.name,
                    ''size'', attach.size,
                    ''link'', ''' || serverurl || '/files/' || tableAppId || '/'' || attach.uniquename)
                from app.tableattachments as ta,
                app.attachments as attach
                where ta.apptableid=tbl.apptableid and ta.recordid=tbl.id and attach.id=ta.attachmentid
                ) attachments' ||
               ' FROM app.' || tableName || ' as tbl ' || fromStr ||
               ' where tbl.apptableid=' || tableId ||
               ' AND ' || relatedColumn || '=' || idrec ||
               ' ORDER BY tbl.updatedat DESC';

    RAISE NOTICE 'execStr:';
    RAISE NOTICE '%', execStr;

    EXECUTE 'SELECT array_to_json(array_agg(row_to_json(t))) FROM (' || execStr || ') t;' INTO result;
    RETURN result;
END;
$$;


ALTER FUNCTION metadata.findrelatedrecords(appcolumnid integer, idrec integer, iduser integer, serverurl text) OWNER TO appowner;

--
-- Name: formrecordadd(integer, integer[], text[]); Type: FUNCTION; Schema: metadata; Owner: appowner
--

CREATE FUNCTION metadata.formrecordadd(idform integer, fieldids integer[], fieldvals text[]) RETURNS json
    LANGUAGE plpgsql
    AS $$

  DECLARE
    resp JSON;
    result JSON;
    id_val integer;
    execStr text;
    tableName text;
    tableCol text;
    appId integer;
    fieldsStr text := '';
    valuesStr text := '';
    apptableFieldStr text := '';
    apptableValueStr text := '';

    cur_fields CURSOR(idform INTEGER)
    FOR SELECT
      tbl.id as apptableid,
      tbl.tablename,
      tbl.appid,
      col.columnname as tableidcolumn,
      coldetails.id as appcolumnid,
      coldetails.columnname,
      coldetails.length,
      coldetails.jsonfield,
      coldetails.name as datatype
    FROM
      metadata.pageforms pf,
      metadata.appcolumns col,
      metadata.apptables tbl
      LEFT OUTER JOIN
        (
          SELECT
            col_details.apptableid,
            col_details.id,
            col_details.columnname,
            col_details.length,
            col_details.jsonfield,
            dt.name
          FROM
            metadata.appcolumns col_details,
            metadata.datatypes dt
          WHERE
            dt.id = col_details.datatypeid
        ) as coldetails
      ON
        coldetails.apptableid = tbl.id
    WHERE
      pf.id = idform
    AND
      col.id = pf.appcolumnid
    AND
      tbl.id = col.apptableid
    ORDER BY appcolumnid;

  BEGIN
    OPEN cur_fields(idform);

    execStr := 'SELECT * from metadata.getColumnElementsFromFieldData(''' || cur_fields || ''', ''' || fieldids::text || ''', ''' || fieldvals::text || ''');';
    EXECUTE execStr INTO resp;

    CLOSE cur_fields;

    tableName := resp->>'tableName';
    tableCol := resp->>'tableCol';
    fieldsStr := resp->>'fieldsStr';
    apptableFieldStr := resp->>'apptableFieldStr';
    apptableValueStr := resp->>'apptableValueStr';
    appId := resp->>'appId';
    valuesStr := resp->>'valuesStr';

    execStr := 'INSERT INTO app.' || tableName ||
      '(' || tableCol || ', createdat, appId' || fieldsStr || apptableFieldStr || ') ' ||
      'VALUES ' ||
      '(DEFAULT, now(), ' || appid || valuesStr || apptableValueStr || ') ' ||
      'RETURNING app.' || tableName || '.' || tableCol || ';';

    RAISE NOTICE 'execStr';
    RAISE NOTICE '%', execStr;

    EXECUTE
      execStr
    INTO id_val;

    EXECUTE 'SELECT row_to_json(t) FROM ( SELECT * FROM metadata.formRecordFindById(' || idform || ', ' || id_val || ')) t;' INTO result;
    RETURN result;
  END;
$$;


ALTER FUNCTION metadata.formrecordadd(idform integer, fieldids integer[], fieldvals text[]) OWNER TO appowner;

--
-- Name: formrecorddelete(integer, integer); Type: FUNCTION; Schema: metadata; Owner: appowner
--

CREATE FUNCTION metadata.formrecorddelete(idform integer, idrec integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$

  DECLARE
    apptableName TEXT;

  BEGIN
    SELECT
      tbl.tablename into apptableName
    FROM
      metadata.pageforms pf,
      metadata.appcolumns  col,
      metadata.apptables tbl
    WHERE
      pf.id = idform
    AND
      col.id = pf.appcolumnid
    AND
      tbl.id = col.apptableid;

    RAISE NOTICE 'tablename: %', apptableName;
    EXECUTE 'DELETE FROM app.' || apptableName || ' WHERE id = ' || idrec || ';';

    RETURN 1;
  END;
$$;


ALTER FUNCTION metadata.formrecorddelete(idform integer, idrec integer) OWNER TO appowner;

--
-- Name: formrecordfindbyid(integer, integer, integer); Type: FUNCTION; Schema: metadata; Owner: appowner
--

CREATE FUNCTION metadata.formrecordfindbyid(idform integer, idrec integer, iduser integer DEFAULT NULL::integer) RETURNS json
    LANGUAGE plpgsql
    AS $$

  DECLARE
    resp JSON;
    result JSON;
    execStr TEXT;
    tableName TEXT;
    selectStr TEXT := 'tbl.id as id';
    fromStr TEXT := '';
    whereStr TEXT := '';
    tableId INTEGER;

    cur_fields CURSOR(id INTEGER)
    FOR SELECT * FROM metadata.appformGetFields(id, iduser);

  BEGIN
    select tbl.id into tableId from metadata.pageforms pf, metadata.appcolumns col, metadata.apptables tbl
    where pf.id = idform and col.id = pf.appcolumnid and tbl.id = col.apptableid;

    RAISE NOTICE '********** tableId: %', tableId;

    OPEN cur_fields(tableId);

    execStr := 'SELECT * from metadata.getColumnElementsFromRecord(''' || cur_fields || ''', ' || idrec || ', true);';
    EXECUTE execStr INTO resp;

    CLOSE cur_fields;

    tableName := resp->>'tableName';
    selectStr := resp->>'selectStr';
    fromStr := resp->>'fromStr';
    whereStr := resp->>'whereStr';

    execStr := 'SELECT ' || selectStr ||
      ' FROM app.' || tableName || ' as tbl ' || fromStr ||
      ' WHERE ' || whereStr;

    RAISE NOTICE 'execStr:';
    RAISE NOTICE '%', execStr;

    EXECUTE 'SELECT row_to_json(t) FROM ( ' || execStr || ' ) t;' INTO result;
    RETURN result;
  END;
$$;


ALTER FUNCTION metadata.formrecordfindbyid(idform integer, idrec integer, iduser integer) OWNER TO appowner;

--
-- Name: formrecordupdate(integer, integer, integer[], text[]); Type: FUNCTION; Schema: metadata; Owner: appowner
--

CREATE FUNCTION metadata.formrecordupdate(idform integer, idrec integer, fieldids integer[], fieldvals text[]) RETURNS json
    LANGUAGE plpgsql
    AS $$

  DECLARE
    resp JSON;
    result JSON;
    id_val integer;
    execStr text;
    tableName text;
    tableCol text;
    setStr text := '';

    cur_fields CURSOR(idform INTEGER)
    FOR SELECT
      tbl.id as apptableid,
      tbl.tablename,
      tbl.appid,
      col.columnname as tableidcolumn,
      coldetails.id as appcolumnid,
      coldetails.columnname,
      coldetails.length,
      coldetails.jsonfield,
      coldetails.name as datatype
    FROM
      metadata.pageforms pf,
      metadata.appcolumns col,
      metadata.apptables tbl
      LEFT OUTER JOIN
        (
          SELECT
            col_details.apptableid,
            col_details.id,
            col_details.columnname,
            col_details.length,
            col_details.jsonfield,
            dt.name
          FROM
            metadata.appcolumns col_details,
            metadata.datatypes dt
          WHERE
            dt.id = col_details.datatypeid
        ) as coldetails
      ON
        coldetails.apptableid = tbl.id
    WHERE
      pf.id = idform
    AND
      col.id = pf.appcolumnid
    AND
      tbl.id = col.apptableid
    ORDER BY appcolumnid;
  BEGIN
    RAISE NOTICE 'fieldids: %', fieldids;
    RAISE NOTICE 'fieldvals: %', fieldvals;

    OPEN cur_fields(idform);

    execStr := 'SELECT * from metadata.getColumnElementsFromFieldData(''' || cur_fields || ''', ''' || fieldids::text || ''', ''' || fieldvals::text || ''');';
    EXECUTE execStr INTO resp;

    CLOSE cur_fields;

    tableName := resp->>'tableName';
    tableCol := resp->>'tableCol';
    setStr := resp->>'setStr';
    RAISE NOTICE 'tableName: %', tableName;
    RAISE NOTICE 'tableCold: %', tableCol;
    RAISE NOTICE 'setStr: %', setStr;

    execStr := 'UPDATE app.' || tableName || ' SET ' || setStr || ' WHERE id = ' || idrec ||
               ' RETURNING app.' || tableName || '.' || tableCol || ';';

    RAISE NOTICE 'execStr';
    RAISE NOTICE '%', execStr;

    EXECUTE
      execStr
    INTO id_val;

    EXECUTE 'SELECT row_to_json(t) FROM ( SELECT * FROM metadata.formRecordFindById(' || idform || ', ' || idrec || ')) t;' INTO result;
    RETURN result;
  END;
$$;


ALTER FUNCTION metadata.formrecordupdate(idform integer, idrec integer, fieldids integer[], fieldvals text[]) OWNER TO appowner;

--
-- Name: getappresources(numeric); Type: FUNCTION; Schema: metadata; Owner: appowner
--

CREATE FUNCTION metadata.getappresources(idapp numeric) RETURNS TABLE(type text, id integer, _id character varying, title character varying, tablename character varying, path character varying, modified timestamp without time zone)
    LANGUAGE plpgsql
    AS $$
BEGIN
		RETURN QUERY
		SELECT
      'resource' as type,
      fr.id,
      fr.formid as _id,
      fr.title,
      fr.tablename,
      fr.apipath as path,
      fr.updatedat as modified
    FROM
      metadata.apptables tbl,
      metadata.appcolumns col,
      metadata.formresources fr
    WHERE
      tbl.appid = idapp
    AND
      col.apptableid = tbl.id
    AND
      fr.appcolumnid = col.id
    ORDER BY fr.title;
	END;
$$;


ALTER FUNCTION metadata.getappresources(idapp numeric) OWNER TO appowner;

--
-- Name: getcolumnelementsfromfielddata(refcursor, integer[], text[]); Type: FUNCTION; Schema: metadata; Owner: appowner
--

CREATE FUNCTION metadata.getcolumnelementsfromfielddata(ref refcursor, fieldids integer[], fieldvals text[]) RETURNS json
    LANGUAGE plpgsql
    AS $$

  DECLARE
    result JSON;
    rec_field RECORD;
    tableName text;
    tableCol text;
    fieldid integer;
    idx integer;
    appId integer;
    fieldsStr text := '';
    valuesStr text := '';
    setStr text := '';
    jsonStr text := '';
    jsonCol text := null;
    apptableFieldStr text := '';
    apptableValueStr text := '';
    quotes text;
    comma text;
    fieldVal text;
    firstJsonField boolean := true;
    valueFnd boolean := false;
    attrKeys text[];
    attrVals text[];

  BEGIN
    RAISE NOTICE 'fieldids: %', fieldids;
    RAISE NOTICE 'fieldvals: %', fieldvals::text;

    LOOP
      FETCH ref into rec_field;
      EXIT WHEN NOT FOUND;

      RAISE NOTICE 'LOOP columnname: %', rec_field.columnname;
      IF (rec_field.columnname != rec_field.tableidcolumn) THEN
--       IF (rec_field.columnname != rec_field.tableidcolumn AND rec_field.columnname <> ALL ( ARRAY['updatedat'] ) ) THEN
        tableName := rec_field.tablename;
        tableCol := rec_field.tableidcolumn;
        appId := rec_field.appid;
        RAISE NOTICE 'columnname: %  recfield.appcolumnid: %', rec_field.columnname, rec_field.appcolumnid;

        idx := 1;
        valueFnd := false;
        FOREACH fieldid IN ARRAY fieldids
        LOOP
          IF (fieldid = rec_field.appcolumnid AND rec_field.columnname <> ALL ( ARRAY['updatedat'] ) ) THEN
            valueFnd := true;
--             RAISE NOTICE 'columnname: %  datatype: %  jsonfield %  text: %', rec_field.columnname, rec_field.datatype, rec_field.jsonfield, fieldvals[idx];

--             RAISE NOTICE 'rec_field.datatype: %', rec_field.datatype;
            IF (rec_field.datatype = 'text' OR rec_field.datatype = 'timestamp' OR rec_field.datatype = 'json' OR rec_field.datatype = 'varchar' OR rec_field.datatype = 'integer[]') THEN
              quotes := '''';
            ELSE
              quotes := '';
            END IF;
            IF (rec_field.datatype = 'integer[]' AND rec_field.jsonfield = false) THEN
              -- change the array string
              fieldVal := replace(replace(fieldvals[idx], '[', '{'), ']', '}');
            ELSE
              fieldVal := fieldvals[idx];
            END IF;

            -- TODO: combine the following two if tests and process jsondata at the end
            IF (rec_field.jsonfield) THEN
              -- json data -------------------------------------
              IF (rec_field.columnname != 'jsondata') THEN
                IF (firstJsonField) THEN
                  comma := '';
                  firstJsonField := false;
                ELSE
                  comma := ', ';
                END IF;
                RAISE NOTICE 'datatype: %', rec_field.datatype;
                IF (rec_field.datatype = 'text' OR rec_field.datatype = 'timestamp' OR rec_field.datatype = 'json' OR rec_field.datatype = 'varchar') THEN
                  quotes := E'\"';
                ELSE
                  quotes := '';
                  IF(fieldVal = '' AND rec_field.datatype = 'integer') THEN
                    fieldVal := 'null';
                  END IF;
                END IF;
                RAISE NOTICE 'fieldVal: .%.  quotes: .%.', fieldVal, quotes;
                jsonStr := jsonStr || comma || '"' || rec_field.columnname || '": ' || quotes || fieldVal || quotes;
              END IF;
            ELSIF (rec_field.columnname <> 'createdat') THEN
              -- standard fields -----------------------------
              fieldsStr := fieldsStr || ', ' || rec_field.columnname;
              valuesStr := valuesStr || ', ' || quotes || fieldVal || quotes;
              IF (char_length(setStr) > 0) THEN
                comma := ', ';
              ELSE
                comma := '';
              END IF;
              setStr := setStr || comma || rec_field.columnname || ' = ' || quotes || fieldVal || quotes;
              RAISE NOTICE 'setStr: %', setStr;
              EXIT;  -- stop looping thru fieldids
            END IF;
          END IF;
          idx := idx + 1;
        END LOOP;  -- fieldids

        IF (valueFnd = false) THEN
          IF (rec_field.columnname = 'jsondata') THEN
            -- TODO: finalize how to distinguish the json column name; if using jsondata just hard code else if using flag change if conditional
            jsonCol := rec_field.columnname;
          ELSIF (rec_field.columnname = 'apptableid' AND (rec_field.tablename = 'appdata' OR rec_field.tablename = 'masterdata')) THEN
            RAISE NOTICE '**************** table name: %  table id: %  column name: %', rec_field.tablename, rec_field.apptableid, rec_field.columnname;
            apptableFieldStr := ', apptableid';
            apptableValueStr := ', ' || rec_field.apptableid;
          ELSE
            RAISE NOTICE 'no value found for %', rec_field.columnname;
          END IF;
        END IF;

      END IF;  -- !tableidcolumn
    END LOOP;  -- cursor records

    RAISE NOTICE 'jsonCol is not null: %  firstJsonField: %', (jsonCol IS NOT NULL), firstJsonField;
    IF (jsonCol IS NOT NULL AND firstJsonField = false) THEN
      RAISE NOTICE 'jsonCol: %  jsonStr: .%.', jsonCol, jsonStr;
      fieldsStr := fieldsStr || ', ' || jsonCol;
      valuesStr := valuesStr || ', ''{' || jsonStr || '}''';
      IF (char_length(setStr) > 0) THEN
        comma := ', ';
      ELSE
        comma := '';
      END IF;
      setStr := setStr || comma || jsonCol || ' = ''{' || jsonStr || '}''';
    END IF;

    attrKeys := ARRAY['tableName', 'tableCol', 'apptableFieldStr', 'apptableValueStr', 'appId', 'fieldsStr', 'valuesStr', 'setStr'];
    attrVals := ARRAY[tableName, tableCol, apptableFieldStr, apptableValueStr, appId::text, fieldsStr, valuesStr, setStr];
    return json_object(attrKeys::text[], attrVals::text[]);
  END;
$$;


ALTER FUNCTION metadata.getcolumnelementsfromfielddata(ref refcursor, fieldids integer[], fieldvals text[]) OWNER TO appowner;

--
-- Name: getcolumnelementsfromrecord(refcursor, integer, boolean); Type: FUNCTION; Schema: metadata; Owner: appowner
--

CREATE FUNCTION metadata.getcolumnelementsfromrecord(ref refcursor, idrec integer, idandref boolean DEFAULT false) RETURNS json
    LANGUAGE plpgsql
    AS $$

  DECLARE
    rec_field RECORD;
    tableName TEXT;
    tableId INTEGER;
    tableIdColumn TEXT := 'id';
    colLabel TEXT;
    colTable TEXT;
    colSelect TEXT;
    selectStr TEXT := 'tbl.id as id';
    fromStr TEXT := '';
    whereStr TEXT := '';
    relationColName TEXT;
    masterTableCount INTEGER;
    masterTableName TEXT;
    masterdisplayPos INTEGER;

    attrKeys text[];
    attrVals text[];

  BEGIN
    CREATE TEMP TABLE lookup(tablename VARCHAR);

    LOOP
      FETCH ref into rec_field;
      EXIT WHEN NOT FOUND;

      RAISE NOTICE 'LOOP columnname: %', rec_field.columnname;
      colLabel := '';
      colSelect  := '';
      colTable := 'tbl.';

      RAISE NOTICE '** columnname: %', rec_field.columnname;

      IF (rec_field.columnname != tableIdColumn) THEN

        IF (rec_field.jsonfield = true) THEN

          -- =========================================================
          -- json column
          -- =========================================================
          colTable := '';
          colSelect  := 'tbl.jsondata->>''' || rec_field.columnname || '''';
          colLabel := ' as ' || rec_field.columnname;

          IF (rec_field.mastertable IS NOT NULL) THEN
            IF (idAndRef) THEN
              -- add ID information
              selectStr := selectStr || ', ' || colTable || colSelect || colLabel;
              -- strip id from end of columnname
              colLabel := left(colLabel, -2);
            END IF;

            -- =========================================================
            -- related table
            -- =========================================================
            IF (rec_field.datatype = 'integer[]') THEN
              -- =========================================================
              -- array of references
              -- =========================================================
              RAISE NOTICE '************************* datatype: %', rec_field.datatype;
              -- ARRAY( SELECT name FROM app.masterdata WHERE id IN ( SELECT jsonb_array_elements_text(tbl.jsondata->'mls')::integer ) ) as mls,
              colTable := 'ARRAY(SELECT ' || rec_field.masterdisplay ||
                          ' FROM app.' || rec_field.mastertable ||
                          ' WHERE id IN ( SELECT jsonb_array_elements_text(tbl.jsondata->''' || rec_field.columnname || ''')::integer ) )';
              RAISE NOTICE 'colTable: %', colTable;
              colSelect := '';
            ELSE
              -- =========================================================
              -- single reference
              -- =========================================================
              -- check for whether there are multiple references to the same table
              INSERT INTO lookup (tablename) VALUES (rec_field.mastertable);
              masterTableName := rec_field.mastertable;
              SELECT COUNT(*) INTO masterTableCount FROM lookup WHERE lookup.tablename = rec_field.mastertable;
              RAISE NOTICE '************* count: %', masterTableCount;
              IF (masterTableCount > 1) THEN
                -- there are multiple references to the same table so make them unique using the Count
                masterTableName := masterTableName || masterTableCount;
              END IF;
               IF (rec_field.masterdisplay ~ '||') THEN
                -- TODO: process compound display: add mastertable to each column, create procedure, provide logic for standard columns as well
                colSelect := regexp_replace(rec_field.masterdisplay, rec_field.mastertable, masterTableName, 'g');
              ELSE
                colTable := masterTableName || '.';
                colSelect := regexp_replace(rec_field.masterdisplay, rec_field.mastertable, masterTableName, 'g');
              END IF;
              relationColName := 'CAST(coalesce(tbl.jsondata->>''' || rec_field.columnname || ''', ''0'') AS INTEGER)';
              fromStr := fromStr || ' LEFT OUTER JOIN app.' || rec_field.mastertable || ' as ' || masterTableName ||
                         ' ON ' || masterTableName || '.' || rec_field.mastercolumn || ' = ' || relationColName;
            END IF;
          END IF;

        ELSE

          -- =========================================================
          -- standard column
          -- =========================================================
          colSelect := rec_field.columnname;
          colLabel  := ' as ' || rec_field.columnname;

          IF (rec_field.mastertable IS NOT NULL) THEN
            IF (idAndRef) THEN
              -- add ID information
              selectStr := selectStr || ', ' || colTable || colSelect || colLabel;
              -- strip id from end of columnname
              colLabel := left(colLabel, -2);
            END IF;

            IF (rec_field.datatype = 'integer[]') THEN
              -- =========================================================
              -- array of references
              -- =========================================================
              RAISE NOTICE '************************* datatype: %', rec_field.datatype;
              -- ARRAY( SELECT name FROM app.masterdata WHERE id IN ( SELECT jsonb_array_elements_text(tbl.jsondata->'mls')::integer ) ) as mls,
              colTable := 'ARRAY(SELECT ' || rec_field.masterdisplay ||
                          ' FROM app.' || rec_field.mastertable ||
                          ' WHERE id IN ( SELECT unnest(tbl.' || rec_field.columnname || ') ) )';
              RAISE NOTICE 'colTable: %', colTable;
              colSelect := '';
            ELSE
              -- =========================================================
              -- single reference
              -- =========================================================
              INSERT INTO lookup (tablename) VALUES (rec_field.mastertable);
              masterTableName := rec_field.mastertable;
              SELECT COUNT(*) INTO masterTableCount FROM lookup WHERE lookup.tablename = rec_field.mastertable;
              IF (masterTableCount > 1) THEN
                masterTableName := masterTableName || masterTableCount;
              END IF;
              -- =========================================================
              -- related table
              -- =========================================================
              IF (rec_field.mastertable = 'apptables') THEN
                RAISE NOTICE '**** mastertable = apptables';
              ELSE
                colTable := masterTableName || '.';

                colSelect := regexp_replace(rec_field.masterdisplay, rec_field.mastertable, masterTableName, 'g');
                relationColName  := 'tbl.' || rec_field.columnname;
                fromStr := fromStr || ' LEFT OUTER JOIN app.' || rec_field.mastertable || ' as ' || masterTableName ||
                           ' ON ' || masterTableName || '.' || rec_field.mastercolumn || ' = ' || relationColName;
                IF (POSITION('.' in rec_field.masterdisplay) > 0) THEN
                  RAISE NOTICE '****************** masterdisplay: %  pos: %', rec_field.masterdisplay, masterdisplayPos;
                  colTable := '';
                END IF;
              END IF;
            END IF;
          END IF;

        END IF;

        IF (rec_field.columnname != 'jsondata') THEN
          selectStr := selectStr || ', ' || colTable || colSelect || colLabel;
        END IF;
      ELSE
        -- =========================================================
        -- table id
        -- =========================================================
        tableName := rec_field.tablename;
        tableId := rec_field.apptableid;
        RAISE NOTICE 'tableName: %', tableName;
        IF (tableName = 'appdata' OR tableName = 'masterdata') THEN
          whereStr := ' tbl.apptableid = ' || tableid || ' and tbl.id = ' || idrec;
        ELSIF (tableName != 'users') THEN
          whereStr := ' tbl.appid = ' || rec_field.appid || ' and tbl.id = ' || idrec;
        END IF;
      END IF;

    END LOOP;  -- cursor records

    DROP TABLE lookup;

    attrKeys := ARRAY['tableName', 'selectStr', 'fromStr', 'whereStr'];
    attrVals := ARRAY[tableName, selectStr, fromStr, whereStr];
    return json_object(attrKeys::text[], attrVals::text[]);
  END;
$$;


ALTER FUNCTION metadata.getcolumnelementsfromrecord(ref refcursor, idrec integer, idandref boolean) OWNER TO appowner;

--
-- Name: getcolumnfromdisplayname(text); Type: FUNCTION; Schema: metadata; Owner: appowner
--

CREATE FUNCTION metadata.getcolumnfromdisplayname(str text) RETURNS text
    LANGUAGE plpgsql
    AS $$

DECLARE
  pos integer;
  arr text[];
  newstr text;

BEGIN
  arr := string_to_array(str, ' || ');
--   RAISE NOTICE '-----------------------';
--   RAISE NOTICE '%', arr;
--   RAISE NOTICE 'length: %', array_length(arr, 1);
  newstr := arr[array_length(arr, 1)];
--   RAISE NOTICE 'newstr: .%.', newstr;
--   RAISE NOTICE '-----------------------';

  pos := position('.' in newstr);

  IF(pos > 0) THEN
    RETURN substr(newstr, pos+1);
  ELSE
    RETURN newstr;
  END IF;
END;

$$;


ALTER FUNCTION metadata.getcolumnfromdisplayname(str text) OWNER TO appowner;

--
-- Name: getresourcevalues(character varying); Type: FUNCTION; Schema: metadata; Owner: appowner
--

CREATE FUNCTION metadata.getresourcevalues(idresource character varying) RETURNS TABLE(label text, value integer, jsondata jsonb)
    LANGUAGE plpgsql
    AS $$
DECLARE
  _tablename   varchar(60);
  _labelcol    varchar(60);
  _appid       integer;
  _apptableid  integer;
  _specialproc boolean;
  _jsonfield   boolean;
  _whereStr    text;

BEGIN
  SELECT
    tbl.tablename,
    col.columnname,
		col.jsonfield,
    col.apptableid,
    tbl.appid,
    fr.specialprocessing
  INTO
    _tablename,
    _labelcol,
    _jsonfield,
    _apptableid,
    _appid,
    _specialproc
  FROM
    metadata.apptables tbl,
    metadata.appcolumns col,
    metadata.formresources fr
  WHERE
    fr.formid = idresource
  AND
    col.id = fr.appcolumnid
  AND
    tbl.id = col.apptableid;

  raise notice '_appid: %', _appid;
  raise notice '_tablename: %', _tablename;
  raise notice '_labelcol: %', _labelcol;
  raise notice '_jsonfield: %', _jsonfield;
  raise notice '_specialproc: %', _specialproc;

  IF _specialproc THEN
    IF _tablename = 'roleassignments' THEN
      RETURN QUERY
      EXECUTE
        'SELECT DISTINCT ON (label)
          CONCAT_WS('' '', u.firstname, u.lastname) as label,
          u.id as value,
          ''{}''::jsonb
        FROM
          app.roles r,
          app.users u,
          app.roleassignments ra
          LEFT OUTER JOIN app.usergroups ug ON ug.groupid = ra.groupid
        WHERE
          r.appid = ' || _appid || '
          AND ra.roleid = r.id
          AND (u.id = ra.userid OR u.id = ug.userid)
        ORDER BY label;';
    ELSEIF _tablename = 'appbunos' THEN
      RETURN QUERY
      EXECUTE
        'SELECT
          b.identifier::text as label,
          b.id as value,
          ''{}''::jsonb
        FROM
          app.appbunos ab,
          app.bunos b
        WHERE
          ab.appid = ' || _appid || '
          AND b.id = ab.bunoid
        ORDER BY b.identifier;';
    END IF;
  ELSE
    IF (_jsonfield) THEN
      _labelcol := 'jsondata->>''' || _labelcol || '''';
    END IF;

    IF (_tablename = 'appdata' OR _tablename = 'masterdata') THEN
      _whereStr := 'tbl.apptableid = ' || _apptableid;
    ELSE
      _whereStr := 'tbl.appid = ' || _appid;
    END IF;

    RETURN QUERY
    EXECUTE
    'SELECT
          tbl.' || _labelcol || '::text,
          tbl.id as value,
          tbl.jsondata
        FROM
          app.' || _tablename || ' tbl
        WHERE ' || _whereStr ||
    ' ORDER BY tbl.' || _labelcol || ';';
  END IF;
END;
$$;


ALTER FUNCTION metadata.getresourcevalues(idresource character varying) OWNER TO appowner;

--
-- Name: getuserrolesarray(integer); Type: FUNCTION; Schema: metadata; Owner: appowner
--

CREATE FUNCTION metadata.getuserrolesarray(iduser integer DEFAULT NULL::integer) RETURNS integer[]
    LANGUAGE plpgsql
    AS $$

  DECLARE
	  userRoles integer[] := ARRAY[]::integer[];
	  user_role RECORD;
	  user_roles CURSOR(id INTEGER) FOR SELECT * FROM app.getUserRoles(id);

  BEGIN
    IF (iduser IS NOT NULL) THEN
      OPEN user_roles(iduser);
      LOOP
        FETCH user_roles INTO user_role;
        EXIT WHEN NOT FOUND;
        userRoles := array_append(userRoles, user_role.roleid);
      END LOOP;
      CLOSE user_roles;
    END IF;

    RETURN userRoles;
  END;

$$;


ALTER FUNCTION metadata.getuserrolesarray(iduser integer) OWNER TO appowner;

--
-- Name: loadappbunos(integer); Type: FUNCTION; Schema: metadata; Owner: appowner
--

CREATE FUNCTION metadata.loadappbunos(idapp integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$

  DECLARE
    cnt INTEGER := 0;
    rec_field RECORD;
    cur_fields CURSOR
    FOR SELECT * FROM app.bunos;

  BEGIN
    OPEN cur_fields;

    LOOP
      FETCH cur_fields into rec_field;
      EXIT WHEN NOT FOUND;

      RAISE NOTICE 'buno id: %', rec_field.id;
      insert into app.appbunos (id, appid, bunoid, createdat, updatedat) values (DEFAULT, idapp, rec_field.id, now(), now());
      cnt := cnt + 1;
    END LOOP;  -- cursor records

    CLOSE cur_fields;

    RETURN cnt;
  END;

$$;


ALTER FUNCTION metadata.loadappbunos(idapp integer) OWNER TO appowner;

--
-- Name: menubulkadd(json[]); Type: FUNCTION; Schema: metadata; Owner: appowner
--

CREATE FUNCTION metadata.menubulkadd(nodes json[]) RETURNS integer
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
      EXECUTE 'INSERT INTO metadata.menuitems (id, label, parentid, position, routerpath) VALUES' ||
              '(DEFAULT, ''' || labelStr || ''', ' || parentid || ', ' || pos ||', ''undefined'') ' ||
              'RETURNING metadata.menuitems.id;'
      INTO id_val;

      INSERT INTO lookup (origid, id) VALUES (id, id_val);
    END LOOP;

    DROP TABLE lookup;

    RETURN array_length(nodes, 1);
  END;
$_$;


ALTER FUNCTION metadata.menubulkadd(nodes json[]) OWNER TO appowner;

--
-- Name: menubulkdelete(json[]); Type: FUNCTION; Schema: metadata; Owner: appowner
--

CREATE FUNCTION metadata.menubulkdelete(nodes json[]) RETURNS integer
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


ALTER FUNCTION metadata.menubulkdelete(nodes json[]) OWNER TO appowner;

--
-- Name: menubulkupdate(json[]); Type: FUNCTION; Schema: metadata; Owner: appowner
--

CREATE FUNCTION metadata.menubulkupdate(nodes json[]) RETURNS integer
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
      EXECUTE 'UPDATE metadata.menuitems SET label = $2, parentid = $3, position = $4 WHERE id = $1'
      USING id, labelStr, parentid, pos;
    END LOOP;

    RETURN array_length(nodes, 1);
  END;
$_$;


ALTER FUNCTION metadata.menubulkupdate(nodes json[]) OWNER TO appowner;

--
-- Name: menuitemadd(json); Type: FUNCTION; Schema: metadata; Owner: appowner
--

CREATE FUNCTION metadata.menuitemadd(item json) RETURNS integer
    LANGUAGE plpgsql
    AS $$

DECLARE
  id_val integer;
  appid integer;
  parentid integer;
  pos integer;
  menulabel text;
  routerpath text;
  pageid integer;

BEGIN
  appid := item->'appid';
  parentid := item->'parentid';
  pos := item->'position';
  menulabel := item->>'label';
  routerpath := item->>'routerpath';
  pageid := item->'pageid';

  RAISE NOTICE 'appid: %  label: %  parentid: %  position: %  routerpath: %  pageid: %' , appid, menulabel, parentid, pos, routerpath, pageid;

  EXECUTE 'INSERT INTO metadata.menuitems (id, appid, label, parentid, position, routerpath, pageid) VALUES' ||
  '(DEFAULT, ' || appid || ', ''' || menulabel || ''', ' || parentid || ', ' || pos ||', ''' || routerpath || ''', ' || pageid || ') ' ||
  'RETURNING metadata.menuitems.id;'
  INTO id_val;

  RETURN id_val;
END;
$$;


ALTER FUNCTION metadata.menuitemadd(item json) OWNER TO appowner;

--
-- Name: menusfindall(integer); Type: FUNCTION; Schema: metadata; Owner: appowner
--

CREATE FUNCTION metadata.menusfindall(iduser integer DEFAULT NULL::integer) RETURNS TABLE(id integer, parentid integer, label character varying, routerpath character varying, icon character varying, appid integer, pageid integer, active integer, helppath character varying, itemposition integer, syspath character varying, subitems integer[])
    LANGUAGE plpgsql
    AS $$

DECLARE
  userRoles integer[] := ARRAY []::integer[];
  user_role RECORD;
  user_roles CURSOR (id INTEGER) FOR SELECT * FROM app.getUserRoles(id);

BEGIN
  IF (iduser IS NOT NULL) THEN
    OPEN user_roles(iduser);
    LOOP
      FETCH user_roles INTO user_role;
      EXIT WHEN NOT FOUND;
      RAISE NOTICE 'roleid: %', user_role.roleid;
      userRoles := array_append(userRoles, user_role.roleid);
    END LOOP;
  END IF;

  RAISE NOTICE 'userRoles: %', userRoles;
  RETURN QUERY
    SELECT items.id,
           items.parentid,
           items.label,
           items.routerpath,
           (select icons.icon from metadata.menuicons icons where icons.id = items.iconid),
           items.appid,
           items.pageid,
           items.active,
           page.helppath,
           items.position                                                                    as itemposition,
           (select mp.syspath from metadata.menupaths mp where mp.id = items.pathid)         as syspath,
           array(select subs.id from metadata.menuitems subs where subs.parentid = items.id) as subitems
    FROM metadata.menuitems items
           LEFT OUTER JOIN metadata.pages as page ON items.pageid = page.id
    WHERE items.pageid = 0
       OR (page.allowedroles is null OR page.allowedroles = '{}' OR page.allowedroles && userRoles)
    ORDER BY syspath, itemposition;
END;
$$;


ALTER FUNCTION metadata.menusfindall(iduser integer) OWNER TO appowner;

--
-- Name: pageadd(json); Type: FUNCTION; Schema: metadata; Owner: appowner
--

CREATE FUNCTION metadata.pageadd(item json) RETURNS json
    LANGUAGE plpgsql
    AS $$

DECLARE
  result JSON;
  id_val integer;
  appid integer;
  pagetitle text;
  pagename text;
  description text;

BEGIN
  appid := item->'appid';
  pagetitle := item->>'title';
  pagename := item->>'name';
  description := item->>'description';

  EXECUTE 'INSERT INTO metadata.pages (id, appid, title, name, description) VALUES' ||
  '(DEFAULT, ' || appid || ', ''' || pagetitle || ''', ''' || pagename || ''', ''' || description || ''') ' ||
  'RETURNING metadata.pages.id;'
  INTO id_val;

  EXECUTE 'SELECT row_to_json(t) FROM ( SELECT * FROM metadata.pagefindbyid(' || id_val || ')) t;' INTO result;
	RETURN result;
END;
$$;


ALTER FUNCTION metadata.pageadd(item json) OWNER TO appowner;

--
-- Name: pagedelete(integer); Type: FUNCTION; Schema: metadata; Owner: appowner
--

CREATE FUNCTION metadata.pagedelete(idpage integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$

DECLARE
  id_val integer;

BEGIN

  EXECUTE 'DELETE FROM metadata.pages WHERE metadata.pages.id = ' || idpage ||
          ' RETURNING metadata.pages.id;'
  INTO id_val;

  RETURN id_val;
END;
$$;


ALTER FUNCTION metadata.pagedelete(idpage integer) OWNER TO appowner;

--
-- Name: pagefindbyid(numeric); Type: FUNCTION; Schema: metadata; Owner: appowner
--

CREATE FUNCTION metadata.pagefindbyid(idpage numeric) RETURNS TABLE(id integer, appid integer, title character varying, name character varying, description character varying, appname character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
		RETURN QUERY
		SELECT
      page.id,
      page.appid,
      page.title,
      page.name,
      page.description,
      app.name as appname
		FROM
         metadata.pages page,
         metadata.applications app
    WHERE
      page.id = idpage
    AND app.id = page.appid;
	END;
$$;


ALTER FUNCTION metadata.pagefindbyid(idpage numeric) OWNER TO appowner;

--
-- Name: pageformsadd(numeric, numeric, numeric, text, jsonb); Type: FUNCTION; Schema: metadata; Owner: appowner
--

CREATE FUNCTION metadata.pageformsadd(idapp numeric, idpage numeric, idappcolumn numeric, descr text, jsonvalue jsonb) RETURNS integer
    LANGUAGE plpgsql
    AS $$
  DECLARE
    id_val integer;
  BEGIN
    INSERT INTO metadata.pageforms
      (
        id,
        pageid,
        jsondata,
        createdat,
        updatedat,
        appcolumnid,
        description
      )
    VALUES
      (
        DEFAULT,
        idpage,
        jsonvalue,
        now(),
        now(),
        idappcolumn,
        descr
      )
    RETURNING metadata.pageforms.id INTO id_val;
    RETURN id_val;
  END;
$$;


ALTER FUNCTION metadata.pageformsadd(idapp numeric, idpage numeric, idappcolumn numeric, descr text, jsonvalue jsonb) OWNER TO appowner;

--
-- Name: pageformsfindbyid(numeric, numeric, integer); Type: FUNCTION; Schema: metadata; Owner: appowner
--

CREATE FUNCTION metadata.pageformsfindbyid(idapp numeric, idpage numeric, iduser integer DEFAULT NULL::integer) RETURNS TABLE(appid integer, pageid integer, title character varying, helppath character varying, formid integer, tableid integer, columnid integer, columnname character varying, description character varying, formjson jsonb, pageactions json)
    LANGUAGE plpgsql
    AS $$

  DECLARE
    actions JSON := metadata.pageFormsGetActionsByPage(idpage);
	  userRoles integer[] := metadata.getUserRolesArray(iduser);

  BEGIN
		RETURN QUERY
		SELECT
      page.appid,
      page.id as pageid,
      page.title,
      page.helppath,
      pf.id as formid,
      pf.apptableid as tableid,
      pf.columnid,
      pf.columnname,
      pf.description,
      pf.jsondata as formjson,
      actions as pageactions
    FROM
      metadata.pages page
      LEFT OUTER JOIN
        (
          SELECT
            pf.pageid,
            pf.id,
            pf.systemcategoryid,
            col.apptableid,
            col.id as columnid,
            col.columnname,
            pf.description,
            pf.jsondata
          FROM
            metadata.pageforms pf
            LEFT OUTER JOIN metadata.appcolumns as col ON pf.appcolumnid = col.id
        ) as pf
      ON
        pf.pageid = page.id
    WHERE
      page.appid = idapp AND page.id = idpage
      AND (page.allowedroles is null OR page.allowedroles = '{}' OR page.allowedroles && userRoles);
	END;
$$;


ALTER FUNCTION metadata.pageformsfindbyid(idapp numeric, idpage numeric, iduser integer) OWNER TO appowner;

--
-- Name: pageformsgetactionsbypage(numeric); Type: FUNCTION; Schema: metadata; Owner: appowner
--

CREATE FUNCTION metadata.pageformsgetactionsbypage(idpage numeric) RETURNS json
    LANGUAGE plpgsql
    AS $$

  DECLARE
    result JSON;
    execStr TEXT;

	BEGIN
		execStr := 'SELECT fea.id, fea.actiondata, events.name as eventname, actions.name as actionname
    FROM
      metadata.pageforms pf,
      metadata.formeventactions fea,
      metadata.events events,
      metadata.actions actions
    WHERE
      pf.pageid = ' || idpage || ' ' || '
    AND
      fea.pageformid = pf.id
    AND
      events.id = fea.eventid
    AND
      actions.id = fea.actionid';

    EXECUTE 'SELECT COALESCE(array_to_json(array_agg(row_to_json(t))), ''[]'') FROM (' || execStr || ') t;' INTO result;
    RETURN result;
	END;
$$;


ALTER FUNCTION metadata.pageformsgetactionsbypage(idpage numeric) OWNER TO appowner;

--
-- Name: pageformsgetformtable(integer); Type: FUNCTION; Schema: metadata; Owner: appowner
--

CREATE FUNCTION metadata.pageformsgetformtable(idform integer) RETURNS TABLE(id integer, appid integer, label character varying, tablename character varying, description character varying, createdat timestamp without time zone, updatedat timestamp without time zone)
    LANGUAGE plpgsql
    AS $$

  BEGIN
    RETURN QUERY
    select
      tbl.id,
      tbl.appid,
      tbl.label,
      tbl.tablename,
      tbl.description,
      tbl.createdat,
      tbl.updatedat
    from metadata.pageforms pf, metadata.appcolumns col, metadata.apptables tbl
    where pf.id = idform and col.id = pf.appcolumnid and tbl.id = col.apptableid;
  END;
$$;


ALTER FUNCTION metadata.pageformsgetformtable(idform integer) OWNER TO appowner;

--
-- Name: pageformsupdate(numeric, numeric, text, jsonb); Type: FUNCTION; Schema: metadata; Owner: appowner
--

CREATE FUNCTION metadata.pageformsupdate(idform numeric, idappcolumn numeric, descr text, jsonvalue jsonb) RETURNS integer
    LANGUAGE plpgsql
    AS $$
  DECLARE
    id_val integer;
	BEGIN
    UPDATE metadata.pageforms
      SET jsondata = jsonvalue,
			    updatedat = now(),
          appcolumnid = idappcolumn,
          description = descr
    WHERE id = idform;
    RETURN idform;
  END;
$$;


ALTER FUNCTION metadata.pageformsupdate(idform numeric, idappcolumn numeric, descr text, jsonvalue jsonb) OWNER TO appowner;

--
-- Name: pageupdate(json); Type: FUNCTION; Schema: metadata; Owner: appowner
--

CREATE FUNCTION metadata.pageupdate(item json) RETURNS json
    LANGUAGE plpgsql
    AS $$

DECLARE
  result JSON;
  id_val integer;
  pageid integer;
  pagetitle text;
  pagename text;
  description text;

BEGIN
  pageid := item->'id';
  pagetitle := item->>'title';
  pagename := item->>'name';
  description := item->>'description';

  EXECUTE 'UPDATE metadata.pages SET title = ''' || pagetitle || ''', name = ''' || pagename || ''', description = ''' || description ||
          ''' WHERE metadata.pages.id = ' || pageid ||
          ' RETURNING metadata.pages.id;'
  INTO id_val;

  EXECUTE 'SELECT row_to_json(t) FROM ( SELECT * FROM metadata.pagefindbyid(' || id_val || ')) t;' INTO result;
	RETURN result;
END;
$$;


ALTER FUNCTION metadata.pageupdate(item json) OWNER TO appowner;

--
-- Name: testarrays(integer, integer[]); Type: FUNCTION; Schema: metadata; Owner: appowner
--

CREATE FUNCTION metadata.testarrays(idform integer, arr1 integer[]) RETURNS integer
    LANGUAGE plpgsql
    AS $$
  DECLARE
--     id_val integer;
--     rec_field RECORD;
    arr integer;
    idx integer;

  BEGIN
    idx := 0;
    FOREACH arr IN ARRAY arr1
    LOOP
      RAISE NOTICE 'arr: |%| idx: %', arr, idx;
      idx := idx + 1;
    END LOOP;

  END;
$$;


ALTER FUNCTION metadata.testarrays(idform integer, arr1 integer[]) OWNER TO appowner;

--
-- Name: testarrays(integer, integer[], text[]); Type: FUNCTION; Schema: metadata; Owner: appowner
--

CREATE FUNCTION metadata.testarrays(idform integer, arr1 integer[], arr2 text[]) RETURNS integer
    LANGUAGE plpgsql
    AS $$
  DECLARE
--     id_val integer;
--     rec_field RECORD;
    arr integer;
    idx integer;

  BEGIN
    idx := 1;
    FOREACH arr IN ARRAY arr1
    LOOP
      RAISE NOTICE 'arr: |%| idx: %  text: %', arr, idx, arr2[idx];
      idx := idx + 1;
    END LOOP;

    RETURN array_length(arr2, 1);
  END;
$$;


ALTER FUNCTION metadata.testarrays(idform integer, arr1 integer[], arr2 text[]) OWNER TO appowner;

--
-- Name: workflowstateadd(integer, integer); Type: FUNCTION; Schema: metadata; Owner: appowner
--

CREATE FUNCTION metadata.workflowstateadd(idtable integer, idissuetype integer) RETURNS TABLE(id integer, appid integer, name character varying, issuetypeid integer, initialstate boolean, workflowactionid integer, workflowstateid integer, workflowactionvalue integer)
    LANGUAGE plpgsql
    AS $$

	BEGIN
    RETURN QUERY
    select
      st.id,
      st.appid,
      st.name,
      st.issuetypeid,
      st.initialstate,
      col1.id as workflowactionid,
      col2.id as workflowstateid,
      action.id as workflowactionvalue
    from
      app.workflow_states st
      left outer join metadata.appcolumns as col1 on col1.apptableid = idtable and col1.columnname = 'workflowactionid'
      left outer join metadata.appcolumns as col2 on col2.apptableid = idtable and col2.columnname = 'workflowstateid'
      left outer join app.workflow_actions as action on action.name = 'Submission' and action.appid = st.appid
    where st.issuetypeid = idissuetype and st.initialstate = true;
	END;
$$;


ALTER FUNCTION metadata.workflowstateadd(idtable integer, idissuetype integer) OWNER TO appowner;

--
-- Name: workflowstatebyid(numeric); Type: FUNCTION; Schema: metadata; Owner: appowner
--

CREATE FUNCTION metadata.workflowstatebyid(idissuetype numeric) RETURNS TABLE(issuetype character varying, status character varying, wf_stat character varying, id integer, name character varying, description character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
		RETURN QUERY
    select
      iss.label as issuetype,
      stat.label as status,
      wf_stat.name as wf_stat,
      s.id,
      s.name,
      s.description
    from metadata.workflow_states as s
    left join metadata.issuetypes as iss on iss.id = s.issuetypeid
    left join metadata.status as stat on stat.id = s.statusid
    left join metadata.workflow_status wf_stat on wf_stat.id = s.workflowstatusid
    where issuetypeid = idissuetype
    order by status, wf_stat;
	END;
$$;


ALTER FUNCTION metadata.workflowstatebyid(idissuetype numeric) OWNER TO appowner;

--
-- Name: workflowstatetransition(integer, boolean, integer); Type: FUNCTION; Schema: metadata; Owner: appowner
--

CREATE FUNCTION metadata.workflowstatetransition(idtable integer, initialstate boolean, idkey integer) RETURNS TABLE(appid integer, name character varying, issuetypeid integer, actionid integer, stateinid integer, stateoutid integer, workflowactionid integer, workflowstateid integer, statein character varying, action character varying)
    LANGUAGE plpgsql
    AS $$

  DECLARE
    nullVar varchar;

	BEGIN
	  IF (initialstate) THEN
      RETURN QUERY
      select
        st.appid,
        st.name,
        st.issuetypeid,
        action.id as actionid,
        0 as stateinid,
        st.id as stateoutid,
        col1.id as workflowactionid,
        col2.id as workflowstateid,
        nullVar as statein,
        action.name as action
      from
        app.workflow_states st
        left outer join metadata.appcolumns as col1 on col1.apptableid = idtable and col1.columnname = 'workflowactionid'
        left outer join metadata.appcolumns as col2 on col2.apptableid = idtable and col2.columnname = 'workflowstateid'
        left outer join app.workflow_actions as action on action.name = 'Submission' and action.appid = st.appid
      where st.issuetypeid = idkey and st.initialstate = true;
    ELSE
      RETURN QUERY
      select
        st.appid,
        state.name,
        state.issuetypeid,
        st.actionid,
        st.stateinid,
        st.stateoutid,
        col1.id as workflowactionid,
        col2.id as workflowstateid,
				state2.name as statein,
				action.name as action
      from
        app.workflow_statetransitions st
        left outer join metadata.appcolumns as col1 on col1.apptableid = idtable and col1.columnname = 'workflowactionid'
        left outer join metadata.appcolumns as col2 on col2.apptableid = idtable and col2.columnname = 'workflowstateid'
        left outer join app.workflow_states as state on state.id = st.stateoutid
        left outer join app.workflow_states as state2 on state2.id = st.stateinid
        left outer join app.workflow_actions as action on action.id = st.actionid
      where st.id = idkey;
    END IF;
	END;
$$;


ALTER FUNCTION metadata.workflowstatetransition(idtable integer, initialstate boolean, idkey integer) OWNER TO appowner;

--
-- Name: workflowstateupdate(integer, integer); Type: FUNCTION; Schema: metadata; Owner: appowner
--

CREATE FUNCTION metadata.workflowstateupdate(idtable integer, idtransition integer) RETURNS TABLE(id integer, appid integer, actionid integer, stateinid integer, stateoutid integer, label character varying, workflowactionid integer, workflowstateid integer)
    LANGUAGE plpgsql
    AS $$

	BEGIN
    RETURN QUERY
    select
    st.id,
		st.appid,
    st.actionid,
    st.stateinid,
		st.stateoutid,
		st.label,
    col1.id as workflowactionid,
    col2.id as workflowstateid
    from
      app.workflow_statetransitions st
      left outer join metadata.appcolumns as col1 on col1.apptableid = idtable and col1.columnname = 'workflowactionid'
      left outer join metadata.appcolumns as col2 on col2.apptableid = idtable and col2.columnname = 'workflowstateid'
    where st.id = idtransition;
	END;
$$;


ALTER FUNCTION metadata.workflowstateupdate(idtable integer, idtransition integer) OWNER TO appowner;

--
-- Name: findrelatedrecords(integer, integer, integer); Type: FUNCTION; Schema: public; Owner: appowner
--

CREATE FUNCTION public.findrelatedrecords(appcolumnid integer, idrec integer, iduser integer DEFAULT NULL::integer) RETURNS json
    LANGUAGE plpgsql
    AS $$
DECLARE
    rec_field RECORD;
    resp      JSON;
    result    JSON;
    execStr   TEXT;
    tableName TEXT;
    selectStr TEXT := 'tbl.id as id';
    fromStr   TEXT := '';
    whereStr  TEXT := '';
    tableId   INTEGER;
    relatedColumn TEXT;
    cur_fields scroll CURSOR (id INTEGER) FOR SELECT * FROM metadata.appformGetFields(id, iduser);

BEGIN
    select * into rec_field from metadata.appcolumns where id = appcolumnid;
    tableId := rec_field.apptableid;
    RAISE NOTICE '********** tableId: %', tableId;
    IF(rec_field.jsonfield) THEN
      relatedColumn := 'CAST(coalesce(tbl.jsondata->>''' || rec_field.columnname || ''', ''0'') AS INTEGER)';
    ELSE
      relatedColumn := 'tbl.' || rec_field.columnname;
    END IF;

    OPEN cur_fields(tableId);
    execStr := 'SELECT * from metadata.getColumnElementsFromRecord(''' || cur_fields || ''', ' || idrec || ');';
    EXECUTE execStr INTO resp;
    CLOSE cur_fields;

    tableName := resp ->> 'tableName';
    selectStr := resp ->> 'selectStr';
    fromStr := resp ->> 'fromStr';
    whereStr := resp ->> 'whereStr';

    RAISE NOTICE 'tableName: %', tableName;
    RAISE NOTICE 'selectStr: %', selectStr;
    RAISE NOTICE 'fromStr: %', fromStr;
    RAISE NOTICE 'whereStr: %', whereStr;

    execStr := 'SELECT ' || selectStr || ', users.firstname, users.mi, users.lastname, users.email, users.phone, ' ||
               'array(
                select json_build_object(''id'', attach.id, ''path'', attach.path, ''uniquename'', attach.uniquename, ''name'', attach.name, ''size'', attach.size)
                from app.tableattachments as ta,
                app.attachments as attach
                where ta.apptableid=tbl.apptableid and ta.recordid=tbl.id and attach.id=ta.attachmentid
                ) attachments' ||
               ' FROM app.' || tableName || ' as tbl ' || fromStr ||
               ' where tbl.apptableid=' || tableId ||
               ' AND ' || relatedColumn || '=' || idrec ||
               ' ORDER BY tbl.updatedat DESC';

    RAISE NOTICE 'execStr:';
    RAISE NOTICE '%', execStr;

    EXECUTE 'SELECT array_to_json(array_agg(row_to_json(t))) FROM (' || execStr || ') t;' INTO result;
    RETURN result;
END;
$$;


ALTER FUNCTION public.findrelatedrecords(appcolumnid integer, idrec integer, iduser integer) OWNER TO appowner;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: activity; Type: TABLE; Schema: app; Owner: appowner
--

CREATE TABLE app.activity (
    id integer NOT NULL,
    appid integer NOT NULL,
    label character varying(128),
    description character varying(128),
    createdat timestamp without time zone,
    updatedat timestamp without time zone DEFAULT now(),
    jsondata jsonb
);


ALTER TABLE app.activity OWNER TO appowner;

--
-- Name: activities_id_seq; Type: SEQUENCE; Schema: app; Owner: appowner
--

CREATE SEQUENCE app.activities_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE app.activities_id_seq OWNER TO appowner;

--
-- Name: activities_id_seq; Type: SEQUENCE OWNED BY; Schema: app; Owner: appowner
--

ALTER SEQUENCE app.activities_id_seq OWNED BY app.activity.id;


--
-- Name: adhoc_queries; Type: TABLE; Schema: app; Owner: appowner
--

CREATE TABLE app.adhoc_queries (
    id integer NOT NULL,
    name character varying(60),
    appid integer NOT NULL,
    jsondata jsonb,
    createdat timestamp without time zone,
    updatedat timestamp without time zone DEFAULT now(),
    reporttemplateid integer,
    ownerid integer
);


ALTER TABLE app.adhoc_queries OWNER TO appowner;

--
-- Name: adhoc_queries_id_seq; Type: SEQUENCE; Schema: app; Owner: appowner
--

CREATE SEQUENCE app.adhoc_queries_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE app.adhoc_queries_id_seq OWNER TO appowner;

--
-- Name: adhoc_queries_id_seq; Type: SEQUENCE OWNED BY; Schema: app; Owner: appowner
--

ALTER SEQUENCE app.adhoc_queries_id_seq OWNED BY app.adhoc_queries.id;


--
-- Name: appbunos; Type: TABLE; Schema: app; Owner: appowner
--

CREATE TABLE app.appbunos (
    id integer NOT NULL,
    appid integer NOT NULL,
    bunoid integer NOT NULL,
    createdat timestamp without time zone,
    updatedat timestamp without time zone DEFAULT now()
);


ALTER TABLE app.appbunos OWNER TO appowner;

--
-- Name: appbunos_id_seq; Type: SEQUENCE; Schema: app; Owner: appowner
--

CREATE SEQUENCE app.appbunos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE app.appbunos_id_seq OWNER TO appowner;

--
-- Name: appbunos_id_seq; Type: SEQUENCE OWNED BY; Schema: app; Owner: appowner
--

ALTER SEQUENCE app.appbunos_id_seq OWNED BY app.appbunos.id;


--
-- Name: appdata; Type: TABLE; Schema: app; Owner: appowner
--

CREATE TABLE app.appdata (
    id integer NOT NULL,
    jsondata jsonb,
    createdat timestamp with time zone,
    updatedat timestamp with time zone DEFAULT now(),
    apptableid integer NOT NULL,
    appid integer NOT NULL
);


ALTER TABLE app.appdata OWNER TO appowner;

--
-- Name: appdata_id_seq; Type: SEQUENCE; Schema: app; Owner: appowner
--

CREATE SEQUENCE app.appdata_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE app.appdata_id_seq OWNER TO appowner;

--
-- Name: appdata_id_seq; Type: SEQUENCE OWNED BY; Schema: app; Owner: appowner
--

ALTER SEQUENCE app.appdata_id_seq OWNED BY app.appdata.id;


--
-- Name: tableattachments; Type: TABLE; Schema: app; Owner: appowner
--

CREATE TABLE app.tableattachments (
    createdat timestamp without time zone,
    updatedat timestamp without time zone DEFAULT now(),
    id integer NOT NULL,
    attachmentid integer NOT NULL,
    apptableid integer NOT NULL,
    recordid integer NOT NULL
);


ALTER TABLE app.tableattachments OWNER TO appowner;

--
-- Name: appdataattachments_id_seq; Type: SEQUENCE; Schema: app; Owner: appowner
--

CREATE SEQUENCE app.appdataattachments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE app.appdataattachments_id_seq OWNER TO appowner;

--
-- Name: appdataattachments_id_seq; Type: SEQUENCE OWNED BY; Schema: app; Owner: appowner
--

ALTER SEQUENCE app.appdataattachments_id_seq OWNED BY app.tableattachments.id;


--
-- Name: attachments; Type: TABLE; Schema: app; Owner: appowner
--

CREATE TABLE app.attachments (
    id integer NOT NULL,
    path character varying(2000),
    uniquename character varying(128),
    name character varying(128),
    size integer,
    createdat timestamp without time zone,
    updatedat timestamp without time zone DEFAULT now()
);


ALTER TABLE app.attachments OWNER TO appowner;

--
-- Name: attachments_id_seq; Type: SEQUENCE; Schema: app; Owner: appowner
--

CREATE SEQUENCE app.attachments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE app.attachments_id_seq OWNER TO appowner;

--
-- Name: attachments_id_seq; Type: SEQUENCE OWNED BY; Schema: app; Owner: appowner
--

ALTER SEQUENCE app.attachments_id_seq OWNED BY app.attachments.id;


--
-- Name: bunos; Type: TABLE; Schema: app; Owner: appowner
--

CREATE TABLE app.bunos (
    id integer NOT NULL,
    identifier character varying(40) NOT NULL,
    description character varying(128),
    createdat timestamp without time zone,
    updatedat timestamp without time zone DEFAULT now()
);


ALTER TABLE app.bunos OWNER TO appowner;

--
-- Name: bunos_id_seq; Type: SEQUENCE; Schema: app; Owner: appowner
--

CREATE SEQUENCE app.bunos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE app.bunos_id_seq OWNER TO appowner;

--
-- Name: bunos_id_seq; Type: SEQUENCE OWNED BY; Schema: app; Owner: appowner
--

ALTER SEQUENCE app.bunos_id_seq OWNED BY app.bunos.id;


--
-- Name: dashboardreports; Type: TABLE; Schema: app; Owner: appowner
--

CREATE TABLE app.dashboardreports (
    id integer NOT NULL,
    userid integer NOT NULL,
    adhocqueryid integer NOT NULL,
    createdat timestamp without time zone,
    updatedat timestamp without time zone DEFAULT now()
);


ALTER TABLE app.dashboardreports OWNER TO appowner;

--
-- Name: dashboardreport_id_seq; Type: SEQUENCE; Schema: app; Owner: appowner
--

CREATE SEQUENCE app.dashboardreport_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE app.dashboardreport_id_seq OWNER TO appowner;

--
-- Name: dashboardreport_id_seq; Type: SEQUENCE OWNED BY; Schema: app; Owner: appowner
--

ALTER SEQUENCE app.dashboardreport_id_seq OWNED BY app.dashboardreports.id;


--
-- Name: groups; Type: TABLE; Schema: app; Owner: appowner
--

CREATE TABLE app.groups (
    id integer NOT NULL,
    name character varying(60) NOT NULL,
    description character varying(256),
    createdat timestamp without time zone,
    updatedat timestamp without time zone DEFAULT now()
);


ALTER TABLE app.groups OWNER TO appowner;

--
-- Name: groups_id_seq; Type: SEQUENCE; Schema: app; Owner: appowner
--

CREATE SEQUENCE app.groups_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE app.groups_id_seq OWNER TO appowner;

--
-- Name: groups_id_seq; Type: SEQUENCE OWNED BY; Schema: app; Owner: appowner
--

ALTER SEQUENCE app.groups_id_seq OWNED BY app.groups.id;


--
-- Name: issueattachments; Type: TABLE; Schema: app; Owner: appowner
--

CREATE TABLE app.issueattachments (
    id integer NOT NULL,
    issueid integer NOT NULL,
    attachmentid integer NOT NULL,
    createdat timestamp without time zone,
    updatedat timestamp without time zone DEFAULT now()
);


ALTER TABLE app.issueattachments OWNER TO appowner;

--
-- Name: issueattachments_id_seq; Type: SEQUENCE; Schema: app; Owner: appowner
--

CREATE SEQUENCE app.issueattachments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE app.issueattachments_id_seq OWNER TO appowner;

--
-- Name: issueattachments_id_seq; Type: SEQUENCE OWNED BY; Schema: app; Owner: appowner
--

ALTER SEQUENCE app.issueattachments_id_seq OWNED BY app.issueattachments.id;


--
-- Name: issues; Type: TABLE; Schema: app; Owner: appowner
--

CREATE TABLE app.issues (
    id integer NOT NULL,
    appid integer NOT NULL,
    issuetypeid integer NOT NULL,
    createdat timestamp with time zone,
    updatedat timestamp with time zone DEFAULT now(),
    jsondata jsonb,
    subject character varying(1000) NOT NULL,
    activityid integer,
    priorityid integer,
    statusid integer,
    workflowstateid integer,
    workflowactionid integer
);


ALTER TABLE app.issues OWNER TO appowner;

--
-- Name: issues_id_seq; Type: SEQUENCE; Schema: app; Owner: appowner
--

CREATE SEQUENCE app.issues_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE app.issues_id_seq OWNER TO appowner;

--
-- Name: issues_id_seq; Type: SEQUENCE OWNED BY; Schema: app; Owner: appowner
--

ALTER SEQUENCE app.issues_id_seq OWNED BY app.issues.id;


--
-- Name: issuetypes; Type: TABLE; Schema: app; Owner: appowner
--

CREATE TABLE app.issuetypes (
    id integer NOT NULL,
    appid integer NOT NULL,
    searchable boolean DEFAULT true,
    description character varying(1000),
    createdat timestamp without time zone,
    updatedat timestamp without time zone DEFAULT now(),
    label character varying(60),
    jsondata jsonb
);


ALTER TABLE app.issuetypes OWNER TO appowner;

--
-- Name: issuetypes_id_seq; Type: SEQUENCE; Schema: app; Owner: appowner
--

CREATE SEQUENCE app.issuetypes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE app.issuetypes_id_seq OWNER TO appowner;

--
-- Name: issuetypes_id_seq; Type: SEQUENCE OWNED BY; Schema: app; Owner: appowner
--

ALTER SEQUENCE app.issuetypes_id_seq OWNED BY app.issuetypes.id;


--
-- Name: masterdata; Type: TABLE; Schema: app; Owner: appowner
--

CREATE TABLE app.masterdata (
    id integer NOT NULL,
    apptableid integer NOT NULL,
    name character varying(60),
    description character varying(1000),
    createdat timestamp without time zone,
    updatedat timestamp without time zone DEFAULT now(),
    appid integer NOT NULL,
    jsondata jsonb
);


ALTER TABLE app.masterdata OWNER TO appowner;

--
-- Name: mastertypes_id_seq; Type: SEQUENCE; Schema: app; Owner: appowner
--

CREATE SEQUENCE app.mastertypes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE app.mastertypes_id_seq OWNER TO appowner;

--
-- Name: mastertypes_id_seq; Type: SEQUENCE OWNED BY; Schema: app; Owner: appowner
--

ALTER SEQUENCE app.mastertypes_id_seq OWNED BY app.masterdata.id;


--
-- Name: priority; Type: TABLE; Schema: app; Owner: appowner
--

CREATE TABLE app.priority (
    id integer NOT NULL,
    appid integer NOT NULL,
    label character varying(128),
    description character varying(128),
    createdat timestamp without time zone,
    updatedat timestamp without time zone DEFAULT now(),
    jsondata jsonb
);


ALTER TABLE app.priority OWNER TO appowner;

--
-- Name: priority_id_seq; Type: SEQUENCE; Schema: app; Owner: appowner
--

CREATE SEQUENCE app.priority_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE app.priority_id_seq OWNER TO appowner;

--
-- Name: priority_id_seq; Type: SEQUENCE OWNED BY; Schema: app; Owner: appowner
--

ALTER SEQUENCE app.priority_id_seq OWNED BY app.priority.id;


--
-- Name: reporttemplates; Type: TABLE; Schema: app; Owner: appowner
--

CREATE TABLE app.reporttemplates (
    id integer NOT NULL,
    appid integer NOT NULL,
    name character varying(60) NOT NULL,
    createdat timestamp without time zone,
    updatedat timestamp without time zone DEFAULT now(),
    primarytableid integer,
    jsondata jsonb,
    ownerid integer,
    editaction boolean DEFAULT false,
    deleteaction boolean DEFAULT false
);


ALTER TABLE app.reporttemplates OWNER TO appowner;

--
-- Name: reporttemplates_id_seq; Type: SEQUENCE; Schema: app; Owner: appowner
--

CREATE SEQUENCE app.reporttemplates_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE app.reporttemplates_id_seq OWNER TO appowner;

--
-- Name: reporttemplates_id_seq; Type: SEQUENCE OWNED BY; Schema: app; Owner: appowner
--

ALTER SEQUENCE app.reporttemplates_id_seq OWNED BY app.reporttemplates.id;


--
-- Name: resourcetypes; Type: TABLE; Schema: app; Owner: appowner
--

CREATE TABLE app.resourcetypes (
    id integer NOT NULL,
    name character varying(20) NOT NULL
);


ALTER TABLE app.resourcetypes OWNER TO appowner;

--
-- Name: resourcetypes_id_seq; Type: SEQUENCE; Schema: app; Owner: appowner
--

CREATE SEQUENCE app.resourcetypes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE app.resourcetypes_id_seq OWNER TO appowner;

--
-- Name: resourcetypes_id_seq; Type: SEQUENCE OWNED BY; Schema: app; Owner: appowner
--

ALTER SEQUENCE app.resourcetypes_id_seq OWNED BY app.resourcetypes.id;


--
-- Name: roleassignments; Type: TABLE; Schema: app; Owner: appowner
--

CREATE TABLE app.roleassignments (
    id integer NOT NULL,
    roleid integer NOT NULL,
    userid integer,
    groupid integer,
    createdat timestamp without time zone,
    updatedat timestamp without time zone DEFAULT now()
);


ALTER TABLE app.roleassignments OWNER TO appowner;

--
-- Name: roleassignments_id_seq; Type: SEQUENCE; Schema: app; Owner: appowner
--

CREATE SEQUENCE app.roleassignments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE app.roleassignments_id_seq OWNER TO appowner;

--
-- Name: roleassignments_id_seq; Type: SEQUENCE OWNED BY; Schema: app; Owner: appowner
--

ALTER SEQUENCE app.roleassignments_id_seq OWNED BY app.roleassignments.id;


--
-- Name: rolerestrictions; Type: TABLE; Schema: app; Owner: appowner
--

CREATE TABLE app.rolerestrictions (
    id integer NOT NULL,
    resourcetypeid integer NOT NULL,
    appid integer NOT NULL,
    roleid integer,
    visible boolean DEFAULT false,
    editable boolean DEFAULT false,
    resourceid integer NOT NULL,
    workflowstateid integer
);


ALTER TABLE app.rolerestrictions OWNER TO appowner;

--
-- Name: rolepermissions_id_seq; Type: SEQUENCE; Schema: app; Owner: appowner
--

CREATE SEQUENCE app.rolepermissions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE app.rolepermissions_id_seq OWNER TO appowner;

--
-- Name: rolepermissions_id_seq; Type: SEQUENCE OWNED BY; Schema: app; Owner: appowner
--

ALTER SEQUENCE app.rolepermissions_id_seq OWNED BY app.rolerestrictions.id;


--
-- Name: roles; Type: TABLE; Schema: app; Owner: appowner
--

CREATE TABLE app.roles (
    id integer NOT NULL,
    name character varying(60) NOT NULL,
    description character varying(256),
    appid integer NOT NULL,
    createdat timestamp without time zone,
    updatedat timestamp without time zone DEFAULT now(),
    jsondata jsonb
);


ALTER TABLE app.roles OWNER TO appowner;

--
-- Name: roles_id_seq; Type: SEQUENCE; Schema: app; Owner: appowner
--

CREATE SEQUENCE app.roles_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE app.roles_id_seq OWNER TO appowner;

--
-- Name: roles_id_seq; Type: SEQUENCE OWNED BY; Schema: app; Owner: appowner
--

ALTER SEQUENCE app.roles_id_seq OWNED BY app.roles.id;


--
-- Name: status; Type: TABLE; Schema: app; Owner: appowner
--

CREATE TABLE app.status (
    id integer NOT NULL,
    appid integer NOT NULL,
    label character varying(128),
    description character varying(128),
    createdat timestamp without time zone,
    updatedat timestamp without time zone DEFAULT now(),
    jsondata jsonb
);


ALTER TABLE app.status OWNER TO appowner;

--
-- Name: status_id_seq; Type: SEQUENCE; Schema: app; Owner: appowner
--

CREATE SEQUENCE app.status_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE app.status_id_seq OWNER TO appowner;

--
-- Name: status_id_seq; Type: SEQUENCE OWNED BY; Schema: app; Owner: appowner
--

ALTER SEQUENCE app.status_id_seq OWNED BY app.status.id;


--
-- Name: support; Type: TABLE; Schema: app; Owner: appowner
--

CREATE TABLE app.support (
    id integer NOT NULL,
    title character varying(60) NOT NULL,
    value character varying(128),
    hours character varying(60),
    userid integer,
    createdat timestamp without time zone,
    updatedat timestamp without time zone DEFAULT now(),
    displayorder integer,
    appid integer NOT NULL
);


ALTER TABLE app.support OWNER TO appowner;

--
-- Name: support_id_seq; Type: SEQUENCE; Schema: app; Owner: appowner
--

CREATE SEQUENCE app.support_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE app.support_id_seq OWNER TO appowner;

--
-- Name: support_id_seq; Type: SEQUENCE OWNED BY; Schema: app; Owner: appowner
--

ALTER SEQUENCE app.support_id_seq OWNED BY app.support.id;


--
-- Name: userattachments; Type: TABLE; Schema: app; Owner: appowner
--

CREATE TABLE app.userattachments (
    id integer NOT NULL,
    userid integer NOT NULL,
    attachmentid integer NOT NULL,
    createdat timestamp without time zone,
    updatedat timestamp without time zone DEFAULT now()
);


ALTER TABLE app.userattachments OWNER TO appowner;

--
-- Name: userattachments_id_seq; Type: SEQUENCE; Schema: app; Owner: appowner
--

CREATE SEQUENCE app.userattachments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE app.userattachments_id_seq OWNER TO appowner;

--
-- Name: userattachments_id_seq; Type: SEQUENCE OWNED BY; Schema: app; Owner: appowner
--

ALTER SEQUENCE app.userattachments_id_seq OWNED BY app.userattachments.id;


--
-- Name: usergroups; Type: TABLE; Schema: app; Owner: appowner
--

CREATE TABLE app.usergroups (
    id integer NOT NULL,
    userid integer NOT NULL,
    groupid integer NOT NULL,
    createdat timestamp without time zone,
    updatedat timestamp without time zone DEFAULT now()
);


ALTER TABLE app.usergroups OWNER TO appowner;

--
-- Name: usergroups_id_seq; Type: SEQUENCE; Schema: app; Owner: appowner
--

CREATE SEQUENCE app.usergroups_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE app.usergroups_id_seq OWNER TO appowner;

--
-- Name: usergroups_id_seq; Type: SEQUENCE OWNED BY; Schema: app; Owner: appowner
--

ALTER SEQUENCE app.usergroups_id_seq OWNED BY app.usergroups.id;


--
-- Name: users; Type: TABLE; Schema: app; Owner: appowner
--

CREATE TABLE app.users (
    id integer NOT NULL,
    active integer,
    email character varying(100),
    firstname character varying(100),
    mi character varying(1),
    lastname character varying(100),
    designationid integer,
    phone character varying(20),
    dsn character varying(20),
    fax character varying(20),
    npke_subject character varying(255),
    npke_edipi numeric,
    npke_user character varying(50),
    rankid integer,
    activityid integer,
    affiliationid integer,
    siteid integer,
    saarn numeric,
    initialdate timestamp without time zone DEFAULT now(),
    updatedate timestamp without time zone,
    lastlogindate timestamp without time zone,
    branchid integer,
    approvaldate timestamp without time zone,
    disabled integer DEFAULT 1,
    aircrafttypeid integer
);


ALTER TABLE app.users OWNER TO appowner;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: app; Owner: appowner
--

ALTER TABLE app.users ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME app.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: workflow_status; Type: TABLE; Schema: app; Owner: appowner
--

CREATE TABLE app.workflow_status (
    id integer NOT NULL,
    name character varying(20),
    description character varying(20),
    createdat timestamp without time zone,
    updatedat timestamp without time zone DEFAULT now(),
    appid integer NOT NULL,
    jsondata jsonb
);


ALTER TABLE app.workflow_status OWNER TO appowner;

--
-- Name: workflow_actionresponse_id_seq; Type: SEQUENCE; Schema: app; Owner: appowner
--

CREATE SEQUENCE app.workflow_actionresponse_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE app.workflow_actionresponse_id_seq OWNER TO appowner;

--
-- Name: workflow_actionresponse_id_seq; Type: SEQUENCE OWNED BY; Schema: app; Owner: appowner
--

ALTER SEQUENCE app.workflow_actionresponse_id_seq OWNED BY app.workflow_status.id;


--
-- Name: workflow_actions; Type: TABLE; Schema: app; Owner: appowner
--

CREATE TABLE app.workflow_actions (
    id integer NOT NULL,
    name character varying(100),
    description character varying(128),
    active boolean,
    appid integer,
    jsondata jsonb,
    createdat timestamp without time zone,
    updatedat timestamp without time zone DEFAULT now()
);


ALTER TABLE app.workflow_actions OWNER TO appowner;

--
-- Name: workflow_actions_id_seq; Type: SEQUENCE; Schema: app; Owner: appowner
--

CREATE SEQUENCE app.workflow_actions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE app.workflow_actions_id_seq OWNER TO appowner;

--
-- Name: workflow_actions_id_seq; Type: SEQUENCE OWNED BY; Schema: app; Owner: appowner
--

ALTER SEQUENCE app.workflow_actions_id_seq OWNED BY app.workflow_actions.id;


--
-- Name: workflow_states; Type: TABLE; Schema: app; Owner: appowner
--

CREATE TABLE app.workflow_states (
    id integer NOT NULL,
    name character varying(50),
    description character varying(1000),
    statusid integer NOT NULL,
    workflowstatusid integer,
    appid integer NOT NULL,
    issuetypeid integer,
    jsondata jsonb,
    initialstate boolean DEFAULT false,
    createdat timestamp without time zone,
    updatedat timestamp without time zone DEFAULT now()
);


ALTER TABLE app.workflow_states OWNER TO appowner;

--
-- Name: workflow_states_id_seq; Type: SEQUENCE; Schema: app; Owner: appowner
--

CREATE SEQUENCE app.workflow_states_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE app.workflow_states_id_seq OWNER TO appowner;

--
-- Name: workflow_states_id_seq; Type: SEQUENCE OWNED BY; Schema: app; Owner: appowner
--

ALTER SEQUENCE app.workflow_states_id_seq OWNED BY app.workflow_states.id;


--
-- Name: workflow_statetransitions; Type: TABLE; Schema: app; Owner: appowner
--

CREATE TABLE app.workflow_statetransitions (
    id integer NOT NULL,
    actionid integer,
    stateinid integer,
    stateoutid integer,
    label character varying(100),
    appid integer,
    jsondata jsonb,
    createdat timestamp without time zone,
    updatedat timestamp without time zone DEFAULT now(),
    allowedroles integer[]
);


ALTER TABLE app.workflow_statetransitions OWNER TO appowner;

--
-- Name: workflow_statetransitions_id_seq; Type: SEQUENCE; Schema: app; Owner: appowner
--

CREATE SEQUENCE app.workflow_statetransitions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE app.workflow_statetransitions_id_seq OWNER TO appowner;

--
-- Name: workflow_statetransitions_id_seq; Type: SEQUENCE OWNED BY; Schema: app; Owner: appowner
--

ALTER SEQUENCE app.workflow_statetransitions_id_seq OWNED BY app.workflow_statetransitions.id;


--
-- Name: actions; Type: TABLE; Schema: metadata; Owner: appowner
--

CREATE TABLE metadata.actions (
    name character varying(40),
    id integer NOT NULL
);


ALTER TABLE metadata.actions OWNER TO appowner;

--
-- Name: actions_id_seq; Type: SEQUENCE; Schema: metadata; Owner: appowner
--

CREATE SEQUENCE metadata.actions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE metadata.actions_id_seq OWNER TO appowner;

--
-- Name: actions_id_seq; Type: SEQUENCE OWNED BY; Schema: metadata; Owner: appowner
--

ALTER SEQUENCE metadata.actions_id_seq OWNED BY metadata.actions.id;


--
-- Name: apiactions; Type: TABLE; Schema: metadata; Owner: appowner
--

CREATE TABLE metadata.apiactions (
    id integer NOT NULL,
    name character varying(40) NOT NULL,
    description character varying(400)
);


ALTER TABLE metadata.apiactions OWNER TO appowner;

--
-- Name: apiactions_id_seq; Type: SEQUENCE; Schema: metadata; Owner: appowner
--

CREATE SEQUENCE metadata.apiactions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE metadata.apiactions_id_seq OWNER TO appowner;

--
-- Name: apiactions_id_seq; Type: SEQUENCE OWNED BY; Schema: metadata; Owner: appowner
--

ALTER SEQUENCE metadata.apiactions_id_seq OWNED BY metadata.apiactions.id;


--
-- Name: appcolumns; Type: TABLE; Schema: metadata; Owner: appowner
--

CREATE TABLE metadata.appcolumns (
    id integer NOT NULL,
    apptableid integer NOT NULL,
    columnname character varying(40),
    label character varying(40),
    datatypeid integer NOT NULL,
    length integer,
    jsonfield boolean DEFAULT false,
    createdat timestamp without time zone,
    updatedat timestamp without time zone DEFAULT now(),
    mastertable character varying(40),
    mastercolumn character varying(40),
    name character varying(40),
    masterdisplay character varying(128),
    displayorder integer,
    active boolean DEFAULT true,
    allowedroles integer[],
    allowededitroles integer[]
);


ALTER TABLE metadata.appcolumns OWNER TO appowner;

--
-- Name: appcolumns_id_seq; Type: SEQUENCE; Schema: metadata; Owner: appowner
--

CREATE SEQUENCE metadata.appcolumns_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE metadata.appcolumns_id_seq OWNER TO appowner;

--
-- Name: appcolumns_id_seq; Type: SEQUENCE OWNED BY; Schema: metadata; Owner: appowner
--

ALTER SEQUENCE metadata.appcolumns_id_seq OWNED BY metadata.appcolumns.id;


--
-- Name: applications; Type: TABLE; Schema: metadata; Owner: appowner
--

CREATE TABLE metadata.applications (
    id integer NOT NULL,
    name character varying(40) NOT NULL,
    shortname character varying(20),
    description character varying(60)
);


ALTER TABLE metadata.applications OWNER TO appowner;

--
-- Name: TABLE applications; Type: COMMENT; Schema: metadata; Owner: appowner
--

COMMENT ON TABLE metadata.applications IS 'applications master file';


--
-- Name: applications_id_seq; Type: SEQUENCE; Schema: metadata; Owner: appowner
--

ALTER TABLE metadata.applications ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME metadata.applications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: appqueries; Type: TABLE; Schema: metadata; Owner: appowner
--

CREATE TABLE metadata.appqueries (
    id integer NOT NULL,
    procname character varying(60) NOT NULL,
    appid integer NOT NULL,
    schema character varying(20) NOT NULL,
    description character varying(256),
    createdat timestamp without time zone,
    updatedat timestamp without time zone DEFAULT now(),
    name character varying(60) NOT NULL,
    params character varying(20)[]
);


ALTER TABLE metadata.appqueries OWNER TO appowner;

--
-- Name: appquery_id_seq; Type: SEQUENCE; Schema: metadata; Owner: appowner
--

CREATE SEQUENCE metadata.appquery_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE metadata.appquery_id_seq OWNER TO appowner;

--
-- Name: appquery_id_seq; Type: SEQUENCE OWNED BY; Schema: metadata; Owner: appowner
--

ALTER SEQUENCE metadata.appquery_id_seq OWNED BY metadata.appqueries.id;


--
-- Name: apptables; Type: TABLE; Schema: metadata; Owner: appowner
--

CREATE TABLE metadata.apptables (
    id integer NOT NULL,
    appid integer,
    label character varying(40),
    tablename character varying(40),
    description character varying(128),
    createdat timestamp without time zone,
    updatedat timestamp without time zone DEFAULT now()
);


ALTER TABLE metadata.apptables OWNER TO appowner;

--
-- Name: apptables_id_seq; Type: SEQUENCE; Schema: metadata; Owner: appowner
--

CREATE SEQUENCE metadata.apptables_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE metadata.apptables_id_seq OWNER TO appowner;

--
-- Name: apptables_id_seq; Type: SEQUENCE OWNED BY; Schema: metadata; Owner: appowner
--

ALTER SEQUENCE metadata.apptables_id_seq OWNED BY metadata.apptables.id;


--
-- Name: columntemplate; Type: TABLE; Schema: metadata; Owner: appowner
--

CREATE TABLE metadata.columntemplate (
    id integer NOT NULL,
    tablename character varying(40),
    label character varying(40),
    datatypeid integer,
    length integer,
    jsonfield boolean,
    mastertable character varying(40),
    mastercolumn character varying(40),
    name character varying(40),
    masterdisplay character varying(128),
    columnname character varying(40)
);


ALTER TABLE metadata.columntemplate OWNER TO appowner;

--
-- Name: columntemplate_id_seq; Type: SEQUENCE; Schema: metadata; Owner: appowner
--

CREATE SEQUENCE metadata.columntemplate_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE metadata.columntemplate_id_seq OWNER TO appowner;

--
-- Name: columntemplate_id_seq; Type: SEQUENCE OWNED BY; Schema: metadata; Owner: appowner
--

ALTER SEQUENCE metadata.columntemplate_id_seq OWNED BY metadata.columntemplate.id;


--
-- Name: controltypes; Type: TABLE; Schema: metadata; Owner: appowner
--

CREATE TABLE metadata.controltypes (
    id integer NOT NULL,
    controlname character varying(30),
    multiselect boolean DEFAULT false,
    datatypeid integer NOT NULL
);


ALTER TABLE metadata.controltypes OWNER TO appowner;

--
-- Name: controltypes_id_seq; Type: SEQUENCE; Schema: metadata; Owner: appowner
--

ALTER TABLE metadata.controltypes ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME metadata.controltypes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: datatypes; Type: TABLE; Schema: metadata; Owner: appowner
--

CREATE TABLE metadata.datatypes (
    id integer NOT NULL,
    name character varying(20) NOT NULL
);


ALTER TABLE metadata.datatypes OWNER TO appowner;

--
-- Name: datatypes_id_seq; Type: SEQUENCE; Schema: metadata; Owner: appowner
--

CREATE SEQUENCE metadata.datatypes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE metadata.datatypes_id_seq OWNER TO appowner;

--
-- Name: datatypes_id_seq; Type: SEQUENCE OWNED BY; Schema: metadata; Owner: appowner
--

ALTER SEQUENCE metadata.datatypes_id_seq OWNED BY metadata.datatypes.id;


--
-- Name: events; Type: TABLE; Schema: metadata; Owner: appowner
--

CREATE TABLE metadata.events (
    id integer NOT NULL,
    name character varying(40),
    "description " character varying(128)
);


ALTER TABLE metadata.events OWNER TO appowner;

--
-- Name: events_id_seq; Type: SEQUENCE; Schema: metadata; Owner: appowner
--

CREATE SEQUENCE metadata.events_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE metadata.events_id_seq OWNER TO appowner;

--
-- Name: events_id_seq; Type: SEQUENCE OWNED BY; Schema: metadata; Owner: appowner
--

ALTER SEQUENCE metadata.events_id_seq OWNED BY metadata.events.id;


--
-- Name: fieldcategories; Type: TABLE; Schema: metadata; Owner: appowner
--

CREATE TABLE metadata.fieldcategories (
    id integer NOT NULL,
    name character varying(30),
    label character varying(30)
);


ALTER TABLE metadata.fieldcategories OWNER TO appowner;

--
-- Name: fieldcategories_id_seq; Type: SEQUENCE; Schema: metadata; Owner: appowner
--

CREATE SEQUENCE metadata.fieldcategories_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE metadata.fieldcategories_id_seq OWNER TO appowner;

--
-- Name: fieldcategories_id_seq; Type: SEQUENCE OWNED BY; Schema: metadata; Owner: appowner
--

ALTER SEQUENCE metadata.fieldcategories_id_seq OWNED BY metadata.fieldcategories.id;


--
-- Name: formeventactions; Type: TABLE; Schema: metadata; Owner: appowner
--

CREATE TABLE metadata.formeventactions (
    id integer NOT NULL,
    eventid integer NOT NULL,
    actionid integer NOT NULL,
    actiondata jsonb,
    pageformid integer,
    reporttemplateid integer
);


ALTER TABLE metadata.formeventactions OWNER TO appowner;

--
-- Name: formeventactions_id_seq; Type: SEQUENCE; Schema: metadata; Owner: appowner
--

CREATE SEQUENCE metadata.formeventactions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE metadata.formeventactions_id_seq OWNER TO appowner;

--
-- Name: formeventactions_id_seq; Type: SEQUENCE OWNED BY; Schema: metadata; Owner: appowner
--

ALTER SEQUENCE metadata.formeventactions_id_seq OWNED BY metadata.formeventactions.id;


--
-- Name: formresources; Type: TABLE; Schema: metadata; Owner: appowner
--

CREATE TABLE metadata.formresources (
    id integer NOT NULL,
    title character varying(40),
    tablename character varying(40),
    description character varying(128),
    apipath character varying(20),
    createdat timestamp without time zone,
    updatedat timestamp without time zone DEFAULT now(),
    specialprocessing boolean DEFAULT false,
    formid character varying(40) DEFAULT uuid_in((md5((random())::text))::cstring),
    appcolumnid integer,
    appid integer NOT NULL
);


ALTER TABLE metadata.formresources OWNER TO appowner;

--
-- Name: formresources_id_seq; Type: SEQUENCE; Schema: metadata; Owner: appowner
--

CREATE SEQUENCE metadata.formresources_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE metadata.formresources_id_seq OWNER TO appowner;

--
-- Name: formresources_id_seq; Type: SEQUENCE OWNED BY; Schema: metadata; Owner: appowner
--

ALTER SEQUENCE metadata.formresources_id_seq OWNED BY metadata.formresources.id;


--
-- Name: images; Type: TABLE; Schema: metadata; Owner: appowner
--

CREATE TABLE metadata.images (
    id integer NOT NULL,
    appid integer NOT NULL,
    url character varying(128) NOT NULL
);


ALTER TABLE metadata.images OWNER TO appowner;

--
-- Name: images_id_seq; Type: SEQUENCE; Schema: metadata; Owner: appowner
--

ALTER TABLE metadata.images ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME metadata.images_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: issues_id_seq; Type: SEQUENCE; Schema: metadata; Owner: appowner
--

CREATE SEQUENCE metadata.issues_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE metadata.issues_id_seq OWNER TO appowner;

--
-- Name: menuicons; Type: TABLE; Schema: metadata; Owner: appowner
--

CREATE TABLE metadata.menuicons (
    id integer NOT NULL,
    icon character varying(32),
    iconname character varying(20)
);


ALTER TABLE metadata.menuicons OWNER TO appowner;

--
-- Name: menuicons_id_seq; Type: SEQUENCE; Schema: metadata; Owner: appowner
--

CREATE SEQUENCE metadata.menuicons_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE metadata.menuicons_id_seq OWNER TO appowner;

--
-- Name: menuicons_id_seq; Type: SEQUENCE OWNED BY; Schema: metadata; Owner: appowner
--

ALTER SEQUENCE metadata.menuicons_id_seq OWNED BY metadata.menuicons.id;


--
-- Name: menuitems; Type: TABLE; Schema: metadata; Owner: appowner
--

CREATE TABLE metadata.menuitems (
    id integer NOT NULL,
    parentid integer,
    label character varying(40),
    iconid integer,
    appid integer,
    pageid integer DEFAULT 0 NOT NULL,
    active integer DEFAULT 1,
    "position" integer,
    pathid integer,
    routerpath character varying(40)
);


ALTER TABLE metadata.menuitems OWNER TO appowner;

--
-- Name: menuitems_id_seq; Type: SEQUENCE; Schema: metadata; Owner: appowner
--

CREATE SEQUENCE metadata.menuitems_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE metadata.menuitems_id_seq OWNER TO appowner;

--
-- Name: menuitems_id_seq; Type: SEQUENCE OWNED BY; Schema: metadata; Owner: appowner
--

ALTER SEQUENCE metadata.menuitems_id_seq OWNED BY metadata.menuitems.id;


--
-- Name: menupaths; Type: TABLE; Schema: metadata; Owner: appowner
--

CREATE TABLE metadata.menupaths (
    syspath character varying(256),
    sysname character varying(60),
    shortname character varying(20),
    id integer NOT NULL
);


ALTER TABLE metadata.menupaths OWNER TO appowner;

--
-- Name: menupaths_id_seq; Type: SEQUENCE; Schema: metadata; Owner: appowner
--

CREATE SEQUENCE metadata.menupaths_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE metadata.menupaths_id_seq OWNER TO appowner;

--
-- Name: menupaths_id_seq; Type: SEQUENCE OWNED BY; Schema: metadata; Owner: appowner
--

ALTER SEQUENCE metadata.menupaths_id_seq OWNED BY metadata.menupaths.id;


--
-- Name: pageforms; Type: TABLE; Schema: metadata; Owner: appowner
--

CREATE TABLE metadata.pageforms (
    id integer NOT NULL,
    pageid integer NOT NULL,
    jsondata jsonb,
    createdat timestamp without time zone,
    updatedat timestamp without time zone DEFAULT now(),
    systemcategoryid integer,
    appcolumnid integer,
    description character varying(128)
);


ALTER TABLE metadata.pageforms OWNER TO appowner;

--
-- Name: pageforms_id_seq; Type: SEQUENCE; Schema: metadata; Owner: appowner
--

CREATE SEQUENCE metadata.pageforms_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE metadata.pageforms_id_seq OWNER TO appowner;

--
-- Name: pageforms_id_seq; Type: SEQUENCE OWNED BY; Schema: metadata; Owner: appowner
--

ALTER SEQUENCE metadata.pageforms_id_seq OWNED BY metadata.pageforms.id;


--
-- Name: pages; Type: TABLE; Schema: metadata; Owner: appowner
--

CREATE TABLE metadata.pages (
    id integer NOT NULL,
    appid integer NOT NULL,
    title character varying(40) NOT NULL,
    name character varying(30),
    description character varying(60),
    allowedroles integer[],
    helppath character varying(128)
);


ALTER TABLE metadata.pages OWNER TO appowner;

--
-- Name: TABLE pages; Type: COMMENT; Schema: metadata; Owner: appowner
--

COMMENT ON TABLE metadata.pages IS 'pages within an application';


--
-- Name: pages_id_seq; Type: SEQUENCE; Schema: metadata; Owner: appowner
--

ALTER TABLE metadata.pages ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME metadata.pages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: systemcategories; Type: TABLE; Schema: metadata; Owner: appowner
--

CREATE TABLE metadata.systemcategories (
    id integer NOT NULL,
    name character varying(30),
    description character varying(128),
    prefix character varying(10)
);


ALTER TABLE metadata.systemcategories OWNER TO appowner;

--
-- Name: systemcategories_id_seq; Type: SEQUENCE; Schema: metadata; Owner: appowner
--

CREATE SEQUENCE metadata.systemcategories_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE metadata.systemcategories_id_seq OWNER TO appowner;

--
-- Name: systemcategories_id_seq; Type: SEQUENCE OWNED BY; Schema: metadata; Owner: appowner
--

ALTER SEQUENCE metadata.systemcategories_id_seq OWNED BY metadata.systemcategories.id;


--
-- Name: systemtables; Type: TABLE; Schema: metadata; Owner: appowner
--

CREATE TABLE metadata.systemtables (
    id integer NOT NULL,
    label character varying(30),
    tablename character varying(30),
    description character varying(128),
    systemtabletypeid integer NOT NULL
);


ALTER TABLE metadata.systemtables OWNER TO appowner;

--
-- Name: systemtables_id_seq; Type: SEQUENCE; Schema: metadata; Owner: appowner
--

CREATE SEQUENCE metadata.systemtables_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE metadata.systemtables_id_seq OWNER TO appowner;

--
-- Name: systemtables_id_seq; Type: SEQUENCE OWNED BY; Schema: metadata; Owner: appowner
--

ALTER SEQUENCE metadata.systemtables_id_seq OWNED BY metadata.systemtables.id;


--
-- Name: systemtabletypes; Type: TABLE; Schema: metadata; Owner: appowner
--

CREATE TABLE metadata.systemtabletypes (
    id integer NOT NULL,
    name character varying(30),
    label character varying(40)
);


ALTER TABLE metadata.systemtabletypes OWNER TO appowner;

--
-- Name: systemtabletypes_id_seq; Type: SEQUENCE; Schema: metadata; Owner: appowner
--

CREATE SEQUENCE metadata.systemtabletypes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE metadata.systemtabletypes_id_seq OWNER TO appowner;

--
-- Name: systemtabletypes_id_seq; Type: SEQUENCE OWNED BY; Schema: metadata; Owner: appowner
--

ALTER SEQUENCE metadata.systemtabletypes_id_seq OWNED BY metadata.systemtabletypes.id;


--
-- Name: urlactions; Type: TABLE; Schema: metadata; Owner: appowner
--

CREATE TABLE metadata.urlactions (
    id integer NOT NULL,
    url character varying(128) NOT NULL,
    apiactionid integer NOT NULL,
    actiondata jsonb,
    appid integer,
    pre boolean DEFAULT false,
    post boolean DEFAULT false,
    method text[],
    description character varying(128),
    pageformid integer,
    template character varying(2000)
);


ALTER TABLE metadata.urlactions OWNER TO appowner;

--
-- Name: urlactions_id_seq; Type: SEQUENCE; Schema: metadata; Owner: appowner
--

CREATE SEQUENCE metadata.urlactions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE metadata.urlactions_id_seq OWNER TO appowner;

--
-- Name: urlactions_id_seq; Type: SEQUENCE OWNED BY; Schema: metadata; Owner: appowner
--

ALTER SEQUENCE metadata.urlactions_id_seq OWNED BY metadata.urlactions.id;


--
-- Name: adhoc_queries_id_seq; Type: SEQUENCE; Schema: public; Owner: appowner
--

CREATE SEQUENCE public.adhoc_queries_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.adhoc_queries_id_seq OWNER TO appowner;

--
-- Name: activity id; Type: DEFAULT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.activity ALTER COLUMN id SET DEFAULT nextval('app.activities_id_seq'::regclass);


--
-- Name: adhoc_queries id; Type: DEFAULT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.adhoc_queries ALTER COLUMN id SET DEFAULT nextval('app.adhoc_queries_id_seq'::regclass);


--
-- Name: appbunos id; Type: DEFAULT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.appbunos ALTER COLUMN id SET DEFAULT nextval('app.appbunos_id_seq'::regclass);


--
-- Name: appdata id; Type: DEFAULT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.appdata ALTER COLUMN id SET DEFAULT nextval('app.appdata_id_seq'::regclass);


--
-- Name: attachments id; Type: DEFAULT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.attachments ALTER COLUMN id SET DEFAULT nextval('app.attachments_id_seq'::regclass);


--
-- Name: bunos id; Type: DEFAULT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.bunos ALTER COLUMN id SET DEFAULT nextval('app.bunos_id_seq'::regclass);


--
-- Name: dashboardreports id; Type: DEFAULT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.dashboardreports ALTER COLUMN id SET DEFAULT nextval('app.dashboardreport_id_seq'::regclass);


--
-- Name: groups id; Type: DEFAULT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.groups ALTER COLUMN id SET DEFAULT nextval('app.groups_id_seq'::regclass);


--
-- Name: issueattachments id; Type: DEFAULT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.issueattachments ALTER COLUMN id SET DEFAULT nextval('app.issueattachments_id_seq'::regclass);


--
-- Name: issues id; Type: DEFAULT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.issues ALTER COLUMN id SET DEFAULT nextval('app.issues_id_seq'::regclass);


--
-- Name: issuetypes id; Type: DEFAULT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.issuetypes ALTER COLUMN id SET DEFAULT nextval('app.issuetypes_id_seq'::regclass);


--
-- Name: masterdata id; Type: DEFAULT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.masterdata ALTER COLUMN id SET DEFAULT nextval('app.mastertypes_id_seq'::regclass);


--
-- Name: priority id; Type: DEFAULT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.priority ALTER COLUMN id SET DEFAULT nextval('app.priority_id_seq'::regclass);


--
-- Name: reporttemplates id; Type: DEFAULT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.reporttemplates ALTER COLUMN id SET DEFAULT nextval('app.reporttemplates_id_seq'::regclass);


--
-- Name: resourcetypes id; Type: DEFAULT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.resourcetypes ALTER COLUMN id SET DEFAULT nextval('app.resourcetypes_id_seq'::regclass);


--
-- Name: roleassignments id; Type: DEFAULT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.roleassignments ALTER COLUMN id SET DEFAULT nextval('app.roleassignments_id_seq'::regclass);


--
-- Name: rolerestrictions id; Type: DEFAULT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.rolerestrictions ALTER COLUMN id SET DEFAULT nextval('app.rolepermissions_id_seq'::regclass);


--
-- Name: roles id; Type: DEFAULT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.roles ALTER COLUMN id SET DEFAULT nextval('app.roles_id_seq'::regclass);


--
-- Name: status id; Type: DEFAULT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.status ALTER COLUMN id SET DEFAULT nextval('app.status_id_seq'::regclass);


--
-- Name: support id; Type: DEFAULT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.support ALTER COLUMN id SET DEFAULT nextval('app.support_id_seq'::regclass);


--
-- Name: tableattachments id; Type: DEFAULT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.tableattachments ALTER COLUMN id SET DEFAULT nextval('app.appdataattachments_id_seq'::regclass);


--
-- Name: userattachments id; Type: DEFAULT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.userattachments ALTER COLUMN id SET DEFAULT nextval('app.userattachments_id_seq'::regclass);


--
-- Name: usergroups id; Type: DEFAULT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.usergroups ALTER COLUMN id SET DEFAULT nextval('app.usergroups_id_seq'::regclass);


--
-- Name: workflow_actions id; Type: DEFAULT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.workflow_actions ALTER COLUMN id SET DEFAULT nextval('app.workflow_actions_id_seq'::regclass);


--
-- Name: workflow_states id; Type: DEFAULT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.workflow_states ALTER COLUMN id SET DEFAULT nextval('app.workflow_states_id_seq'::regclass);


--
-- Name: workflow_statetransitions id; Type: DEFAULT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.workflow_statetransitions ALTER COLUMN id SET DEFAULT nextval('app.workflow_statetransitions_id_seq'::regclass);


--
-- Name: workflow_status id; Type: DEFAULT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.workflow_status ALTER COLUMN id SET DEFAULT nextval('app.workflow_actionresponse_id_seq'::regclass);


--
-- Name: actions id; Type: DEFAULT; Schema: metadata; Owner: appowner
--

ALTER TABLE ONLY metadata.actions ALTER COLUMN id SET DEFAULT nextval('metadata.actions_id_seq'::regclass);


--
-- Name: apiactions id; Type: DEFAULT; Schema: metadata; Owner: appowner
--

ALTER TABLE ONLY metadata.apiactions ALTER COLUMN id SET DEFAULT nextval('metadata.apiactions_id_seq'::regclass);


--
-- Name: appcolumns id; Type: DEFAULT; Schema: metadata; Owner: appowner
--

ALTER TABLE ONLY metadata.appcolumns ALTER COLUMN id SET DEFAULT nextval('metadata.appcolumns_id_seq'::regclass);


--
-- Name: appqueries id; Type: DEFAULT; Schema: metadata; Owner: appowner
--

ALTER TABLE ONLY metadata.appqueries ALTER COLUMN id SET DEFAULT nextval('metadata.appquery_id_seq'::regclass);


--
-- Name: apptables id; Type: DEFAULT; Schema: metadata; Owner: appowner
--

ALTER TABLE ONLY metadata.apptables ALTER COLUMN id SET DEFAULT nextval('metadata.apptables_id_seq'::regclass);


--
-- Name: columntemplate id; Type: DEFAULT; Schema: metadata; Owner: appowner
--

ALTER TABLE ONLY metadata.columntemplate ALTER COLUMN id SET DEFAULT nextval('metadata.columntemplate_id_seq'::regclass);


--
-- Name: datatypes id; Type: DEFAULT; Schema: metadata; Owner: appowner
--

ALTER TABLE ONLY metadata.datatypes ALTER COLUMN id SET DEFAULT nextval('metadata.datatypes_id_seq'::regclass);


--
-- Name: events id; Type: DEFAULT; Schema: metadata; Owner: appowner
--

ALTER TABLE ONLY metadata.events ALTER COLUMN id SET DEFAULT nextval('metadata.events_id_seq'::regclass);


--
-- Name: fieldcategories id; Type: DEFAULT; Schema: metadata; Owner: appowner
--

ALTER TABLE ONLY metadata.fieldcategories ALTER COLUMN id SET DEFAULT nextval('metadata.fieldcategories_id_seq'::regclass);


--
-- Name: formeventactions id; Type: DEFAULT; Schema: metadata; Owner: appowner
--

ALTER TABLE ONLY metadata.formeventactions ALTER COLUMN id SET DEFAULT nextval('metadata.formeventactions_id_seq'::regclass);


--
-- Name: formresources id; Type: DEFAULT; Schema: metadata; Owner: appowner
--

ALTER TABLE ONLY metadata.formresources ALTER COLUMN id SET DEFAULT nextval('metadata.formresources_id_seq'::regclass);


--
-- Name: menuicons id; Type: DEFAULT; Schema: metadata; Owner: appowner
--

ALTER TABLE ONLY metadata.menuicons ALTER COLUMN id SET DEFAULT nextval('metadata.menuicons_id_seq'::regclass);


--
-- Name: menuitems id; Type: DEFAULT; Schema: metadata; Owner: appowner
--

ALTER TABLE ONLY metadata.menuitems ALTER COLUMN id SET DEFAULT nextval('metadata.menuitems_id_seq'::regclass);


--
-- Name: menupaths id; Type: DEFAULT; Schema: metadata; Owner: appowner
--

ALTER TABLE ONLY metadata.menupaths ALTER COLUMN id SET DEFAULT nextval('metadata.menupaths_id_seq'::regclass);


--
-- Name: pageforms id; Type: DEFAULT; Schema: metadata; Owner: appowner
--

ALTER TABLE ONLY metadata.pageforms ALTER COLUMN id SET DEFAULT nextval('metadata.pageforms_id_seq'::regclass);


--
-- Name: systemcategories id; Type: DEFAULT; Schema: metadata; Owner: appowner
--

ALTER TABLE ONLY metadata.systemcategories ALTER COLUMN id SET DEFAULT nextval('metadata.systemcategories_id_seq'::regclass);


--
-- Name: systemtables id; Type: DEFAULT; Schema: metadata; Owner: appowner
--

ALTER TABLE ONLY metadata.systemtables ALTER COLUMN id SET DEFAULT nextval('metadata.systemtables_id_seq'::regclass);


--
-- Name: systemtabletypes id; Type: DEFAULT; Schema: metadata; Owner: appowner
--

ALTER TABLE ONLY metadata.systemtabletypes ALTER COLUMN id SET DEFAULT nextval('metadata.systemtabletypes_id_seq'::regclass);


--
-- Name: urlactions id; Type: DEFAULT; Schema: metadata; Owner: appowner
--

ALTER TABLE ONLY metadata.urlactions ALTER COLUMN id SET DEFAULT nextval('metadata.urlactions_id_seq'::regclass);


--
-- Data for Name: activity; Type: TABLE DATA; Schema: app; Owner: appowner
--

COPY app.activity (id, appid, label, description, createdat, updatedat, jsondata) FROM stdin;
\.


--
-- Data for Name: adhoc_queries; Type: TABLE DATA; Schema: app; Owner: appowner
--

COPY app.adhoc_queries (id, name, appid, jsondata, createdat, updatedat, reporttemplateid, ownerid) FROM stdin;
\.


--
-- Data for Name: appbunos; Type: TABLE DATA; Schema: app; Owner: appowner
--

COPY app.appbunos (id, appid, bunoid, createdat, updatedat) FROM stdin;
\.


--
-- Data for Name: appdata; Type: TABLE DATA; Schema: app; Owner: appowner
--

COPY app.appdata (id, jsondata, createdat, updatedat, apptableid, appid) FROM stdin;
\.


--
-- Data for Name: attachments; Type: TABLE DATA; Schema: app; Owner: appowner
--

COPY app.attachments (id, path, uniquename, name, size, createdat, updatedat) FROM stdin;
\.


--
-- Data for Name: bunos; Type: TABLE DATA; Schema: app; Owner: appowner
--

COPY app.bunos (id, identifier, description, createdat, updatedat) FROM stdin;
1	990021		2018-12-12 14:24:17.691368	2018-12-12 14:24:17.691368
34	100052		2018-12-12 20:19:39	2018-12-12 20:19:39
35	100053		2018-12-12 20:19:39.001	2018-12-12 20:19:39.001
36	100054		2018-12-12 20:19:39.001	2018-12-12 20:19:39.001
37	100055		2018-12-12 20:19:39.001	2018-12-12 20:19:39.001
38	100056		2018-12-12 20:19:39.001	2018-12-12 20:19:39.001
100	165841		2018-12-12 20:19:39.006	2018-12-12 20:19:39.006
101	165842		2018-12-12 20:19:39.006	2018-12-12 20:19:39.006
102	165845		2018-12-12 20:19:39.006	2018-12-12 20:19:39.006
103	165846		2018-12-12 20:19:39.006	2018-12-12 20:19:39.006
104	165847		2018-12-12 20:19:39.006	2018-12-12 20:19:39.006
105	165849		2018-12-12 20:19:39.006	2018-12-12 20:19:39.006
106	165850		2018-12-12 20:19:39.006	2018-12-12 20:19:39.006
107	165851		2018-12-12 20:19:39.006	2018-12-12 20:19:39.006
108	165852		2018-12-12 20:19:39.006	2018-12-12 20:19:39.006
109	165853		2018-12-12 20:19:39.006	2018-12-12 20:19:39.006
110	165940		2018-12-12 20:19:39.007	2018-12-12 20:19:39.007
111	165941		2018-12-12 20:19:39.007	2018-12-12 20:19:39.007
112	165943		2018-12-12 20:19:39.007	2018-12-12 20:19:39.007
113	165944		2018-12-12 20:19:39.007	2018-12-12 20:19:39.007
114	165945		2018-12-12 20:19:39.007	2018-12-12 20:19:39.007
115	165946		2018-12-12 20:19:39.007	2018-12-12 20:19:39.007
116	165947		2018-12-12 20:19:39.007	2018-12-12 20:19:39.007
117	165948		2018-12-12 20:19:39.007	2018-12-12 20:19:39.007
118	165956		2018-12-12 20:19:39.007	2018-12-12 20:19:39.007
119	166492		2018-12-12 20:19:39.007	2018-12-12 20:19:39.007
120	166493		2018-12-12 20:19:39.007	2018-12-12 20:19:39.007
121	166494		2018-12-12 20:19:39.007	2018-12-12 20:19:39.007
122	166495		2018-12-12 20:19:39.007	2018-12-12 20:19:39.007
123	166496		2018-12-12 20:19:39.008	2018-12-12 20:19:39.008
124	166497		2018-12-12 20:19:39.008	2018-12-12 20:19:39.008
125	166498		2018-12-12 20:19:39.008	2018-12-12 20:19:39.008
126	166499		2018-12-12 20:19:39.008	2018-12-12 20:19:39.008
127	166685		2018-12-12 20:19:39.008	2018-12-12 20:19:39.008
128	166686		2018-12-12 20:19:39.008	2018-12-12 20:19:39.008
129	166687		2018-12-12 20:19:39.008	2018-12-12 20:19:39.008
130	166688		2018-12-12 20:19:39.008	2018-12-12 20:19:39.008
131	166689		2018-12-12 20:19:39.008	2018-12-12 20:19:39.008
132	166690		2018-12-12 20:19:39.008	2018-12-12 20:19:39.008
133	166691		2018-12-12 20:19:39.008	2018-12-12 20:19:39.008
134	166692		2018-12-12 20:19:39.008	2018-12-12 20:19:39.008
135	166718		2018-12-12 20:19:39.009	2018-12-12 20:19:39.009
136	166719		2018-12-12 20:19:39.009	2018-12-12 20:19:39.009
141	166724		2018-12-12 20:19:39.009	2018-12-12 20:19:39.009
146	166733		2018-12-12 20:19:39.009	2018-12-12 20:19:39.009
151	166739		2018-12-12 20:19:39.01	2018-12-12 20:19:39.01
156	166744		2018-12-12 20:19:39.01	2018-12-12 20:19:39.01
161	167903		2018-12-12 20:19:39.011	2018-12-12 20:19:39.011
166	167908		2018-12-12 20:19:39.012	2018-12-12 20:19:39.012
171	167913		2018-12-12 20:19:39.012	2018-12-12 20:19:39.012
176	167918		2018-12-12 20:19:39.012	2018-12-12 20:19:39.012
181	168004		2018-12-12 20:19:39.013	2018-12-12 20:19:39.013
186	168009		2018-12-12 20:19:39.014	2018-12-12 20:19:39.014
191	168014		2018-12-12 20:19:39.014	2018-12-12 20:19:39.014
196	168019		2018-12-12 20:19:39.015	2018-12-12 20:19:39.015
201	168025		2018-12-12 20:19:39.015	2018-12-12 20:19:39.015
206	168032		2018-12-12 20:19:39.015	2018-12-12 20:19:39.015
241	110060		2018-12-12 20:19:39.018	2018-12-12 20:19:39.018
451	166383		2018-12-12 20:19:39.035	2018-12-12 20:19:39.035
456	166388		2018-12-12 20:19:39.035	2018-12-12 20:19:39.035
461	166483		2018-12-12 20:19:39.036	2018-12-12 20:19:39.036
466	166488		2018-12-12 20:19:39.036	2018-12-12 20:19:39.036
491	165843		2018-12-12 20:19:39.038	2018-12-12 20:19:39.038
137	166720		2018-12-12 20:19:39.009	2018-12-12 20:19:39.009
142	166725		2018-12-12 20:19:39.009	2018-12-12 20:19:39.009
147	166734		2018-12-12 20:19:39.009	2018-12-12 20:19:39.009
152	166740		2018-12-12 20:19:39.01	2018-12-12 20:19:39.01
157	166745		2018-12-12 20:19:39.01	2018-12-12 20:19:39.01
162	167904		2018-12-12 20:19:39.011	2018-12-12 20:19:39.011
167	167909		2018-12-12 20:19:39.012	2018-12-12 20:19:39.012
172	167914		2018-12-12 20:19:39.012	2018-12-12 20:19:39.012
177	167919		2018-12-12 20:19:39.012	2018-12-12 20:19:39.012
182	168005		2018-12-12 20:19:39.013	2018-12-12 20:19:39.013
187	168010		2018-12-12 20:19:39.014	2018-12-12 20:19:39.014
192	168015		2018-12-12 20:19:39.014	2018-12-12 20:19:39.014
197	168021		2018-12-12 20:19:39.015	2018-12-12 20:19:39.015
202	168028		2018-12-12 20:19:39.015	2018-12-12 20:19:39.015
207	168033		2018-12-12 20:19:39.015	2018-12-12 20:19:39.015
452	166384		2018-12-12 20:19:39.035	2018-12-12 20:19:39.035
457	166390		2018-12-12 20:19:39.036	2018-12-12 20:19:39.036
462	166484		2018-12-12 20:19:39.036	2018-12-12 20:19:39.036
467	166489		2018-12-12 20:19:39.036	2018-12-12 20:19:39.036
527	166491		2018-12-12 20:19:39.042	2018-12-12 20:19:39.042
138	166721		2018-12-12 20:19:39.009	2018-12-12 20:19:39.009
143	166726		2018-12-12 20:19:39.009	2018-12-12 20:19:39.009
148	166736		2018-12-12 20:19:39.01	2018-12-12 20:19:39.01
153	166741		2018-12-12 20:19:39.01	2018-12-12 20:19:39.01
158	166746		2018-12-12 20:19:39.01	2018-12-12 20:19:39.01
163	167905		2018-12-12 20:19:39.011	2018-12-12 20:19:39.011
168	167910		2018-12-12 20:19:39.012	2018-12-12 20:19:39.012
173	167915		2018-12-12 20:19:39.012	2018-12-12 20:19:39.012
178	167920		2018-12-12 20:19:39.012	2018-12-12 20:19:39.012
183	168006		2018-12-12 20:19:39.013	2018-12-12 20:19:39.013
188	168011		2018-12-12 20:19:39.014	2018-12-12 20:19:39.014
193	168016		2018-12-12 20:19:39.014	2018-12-12 20:19:39.014
198	168022		2018-12-12 20:19:39.015	2018-12-12 20:19:39.015
203	168029		2018-12-12 20:19:39.015	2018-12-12 20:19:39.015
238	110057		2018-12-12 20:19:39.018	2018-12-12 20:19:39.018
453	166385		2018-12-12 20:19:39.035	2018-12-12 20:19:39.035
458	166391		2018-12-12 20:19:39.036	2018-12-12 20:19:39.036
463	166485		2018-12-12 20:19:39.036	2018-12-12 20:19:39.036
468	166490		2018-12-12 20:19:39.036	2018-12-12 20:19:39.036
503	165942		2018-12-12 20:19:39.039	2018-12-12 20:19:39.039
728	166735		2018-12-12 20:19:39.054	2018-12-12 20:19:39.054
778	168020		2018-12-12 20:19:39.056	2018-12-12 20:19:39.056
793	999991-6504-34		2018-12-12 20:19:39.057	2018-12-12 20:19:39.057
139	166722		2018-12-12 20:19:39.009	2018-12-12 20:19:39.009
144	166731		2018-12-12 20:19:39.009	2018-12-12 20:19:39.009
149	166737		2018-12-12 20:19:39.01	2018-12-12 20:19:39.01
154	166742		2018-12-12 20:19:39.01	2018-12-12 20:19:39.01
159	166747		2018-12-12 20:19:39.011	2018-12-12 20:19:39.011
388	060032		2018-12-12 20:19:39.029	2018-12-12 20:19:39.029
165	167906		2018-12-12 20:19:39.011	2018-12-12 20:19:39.011
169	167911		2018-12-12 20:19:39.012	2018-12-12 20:19:39.012
174	167916		2018-12-12 20:19:39.012	2018-12-12 20:19:39.012
179	167921		2018-12-12 20:19:39.013	2018-12-12 20:19:39.013
184	168007		2018-12-12 20:19:39.013	2018-12-12 20:19:39.013
189	168012		2018-12-12 20:19:39.014	2018-12-12 20:19:39.014
194	168017		2018-12-12 20:19:39.014	2018-12-12 20:19:39.014
199	168023		2018-12-12 20:19:39.015	2018-12-12 20:19:39.015
204	168030		2018-12-12 20:19:39.015	2018-12-12 20:19:39.015
239	110058		2018-12-12 20:19:39.018	2018-12-12 20:19:39.018
454	166386		2018-12-12 20:19:39.035	2018-12-12 20:19:39.035
459	166480		2018-12-12 20:19:39.036	2018-12-12 20:19:39.036
464	166486		2018-12-12 20:19:39.036	2018-12-12 20:19:39.036
784	168026		2018-12-12 20:19:39.056	2018-12-12 20:19:39.056
794	999991-6504-39		2018-12-12 20:19:39.057	2018-12-12 20:19:39.057
140	166723		2018-12-12 20:19:39.009	2018-12-12 20:19:39.009
145	166732		2018-12-12 20:19:39.009	2018-12-12 20:19:39.009
150	166738		2018-12-12 20:19:39.01	2018-12-12 20:19:39.01
155	166743		2018-12-12 20:19:39.01	2018-12-12 20:19:39.01
160	167902		2018-12-12 20:19:39.011	2018-12-12 20:19:39.011
164	167907		2018-12-12 20:19:39.012	2018-12-12 20:19:39.012
170	167912		2018-12-12 20:19:39.012	2018-12-12 20:19:39.012
175	167917		2018-12-12 20:19:39.012	2018-12-12 20:19:39.012
180	167922		2018-12-12 20:19:39.013	2018-12-12 20:19:39.013
185	168008		2018-12-12 20:19:39.013	2018-12-12 20:19:39.013
190	168013		2018-12-12 20:19:39.014	2018-12-12 20:19:39.014
195	168018		2018-12-12 20:19:39.015	2018-12-12 20:19:39.015
200	168024		2018-12-12 20:19:39.015	2018-12-12 20:19:39.015
205	168031		2018-12-12 20:19:39.015	2018-12-12 20:19:39.015
240	110059		2018-12-12 20:19:39.018	2018-12-12 20:19:39.018
455	166387		2018-12-12 20:19:39.035	2018-12-12 20:19:39.035
460	166481		2018-12-12 20:19:39.036	2018-12-12 20:19:39.036
465	166487		2018-12-12 20:19:39.036	2018-12-12 20:19:39.036
515	166389		2018-12-12 20:19:39.04	2018-12-12 20:19:39.04
520	166482		2018-12-12 20:19:39.041	2018-12-12 20:19:39.041
785	168027		2018-12-12 20:19:39.056	2018-12-12 20:19:39.056
1326	165856		2018-12-12 20:19:39.084	2018-12-12 20:19:39.084
1317	165844		2018-12-12 20:19:39.084	2018-12-12 20:19:39.084
1646	168348		2018-12-12 20:19:39.098	2018-12-12 20:19:39.098
1651	168601		2018-12-12 20:19:39.098	2018-12-12 20:19:39.098
1656	168606		2018-12-12 20:19:39.098	2018-12-12 20:19:39.098
1661	168612		2018-12-12 20:19:39.098	2018-12-12 20:19:39.098
1666	168618		2018-12-12 20:19:39.099	2018-12-12 20:19:39.099
1671	168624		2018-12-12 20:19:39.099	2018-12-12 20:19:39.099
1676	168629		2018-12-12 20:19:39.099	2018-12-12 20:19:39.099
1681	168638		2018-12-12 20:19:39.099	2018-12-12 20:19:39.099
1686	168661		2018-12-12 20:19:39.099	2018-12-12 20:19:39.099
1691	168289		2018-12-12 20:19:39.1	2018-12-12 20:19:39.1
1696	168324		2018-12-12 20:19:39.1	2018-12-12 20:19:39.1
1891	168214		2018-12-12 20:19:39.112	2018-12-12 20:19:39.112
1896	168219		2018-12-12 20:19:39.112	2018-12-12 20:19:39.112
1901	168224		2018-12-12 20:19:39.112	2018-12-12 20:19:39.112
1906	168229		2018-12-12 20:19:39.113	2018-12-12 20:19:39.113
1911	168234		2018-12-12 20:19:39.113	2018-12-12 20:19:39.113
1916	168239		2018-12-12 20:19:39.113	2018-12-12 20:19:39.113
1921	168278		2018-12-12 20:19:39.114	2018-12-12 20:19:39.114
1926	168283		2018-12-12 20:19:39.114	2018-12-12 20:19:39.114
1931	168288		2018-12-12 20:19:39.114	2018-12-12 20:19:39.114
1936	168293		2018-12-12 20:19:39.115	2018-12-12 20:19:39.115
1941	168298		2018-12-12 20:19:39.115	2018-12-12 20:19:39.115
1946	168303		2018-12-12 20:19:39.115	2018-12-12 20:19:39.115
1951	168322		2018-12-12 20:19:39.115	2018-12-12 20:19:39.115
1966	168337		2018-12-12 20:19:39.116	2018-12-12 20:19:39.116
1971	168342		2018-12-12 20:19:39.116	2018-12-12 20:19:39.116
2051	120065		2018-12-12 20:19:39.119	2018-12-12 20:19:39.119
2056	130070		2018-12-12 20:19:39.119	2018-12-12 20:19:39.119
2061	140075		2018-12-12 20:19:39.119	2018-12-12 20:19:39.119
1647	168349		2018-12-12 20:19:39.098	2018-12-12 20:19:39.098
1652	168602		2018-12-12 20:19:39.098	2018-12-12 20:19:39.098
1657	168607		2018-12-12 20:19:39.098	2018-12-12 20:19:39.098
1662	168613		2018-12-12 20:19:39.098	2018-12-12 20:19:39.098
1667	168619		2018-12-12 20:19:39.099	2018-12-12 20:19:39.099
1672	168625		2018-12-12 20:19:39.099	2018-12-12 20:19:39.099
1677	168630		2018-12-12 20:19:39.099	2018-12-12 20:19:39.099
1682	168641		2018-12-12 20:19:39.099	2018-12-12 20:19:39.099
1687	168663		2018-12-12 20:19:39.099	2018-12-12 20:19:39.099
1692	168292		2018-12-12 20:19:39.1	2018-12-12 20:19:39.1
1697	168327		2018-12-12 20:19:39.1	2018-12-12 20:19:39.1
1892	168215		2018-12-12 20:19:39.112	2018-12-12 20:19:39.112
1897	168220		2018-12-12 20:19:39.112	2018-12-12 20:19:39.112
1902	168225		2018-12-12 20:19:39.113	2018-12-12 20:19:39.113
1907	168230		2018-12-12 20:19:39.113	2018-12-12 20:19:39.113
1912	168235		2018-12-12 20:19:39.113	2018-12-12 20:19:39.113
1917	168240		2018-12-12 20:19:39.114	2018-12-12 20:19:39.114
1922	168279		2018-12-12 20:19:39.114	2018-12-12 20:19:39.114
1937	168294		2018-12-12 20:19:39.115	2018-12-12 20:19:39.115
1942	168299		2018-12-12 20:19:39.115	2018-12-12 20:19:39.115
1947	168304		2018-12-12 20:19:39.115	2018-12-12 20:19:39.115
1952	168323		2018-12-12 20:19:39.115	2018-12-12 20:19:39.115
1957	168328		2018-12-12 20:19:39.115	2018-12-12 20:19:39.115
1962	168333		2018-12-12 20:19:39.116	2018-12-12 20:19:39.116
1967	168338		2018-12-12 20:19:39.116	2018-12-12 20:19:39.116
1972	168343		2018-12-12 20:19:39.116	2018-12-12 20:19:39.116
2002	168621		2018-12-12 20:19:39.118	2018-12-12 20:19:39.118
2047	110061		2018-12-12 20:19:39.119	2018-12-12 20:19:39.119
2052	120066		2018-12-12 20:19:39.119	2018-12-12 20:19:39.119
2057	130071		2018-12-12 20:19:39.119	2018-12-12 20:19:39.119
1648	168350		2018-12-12 20:19:39.098	2018-12-12 20:19:39.098
1653	168603		2018-12-12 20:19:39.098	2018-12-12 20:19:39.098
1658	168609		2018-12-12 20:19:39.098	2018-12-12 20:19:39.098
1663	168614		2018-12-12 20:19:39.098	2018-12-12 20:19:39.098
1668	168620		2018-12-12 20:19:39.099	2018-12-12 20:19:39.099
1673	168626		2018-12-12 20:19:39.099	2018-12-12 20:19:39.099
1678	168631		2018-12-12 20:19:39.099	2018-12-12 20:19:39.099
1683	168653		2018-12-12 20:19:39.099	2018-12-12 20:19:39.099
1688	168666		2018-12-12 20:19:39.099	2018-12-12 20:19:39.099
1693	168297		2018-12-12 20:19:39.1	2018-12-12 20:19:39.1
1698	168332		2018-12-12 20:19:39.1	2018-12-12 20:19:39.1
1893	168216		2018-12-12 20:19:39.112	2018-12-12 20:19:39.112
1898	168221		2018-12-12 20:19:39.112	2018-12-12 20:19:39.112
1903	168226		2018-12-12 20:19:39.113	2018-12-12 20:19:39.113
1908	168231		2018-12-12 20:19:39.113	2018-12-12 20:19:39.113
1913	168236		2018-12-12 20:19:39.113	2018-12-12 20:19:39.113
1918	168242		2018-12-12 20:19:39.114	2018-12-12 20:19:39.114
1923	168280		2018-12-12 20:19:39.114	2018-12-12 20:19:39.114
1928	168285		2018-12-12 20:19:39.114	2018-12-12 20:19:39.114
1933	168290		2018-12-12 20:19:39.114	2018-12-12 20:19:39.114
1938	168295		2018-12-12 20:19:39.115	2018-12-12 20:19:39.115
1943	168300		2018-12-12 20:19:39.115	2018-12-12 20:19:39.115
1948	168305		2018-12-12 20:19:39.115	2018-12-12 20:19:39.115
1958	168329		2018-12-12 20:19:39.115	2018-12-12 20:19:39.115
1963	168334		2018-12-12 20:19:39.116	2018-12-12 20:19:39.116
1973	168344		2018-12-12 20:19:39.116	2018-12-12 20:19:39.116
1998	168617		2018-12-12 20:19:39.117	2018-12-12 20:19:39.117
2048	120062		2018-12-12 20:19:39.119	2018-12-12 20:19:39.119
2053	120067		2018-12-12 20:19:39.119	2018-12-12 20:19:39.119
2058	140072		2018-12-12 20:19:39.119	2018-12-12 20:19:39.119
1649	168351		2018-12-12 20:19:39.098	2018-12-12 20:19:39.098
1654	168604		2018-12-12 20:19:39.098	2018-12-12 20:19:39.098
1659	168610		2018-12-12 20:19:39.098	2018-12-12 20:19:39.098
1664	168615		2018-12-12 20:19:39.099	2018-12-12 20:19:39.099
1669	168622		2018-12-12 20:19:39.099	2018-12-12 20:19:39.099
1674	168627		2018-12-12 20:19:39.099	2018-12-12 20:19:39.099
1679	168632		2018-12-12 20:19:39.099	2018-12-12 20:19:39.099
1684	168659		2018-12-12 20:19:39.099	2018-12-12 20:19:39.099
1694	168302		2018-12-12 20:19:39.1	2018-12-12 20:19:39.1
1699	168335		2018-12-12 20:19:39.1	2018-12-12 20:19:39.1
1744	265945		2018-12-12 20:19:39.104	2018-12-12 20:19:39.104
1894	168217		2018-12-12 20:19:39.112	2018-12-12 20:19:39.112
1899	168222		2018-12-12 20:19:39.112	2018-12-12 20:19:39.112
1904	168227		2018-12-12 20:19:39.113	2018-12-12 20:19:39.113
1909	168232		2018-12-12 20:19:39.113	2018-12-12 20:19:39.113
1914	168237		2018-12-12 20:19:39.113	2018-12-12 20:19:39.113
1919	168243		2018-12-12 20:19:39.114	2018-12-12 20:19:39.114
1924	168281		2018-12-12 20:19:39.114	2018-12-12 20:19:39.114
1929	168286		2018-12-12 20:19:39.114	2018-12-12 20:19:39.114
1934	168291		2018-12-12 20:19:39.114	2018-12-12 20:19:39.114
1939	168296		2018-12-12 20:19:39.115	2018-12-12 20:19:39.115
1944	168301		2018-12-12 20:19:39.115	2018-12-12 20:19:39.115
1954	168325		2018-12-12 20:19:39.115	2018-12-12 20:19:39.115
1959	168330		2018-12-12 20:19:39.115	2018-12-12 20:19:39.115
1969	168340		2018-12-12 20:19:39.116	2018-12-12 20:19:39.116
1974	168345		2018-12-12 20:19:39.116	2018-12-12 20:19:39.116
1989	168608		2018-12-12 20:19:39.117	2018-12-12 20:19:39.117
2049	120063		2018-12-12 20:19:39.119	2018-12-12 20:19:39.119
2054	130068		2018-12-12 20:19:39.119	2018-12-12 20:19:39.119
2059	140073		2018-12-12 20:19:39.119	2018-12-12 20:19:39.119
1645	168347		2018-12-12 20:19:39.098	2018-12-12 20:19:39.098
1650	168352		2018-12-12 20:19:39.098	2018-12-12 20:19:39.098
1655	168605		2018-12-12 20:19:39.098	2018-12-12 20:19:39.098
1660	168611		2018-12-12 20:19:39.098	2018-12-12 20:19:39.098
1665	168616		2018-12-12 20:19:39.099	2018-12-12 20:19:39.099
1670	168623		2018-12-12 20:19:39.099	2018-12-12 20:19:39.099
1675	168628		2018-12-12 20:19:39.099	2018-12-12 20:19:39.099
1680	168636		2018-12-12 20:19:39.099	2018-12-12 20:19:39.099
1685	168660		2018-12-12 20:19:39.099	2018-12-12 20:19:39.099
1690	168284		2018-12-12 20:19:39.099	2018-12-12 20:19:39.099
1695	168306		2018-12-12 20:19:39.1	2018-12-12 20:19:39.1
1700	168339		2018-12-12 20:19:39.1	2018-12-12 20:19:39.1
1765	165848		2018-12-12 20:19:39.105	2018-12-12 20:19:39.105
1895	168218		2018-12-12 20:19:39.112	2018-12-12 20:19:39.112
1900	168223		2018-12-12 20:19:39.112	2018-12-12 20:19:39.112
1905	168228		2018-12-12 20:19:39.113	2018-12-12 20:19:39.113
1910	168233		2018-12-12 20:19:39.113	2018-12-12 20:19:39.113
1915	168238		2018-12-12 20:19:39.113	2018-12-12 20:19:39.113
1920	168244		2018-12-12 20:19:39.114	2018-12-12 20:19:39.114
1925	168282		2018-12-12 20:19:39.114	2018-12-12 20:19:39.114
1930	168287		2018-12-12 20:19:39.114	2018-12-12 20:19:39.114
1950	168307		2018-12-12 20:19:39.115	2018-12-12 20:19:39.115
1955	168326		2018-12-12 20:19:39.115	2018-12-12 20:19:39.115
1960	168331		2018-12-12 20:19:39.115	2018-12-12 20:19:39.115
1965	168336		2018-12-12 20:19:39.116	2018-12-12 20:19:39.116
1970	168341		2018-12-12 20:19:39.116	2018-12-12 20:19:39.116
1975	168346		2018-12-12 20:19:39.116	2018-12-12 20:19:39.116
2050	120064		2018-12-12 20:19:39.119	2018-12-12 20:19:39.119
2055	130069		2018-12-12 20:19:39.119	2018-12-12 20:19:39.119
2060	140074		2018-12-12 20:19:39.119	2018-12-12 20:19:39.119
3507	166903		2018-12-12 20:19:39.168	2018-12-12 20:19:39.168
3512	166908		2018-12-12 20:19:39.168	2018-12-12 20:19:39.168
3517	166913		2018-12-12 20:19:39.168	2018-12-12 20:19:39.168
3522	166918		2018-12-12 20:19:39.168	2018-12-12 20:19:39.168
3506	166902		2018-12-12 20:19:39.168	2018-12-12 20:19:39.168
3511	166907		2018-12-12 20:19:39.168	2018-12-12 20:19:39.168
3516	166912		2018-12-12 20:19:39.168	2018-12-12 20:19:39.168
3521	166917		2018-12-12 20:19:39.168	2018-12-12 20:19:39.168
3526	166922		2018-12-12 20:19:39.168	2018-12-12 20:19:39.168
3068	168241		2018-12-12 20:19:39.155	2018-12-12 20:19:39.155
3508	166904		2018-12-12 20:19:39.168	2018-12-12 20:19:39.168
3513	166909		2018-12-12 20:19:39.168	2018-12-12 20:19:39.168
3518	166914		2018-12-12 20:19:39.168	2018-12-12 20:19:39.168
3523	166919		2018-12-12 20:19:39.168	2018-12-12 20:19:39.168
3509	166905		2018-12-12 20:19:39.168	2018-12-12 20:19:39.168
3514	166910		2018-12-12 20:19:39.168	2018-12-12 20:19:39.168
3519	166915		2018-12-12 20:19:39.168	2018-12-12 20:19:39.168
3524	166920		2018-12-12 20:19:39.168	2018-12-12 20:19:39.168
3510	166906		2018-12-12 20:19:39.168	2018-12-12 20:19:39.168
3515	166911		2018-12-12 20:19:39.168	2018-12-12 20:19:39.168
3520	166916		2018-12-12 20:19:39.168	2018-12-12 20:19:39.168
3525	166921		2018-12-12 20:19:39.168	2018-12-12 20:19:39.168
3760	165493		2018-12-12 20:19:39.173	2018-12-12 20:19:39.173
4245	165840		2018-12-12 20:19:39.179	2018-12-12 20:19:39.179
4244	165838		2018-12-12 20:19:39.179	2018-12-12 20:19:39.179
6	040027		2018-12-12 19:27:01.904	2018-12-12 19:27:01.904
15	050029		2018-12-12 20:19:38.999	2018-12-12 20:19:38.999
29	090042		2018-12-12 20:19:39	2018-12-12 20:19:39
8	050028		2018-12-12 19:28:47.26	2018-12-12 19:29:58.858
17	070033		2018-12-12 20:19:38.999	2018-12-12 20:19:38.999
23	080039		2018-12-12 20:19:39	2018-12-12 20:19:39
4	040026		2018-12-12 14:25:08.01014	2018-12-12 14:25:08.01014
3	020025		2018-12-12 14:24:49.294852	2018-12-12 14:24:49.294852
28	090041		2018-12-12 20:19:39	2018-12-12 20:19:39
30	090043		2018-12-12 20:19:39	2018-12-12 20:19:39
24	080040		2018-12-12 20:19:39	2018-12-12 20:19:39
31	090044		2018-12-12 20:19:39	2018-12-12 20:19:39
27	080049		2018-12-12 20:19:39	2018-12-12 20:19:39
2	020024		2018-12-12 14:24:33.913533	2018-12-12 14:24:33.913533
20	080036		2018-12-12 20:19:38.999	2018-12-12 20:19:38.999
25	080047		2018-12-12 20:19:39	2018-12-12 20:19:39
26	080048		2018-12-12 20:19:39	2018-12-12 20:19:39
18	070034		2018-12-12 20:19:38.999	2018-12-12 20:19:38.999
19	080035		2018-12-12 20:19:38.999	2018-12-12 20:19:38.999
22	080038		2018-12-12 20:19:38.999	2018-12-12 20:19:38.999
33	090046		2018-12-12 20:19:39	2018-12-12 20:19:39
21	080037		2018-12-12 20:19:38.999	2018-12-12 20:19:38.999
32	090045		2018-12-12 20:19:39	2018-12-12 20:19:39
16	050030		2018-12-12 20:19:38.999	2018-12-12 20:19:38.999
2037	080051		2018-12-12 20:19:39.119	2018-12-12 20:19:39.119
1129	060031		2018-12-12 20:19:39.075	2018-12-12 20:19:39.075
2036	080050		2018-12-12 20:19:39.119	2018-12-12 20:19:39.119
1596	090040		2018-12-12 20:19:39.096	2018-12-12 20:19:39.096
4403	168633		2018-12-12 20:19:39.099	2018-12-12 20:19:39.099
4404	168634		2018-12-12 20:19:39.099	2018-12-12 20:19:39.099
4405	168635		2018-12-12 20:19:39.099	2018-12-12 20:19:39.099
4406	168637		2018-12-12 20:19:39.099	2018-12-12 20:19:39.099
4407	168639		2018-12-12 20:19:39.099	2018-12-12 20:19:39.099
4408	168640		2018-12-12 20:19:39.099	2018-12-12 20:19:39.099
4409	168642		2018-12-12 20:19:39.099	2018-12-12 20:19:39.099
4410	168643		2018-12-12 20:19:39.099	2018-12-12 20:19:39.099
4411	168644		2018-12-12 20:19:39.099	2018-12-12 20:19:39.099
4412	168645		2018-12-12 20:19:39.099	2018-12-12 20:19:39.099
4413	168646		2018-12-12 20:19:39.099	2018-12-12 20:19:39.099
4414	168647		2018-12-12 20:19:39.099	2018-12-12 20:19:39.099
4415	168648		2018-12-12 20:19:39.099	2018-12-12 20:19:39.099
4416	168649		2018-12-12 20:19:39.099	2018-12-12 20:19:39.099
4417	164940		2018-12-12 20:19:39.099	2018-12-12 20:19:39.099
4425	168650		2018-12-12 20:19:39.099	2018-12-12 20:19:39.099
4426	168651		2018-12-12 20:19:39.099	2018-12-12 20:19:39.099
4427	168652		2018-12-12 20:19:39.099	2018-12-12 20:19:39.099
4428	168654		2018-12-12 20:19:39.099	2018-12-12 20:19:39.099
4429	168655		2018-12-12 20:19:39.099	2018-12-12 20:19:39.099
4430	168656		2018-12-12 20:19:39.099	2018-12-12 20:19:39.099
4431	999991-6504-33		2018-12-12 20:19:39.057	2018-12-12 20:19:39.057
4432	001-007722-3061		2018-12-12 20:19:39.057	2018-12-12 20:19:39.057
4433	A3291001-1		2018-12-12 20:19:39.057	2018-12-12 20:19:39.057
4434	901-370-361-403		2018-12-12 20:19:39.057	2018-12-12 20:19:39.057
4435	020026	\N	2019-01-18 20:42:25.582341	2019-01-18 20:42:25.572
4436	040025	\N	2019-01-18 20:42:25.600836	2019-01-18 20:42:25.598
4437	090049	\N	2019-01-18 20:42:25.608954	2019-01-18 20:42:25.606
4438	000000	\N	2019-01-18 20:42:25.62323	2019-01-18 20:42:25.621
4439	163911	\N	2019-01-18 20:43:26.15223	2019-01-18 20:43:26.142
4440	163912	\N	2019-01-18 20:43:26.161787	2019-01-18 20:43:26.159
4441	163913	\N	2019-01-18 20:43:26.169721	2019-01-18 20:43:26.167
4442	163914	\N	2019-01-18 20:43:26.177233	2019-01-18 20:43:26.175
4443	163915	\N	2019-01-18 20:43:26.184559	2019-01-18 20:43:26.182
4444	163916	\N	2019-01-18 20:43:26.191743	2019-01-18 20:43:26.189
4445	164939	\N	2019-01-18 20:43:26.199368	2019-01-18 20:43:26.197
4446	164941	\N	2019-01-18 20:43:26.21043	2019-01-18 20:43:26.208
4447	164942	\N	2019-01-18 20:43:26.218848	2019-01-18 20:43:26.216
4448	164949	\N	2019-01-18 20:43:26.227245	2019-01-18 20:43:26.225
4449	165432	\N	2019-01-18 20:43:26.237021	2019-01-18 20:43:26.234
4450	165433	\N	2019-01-18 20:43:26.248271	2019-01-18 20:43:26.246
4451	165434	\N	2019-01-18 20:43:26.25632	2019-01-18 20:43:26.254
4452	165435	\N	2019-01-18 20:43:26.264667	2019-01-18 20:43:26.262
4453	165436	\N	2019-01-18 20:43:26.272916	2019-01-18 20:43:26.27
4454	165437	\N	2019-01-18 20:43:26.281093	2019-01-18 20:43:26.278
4455	165438	\N	2019-01-18 20:43:26.288735	2019-01-18 20:43:26.286
4456	165439	\N	2019-01-18 20:43:26.296556	2019-01-18 20:43:26.294
4457	165440	\N	2019-01-18 20:43:26.308595	2019-01-18 20:43:26.306
4458	165441	\N	2019-01-18 20:43:26.317797	2019-01-18 20:43:26.315
4459	165442	\N	2019-01-18 20:43:26.32555	2019-01-18 20:43:26.323
4460	165443	\N	2019-01-18 20:43:26.333138	2019-01-18 20:43:26.331
4461	165444	\N	2019-01-18 20:43:26.344674	2019-01-18 20:43:26.342
4462	165837	\N	2019-01-18 20:43:26.352483	2019-01-18 20:43:26.35
4463	165839	\N	2019-01-18 20:43:26.363533	2019-01-18 20:43:26.361
4464	166392	\N	2019-01-18 20:43:26.48965	2019-01-18 20:43:26.487
4465	166393	\N	2019-01-18 20:43:26.500018	2019-01-18 20:43:26.498
4466	166394	\N	2019-01-18 20:43:26.50716	2019-01-18 20:43:26.505
4467	166395	\N	2019-01-18 20:43:26.514058	2019-01-18 20:43:26.512
4468	N/A	\N	2019-01-18 20:43:27.114301	2019-01-18 20:43:27.112
4469	I-level 	\N	2019-01-18 20:43:27.132797	2019-01-18 20:43:27.13
\.


--
-- Data for Name: dashboardreports; Type: TABLE DATA; Schema: app; Owner: appowner
--

COPY app.dashboardreports (id, userid, adhocqueryid, createdat, updatedat) FROM stdin;
\.


--
-- Data for Name: groups; Type: TABLE DATA; Schema: app; Owner: appowner
--

COPY app.groups (id, name, description, createdat, updatedat) FROM stdin;
1	devs	AppFactory developers	2018-12-04 13:39:00.783889	2018-12-04 13:39:00.783889
4	v22users	V-22 Users	2018-12-06 18:22:25.254	2018-12-06 18:22:25.254
7	testgroup1	Test group 1	2018-12-07 12:59:50.29	2018-12-07 12:59:50.29
8	testgroup2	Test group2	2018-12-07 13:00:00.159	2018-12-07 13:00:00.159
9	testgroup3	Test group3	2018-12-07 13:00:27.999	2018-12-07 13:00:27.999
6	admins	Project Administrators	2018-12-07 04:24:40.034	2018-12-07 18:19:23.555
10	TD Tracker Users	TD Tracker users group	2018-12-07 18:30:02.817	2018-12-07 18:30:02.817
11	managers1	Test managers 1	2019-02-27 20:54:24.989	2019-02-27 20:54:24.989
17	Squadron	General squadron user	2019-05-16 15:16:14.505	2019-05-16 15:16:14.505
16	FST	Fleet Support Team group	2019-05-16 19:15:36.04	2019-05-16 15:24:38.219
15	FSR	Field Service Representative group	2019-05-16 19:15:22.826	2019-05-16 15:25:03.696
18	OEM	Original Equipment Manufacturer group	2019-05-16 15:27:52.695	2019-05-16 15:27:52.695
\.


--
-- Data for Name: issueattachments; Type: TABLE DATA; Schema: app; Owner: appowner
--

COPY app.issueattachments (id, issueid, attachmentid, createdat, updatedat) FROM stdin;
\.


--
-- Data for Name: issues; Type: TABLE DATA; Schema: app; Owner: appowner
--

COPY app.issues (id, appid, issuetypeid, createdat, updatedat, jsondata, subject, activityid, priorityid, statusid, workflowstateid, workflowactionid) FROM stdin;
\.


--
-- Data for Name: issuetypes; Type: TABLE DATA; Schema: app; Owner: appowner
--

COPY app.issuetypes (id, appid, searchable, description, createdat, updatedat, label, jsondata) FROM stdin;
\.


--
-- Data for Name: masterdata; Type: TABLE DATA; Schema: app; Owner: appowner
--

COPY app.masterdata (id, apptableid, name, description, createdat, updatedat, appid, jsondata) FROM stdin;
\.


--
-- Data for Name: priority; Type: TABLE DATA; Schema: app; Owner: appowner
--

COPY app.priority (id, appid, label, description, createdat, updatedat, jsondata) FROM stdin;
\.


--
-- Data for Name: reporttemplates; Type: TABLE DATA; Schema: app; Owner: appowner
--

COPY app.reporttemplates (id, appid, name, createdat, updatedat, primarytableid, jsondata, ownerid, editaction, deleteaction) FROM stdin;
\.


--
-- Data for Name: resourcetypes; Type: TABLE DATA; Schema: app; Owner: appowner
--

COPY app.resourcetypes (id, name) FROM stdin;
\.


--
-- Data for Name: roleassignments; Type: TABLE DATA; Schema: app; Owner: appowner
--

COPY app.roleassignments (id, roleid, userid, groupid, createdat, updatedat) FROM stdin;
79	36	\N	1	2019-05-14 12:51:47.291	2019-05-14 12:51:51.963
95	36	\N	6	2019-05-28 12:34:30.800446	2019-05-28 12:34:30.800446
\.


--
-- Data for Name: rolerestrictions; Type: TABLE DATA; Schema: app; Owner: appowner
--

COPY app.rolerestrictions (id, resourcetypeid, appid, roleid, visible, editable, resourceid, workflowstateid) FROM stdin;
\.


--
-- Data for Name: roles; Type: TABLE DATA; Schema: app; Owner: appowner
--

COPY app.roles (id, name, description, appid, createdat, updatedat, jsondata) FROM stdin;
36	System Administrators	System admins for maintenance of applications	0	2019-05-14 16:45:27.003	2019-05-28 12:34:30.802	\N
\.


--
-- Data for Name: status; Type: TABLE DATA; Schema: app; Owner: appowner
--

COPY app.status (id, appid, label, description, createdat, updatedat, jsondata) FROM stdin;
\.


--
-- Data for Name: support; Type: TABLE DATA; Schema: app; Owner: appowner
--

COPY app.support (id, title, value, hours, userid, createdat, updatedat, displayorder, appid) FROM stdin;
4	Primary Email Support	v22web@navy.mil	\N	\N	2019-10-17 12:39:16	2019-10-17 12:39:15	1	0
5	Phone support after 1500 eastern	(252)464-6035	\N	\N	2019-10-17 12:40:09	2019-10-17 12:40:11	2	0
6	Developer	\N	0630-1500 eastern	3573	2019-10-17 12:41:05	2019-10-17 12:41:07	3	0
7	Developer	\N	0600-1430 eastern	1725	2019-10-17 12:41:54	2019-10-17 12:41:57	4	0
8	Program Manager	\N	0730-1600 eastern	1768	2019-10-17 12:42:35	2019-10-17 12:42:38	5	0
\.


--
-- Data for Name: tableattachments; Type: TABLE DATA; Schema: app; Owner: appowner
--

COPY app.tableattachments (createdat, updatedat, id, attachmentid, apptableid, recordid) FROM stdin;
\.


--
-- Data for Name: userattachments; Type: TABLE DATA; Schema: app; Owner: appowner
--

COPY app.userattachments (id, userid, attachmentid, createdat, updatedat) FROM stdin;
\.


--
-- Data for Name: usergroups; Type: TABLE DATA; Schema: app; Owner: appowner
--

COPY app.usergroups (id, userid, groupid, createdat, updatedat) FROM stdin;
1	3575	1	\N	2018-12-05 19:41:23.812081
2	3573	1	\N	2018-12-05 19:41:23.812081
3	1725	1	\N	2018-12-05 19:41:23.812081
18	4	4	2018-12-06 20:31:06.979746	2018-12-06 20:31:06.979746
21	3575	4	2018-12-06 20:36:18.21562	2018-12-06 20:36:18.21562
22	6	10	2018-12-07 18:39:12.348303	2018-12-07 18:39:12.348303
23	7	10	2018-12-07 18:39:39.971015	2018-12-07 18:39:39.971015
24	8	10	2018-12-07 18:40:00.775802	2018-12-07 18:40:00.775802
25	10	7	2018-12-07 19:18:31.858278	2018-12-07 19:18:31.858278
26	11	7	2018-12-07 19:19:03.011395	2018-12-07 19:19:03.011395
27	12	7	2018-12-07 19:19:29.273873	2018-12-07 19:19:29.273873
28	14	11	2019-02-27 20:54:55.895697	2019-02-27 20:54:55.895697
29	15	11	2019-02-27 20:55:02.858622	2019-02-27 20:55:02.858622
30	16	11	2019-02-27 20:55:09.260444	2019-02-27 20:55:09.260444
31	13	7	2019-02-27 21:18:21.334095	2019-02-27 21:18:21.334095
32	13	6	2019-02-27 21:18:21.334095	2019-02-27 21:18:21.334095
33	2174	6	2019-02-27 21:21:57.822569	2019-02-27 21:21:57.822569
34	2174	11	2019-02-27 21:21:57.822569	2019-02-27 21:21:57.822569
41	33	15	2019-05-16 17:00:30.211943	2019-05-16 17:00:30.211943
42	34	15	2019-05-16 17:01:04.741426	2019-05-16 17:01:04.741426
43	36	16	2019-05-16 17:02:21.810356	2019-05-16 17:02:21.810356
44	35	16	2019-05-16 17:02:40.783454	2019-05-16 17:02:40.783454
45	37	18	2019-05-16 17:03:54.696959	2019-05-16 17:03:54.696959
46	38	18	2019-05-16 17:04:20.516743	2019-05-16 17:04:20.516743
47	10	17	2019-05-16 18:18:12.921876	2019-05-16 18:18:12.921876
48	11	17	2019-05-16 18:18:17.95073	2019-05-16 18:18:17.95073
49	12	17	2019-05-16 18:18:23.496915	2019-05-16 18:18:23.496915
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: app; Owner: appowner
--

COPY app.users (id, active, email, firstname, mi, lastname, designationid, phone, dsn, fax, npke_subject, npke_edipi, npke_user, rankid, activityid, affiliationid, siteid, saarn, initialdate, updatedate, lastlogindate, branchid, approvaldate, disabled, aircrafttypeid) FROM stdin;
3176	1	joe.vang@usmc.mil	Joe		Vang	5	9104496065			CN=VANG.JOE.1455246748,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1455246748		4	25	3	2	0	\N	\N	\N	3	\N	1	1
2366	0	shawn.draper@us.af.mil	Shawn	O	Draper	\N				CN=DRAPER.SHAWN.O.1083630368,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1	DRAPER.SHAWN.O	\N	\N	\N	\N	1	\N	\N	\N	\N	\N	0	\N
2424	0	carlos.a.franco@navy.mil	Carlos	A	Franco	\N				CN=FRANCO.CARLOS.ALBERTO.1235172905,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1	FRANCO.CARLOS.ALBERTO	\N	\N	\N	\N	1	\N	\N	\N	\N	\N	0	\N
3358	1	grant.roth@navy.mil	Grant		Roth	3	2524646683			CN=ROTH.GRANT.T.1523583057,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1523583057		20	15	1	18	0	\N	\N	\N	4	\N	0	1
2049	0	victoria.bader.1@us.af.mil	Victoria		Bader	5	5058467622	2467622		CN=BADER.VICTORIA.MARIE.1140927410,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1140927410		5	6	3	5	0	\N	\N	\N	1	\N	0	2
900	1	gary.m.kline.ctr@navy.mil	Gary		Kline	4	9107501623			CN=KLINE.GARY.M.1093063445,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1141323233	KLINE.GARY.M	20	15	2	2	0	\N	\N	\N	3	\N	0	1
910	1	mguy@bh.com	Michael		Guy	5	5058537160	2637160		CN=GUY.MICHAEL.L.1155567534,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1060319371	GUY.MICHAEL.L	20	20	2	5	0	\N	\N	\N	1	\N	0	2
2021	1	patrick.armentrout@navy.mil	Patrick		Armentrout	1	9104495494			CN=ARMENTROUT.PATRICK.A.1229745480,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1229745480	ARMENTROUT.PATRICK.A	20	15	1	2	0	\N	\N	\N	3	\N	0	1
2022	1	john.dantic@usmc.mil	John		Dantic	1	8585776225	2222		CN=DANTIC.JOHN.M.1133281564,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1065484494	DANTIC.JOHN.M	21	10	1	6	0	\N	\N	\N	3	\N	0	\N
1	1	v22web@navy.mil	Sys		Admin	\N					\N		20	2	1	2	\N	\N	\N	\N	4	\N	1	\N
2028	1	john.e.plets.civ@mail.mil	John		Plets	3	8004736597			CN=PLETS.JOHN.E.1268158940,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1268158940	PLETS.JOHN.E	21	10	1	4	0	\N	\N	\N	4	\N	0	\N
2050	1	andrew.gartee@usmc.mil	Andrew		Gartee	5	9104496267	7526267		CN=GARTEE.ANDREW.JAMES.JR.1411005271,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1141323233		4	25	3	2	0	\N	\N	\N	3	\N	0	\N
3117	0	joshua.r.white1@navy.mil	Joshua		White	5	6195530062		6195534229	CN=WHITE.JOSHUA.R.1369124265,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1229745480		20	38	2	6	0	\N	\N	\N	4	\N	0	1
926	1	jimmy.r.jalil@boeing.com	Jimmy		Jalil	5	8508812645	6412645		CN=JALIL.JIMMY.R.1024394910,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1024394910	JALIL.JIMMY.R	20	16	2	11	0	\N	\N	\N	1	\N	0	2
2038	0	jonathan.miller@usmc.mil	Jonathan		Miller	5	9104497265	7527265		CN=MILLER.JONATHAN.JOB.1265528020,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1265528020		6	25	3	2	0	\N	\N	\N	3	\N	0	1
2051	1	justin.caudle@us.af.mil	Justin		Caudle	5	8508841313			CN=CAUDLE.JUSTIN.EDWARD.1364972233,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1364972233		5	2	3	11	0	\N	\N	\N	1	\N	0	\N
2001	1	jimmy.r.jalil@boeing.com	Jimmy		Jalil	5	8508812645	6412645		CN=Jimmy Jalil,OU=The Boeing Company,OU=VeriSign\\, Inc.,OU=ECA,O=U.S. Government,C=US	-1		20	16	2	11	0	\N	\N	\N	1	\N	0	2
2004	1	jonathan.reyes3@usmc.mil	Jonathan		Reyes	5	8585771318	5771318		CN=REYES.JONATHAN.AGUYLES.1455990382,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1051055540		4	23	3	4	0	\N	\N	\N	3	\N	0	2
2005	1	kelly.campagna@usmc.mil	Kelly		Campagna	5	8585777694	1231231234		CN=CAMPAGNA.KELLY.ANNE.1362108671,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1065484494		6	23	3	6	0	\N	\N	\N	3	\N	0	\N
2007	1	brian.sulser@usmc.mil	Brian		Sulser	5	8585779107			CN=SULSER.BRIAN.J.1058523662,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1051055540		7	45	3	4	0	\N	\N	\N	3	\N	0	1
2008	1	mark.whittle.2@us.af.mil	Mark		Whittle	3	8508813105	641310511		CN=WHITTLE.MARK.ANTHONY.1060319371,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1065484494	WHITTLE.MARK.ANTHONY	21	15	1	11	0	\N	\N	\N	4	\N	0	\N
2025	1	victor.reyes.1@us.af.mil	Victor		Reyes	5	3142386175	2386175		CN=REYES.VICTOR.M.1243723325,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1243723325		7	4	3	13	0	\N	\N	\N	1	\N	0	\N
2037	0	hadley.hoopes@usmc.mil	Hadley		Hoopes	5	9104497087			CN=HOOPES.HADLEY.BRYAN.1469087812,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1469087812		4	52	3	2	0	\N	\N	\N	3	\N	0	1
3106	0	dejuan.rudolph@usmc.mil	Dejuan		Rudolph	5	8585774132			CN=RUDOLPH.DEJUAN.LEHASHAUN.1258803201,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1258803201		6	56	3	4	0	\N	\N	\N	3	\N	0	1
100	1	scott.a.cottrell@navy.mil	Scott		Cottrell	1	2524646151	4516151	1231231231	CN=COTTRELL.SCOTT.A.1229762679,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1065484494	COTTRELL.SCOTT.A	20	15	1	18	0	\N	\N	\N	4	\N	0	\N
2009	1	matthew.van_benthem.ctr@us.af.mil	Matthew		Van Benthem	3	8508813023	6413023		CN=VAN BENTHEM.MATTHEW.SHERIDAN.1395515655,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1060319371		20	15	2	11	0	\N	\N	\N	1	\N	0	2
2020	1	jacob.mayes@us.af.mil	Jacob		Mayes	5	5757840919	7840919		CN=MAYES.JACOB.MICHAEL.1292500820,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1060319371		5	3	3	12	0	\N	\N	\N	1	\N	0	2
2024	1	victor.camacho.ctr@usmc.mil	Victorian		Camacho	3	8585779534	2679534		CN=CAMACHO.VICTORIAN.1176176020,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1176176020		20	35	2	4	0	\N	\N	\N	3	\N	0	\N
2027	1	alan.rivers@usmc.mil	Alan		Rivers	4	9104496065			CN=RIVERS.ALAN.PAUL.1397570360,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1397570360		5	25	3	2	0	\N	\N	\N	3	\N	0	1
2063	1	zachary.passini@usmc.mil	Zachary		Passini	5	3156367658	6367658		CN=PASSINI.ZACHARY.JOSEPH.1299045214,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1299045214		16	53	3	7	0	\N	\N	\N	3	\N	0	1
3107	1	scarlett.orlando@me.usmc.mil	Orlando		Scarlett	5	8585774132			CN=SCARLETT.ORLANDO.1236752808,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1236752808		7	56	3	4	0	\N	\N	\N	3	\N	0	\N
3108	1	maurice.m.defino@boeing.com	Maurice		Defino	5	8582426983			CN=Maurice DeFino,OU=The Boeing Company,OU=VeriSign\\, Inc.,OU=ECA,O=U.S. Government,C=US	1141323233		20	31	2	8	0	\N	\N	\N	3	\N	0	1
2003	1	gabriel.austin@us.af.mil	Gabriel		Austin	5	5757910854	6817040		CN=AUSTIN.GABRIEL.GUNTLE.1248021868,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1248021868		7	3	3	12	0	\N	\N	\N	1	\N	0	\N
280	1	wabril@bh.com	William		Abril	5	9104495523			CN=ABRIL.WILLIAM.F.1227124420,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1227124420	ABRIL.WILLIAM.F	20	32	2	2	0	\N	\N	\N	3	\N	0	1
2614	0	mark.jones21@us.af.mil	Mark	J	Jones	\N				CN=JONES.MARK.J.1097016581,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1	JONES.MARK.J	\N	\N	\N	\N	1	\N	\N	\N	\N	\N	0	\N
2002	1	fructuoso.santos@usmc.mil	Fructuoso		Santosjr	4	8585779638			CN=SANTOSJR.FRUCTUOSO.MARIANO.III.1376419556,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1287802451		5	23	3	4	0	\N	\N	\N	3	\N	0	\N
2036	1	paul.l.smith1@usmc.mil	Paul		Smith	5	9104496053			CN=SMITH.PAUL.LESLIE.1052653807,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1052653807		5	49	3	2	0	\N	\N	\N	3	\N	0	\N
2055	1	zayed.antonio@us.af.mil	Antonio		Zayed	5	5757841501	6811501		CN=ANTONIO.ZAYED.ISAAC.1293747357,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1293747357		5	3	3	12	0	\N	\N	\N	1	\N	0	\N
2554	1	jonathan.hobby@usmc.mil	Jonathan		Hobby	5	7607631460			CN=HOBBY.JONATHAN.MICHAEL.1270642671,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1287802451	HOBBY.JONATHAN.MICHAEL	6	28	3	8	0	\N	\N	\N	3	\N	0	1
2556	1	john.hoffman.12@us.af.mil	John		Hoffman	5	3142383690	2384646		CN=HOFFMAN.JOHN.AUTHUR.III.1293707940,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1293707940	HOFFMAN.JOHN.AUTHUR.III	6	4	3	13	0	\N	\N	\N	1	\N	0	\N
2558	1	connor.hollern@usmc.mil	Connor		Hollern	5	9104497252			CN=HOLLERN.CONNOR.LESLE.1465548068,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1465548068	HOLLERN.CONNOR.LESLE	3	25	3	2	0	\N	\N	\N	3	\N	0	1
2560	1	gregory.hollinger.ctr@us.af.mil	Gregory		Hollinger	5	5058466519	2466519		CN=HOLLINGER.GREGORY.L.1077683328,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1077683328	HOLLINGER.GREGORY.L	20	20	2	5	0	\N	\N	\N	1	\N	0	\N
2562	1	choppe@bh.com	Clinton		Hoppe	5	9104515525			CN=HOPPE.CLINTON.C.1066021374,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1066021374	HOPPE.CLINTON.C	20	32	2	2	0	\N	\N	\N	3	\N	0	\N
2564	1	george.horvath.1@us.af.mil	George		Horvath	5	5058535089	8535089		CN=HORVATH.GEORGE.AARON.1265675308,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1265675308	HORVATH.GEORGE.AARON	6	6	3	5	0	\N	\N	\N	1	\N	0	2
2566	1	mhouck@bh.com	Micah		Houck	5	3142384654			CN=HOUCK.MICAH.MCCLURE.1257377969,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1257377969	HOUCK.MICAH.MCCLURE	20	21	2	13	0	\N	\N	\N	1	\N	0	2
2568	1	jeffrey.a.houston@navy.mil	Jeffrey		Houston	2	2524648797			CN=HOUSTON.JEFFREY.A.1229801739,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1229801739	HOUSTON.JEFFREY.A	21	10	1	18	0	\N	\N	\N	4	\N	0	\N
2570	1	jeffrey.hovis.1.ctr@us.af.mil	Jeffrey		Hovis	5	5058537171			CN=HOVIS.JEFFREY.S.1167706777,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1167706777	HOVIS.JEFFREY.S	20	6	2	5	0	\N	\N	\N	1	\N	0	2
2572	1	shawn.howard@usmc.mil	Shawn		Howard	1	9104494331			CN=HOWARD.SHAWN.A.1186869750,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1186869750	HOWARD.SHAWN.A	7	61	3	2	0	\N	\N	\N	3	\N	0	1
2574	1	dennis.hudon.2@us.af.mil	Dennis		Hudon	4	8508812641	6412641		CN=HUDON.DENNIS.J.1186701638,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1186701638	HUDON.DENNIS.J	21	2	1	11	0	\N	\N	\N	1	\N	0	2
2576	1	damon.hughes.1.ctr@us.af.mil	Damon		Hughes	5	5759045227	6405227		CN=HUGHES.DAMON.H.1075799299,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1075799299	HUGHES.DAMON.H	20	13	2	12	0	\N	\N	\N	1	\N	0	\N
2578	1	kevin.o.hughes.ctr@navy.mil	Kevin		Hughes	3	3017570051			CN=HUGHES.KEVIN.O.1283782243,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1283782243	HUGHES.KEVIN.O	21	19	2	9	0	\N	\N	\N	3	\N	0	1
2580	1	anthony.huntington@usmc.mil	Anthony		Huntington	1	9104495352	7524352		CN=HUNTINGTON.ANTHONY.E.1160520546,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1160520546	HUNTINGTON.ANTHONY.E	9	61	3	2	0	\N	\N	\N	3	\N	0	1
2582	1	rashad.hurd@usmc.mil	Rashad		Hurd	5	8585778155	2678155		CN=HURD.RASHAD.LEON.1263763480,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1263763480	HURD.RASHAD.LEON	6	43	3	4	0	\N	\N	\N	3	\N	0	1
2584	1	juan.itzol.ctr@navy.mil	Juan		Itzol	5	3019954630			CN=ITZOL.JUAN.C.1028834035,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1028834035	itzoljc	20	39	2	9	0	\N	\N	\N	4	\N	0	1
2586	1	bryan.jackson.11@us.af.mil	Bryan		Jackson	5	5058533490	2633490		CN=JACKSON.BRYAN.K.1054061419,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1054061419	JACKSON.BRYAN.K	20	6	1	5	0	\N	\N	\N	1	\N	0	2
2588	1	matthew.c.jackson1@navy.mil	Matthew		Jackson	3	9104495862	7525862	9104495222	CN=JACKSON.MATTHEW.CHRISTOPHER.1252707030,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1252707030	JACKSON.MATTHEW.CHRISTOPHER	20	15	1	2	0	\N	\N	\N	3	\N	0	\N
2590	1	michael.jackson.61.ctr@us.af.mil	Michael		Jackson	3	8508814306	6414306		CN=JACKSON.MICHAEL.R.1298084046,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1060319371	JACKSON.MICHAEL.R	20	15	2	11	0	\N	\N	\N	1	\N	0	2
2592	1	jesse.jacobsen@usmc.mil	Jesse		Jacobsen	5	9104497123			CN=JACOBSEN.JESSE.OWEN.JR.1269440461,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1269440461	JACOBSEN.JESSE.OWEN.JR	6	49	3	2	0	\N	\N	\N	3	\N	0	1
2594	1	trevor.james@us.af.mil	Trevor		James	1	8508842592	5792959		CN=JAMES.TREVOR.L.1186181634,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1051055540	JAMES.TREVOR.L	8	8	3	11	0	\N	\N	\N	1	\N	0	2
2596	1	kyle.jarchow@us.af.mil	Kyle		Jarchow	5	0756855976			CN=JARCHOW.KYLE.JAMES.1291652863,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1291652863	JARCHOW.KYLE.JAMES	6	4	3	13	0	\N	\N	\N	1	\N	0	2
2598	1	doug.jefferson@navy.mil	Douglas		Jefferson	3	2524648525			CN=JEFFERSON.DOUGLAS.M.1229776394,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1229776394	jeffersondm	21	15	1	18	0	\N	\N	\N	4	\N	0	1
2600	1	adam.johnson.5@us.af.mil	Adam		Johnson	5	5058535755			CN=JOHNSON.ADAM.L.1061541752,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1061541752	JOHNSON.ADAM.L	7	6	3	5	0	\N	\N	\N	1	\N	0	2
2602	1	jeffery.c.johnson@usmc.mil	Jeffery		Johnson	5	9104496970			CN=JOHNSON.JEFFERY.CALVIN.JR.1277946200,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1277946200	JOHNSON.JEFFERY.CALVIN.JR	7	25	3	2	0	\N	\N	\N	3	\N	0	1
2604	1	jeremiah.johnson@usmc.mil	Jeremiah		Johnson	5	9104497252			CN=JOHNSON.JEREMIAH.DEVON.1470537309,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1470537309	JOHNSON.JEREMIAH.DEVON	3	25	3	2	0	\N	\N	\N	3	\N	0	1
2606	1	michael.d.johnson27@boeing.com	Michael		Johnson	5	5058460263	2460263		CN=JOHNSON.MICHAEL.D.1155681957,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1155681957	Johnson, Michael, D	20	20	2	5	0	\N	\N	\N	1	\N	0	2
2608	1	joseph.joiner.2.ctr@us.af.mil	Joseph		Joiner	5	5058535440	2635440		CN=JOINER.JOSEPH.RYAN.1294320373,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1294320373	JOINER.JOSEPH.RYAN	20	20	2	5	0	\N	\N	\N	1	\N	0	\N
2610	1	jason.jones.46@us.af.mil	Jason		Jones	5	3142384613	2384613		CN=JONES.JASON.ALLEN.1363612578,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1363612578	JONES.JASON.ALLEN	6	4	3	13	0	\N	\N	\N	1	\N	0	2
2612	1	ljjones@bh.com	Lawrence		Jones	5	8175425207			CN=JONES.LAWRENCE.JOSEPH.JR.1260039292,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1260039292	JONES.LAWRENCE.JOSEPH.JR	20	31	2	7	0	\N	\N	\N	3	\N	0	\N
2616	1	melisa.jones@navy.mil	Melisa		Jones	5	2524648530	4518530		CN=JONES.MELISA.R.1164255243,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1164255243	JONES.MELISA.R	21	15	1	18	0	\N	\N	\N	4	\N	0	\N
2686	0	kevin.macken@usmc.mil	Kevin	C	Macken	\N				CN=MACKEN.KEVIN.CHRISTOPHER.1300123011,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1	MACKEN.KEVIN.CHRISTOPHER	\N	\N	\N	\N	1	\N	\N	\N	\N	\N	0	\N
2688	1	scott.madden1@navy.mil	Brian		Madden	4	3017574403			CN=MADDEN.BRIAN.SCOTT.1115623482,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1229745480	MADDEN.BRIAN.SCOTT	20	38	1	9	0	\N	\N	\N	3	\N	0	1
2690	0	sebastian.maik@usmc.mil	Sebastian	M	Maik	\N				CN=MAIK.SEBASTIAN.MAREK.1046092763,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1	MAIK.SEBASTIAN.MAREK	\N	\N	\N	\N	1	\N	\N	\N	\N	\N	0	\N
2692	1	christopher.mandich@us.af.mil	Christopher		Mandich	5	5058535089	2535089		CN=MANDICH.CHRISTOPHER.WILLIAM.1296655453,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1296655453	MANDICH.CHRISTOPHER.WILLIAM	5	6	3	5	0	\N	\N	\N	1	\N	0	2
2694	1	angela.mankowski@navy.mil	Angela		Mankowski	4	3017575577	13121212		CN=MANKOWSKI.ANGELA.A.1047244540,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1065484494	MANKOWSKI.ANGELA.A	21	38	1	9	0	\N	\N	\N	4	\N	0	\N
2696	1	enrique.mari@usmc.mil	Enrique		Mari Jr	5	3156366249			CN=MARI.ENRIQUE.JR.1235000314,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1235000314	MARI.ENRIQUE.JR	7	50	3	7	0	\N	\N	\N	3	\N	0	1
2698	1	edward.e.marks@boeing.com	Edward		Marks	4	8503776443			CN=MARKS.EDWARD.E.1121140264,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1060319371	MARKS.EDWARD.E	20	16	2	11	0	\N	\N	\N	1	\N	0	\N
2700	1	amartinez05@bh.com	Abraham		Martinez	5	8585776833	1236547899		CN=MARTINEZ.ABRAHAM.DAVID.1282774891,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1065484494	MARTINEZ.ABRAHAM.DAVID	20	31	2	4	0	\N	\N	\N	3	\N	0	\N
2702	1	ronnie.matthews@usmc.mil	Ronnie		Matthews	5	8082573588			CN=MATTHEWS.RONNIE.ALAN.1157933457,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1157933457	MATTHEWS.RONNIE.ALAN	7	55	3	81	0	\N	\N	\N	3	\N	0	\N
2704	0	brian.mays@usmc.mil	Brian	D	Mays	\N				CN=MAYS.BRIAN.DEE.1285995775, OU=USMC, OU=PKI, OU=DoD, O=U.S. Government, C=US	1	maysbd	\N	\N	\N	\N	1	\N	\N	\N	\N	\N	0	\N
2706	1	mitchell.mccue@us.af.mil	Mitchell		Mccue	5	8508841313	5791313		CN=MCCUE.MITCHELL.LEE.1270810051,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1270810051	MCCUE.MITCHELL.LEE	6	2	3	11	0	\N	\N	\N	1	\N	0	\N
2708	1	todd.mcgee1@navy.mil	Todd		Mcgee	4	3019952893	9952893		CN=MCGEE.TODD.A.1147417639,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1147417639	MCGEE.TODD.A	20	38	1	9	0	\N	\N	\N	1	\N	0	1
2710	1	daniel.mcguigan@usmc.mil	Daniel		Mcguigan	5	3156362024			CN=MCGUIGAN.DANIEL.PATRICK.1035440409,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1035440409	MCGUIGAN.DANIEL.PATRICK	5	50	3	7	0	\N	\N	\N	3	\N	0	1
2712	1	kristi.mckinney1@navy.mil	Kristi		Mckinney	4	2524646479			CN=MCKINNEY.KRISTI.D.1229811408,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1229811408	MCKINNEY.KRISTI.D	21	10	1	18	0	\N	\N	\N	4	\N	0	1
2714	1	richard.medlin@whmo.mil	Richard		Medlin	5	5714944729			CN=MEDLIN.RICHARD.KIETH.1260249211,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1260249211	MEDLIN.RICHARD.KIETH	6	17	3	80	0	\N	\N	\N	3	\N	0	\N
2716	1	jeffrey.mickler@navy.mil	Jeffrey		Mickler	3	2524646158			CN=MICKLER.JEFFREY.L.1502791083,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1229745480	MICKLER.JEFFREY.L	21	15	1	18	0	\N	\N	\N	4	\N	0	1
2718	1	bryce.mihelich@me.usmc.mil	Bryce		Mihelich	5	0809458233	6367658		CN=MIHELICH.BRYCE.ROBERT.1388575480,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1388575480	MIHELICH.BRYCE.ROBERT	5	47	3	4	0	\N	\N	\N	3	\N	0	\N
2720	1	troy.mikko@usmc.mil	Troy		Mikko	5	9104495661			CN=MIKKO.TROY.K.1096306020,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1096306020	MIKKO.TROY.K	20	61	2	2	0	\N	\N	\N	3	\N	0	1
2722	1	christopher.w.miller@boeing.com	Christopher		Miller	1	9109376842			CN=MILLER.CHRISTOPHER.W.1254393149,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1254393149	MILLER.CHRISTOPHER.W	20	32	2	2	0	\N	\N	\N	3	\N	0	1
2724	1	jensen.miller@usmc.mil	Jensen		Miller	5	9104497227	7527227		CN=MILLER.JENSEN.JAMES.1260825034,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1260825034	MILLER.JENSEN.JAMES	7	25	3	2	0	\N	\N	\N	3	\N	0	1
2726	1	kade.miller@usmc.mil	Kade		Miller	5	9104497994			CN=MILLER.KADE.NORMAN.1300817790,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1300817790	MILLER.KADE.NORMAN	5	61	3	2	0	\N	\N	\N	3	\N	0	1
2728	1	stephen.w.miller3@boeing.com	Stephen		Miller	5	9104495220	1236547878		CN=Stephen Miller,OU=The Boeing Company,OU=VeriSign\\, Inc.,OU=ECA,O=U.S. Government,C=US	1065484494	MILLER.STEPHEN.WESLEY	20	32	2	2	0	\N	\N	\N	3	\N	0	\N
2730	1	brodrick.mills@usmc.mil	Brodrick		Mills	5	0906366124			CN=MILLS.BRODRICK.DEAN.1465554920,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1465554920	MILLS.BRODRICK.DEAN	4	27	3	7	0	\N	\N	\N	3	\N	0	\N
2732	1	patrick.moholt@navy.mil	Patrick		Moholt	3	9104494080			CN=MOHOLT.PATRICK.J.1379274532,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1379274532	MOHOLT.PATRICK.J	21	10	1	2	0	\N	\N	\N	4	\N	0	1
2734	1	david.montoya.1@us.af.mil	David		Montoya	5	5058469841	2469841		CN=MONTOYA.DAVID.A.1132480580,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1132480580	MONTOYA.DAVID.A	6	3	3	5	0	\N	\N	\N	1	\N	0	\N
2736	1	adalberto.morales@usmc.mil	Adalberto		Morales	5	0806490712			CN=MORALES.ADALBERTO.1380634070,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1380634070	MORALES.ADALBERTO	5	50	3	7	0	\N	\N	\N	3	\N	0	1
2738	0	kenneth.morris.5@us.af.mil	Kenneth	C	Morris	\N				CN=MORRIS.KENNETH.CHARLES.II.1235298860,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1	MORRIS.KENNETH.CHARLES.II	\N	\N	\N	\N	1	\N	\N	\N	\N	\N	0	\N
2740	1	jonathan.morton.2@us.af.mil	Jonathan		Morton	5	5058533550			CN=MORTON.JONATHAN.GEORGE.1288947526,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1288947526	MORTON.JONATHAN.GEORGE	5	6	3	5	0	\N	\N	\N	1	\N	0	2
2742	1	marshall.mosher@us.af.mil	Marshall		Mosher	5	8508847659	5797659		CN=MOSHER.MARSHALL.HARPER.1249189649,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1249189649	MOSHER.MARSHALL.HARPER	8	8	3	11	0	\N	\N	\N	1	\N	0	2
2744	1	david.motley@navy.mil	David		Motley	3	2524646276			CN=MOTLEY.DAVID.R.1258799905,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1258799905	MOTLEY.DAVID.R	20	10	1	18	0	\N	\N	\N	4	\N	0	\N
2746	0	carlos.muletromero@whmo.mil	Carlos	n	Muletromero	\N				CN=MULETROMERO.CARLOS.1255617741, OU=USMC, OU=PKI, OU=DoD, O=U.S. Government, C=US	1	muletromero.carlos	\N	\N	\N	\N	1	\N	\N	\N	\N	\N	0	\N
2748	1	christopher.munas@usmc.mil	Christopher		Munas	5	9103201654	3156362		CN=MUNAS.CHRISTOPHER.D.1190193779,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1133281564	MUNAS.CHRISTOPHER.D	20	34	2	7	0	\N	\N	\N	3	\N	0	\N
2750	0	john.c.munroe@navy.mil	John	C	Munroe	\N				CN=MUNROE.JOHN.C.1011089000,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1	MUNROE.JOHN.C	\N	\N	\N	\N	1	\N	\N	\N	\N	\N	0	\N
2622	1	thomas.e.jones4@navy.mil	Thomas		Jones	4	3017572007			CN=JONES.THOMAS.E.1049238700,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1049238700	JONES.THOMAS.E	21	38	1	9	0	\N	\N	\N	4	\N	0	\N
2752	1	joseph.a.murray@usmc.mil	Joseph		Murray	5	9104494556			CN=MURRAY.JOSEPH.ALLEN.1261578502,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1261578502	MURRAY.JOSEPH.ALLEN	7	44	3	2	0	\N	\N	\N	3	\N	0	1
2754	1	joseph.muscarella@us.af.mil	Joseph		Muscarella	5	5058465089			CN=MUSCARELLA.JOSEPH.B.III.1287966470,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1287966470	MUSCARELLA.JOSEPH.B.III	6	6	3	5	0	\N	\N	\N	1	\N	0	2
2756	1	christopher.d.napier@boeing.com	Christopher		Napier	5	8585776833			CN=NAPIER.CHRISTOPHER.D.1142167286,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1133281564	NAPIER.CHRISTOPHER.D	20	31	2	4	0	\N	\N	\N	3	\N	0	1
2758	1	ashley.napolitano@us.af.mil	Ashley		Napolitano	5	8508841309	5791309		CN=NAPOLITANO.ASHLEY.HUGHES.1272657838,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1272657838	NAPOLITANO.ASHLEY.HUGHES	5	2	3	11	0	\N	\N	\N	1	\N	0	2
2760	1	ldnelson@bh.com	Larry		Nelson	5	8508812651	6412651		CN=NELSON.LARRY.DUANE.1136393274,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1136393274	NELSON.LARRY.DUANE	20	16	2	11	0	\N	\N	\N	1	\N	0	2
2762	1	joseph.newhart.1@us.af.mil	Joseph		Newhart	3	5759045249	6405249		CN=NEWHART.JOSEPH.P.1079551364,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1079551364	NEWHART.JOSEPH.P	21	3	1	12	0	\N	\N	\N	1	\N	0	\N
2764	0	walter.l.norwood@usmc.mil	Walter	L	Norwood	\N				CN=NORWOOD.WALTER.L.1055085818,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1	NORWOOD.WALTER.L	\N	\N	\N	\N	1	\N	\N	\N	\N	\N	0	\N
2766	1	daniel.nosek@usmc.mil	Daniel		Nosek	5	9104495291			CN=NOSEK.DANIEL.RAY.1276229750,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1276229750	NOSEK.DANIEL.RAY	6	58	3	2	0	\N	\N	\N	3	\N	0	\N
2768	1	david.j.oconnor1@navy.mil	David		Oconnor	5	2524645495	4515495		CN=OCONNOR.DAVID.J.1007344488,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1007344488	OCONNOR.DAVID.J	21	10	1	18	0	\N	\N	\N	4	\N	0	\N
2984	1	zachary.stewart@us.af.mil	Zachary		Stewart	5	5757840529	6810529		CN=STEWART.ZACHARY.DAVID.1077443513,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1077443513	STEWART.ZACHARY.DAVID	7	3	3	12	0	\N	\N	\N	1	\N	0	2
2986	1	christopher.stoffels@us.af.mil	Christopher		Stoffels	5	3142383192	2383178		CN=STOFFELS.CHRISTOPHER.S.1186961265,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1186961265	STOFFELS.CHRISTOPHER.S	7	4	3	13	0	\N	\N	\N	1	\N	0	\N
2988	1	steven.stone.11@us.af.mil	Steven		Stone	5	3142383159			CN=STONE.STEVEN.P.1078459863,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1078459863	STONE.STEVEN.P	21	4	1	13	0	\N	\N	\N	1	\N	0	2
2990	1	mark.strohmeyer@navy.mil	Mark		Strohmeyer	3	2524645434			CN=STROHMEYER.MARK.1272478313,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1272478313	STROHMEYER.MARK	21	15	1	18	0	\N	\N	\N	4	\N	0	\N
2992	1	michael.sullivan.36@us.af.mil	Michael		Sullivan	3	4783272775	4972775		CN=SULLIVAN.MICHAEL.J.1045875551,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1045875551	SULLIVAN.MICHAEL.J	21	7	1	11	0	\N	\N	\N	1	\N	0	\N
2994	1	david.tavares.ctr@usmc.mil	David		Tavares	4	7607253800			CN=TAVARES.DAVID.ALAN.1168653308,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1168653308	TAVARES.DAVID.ALAN	20	28	2	8	0	\N	\N	\N	3	\N	0	1
2996	1	anthony.t.taylor1.ctr@navy.mil	Anthony		Taylor	1	3019954656	1231231234		CN=TAYLOR.ANTHONY.TYRONE.SR.1018749722,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1065484494	TAYLOR.ANTHONY.TYRONE.SR	20	39	2	9	0	\N	\N	\N	3	\N	0	\N
2998	1	timothy.tenny@us.af.mil	Timothy		Tenny	5	3142384308			CN=TENNY.TIMOTHY.BROOKS.1298731661,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1298731661	TENNY.TIMOTHY.BROOKS	5	4	3	13	0	\N	\N	\N	1	\N	0	\N
3000	1	daniel.tesh@usmc.mil	Daniel		Tesh	5	9104494683			CN=TESH.DANIEL.LAMAR.1261806459,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1261806459	TESH.DANIEL.LAMAR	6	44	3	2	0	\N	\N	\N	3	\N	0	1
3002	1	anthony.thomas.5@us.af.mil	Anthony		Thomas	5	3122383154			CN=THOMAS.ANTHONY.P.1170990052,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1170990052	THOMAS.ANTHONY.P	20	4	1	13	0	\N	\N	\N	1	\N	0	2
3004	1	brandon.s.thomas@usmc.mil	Brandon		Thomas	5	9104497368			CN=THOMAS.BRANDON.SHANE.1275859083,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1275859083	THOMAS.BRANDON.SHANE	6	54	3	2	0	\N	\N	\N	3	\N	0	1
3008	1	brian.thompson.28@us.af.mil	Brian		Thompson	5	7554003406	2383192		CN=THOMPSON.BRIAN.DAVID.1266544347,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1266544347	THOMPSON.BRIAN.DAVID	7	4	3	13	0	\N	\N	\N	1	\N	0	2
3010	0	lauren.maldonado@navy.mil	Lauren	J	Maldonado	\N				CN=THORNTON.LAUREN.J.1299007908,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1	MALDONADO.LAUREN.J	\N	\N	\N	\N	1	\N	\N	\N	\N	\N	0	\N
3012	1	jon.k.thorsten@usmc.mil	Jon		Thorsten	5	8585771280			CN=THORSTEN.JON.KENT.1265316901,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1265316901	THORSTEN.JON.KENT	6	60	3	4	0	\N	\N	\N	3	\N	0	1
3014	0	jason.tipaldos@usmc.mil	Jason	R	Tipaldos	\N				CN=TIPALDOS.JASON.RICHARD.1258496031,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1	TIPALDOS.JASON.RICHARD	\N	\N	\N	\N	1	\N	\N	\N	\N	\N	0	\N
3016	0	andrew.torres@usmc.mil	Andrew		Torres	\N				CN=TORRES.ANDREW.1367369244, OU=USMC, OU=PKI, OU=DoD, O=U.S. Government, C=US	1	torresa	\N	\N	\N	\N	1	\N	\N	\N	\N	\N	0	\N
3018	1	chad.trask@usmc.mil	Chad		Trask	5	9104496669			CN=TRASK.CHAD.DAVID.1368840633,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1368840633	TRASK.CHAD.DAVID	5	61	3	2	0	\N	\N	\N	3	\N	0	1
3020	1	joseph.trigg.1@us.af.mil	Joseph		Trigg	5	5757840529			CN=TRIGG.JOSEPH.RYAN.1246365683,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1246365683	TRIGG.JOSEPH.RYAN	7	3	3	12	0	\N	\N	\N	1	\N	0	2
3022	0	guillermo.tristan@usmc.mil	Guillermo	A	Tristan	\N				CN=TRISTAN.GUILLERMO.ALEJANDRO.JR.1400583451,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1	TRISTAN.GUILLERMO.ALEJANDRO.JR	\N	\N	\N	\N	1	\N	\N	\N	\N	\N	0	\N
3024	1	robert.trunck@usmc.mil	Robert		Trunck	5	3156367658			CN=TRUNCK.ROBERT.WILLIAM.1368840625,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1368840625	TRUNCK.ROBERT.WILLIAM	5	53	3	7	0	\N	\N	\N	3	\N	0	\N
3026	1	holly.tucker@navy.mil	Holly		Tucker	3	2524646240			CN=TUCKER.HOLLY.F.1395976130,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1395976130	TUCKER.HOLLY.F	21	15	1	18	0	\N	\N	\N	4	\N	0	1
3028	1	pdturner@bh.com	Paul		Turner	5	8508812651			CN=TURNER.PAUL.D.1048848431,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1060319371	TURNER.PAUL.D	20	16	2	11	0	\N	\N	\N	1	\N	0	2
2618	1	riley.jones@us.af.mil	Riley		Jones	5	3142383192	2383192		CN=JONES.RILEY.W.1237498166,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1237498166	JONES.RILEY.W	7	4	3	13	0	\N	\N	\N	1	\N	0	2
2620	1	terry.jones.25.ctr@us.af.mil	Terry		Jones	3	8508815872	6415872		CN=JONES.TERRY.N.1277015508,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1277015508	JONES.TERRY.N	20	15	2	11	0	\N	\N	\N	1	\N	0	2
2846	0	james.k.riddle@navy.mil	James	K	Riddle	\N				CN=RIDDLE.JAMES.KEVIN.1046572277,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1	RIDDLE.JAMES.KEVIN	\N	\N	\N	\N	1	\N	\N	\N	\N	\N	0	\N
2624	1	zachary.l.jones@usmc.mil	Zachary		Jones	5	9104497252			CN=JONES.ZACHARY.LAVAR.1107228868,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1107228868	JONES.ZACHARY.LAVAR	5	25	3	2	0	\N	\N	\N	3	\N	0	1
2626	1	rckellner@bh.com	Robert		Kellner	5	5058535439	2635439		CN=KELLNER.ROBERT.C.III.1240817264,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1240817264	KELLNER.ROBERT.C.III	20	20	2	5	0	\N	\N	\N	1	\N	0	\N
2628	1	kristopher.kendall.2@us.af.mil	Kristopher		Kendall	5	2106525221			CN=KENDALL.KRISTOPHER.M.1064448567,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1064448567	KENDALL.KRISTOPHER.M	7	8	3	11	0	\N	\N	\N	1	\N	0	\N
2630	1	martin.w.kendrex@boeing.com	Martin		Kendrex	5	5759045225	640522544		CN=KENDREX.MARTIN.W.1179535099,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1065484494	KENDREX.MARTIN.W	20	13	2	12	0	\N	\N	\N	1	\N	0	\N
2632	1	jeffrey.kennedy@usmc.mil	Jeffrey		Kennedy	5	9104495971			CN=KENNEDY.JEFFREY.THOMAS.1265017645,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1265017645	KENNEDY.JEFFREY.THOMAS	16	51	3	2	0	\N	\N	\N	3	\N	0	1
2634	1	emily.kerlin@usmc.mil	Emily		Kerlin	3	8585779543			CN=KERLIN.EMILY.B.1271214487,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1271214487	KERLIN.EMILY.B	21	10	1	4	0	\N	\N	\N	3	\N	0	1
2636	1	beau.kitchens@usmc.mil	Beau		Kitchens	5	9104496419			CN=KITCHENS.BEAU.DAREN.1384071909,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1384071909	KITCHENS.BEAU.DAREN	5	49	3	2	0	\N	\N	\N	3	\N	0	1
2640	0	brian.koskey@usmc.mil	Brian	M	Koskey	\N				CN=KOSKEY.BRIAN.MITCHELL.1258239411,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1	KOSKEY.BRIAN.MITCHELL	\N	\N	\N	\N	1	\N	\N	\N	\N	\N	0	\N
2642	1	sanders.kreycik@usmc.mil	Sanders		Kreycik	5	7607636391	3616391		CN=KREYCIK.SANDERS.R.1159528207,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1159528207	KREYCIK.SANDERS.R	8	28	3	8	0	\N	\N	\N	3	\N	0	\N
2644	1	bryan.kruger@usmc.mil	Bryan		Kruger	5	9282696880			CN=KRUGER.BRYAN.CHRISTOPHER.1275242868,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1275242868	KRUGER.BRYAN.CHRISTOPHER	6	62	3	6	0	\N	\N	\N	3	\N	0	1
2646	1	slane2@bh.com	Stanley		Lane	5	9104496560	4496560		CN=LANE.STANLEY.B.1031373308,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1031373308	LANE.STANLEY.B	20	32	2	2	0	\N	\N	\N	3	\N	0	1
2648	1	clarence.langi@us.af.mil	Clarence		Langi	5	8508846954			CN=LANGI.CLARENCE.ELIJAH.1277824805,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1277824805	LANGI.CLARENCE.ELIJAH	5	2	3	11	0	\N	\N	\N	1	\N	0	2
2650	1	ronald.lasky@us.af.mil	Ronald		Lasky	5	8508813439	6413439		CN=LASKY.RONALD.J.JR.1072466175,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1072466175	LASKY.RONALD.J.JR	21	2	1	11	0	\N	\N	\N	1	\N	0	2
2654	1	brandon.laughrey@whmo.mil	Brandon		Laughrey	4	5714944725	5714944		CN=LAUGHREY.BRANDON.PAUL.1011220050,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1011220050	LAUGHREY.BRANDON.PAUL	7	17	3	80	0	\N	\N	\N	3	\N	0	\N
2656	1	lawrence.lee.5@us.af.mil	Lawrence		Lee	5	5757842939	6812939		CN=LEE.LAWRENCE.III.1246497245,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1246497245	LEE.LAWRENCE.III	6	3	3	12	0	\N	\N	\N	1	\N	0	2
2658	1	matthew.r.lee@usmc.mil	Matthew		Lee	5	7605255487			CN=LEE.MATTHEW.ROYCE.1235298615,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1235298615	LEE.MATTHEW.ROYCE	6	57	3	8	0	\N	\N	\N	3	\N	0	1
2660	1	carlisle.leitch@navy.mil	Carlisle		Leitch	3	2524646177	4516177		CN=LEITCH.CARLISLE.H.1460337344,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1460337344	LEITCH.CARLISLE.H	21	15	1	18	0	\N	\N	\N	4	\N	0	1
2662	1	erwin.lewis@navy.mil	Erwin		Lewis	3	9104494080			CN=LEWIS.ERWIN.B.1467818771,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1467818771	LEWIS.ERWIN.B	20	10	1	18	0	\N	\N	\N	4	\N	0	\N
2664	1	robert.liebig@lhd2.navy.mil	Robert		Liebig	4	8585776624			CN=LIEBIG.ROBERT.WILLIAM.JR.1400294980,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1400294980	LIEBIG.ROBERT.WILLIAM.JR	5	23	3	4	0	\N	\N	\N	3	\N	0	\N
2666	1	joe.lingle@usmc.mil	Joe		Lingle	5	8585779146			CN=LINGLE.JOE.DAVID.JR.1368793791,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1368793791	LINGLE.JOE.DAVID.JR	5	23	3	4	0	\N	\N	\N	3	\N	0	\N
2668	1	orlando.lloyd@usmc.mil	Orlando		Lloyd	5	8585778035			CN=LLOYD.ORLANDO.LEWIS.1281824933,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1281824933	LLOYD.ORLANDO.LEWIS	6	47	3	4	0	\N	\N	\N	3	\N	0	\N
2670	0	john.loizzi@usmc.mil	John	L	Loizzi	\N				CN=LOIZZI.JOHN.L.1186735001,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1	LOIZZI.JOHN.L	\N	\N	\N	\N	1	\N	\N	\N	\N	\N	0	\N
2672	1	danilo.a.lopez@usmc.mil	Danilo		Lopez	3	9104497087			CN=LOPEZ.DANILO.ALBERTO.1274271759,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1274271759	LOPEZ.DANILO.ALBERTO	6	52	3	77	0	\N	\N	\N	3	\N	0	1
2674	0	guillermo.lopez.5.ctr@us.af.mil	Guillermo	M	Lopez	\N				CN=LOPEZ.GUILLERMO.M.1008253060,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1	LOPEZ.GUILLERMO.M	\N	\N	\N	\N	1	\N	\N	\N	\N	\N	0	\N
2676	1	hector.f.lopezavila@boeing.com	Hector		Lopezavila	5	5759045233	6405233		CN=LOPEZAVILA.HECTOR.FRANCISCO.1267961375,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1267961375	LOPEZAVILA.HECTOR.FRANCISCO	20	13	2	12	0	\N	\N	\N	1	\N	0	\N
2678	0	felipe.lucas@usmc.mil	Felipe	U	Lucas	\N				CN=LUCAS.FELIPE.UDEL.1173777686,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1	LUCAS.FELIPE.UDEL	\N	\N	\N	\N	1	\N	\N	\N	\N	\N	0	\N
2680	1	gary.lynch@usmc.mil	Gary		Lynch	5	9105464191			CN=LYNCH.GARY.DON.1268942650,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1268942650	LYNCH.GARY.DON	6	149	3	79	0	\N	\N	\N	3	\N	0	1
2682	1	jeffrey.mabe@navy.mil	Jeffrey		Mabe	3	2524648636	4518636	2524646400	CN=MABE.JEFFREY.D.1254742291,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1254742291	MABE.JEFFREY.D	21	15	1	18	0	\N	\N	\N	4	\N	0	\N
2684	1	kenneth.mabe@usmc.mil	Kenneth		Mabe	5	7607630529			CN=MABE.KENNETH.MICHAEL.1054086225,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1054086225	MABE.KENNETH.MICHAEL	8	46	3	8	0	\N	\N	\N	3	\N	0	1
2950	0	karen.solberg@us.af.mil	Karen	M	Solberg	\N				CN=SOLBERG.KAREN.MICHELLE.1259149777,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1	RUEBELMAN.KAREN.MICHELLE	\N	\N	\N	\N	1	\N	\N	\N	\N	\N	0	\N
2952	1	aaron.m.soto3.civ@mail.mil	Aaron		Soto	1	1231231234	1231231234		CN=SOTO.AARON.M.1403940808,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1065484494	SOTO.AARON.M	16	17	1	8	0	\N	\N	\N	1	\N	0	\N
2954	1	lauren.sovine@usmc.mil	Lauren		Sovine	5	9104497245			CN=SOVINE.LAUREN.ALISON.1463451750,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1463451750	SOVINE.LAUREN.ALISON	4	25	3	2	0	\N	\N	\N	3	\N	0	1
2956	0	jeremy.sparkman@us.af.mil	Jeremy	A	Sparkman	\N				CN=SPARKMAN.JEREMY.A.1242354717,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1	Sparkman,J,A	\N	\N	\N	\N	1	\N	\N	\N	\N	\N	0	\N
2958	1	christopher.d.sparr@navy.mil	Christopher		Sparr	3	2524646273			CN=SPARR.CHRISTOPHER.D.1374268992,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1374268992	SPARR.CHRISTOPHER.D	21	15	1	18	0	\N	\N	\N	4	\N	0	1
2960	1	jeremy.spaulding@navy.mil	Jeremy		Spaulding	4	2402374392			CN=SPAULDING.JEREMY.CARR.1171156781,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1229745480	SPAULDING.JEREMY.CARR	20	38	2	9	0	\N	\N	\N	4	\N	0	1
2962	1	eric.speck@navy.mil	Eric		Speck	3	3013420839			CN=SPECK.ERIC.STANLEY.1200872750,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1200872750	SPECK.ERIC.STANLEY	21	38	1	9	0	\N	\N	\N	4	\N	0	1
2964	1	derek.spencer.2@us.af.mil	Derek		Spencer	5	5759046031	6416031		CN=SPENCER.DEREK.ALAN.1256747738,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1256747738	SPENCER.DEREK.ALAN	6	3	3	12	0	\N	\N	\N	1	\N	0	2
2966	1	john.spitzer.1@us.af.mil	John		Spitzer	5	8508812682			CN=SPITZER.JOHN.ERIC.1253880500,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1253880500	SPITZER.JOHN.ERIC	7	2	3	11	0	\N	\N	\N	1	\N	0	\N
2968	1	dominic.stabler@navy.mil	Dominic		Stabler	1	3019954656			CN=STABLER.DOMINIC.OWEN.SR.1199104558,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1199104558	STABLER.DOMINIC.OWEN.SR	20	39	2	9	0	\N	\N	\N	4	\N	0	1
2970	1	darrell.l.stanley@boeing.com	Darrell		Stanley	5	2525148292	6363984		CN=STANLEY.DARRELL.L.1189474802,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1189474802	stanleydl	20	31	2	7	0	\N	\N	\N	3	\N	0	1
2972	1	sean.starkey@us.af.mil	Sean		Starkey	5	5757842635	6812635		CN=STARKEY.SEAN.T.1126501672,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1126501672	STARKEY.SEAN.T	7	3	3	12	0	\N	\N	\N	1	\N	0	2
2974	1	jesse.steel@navy.mil	Jesse		Steel	3	2524646968	4516968		CN=STEEL.JESSE.R.1298805363,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1298805363	STEEL.JESSE.R	21	15	1	18	0	\N	\N	\N	4	\N	0	1
2976	1	terrance.steele@whmo.mil	Terrance		Steele	5	5714944801			CN=STEELE.TERRANCE.L.1063818611,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1063818611	STEELE.TERRANCE.L	20	32	2	80	0	\N	\N	\N	3	\N	0	1
2978	1	william.b.sterett@boeing.com	William		Sterett	5	8503016966	1234564566		CN=STERETT.WILLIAM.B.1090432296,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1065484494	STERETT.WILLIAM.B	20	21	2	13	0	\N	\N	\N	1	\N	0	\N
2980	0	robert.stevens.5@us.af.mil	Robert	J	Stevens	\N				CN=STEVENS.ROBERT.JOSEPH.1071517604,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1	STEVENS.ROBERT.JOSEPH	\N	\N	\N	\N	1	\N	\N	\N	\N	\N	0	\N
2982	1	russell.d.stewart@navy.mil	Russell		Stewart	5	7578368759			CN=STEWART.RUSSELL.D.1072635759,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1072635759	STEWART.RUSSELL.D	21	38	1	79	0	\N	\N	\N	3	\N	0	\N
2011	1	richard.edwards.21@us.af.mil	Richard		Edwards	5	5058467456	2467465		CN=EDWARDS.RICHARD.LUCAS.1402322906,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1060319371		5	6	3	5	0	\N	\N	\N	1	\N	0	2
2014	1	alejandro.cordero@usmc.mil	Alejandro		Corderogonzalez	4	7574450134	4450134	7574450134	CN=CORDEROGONZALEZ.ALEJANDRO.1248988920,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1248988920		6	149	3	79	0	\N	\N	\N	3	\N	0	1
2015	0	scott.dickover@us.af.mil	Scott		Dickover	5	5757847040	6817040		CN=DICKOVER.SCOTT.E.1088207285,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1060319371		7	3	3	12	0	\N	\N	\N	1	\N	0	2
2019	1	jeffrey.morand.ctr@navy.mil	Jeffrey		Morand	5	2524648716			CN=MORAND.JEFFREY.M.1209016857,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1141323233		20	15	2	18	0	\N	\N	\N	3	\N	0	1
2023	0	fittzpatrick.noel@usmc.mil	Fittzpatrick		Noel	5	9104494556			CN=NOEL.FITTZPATRICK.ARTHUR.1390606377,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1051055540		5	44	3	2	0	\N	\N	\N	3	\N	0	1
2039	1	cameron.a.hubbard@usmc.mil	Cameron		Hubbard	4	7607631479			CN=HUBBARD.CAMERON.ALLEN.1395423386,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1287802451		16	57	3	8	0	\N	\N	\N	3	\N	0	1
2040	0	mark.echard@usmc.mil	Mark		Echard	1	9104496053			CN=ECHARD.MARK.CHRISTOPHER.1281744670,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1051055540		5	49	3	2	0	\N	\N	\N	3	\N	0	1
2041	1	casey.hall@usmc.mil	Casey		Hall	1	9104496053			CN=HALL.CASEY.MITCHELL.1377208583,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1377208583		5	49	3	2	0	\N	\N	\N	3	\N	0	1
2043	1	kevin.ruby@usmc.mil	Kevin		Ruby	5	7607253262			CN=RUBY.KEVIN.HARRISON.1454918807,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1454918807		4	28	3	8	0	\N	\N	\N	3	\N	0	\N
2044	0	carlton.bannerman@us.af.mil	Carlton		Bannerman	5	5058465409			CN=BANNERMAN.CARLTON.V M.1058042575,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1058042575		5	6	3	5	0	\N	\N	\N	1	\N	0	2
2045	0	brian.clark.34@us.af.mil	Brian		Clark	5	5058465409	8465409		CN=CLARK.BRIAN.PETER.1391444370,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1391444370		5	6	3	5	0	\N	\N	\N	1	\N	0	2
2048	1	sharon.d.smith3.ctr@navy.mil	Sharon		Smith	4	2524648526	4518526		CN=SMITH.SHARON.D.1029140401,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1029140401		20	10	2	18	0	\N	\N	\N	4	\N	0	\N
2053	1	joshua.haywood@us.af.mil	Joshua		Haywood	5	5757840919			CN=HAYWOOD.JOSHUA.DANIEL.1254319690,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1254319690		6	3	3	12	0	\N	\N	\N	1	\N	0	\N
2054	1	jared.bennett.4@us.af.mil	Jared		Bennett	5	5757840917	6810917		CN=BENNETT.JARED.ANTHONY.1403994843,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1403994843		5	3	3	12	0	\N	\N	\N	1	\N	0	2
2060	1	michael.e.aguilar1@usmc.mil	Michael		Aguilar	5	9282696863	2696863		CN=AGUILAR.MICHAEL.E.1132431597,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1132431597		7	62	3	2	0	\N	\N	\N	3	\N	0	1
2067	0	jacob.j.cooley@usmc.mil	Jacob		Cooley	5	7605057830			CN=COOLEY.JACOB.JONATHAN.1456760275,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1456760275		4	28	3	8	0	\N	\N	\N	3	\N	0	1
2069	1	ricky.r.boysel@usmc.mil	Ricky		Boysel	5	7607253994	3653994		CN=BOYSEL.RICKY.RAY.JR.1241313227,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1241313227		7	28	3	8	0	\N	\N	\N	3	\N	0	\N
2176	1	edward.abma@usmc.mil	Edward		Abma	5	9104496693	1231231233		CN=ABMA.EDWARD.JACOB.1276272655,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1065484494	ABMA.EDWARD.JACOB	16	52	3	2	0	\N	\N	\N	3	\N	0	\N
2178	0	sergio.acosta@usmc.mil	Sergio	A	Acosta	\N				CN=ACOSTA.SERGIO.A.1134394680,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1	ACOSTA.SERGIO.A	\N	\N	\N	\N	1	\N	\N	\N	\N	\N	0	\N
2180	1	lance.p.aja@boeing.com	Lance		Aja	5	8585776833			CN=AJA.LANCE.P.1007718302,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1229745480	AJA.LANCE.P	20	32	2	79	0	\N	\N	\N	3	\N	0	\N
2182	1	victor.alanis.ctr@navy.mil	Victor		Alanis	5	3017570171			CN=ALANIS.VICTOR.HUGO.JR.1129918043,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1129918043	ALANIS.VICTOR.HUGO.JR	20	39	2	9	0	\N	\N	\N	4	\N	0	1
2184	1	jamie.albonetti@usmc.mil	Jamie		Albonetti	5	3156367659			CN=ALBONETTI.JAMIE.LEIGH.1470083596,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1470083596	ALBONETTI.JAMIE.LEIGH	15	53	3	7	0	\N	\N	\N	3	\N	0	1
2186	1	seth.aldrich@boeing.com	Seth		Aldrich	5	8585776835			CN=ALDRICH.SETH.O.1008962126,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1008962126	ALDRICH.SETH.O	20	31	2	4	0	\N	\N	\N	3	\N	0	1
2188	1	christopher.almeria@us.af.mil	Christopher		Almeria	5	5058467990	2467990		CN=ALMERIA.CHRISTOPHER.J.1167705444,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1167705444	ALMERIA.CHRISTOPHER.J	8	6	3	5	0	\N	\N	\N	1	\N	0	2
2190	1	richard.ammons@us.af.mil	Richard		Ammons	3	8508814474	6414474		CN=AMMONS.RICHARD.B.1246002807,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1060319371	AMMONS.RICHARD.B	21	15	1	11	0	\N	\N	\N	4	\N	0	2
2256	1	lynn.bowman@navy.mil	Lynn		Bowman	3	2524648717			CN=BOWMAN.LYNN.J.1228632950,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1229745480	bowmanlj	21	10	1	18	0	\N	\N	\N	4	\N	0	1
2192	1	lucas.f.anderson.civ@mail.mil	Lucas		Anderson	3	3152642781			CN=ANDERSON.LUCAS.F.1369336866,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1369336866	ANDERSON.LUCAS.F	21	15	1	18	0	\N	\N	\N	4	\N	0	1
2194	1	matthew.a.arsenault@usmc.mil	Matthew		Arsenault	5	7574447818	4447818		CN=ARSENAULT.MATTHEW.A.1013726422,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1013726422	ARSENAULT.MATTHEW.A	6	149	3	79	0	\N	\N	\N	3	\N	0	1
2198	1	robert.j.baker3.ctr@navy.mil	Robert		Baker	5	3019954630			CN=BAKER.ROBERT.JOHN.1298682164,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1298682164	BAKER.ROBERT.JOHN	20	39	2	9	0	\N	\N	\N	4	\N	0	1
2200	1	julius.e.banks@boeing.com	Julius		Banks	1	5714944800	6465465465		CN=Julius Banks,OU=The Boeing Company,OU=VeriSign\\, Inc.,OU=ECA,O=U.S. Government,C=US	1065484494	BANKS.JULIUS.E	20	17	2	80	0	\N	\N	\N	3	\N	0	\N
2202	1	ruber.banks@us.af.mil	Ruber		Banks	5	5757840892			CN=BANKS.RUBER.J.JR.1114922036,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1114922036	banksrj	6	3	3	12	0	\N	\N	\N	1	\N	0	2
2204	1	tony.bare@us.af.mil	Tony		Bare	5	0000000000			CN=BARE.TONY.R.1057549919,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1051055540	BARE.TONY.R	21	8	1	4	0	\N	\N	\N	1	\N	0	2
2206	1	hannah.baron@navy.mil	Hannah		Baron	3	8585778314			CN=BARON.HANNAH.P.1468176030,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1468176030	BARON.HANNAH.P	21	15	1	4	0	\N	\N	\N	4	\N	0	1
2208	1	john.barron.4@us.af.mil	John		Barron	5	8508841313	5791310		CN=BARRON.JOHN.ANDREWS.1290419715,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1290419715	BARRON.JOHN.ANDREWS	6	2	3	11	0	\N	\N	\N	1	\N	0	2
2210	1	aldo.bassignani@navy.mil	Aldo		Bassignani	3	2524646640			CN=BASSIGNANI.ALDO.R.1258528154,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1229745480	BASSIGNANI.ALDO.R	21	10	1	18	0	\N	\N	\N	4	\N	0	1
2212	1	timothy.batchler@usmc.mil	Timothy		Batchler	5	0116365665	315		CN=BATCHLER.TIMOTHY.P.1061411638,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1061411638	BATCHLER.TIMOTHY.P	7	53	3	7	0	\N	\N	\N	3	\N	0	1
2214	1	david.beaman@navy.mil	David		Beaman	3	2524646656	4516656		CN=BEAMAN.DAVID.C.1239535433,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1239535433	BEAMAN.DAVID.C	21	15	1	18	0	\N	\N	\N	4	\N	0	1
2216	1	anita.becerra@usmc.mil	Anita		Becerra	4	8585771318			CN=BECERRA.ANITA.KAREN.1455548922,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1455548922	BECERRA.ANITA.KAREN	5	23	3	4	0	\N	\N	\N	3	\N	0	\N
2218	1	robert.beeton.3@us.af.mil	Robert		Beeton	4	8508814301	6414301		CN=BEETON.ROBERT.ANDREW.1110660363,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1060319371	BEETON.ROBERT.ANDREW	20	15	2	11	0	\N	\N	\N	4	\N	0	\N
2220	1	lee.bennett@usmc.mil	Lee		Bennett	5	3156367658	6367658		CN=BENNETT.LEE.FREDERICK.1163405365,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1163405365	BENNETT.LEE.FREDERICK	6	53	3	7	0	\N	\N	\N	3	\N	0	\N
2222	1	steven.bergland@us.af.mil	Steven		Bergland	5	5757840917			CN=BERGLAND.STEVEN.JAMES GUNN.1294775486,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1294775486	BERGLAND.STEVEN.JAMES GUNN	5	3	3	12	0	\N	\N	\N	1	\N	0	\N
2224	1	mathew.bertalot@navy.mil	Mathew		Bertalot	3	2524646214			CN=BERTALOT.MATHEW.J.1147043054,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1141323233	BERTALOT.MATHEW.J	21	15	1	18	0	\N	\N	\N	3	\N	0	1
2226	1	ted.beszterczei@navy.mil	Ted		Beszterczei	3	2524646183	4516183555		CN=BESZTERCZEI.TED.G.JR.1362611322,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1065484494	beszterczeitg	21	15	1	18	0	\N	\N	\N	4	\N	0	\N
2228	1	timothy.bierce@usmc.mil	Timothy		Bierce	5	7607630576			CN=BIERCE.TIMOTHY.ALLYN.1299735113,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1299735113	BierceTA	5	46	3	8	0	\N	\N	\N	3	\N	0	1
2230	1	robert.bierly@navy.mil	Robert		Bierly	1	3017570161			CN=BIERLY.ROBERT.JOHN.1007531318,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1007531318	BIERLY.ROBERT.JOHN	20	19	2	9	0	\N	\N	\N	3	\N	0	1
2232	1	mbiles@bh.com	Michael		Biles	5	8174716782	2383172	8172789485	CN=BILES.MICHAEL.RAY.1161201509,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1161201509	BILES.MICHAEL.RAY	20	21	2	13	0	\N	\N	\N	1	\N	0	2
2234	0	daniel.blocker@navy.mil	Daniel	K	Blocker	\N				CN=BLOCKER.DANIEL.KEITH.1126306845,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1	BLOCKER.DANIEL.KEITH	\N	\N	\N	\N	1	\N	\N	\N	\N	\N	0	\N
2236	1	kyle.blond@usmc.mil	Kyle		Blond	5	3156363285			CN=BLOND.KYLE.EDWARD.1379789486,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1379789486	BLOND.KYLE.EDWARD	15	27	3	7	0	\N	\N	\N	3	\N	0	1
2238	1	joshua.a.boaz@usmc.mil	Joshua		Boaz	5	8585771677			CN=BOAZ.JOSHUA.A.1088020991,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1088020991	BOAZ.JOSHUA.A	11	60	3	4	0	\N	\N	\N	3	\N	0	1
2240	1	ronald.bogan@us.af.mil	Ronald		Bogan	5	8508812088	6412088		CN=BOGAN.RONALD.L.1081990030,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1060319371	BOGAN.RONALD.L	7	8	3	4	0	\N	\N	\N	1	\N	0	2
2242	0	thomas.h.bonner@navy.mil	Thomas	H	Bonner	\N				CN=BONNER.THOMAS.HOWARD.JR.1134101578,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1	BONNER.THOMAS.HOWARD.JR	\N	\N	\N	\N	1	\N	\N	\N	\N	\N	0	\N
2244	1	leanne.booth@navy.mil	Leanne		Booth	3	2524649978			CN=BOOTH.LEANNE.M.1262186683,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1230678274	BOOTH.LEANNE.M	21	15	1	18	0	\N	\N	\N	4	\N	0	\N
1725	1	travis.makarowski@navy.mil	Travis		Makarowski	4	2524646396			CN=MAKAROWSKI.TRAVIS.W.1141323233,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1141323233	TRAVIS MAKAROWSKI	21	23	1	18	0	\N	\N	\N	4	\N	0	\N
2246	1	travis.borkowski@usmc.mil	Travis		Borkowski	5	8585778089			CN=BORKOWSKI.TRAVIS.CHRISTOPHER.1242523730,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1242523730	BORKOWSKI.TRAVIS.CHRISTOPHER	7	48	3	4	0	\N	\N	\N	3	\N	0	\N
2248	1	brad.bosman@usmc.mil	Brad		Bosman	5	9104494357	4494357		CN=BOSMAN.BRAD.WILLIAM.1411008432,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1411008432	BOSMAN.BRAD.WILLIAM	5	25	3	2	0	\N	\N	\N	3	\N	0	\N
34	\N	sebastian.mills@fsr.mil	Sebastian	B	Mills	\N	1115551212	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2019-05-16 17:01:04.665282	\N	\N	\N	\N	1	\N
2250	0	andrew.boston@usmc.mil	Andrew	M	Boston	\N				CN=BOSTON.ANDREW.MARK.1387733848,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1	BOSTON.ANDREW.MARK	\N	\N	\N	\N	1	\N	\N	\N	\N	\N	0	\N
2252	1	kennth.bowden@usmc.mil	Kenneth		Bowden	5	9104497231			CN=BOWDEN.KENNETH.WEST.1365099894,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1365099894	BOWDEN.KENNETH.WEST	5	25	3	2	0	\N	\N	\N	3	\N	0	1
2254	1	joshua.bowen.1@us.af.mil	Joshua		Bowen	5	0163854461	2384613		CN=BOWEN.JOSHUA.NATHAN.1258473244,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1258473244	BOWEN.JOSHUA.NATHAN	6	4	3	13	0	\N	\N	\N	1	\N	0	2
3498	1	jason.kern@boeing.com	Kern		Jason	1	8584328223			CN=Jason.Kern.2829505,OU=people,O=boeing,C=us	2829505		20	42	2	4	0	\N	\N	\N	3	\N	1	\N
2258	1	brian.m.boyer@rolls-royce.com	Brian		Boyer	1	8582205619	2671332455		CN=BOYER.BRIAN.MICHAEL.1400960476,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1065484494	BOYER.BRIAN.MICHAEL	20	34	2	4	0	\N	\N	\N	3	\N	0	\N
2260	0	james.brady.4@us.af.mil	James	B	Brady	\N				CN=BRADY.JAMES.B.1082207151,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1	BRADY.JAMES.B	\N	\N	\N	\N	1	\N	\N	\N	\N	\N	0	\N
2262	1	scott.braun.2@us.af.mil	Scott		Braun	5	8508815007	6415007		CN=BRAUN.SCOTT.MICHAEL.1256185837,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1256185837	BRAUN.SCOTT.MICHAEL	6	2	3	11	0	\N	\N	\N	1	\N	0	2
2264	1	eric.brodd@usmc.mil	Eric		Brodd	5	3156363938			CN=BRODD.ERIC.ANDREW.1176157166,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1176157166	BRODD.ERIC.ANDREW	12	27	3	7	0	\N	\N	\N	3	\N	0	\N
2266	1	kara.brody@navy.mil	Kara		Brody	3	2524646209			CN=BRODY.KARA.M.1470493697,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1470493697	BRODY.KARA.M	21	15	1	18	0	\N	\N	\N	3	\N	0	\N
2268	1	douglas.brown0@usmc.mil	Douglas		Brown	3	8585774862			CN=BROWN.DOUGLAS.T.1228825553,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1228825553	BROWN.DOUGLAS.T	21	10	1	4	0	\N	\N	\N	3	\N	0	1
2270	0	tyler.budgen@usmc.mil	Tyler	D	Budgen	\N				CN=BUDGEN.TYLER.DEAN.1399618360,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1	BUDGEN.TYLER.DEAN	\N	\N	\N	\N	1	\N	\N	\N	\N	\N	0	\N
2272	0	matthew.burazin@usmc.mil	Matthew	J	Burazin	\N				CN=BURAZIN.MATTHEW.JOHN.1392126984,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1	BURAZIN.MATTHEW.JOHN	\N	\N	\N	\N	1	\N	\N	\N	\N	\N	0	\N
2274	1	joseph.burros@usmc.mil	Joseph		Burros	5	7607253562			CN=BURROS.JOSEPH.STEVEN.1454771644,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1454771644	BURROS.JOSEPH.STEVEN	5	28	3	8	0	\N	\N	\N	3	\N	0	\N
2276	1	dbutler3@bellhelicopter.textron.com	Douglas		Butler	4	8063670448			CN=BUTLER.DOUGLAS.A.1153560524,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1153560524	butlerda	20	39	2	9	0	\N	\N	\N	3	\N	0	1
2278	1	james.m.butler2@navy.mil	James		Butler	3	2524645666			CN=BUTLER.JAMES.M.1196731888,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1196731888	Butlerjm	20	15	1	18	0	\N	\N	\N	4	\N	0	1
2282	0	ethan.calvin@usmc.mil	Ethan	F	Calvin	\N				CN=CALVIN.ETHAN.FRANNELL.1124658353,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1	CALVIN.ETHAN.FRANNELL	\N	\N	\N	\N	1	\N	\N	\N	\N	\N	0	\N
2284	1	joshua.campbell.17@us.af.mil	Joshua		Campbell	5	5058467456	8467456		CN=CAMPBELL.JOSHUA.RYAN.1390748198,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1390748198	CAMPBELL.JOSHUA.RYAN	5	6	3	5	0	\N	\N	\N	1	\N	0	2
2286	1	zachary.capps@navy.mil	Zachary		Capps	3	2527207946			CN=CAPPS.ZACHARY.W.1105031706,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1105031706	CAPPS.ZACHARY.W	21	15	1	18	0	\N	\N	\N	4	\N	0	\N
2288	0	michael.card@us.af.mil	Michael	A	Card	\N				CN=CARD.MICHAEL.ALAN.1102153150,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1	CARD.MICHAEL.ALAN	\N	\N	\N	\N	1	\N	\N	\N	\N	\N	0	\N
2290	1	patrick.j.carr@usmc.mil	Patrick		Carr	5	9104497685			CN=CARR.PATRICK.JAMES.1411011166,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1411011166	CARR.PATRICK.JAMES	5	25	3	2	0	\N	\N	\N	3	\N	0	1
2292	1	kevin.champaigne1@usmc.mil	Kevin		Champaigne	5	9104496116	7526116		CN=CHAMPAIGNE.KEVIN.FRANCIS.1242238660,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1242238660	CHAMPAIGNE.KEVIN.FRANCIS	16	25	3	2	0	\N	\N	\N	3	\N	0	\N
2280	1	bryant.calcote@us.af.mil	Bryant		Calcote	3	8508812534	6412534		CN=CALCOTE.BRYANT.R.1268086443,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1268086443	CALCOTE.BRYANT.R	21	15	1	11	0	\N	\N	\N	4	\N	0	2
2294	1	jason.charpia@us.af.mil	Jason		Charpia	5	3142383192	2383192		CN=CHARPIA.JASON.W.1159871149,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1159871149	CHARPIA.JASON.W	7	4	3	13	0	\N	\N	\N	1	\N	0	2
2296	1	gary.christie@navy.mil	Gary		Christie	4	2524646232	4516232		CN=CHRISTIE.GARY.W.1055348878,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1055348878	CHRISTIE.GARY.W	21	15	1	18	0	\N	\N	\N	3	\N	0	\N
2298	1	jason.cirioni@us.af.mil	Jason		Cirioni	5	0163854614	2386143		CN=CIRIONI.JASON.C.1235313100,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1235313100	CIRIONI.JASON.C	6	4	3	13	0	\N	\N	\N	1	\N	0	2
2300	1	jacob.a.clark2@usmc.mil	Jacob		Clark	5	7607250576			CN=CLARK.JACOB.ALEXANDER.1290918312,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1290918312	CLARK.JACOB.ALEXANDER	6	46	3	6	0	\N	\N	\N	3	\N	0	1
3030	1	gregory.turney@navy.mil	Gregory		Turney	3	2524648725			CN=TURNEY.GREGORY.D.1229828670,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1229828670	turneygd	21	15	1	18	0	\N	\N	\N	3	\N	0	1
3032	1	christopher.k.underw@navy.mil	Christopher		Underwood	3	2524645313			CN=UNDERWOOD.CHRISTOPHER.K.1367940030,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1051055540	UNDERWOOD.CHRISTOPHER.K	20	15	1	18	0	\N	\N	\N	3	\N	0	1
3034	1	roy.uyematsu@us.af.mil	Roy		Uyematsu	3	5759045226	6405226		CN=UYEMATSU.ROY.S.1400711166,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1060319371	UYEMATSU.ROY.S	21	15	1	12	0	\N	\N	\N	4	\N	0	2
3036	1	roy.vancamp.ctr@navy.mil	Roy		Vancamp	5	3017570078			CN=VANCAMP.ROY.EDWARD.1051054748,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1051054748	VANCAMP.ROY.EDWARD	20	39	2	9	0	\N	\N	\N	4	\N	0	\N
3038	1	gerald.vanderstar@usmc.mil	Gerald		Vanderstar	5	9104495865	7825867		CN=VANDERSTAR.GERALD.ELWIN.JR.1093870880,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1093870880	VANDERSTAR.GERALD.ELWIN.JR	7	25	3	2	0	\N	\N	\N	3	\N	0	\N
3040	1	ramon.f.vasquez1@usmc.mil	Ramon		Vasquez	5	9104496839			CN=VASQUEZ.RAMON.F.1187351568,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1187351568	VASQUEZ.RAMON.F	16	25	3	2	0	\N	\N	\N	3	\N	0	\N
3042	1	timothy.j.vaughn@usmc.mil	Timothy		Vaughn	5	9104496065			CN=VAUGHN.TIMOTHY.JOSHUA.1024275180,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1024275180	VAUGHN.TIMOTHY.JOSHUA	4	25	3	2	0	\N	\N	\N	3	\N	0	1
3044	1	leigha.mabe@usmc.mil	Leigha		Veganunez	3	2544627512			CN=VEGANUNEZ.LEIGHA.MARIE.1462636039,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1462636039	VEGANUNEZ.LEIGHA.MARIE	3	25	3	77	0	\N	\N	\N	3	\N	0	1
3046	1	vvillasenor@bh.com	Victor		Villasenor	5	8172401371		8585776830	CN=VILLASENOROJEDA.VICTOR.IVAN.1273605823,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1133281564	VILLASENOROJEDA.VICTOR.IVAN	20	31	2	8	0	\N	\N	\N	3	\N	0	1
3048	1	mvonbergen@bh.com	Michael		Vonbergen	5	8508812651	6412651		CN=VON BERGEN.MICHAEL.EDWARD.1257076551,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1257076551	VON BERGEN.MICHAEL.EDWARD	20	16	2	11	0	\N	\N	\N	1	\N	0	2
3050	1	christopher.voss@usmc.mil	Christopher		Voss	5	3156367661	6367661		CN=VOSS.CHRISTOPHER.JIN.1138177820,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1138177820	VOSS.CHRISTOPHER.JIN	12	53	3	7	0	\N	\N	\N	3	\N	0	\N
3052	1	cory.walker@usmc.mil	Cory		Walker	5	7703612330			CN=WALKER.CORY.DAVID.1410844580,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1410844580	WALKER.CORY.DAVID	15	60	3	4	0	\N	\N	\N	3	\N	0	\N
3054	1	kayo.walton@usmc.mil	Kayo		Walton	1	3156362763			CN=WALTON.KAYO.SCOTT.1397892928,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1397892928	WALTON.KAYO.SCOTT	5	27	3	7	0	\N	\N	\N	3	\N	0	1
3056	1	william.ward@whmo.mil	William		Ward	5	5714944730			CN=WARD.WILLIAM.ROLAND.1288491352,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1288491352	WARD.WILLIAM.ROLAND	6	17	3	80	0	\N	\N	\N	3	\N	0	\N
3060	1	aaron.watson@navy.mil	Aaron		Watsonss	1	1234567890	654654622		abc	1065484494	aaron.watson	4	3	2	17	0	\N	\N	\N	2	\N	0	\N
3062	1	tana.watters@navy.mil	Tana		Watters	5	2524646901	4516901		CN=WATTERS.TANA.S.1155533729,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1155533729	WATTERS.TANA.S	21	10	1	18	0	\N	\N	\N	4	\N	0	\N
3064	1	brenton.webster@usmc.mil	Brenton		Webster	5	9104497087			CN=WEBSTER.BRENTON.LEE.1267734549,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1267734549	WEBSTER.BRENTON.LEE	6	58	3	2	0	\N	\N	\N	3	\N	0	\N
3066	1	james.welch2@usmc.mil	James		Welch	5	3156362000	6362000		CN=WELCH.JAMES.LEE.1242208397,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1242208397	WELCH.JAMES.LEE	15	27	3	7	0	\N	\N	\N	3	\N	0	\N
3068	1	john.wells2@whmo.mil	John		Wells	5	5714944729			CN=WELLS.JOHN.KEVINMCDONALD.1267841060,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1267841060	WELLS.JOHN.KEVINMCDONALD	6	17	3	9	0	\N	\N	\N	3	\N	0	1
3070	1	aaron.wermy@us.af.mil	Aaron		Wermy	5	8508847515	1236548798		CN=WERMY.AARON.JOSEPH.1269270841,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1065484494	WERMY.AARON.JOSEPH	6	2	3	11	0	\N	\N	\N	1	\N	0	\N
3072	1	maurice.wertz@navy.mil	Maurice		Wertz	4	2524645038	4515038		CN=WERTZ.MAURICE.H.1061301336,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1061301336	WERTZ.MAURICE.H	21	15	1	18	0	\N	\N	\N	4	\N	0	1
3074	0	thornton.west@usmc.mil	Thornton	D	West	\N				CN=WEST.THORNTON.DOUGLAS.1365254920, OU=USMC, OU=PKI, OU=DoD, O=U.S. Government, C=US	1	westtd	\N	\N	\N	\N	1	\N	\N	\N	\N	\N	0	\N
3076	1	amy.wheary@navy.mil	Amy		Wheary	3	9104494080			CN=WHEARY.AMY.LYNN.1364811094,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1364811094	WHEARY.AMY.LYNN	21	15	1	2	0	\N	\N	\N	3	\N	0	\N
3078	1	kelly.r.white@navy.mil	Kelly		White	1	2524648388	6546546544	1231231234	CN=WHITE.KELLY.REEVES.1069624240,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1065484494	whitekr	21	15	1	18	0	\N	\N	\N	4	\N	0	\N
3080	1	erin.whitley@navy.mil	Erin		Whitley	3	3017572427			CN=WHITLEY.ERIN.D.1256859897,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1256859897	WHITLEY.ERIN.D	21	38	1	9	0	\N	\N	\N	3	\N	0	1
3082	1	jrwilliams@ltminc.net	Jimmy		Williams	4	2525157281			CN=WILLIAMS.JIMMY.R.1064495867,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1064495867	WILLIAMS.JIMMY.R	20	15	2	18	0	\N	\N	\N	3	\N	0	\N
3084	0	jon.r.williams@usmc.mil	Jon	R	Williams	\N				CN=WILLIAMS.JON.RUSSELL.1407029808,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1	WILLIAMS.JON.RUSSELL	\N	\N	\N	\N	1	\N	\N	\N	\N	\N	0	\N
3086	1	thomas.williams.41@us.af.mil	Thomas		Williams	5	5757840917	6810917		CN=WILLIAMS.THOMAS.CLAY.1288227779,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1288227779	WILLIAMS.THOMAS.CLAY	5	3	3	12	0	\N	\N	\N	1	\N	0	2
3088	1	matthew.willman@usmc.mil	Matthew		Willman	5	7607631468			CN=WILLMAN.MATTHEW.SCOTT.1258495280,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1258495280	WILLMAN.MATTHEW.SCOTT	6	57	3	8	0	\N	\N	\N	3	\N	0	\N
3090	0	jimmy.winn.1@us.af.mil	Jimmy	D	Winn	\N				CN=WINN.JIMMY.D.JR.1042870303,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1	WINN.JIMMY.D.JR	\N	\N	\N	\N	1	\N	\N	\N	\N	\N	0	\N
3092	1	zachary.winter@usmc.mil	Zachary		Winter	5	9104497252			CN=WINTER.ZACHARY.CHARLES.1467472158,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1467472158	WINTER.ZACHARY.CHARLES	4	25	3	2	0	\N	\N	\N	3	\N	0	\N
3094	1	maksim.wolkoff@usmc.mil	Maksim		Wolkoff	5	4405250046			CN=WOLKOFF.MAKSIM.SERGEY.1379358370,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1379358370	WOLKOFF.MAKSIM.SERGEY	5	56	3	4	0	\N	\N	\N	3	\N	0	\N
3096	1	trevor.won@navy.mil	Trevor		Won	3	2524646638			CN=WON.TREVOR.WAY KWONG.1515309299,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1515309299	WON.TREVOR.WAY KWONG	20	10	1	18	0	\N	\N	\N	4	\N	0	1
3098	1	matthew.wuensch@us.af.mil	Matthew		Wuensch	5	8508846954			CN=WUENSCH.MATTHEW.LEE.1266724922,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1266724922	WUENSCH.MATTHEW.LEE	5	2	3	11	0	\N	\N	\N	1	\N	0	2
3100	1	alan.c.young@usmc.mil	Alan		Young	5	7574447818			CN=YOUNG.ALAN.CY.1267735812,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1267735812	YOUNG.ALAN.CY	6	149	3	79	0	\N	\N	\N	3	\N	0	1
1536	1	steven.hagene@navy.mil	Steven		Hagene	5	2524646386		3232323232	CN=HAGENE.STEVEN.EARL.1287802451,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1141323233	STEVEN HAGENE	21	10	1	18	0	\N	\N	\N	4	\N	0	\N
3102	1	richard.j.ytzen@boeing.com	Richard		Ytzen	5	8586927204			CN=Richard Ytzen,OU=BOEING,OU=VeriSign\\, Inc.,OU=ECA,O=U.S. Government,C=US	1141323233	YTZEN.RICHARD.J	20	31	2	8	0	\N	\N	\N	3	\N	0	1
3104	1	kevin.zydowsky@usmc.mil	Kevin		Zydowsky	5	7607253262			CN=ZYDOWSKY.KEVIN.ROBERT.1460507223,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1460507223	ZYDOWSKY.KEVIN.ROBERT	4	28	3	8	0	\N	\N	\N	3	\N	0	\N
3105	1	tyrone.trotter@us.af.mil	Tyrone		Trotter	1	5058537620	2637620		CN=TROTTER.TYRONE.D.1116385259,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1116385259		8	6	3	5	0	\N	\N	\N	1	\N	0	\N
3109	1	michael.graven@us.af.mil	Michael		Graven	5	5757840919			CN=GRAVEN.MICHAEL.JOHN.1103449177,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1103449177		6	3	3	12	0	\N	\N	\N	1	\N	0	\N
3110	1	james.pels.2@us.af.mil	James		Pels	3	8508812690			CN=PELS.JAMES.FRANCIS.1262048698,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1262048698		21	2	1	11	0	\N	\N	\N	1	\N	0	\N
14	\N	bmanager1@navy.mil	Bob	A	Manager1	\N		\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2019-02-28 01:52:58.345	\N	\N	\N	\N	1	\N
3111	1	allen.h.lee@navy.mil	Allen		Lee	3	2524646200	4516200		CN=LEE.ALLEN.H.IV.1513381863,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1513381863		20	10	1	18	0	\N	\N	\N	4	\N	0	1
3112	1	christopher.celestin@navy.mil	Christopher		Celestino	3	2524646651			CN=CELESTINO.CHRISTOPHER.ROBERT.1268041008,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1268041008		21	10	1	18	0	\N	\N	\N	4	\N	0	\N
3113	0	seth.rosbrugh@us.af.mil	Seth		Rosbrugh	5	5752182564	7840910		CN=ROSBRUGH.SETH.LOUIS.1292506887,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1060319371		5	3	3	12	0	\N	\N	\N	1	\N	0	2
3114	0	scott.m.hoffman.ctr@navy.mil	Scott		Hoffman	4	3018636512			CN=HOFFMAN.SCOTT.M.1046531236,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1046531236		20	38	2	9	0	\N	\N	\N	4	\N	0	2
3115	1	joshua.johannsen@usmc.mil	Joshua		Johannsen	5	9104497228			CN=JOHANNSEN.JOSHUA.EDWARD.1454919749,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1454919749		4	25	3	2	0	\N	\N	\N	3	\N	0	1
1770	1	shawn.shea@makin-island.usmc.mil	Shawn		Shea	1	8585279968			CN=SHEA.SHAWN.MICHAEL.1253214992,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1253214992		20	31	2	4	0	\N	\N	\N	3	\N	0	\N
2000	1	paul.charron@navy.mil	Paul		Charron	3	2524646113			CN=CHARRON.PAUL.W.1513905404,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1513905404		21	15	1	18	0	\N	\N	\N	4	\N	0	1
2010	1	jared.kuhn.1@us.af.mil	Jared		Kuhn	5	8508847543	5797543		CN=KUHN.JARED.THOMAS.1383075552,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1383075552		5	2	3	11	0	\N	\N	\N	1	\N	0	2
2016	0	roy.zeisloft@us.af.mil	Roy		Zeisloft	5	5052467610	8467610		CN=ZEISLOFT.ROY.LEE.II.1270641012,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1287802451		6	6	3	5	0	\N	\N	\N	1	\N	0	2
2017	1	kenneth.bobby@usmc.mil	Kenneth		Bobby	5	3183455282			CN=BOBBY.KENNETH.STEPHEN.JR.1025144402,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1025144402		16	56	3	6	0	\N	\N	\N	3	\N	0	1
2018	1	matthew.brownell@usmc.mil	Matthew		Brownell	1	9104497231			CN=BROWNELL.MATTHEW.SPENCER.1454761827,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1454761827		4	25	3	2	0	\N	\N	\N	3	\N	0	1
2029	1	thankins@bh.com	Tobias		Hankins	5	8588373106			CN=HANKINS.TOBIAS.MICHAEL.1083773886,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1133281564		20	31	2	4	0	\N	\N	\N	3	\N	0	1
2030	1	christopher.o.pierce@usmc.mil	Christopher		Pierce	5	9104496053			CN=PIERCE.CHRISTOPHE.OSBORNE.1238010523,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1238010523		6	49	3	2	0	\N	\N	\N	3	\N	0	1
2031	0	jaron.franklin.1@us.af.mil	Jaron		Franklin	5	5058467456	2467456		CN=FRANKLIN.JARON.EDWARD.1100606867,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1060319371		5	6	3	5	0	\N	\N	\N	1	\N	0	2
2032	0	jason.burtnick@navy.mil	Jason		Burtnick	3	2524646178			CN=BURTNICK.JASON.E.1041579494,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1141323233		21	10	1	18	0	\N	\N	\N	4	\N	0	1
2033	1	paul.edwards.6@us.af.mil	Paul		Edwards	5	8508841313	579131		CN=EDWARDS.PAUL.CHANNING.1118769852,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1118769852		6	2	3	11	0	\N	\N	\N	1	\N	0	\N
2034	1	joseph.hollingsworth@usmc.mil	Joseph		Hollingsworth	5	7607630578	3610578		CN=HOLLINGSWORTH.JOSEPH.HERBERT.1235103172,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1235103172		7	46	3	8	0	\N	\N	\N	3	\N	0	\N
2035	1	david.denis@us.af.mil	David		Denis	5	5058467456	2467456		CN=DENIS.DAVID.JOSEPH.1281048771,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1281048771		6	6	3	5	0	\N	\N	\N	1	\N	0	\N
2042	1	tyler.thielen@usmc.mil	Tyler		Thielen	5	6193287107			CN=THIELEN.TYLER.AUSTIN.1455431855,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1455431855		5	23	3	4	0	\N	\N	\N	3	\N	0	1
2046	1	john.l.reeder@boeing.com	John		Reeder	1	6105917639			CN=John Reeder,OU=The Boeing Company,OU=VeriSign\\, Inc.,OU=ECA,O=U.S. Government,C=US	1060319371		20	9	1	18	0	\N	\N	\N	3	\N	0	1
2047	1	v327mxgqa@us.af.mil	Christopher		Taylor	5	5757840919			CN=TAYLOR.CHRISTOPHER.DEWAYNE.1290425588,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1290425588		6	3	3	12	0	\N	\N	\N	1	\N	0	2
2052	1	amado.m.aviles.civ@mail.mil	Amado		Aviles	3	8004736597	3152643		CN=AVILES.AMADO.M.1277023977,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1277023977		21	14	1	4	0	\N	\N	\N	4	\N	0	\N
2056	1	v327mxgqa@us.af.mil	Lindsey		Stanley	5	5757840919	6810919		CN=STANLEY.LINDSEY.MICHELE.1275079851,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1275079851		5	3	3	12	0	\N	\N	\N	1	\N	0	\N
2057	0	darryl.saliva@us.af.mil	Darryl		Saliva	5	5058467622			CN=SALIVA.DARRYL.UCOL.1369370266,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1060319371		5	3	3	5	0	\N	\N	\N	1	\N	0	2
2058	1	michael.gruetzmacher@us.af.mil	Michael		Gruetzmacher	5	5757840919	6810919		CN=GRUETZMACHER.MICHAEL.GORDON.1401461511,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1401461511		5	3	3	12	0	\N	\N	\N	1	\N	0	\N
2059	1	v327mxgqa@us.af.mil	Seth		Bolles	5	5757840919	6810919		CN=BOLLES.SETH.GABRIEL.1367100040,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1367100040		5	3	3	12	0	\N	\N	\N	1	\N	0	2
2061	1	v327mxgqa@us.af.mil	Daniel		Johnson	5	5757840919	6810919		CN=JOHNSON.DANIEL.JAMES.1137781839,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1137781839		5	3	3	12	0	\N	\N	\N	1	\N	0	2
2062	0	james.gerlach@us.af.mil	James		Gerlach	5	5757840919			CN=GERLACH.JAMES.J.1101906589,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1101906589		6	3	3	12	0	\N	\N	\N	1	\N	0	2
2070	1	clayton.loper@us.af.mil	Clayton		Loper	5	5757840919	6810919		CN=LOPER.CLAYTON.ANDREW.1273809925,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1273809925		6	3	3	12	0	\N	\N	\N	1	\N	0	2
3116	1	jeffrey.r.binder.ctr@navy.mil	Jeffrey		Binder	5	3019954632			CN=BINDER.JEFFREY.RONALD.1029486081,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1029486081		21	39	2	9	0	\N	\N	\N	4	\N	0	\N
2770	1	rodney.olsen@navy.mil	Rodney		Olsen	3	2524646109	9426109		CN=OLSEN.RODNEY.J.1251907273,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1141323233	OLSEN.RODNEY.J	21	15	1	18	0	\N	\N	\N	4	\N	0	1
2772	1	steven.orth@usmc.mil	Steven		Orth	5	8585778155			CN=ORTH.STEVEN.ANTONIO.1368373601,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1368373601	ORTH.STEVEN.ANTONIO	5	43	3	4	0	\N	\N	\N	3	\N	0	1
2774	0	donovan.ossman@usmc.mil	Donovan	M	Ossman	\N				CN=OSSMAN.DONOVAN.MICHEAL.1501333570,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1	OSSMAN.DONOVAN.MICHEAL	\N	\N	\N	\N	1	\N	\N	\N	\N	\N	0	\N
2776	1	joseph.pacella@navy.mil	Joseph		Pacella	3	7323231668			CN=PACELLA.JOSEPH.M.1366314608,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1366314608	PACELLA.JOSEPH.M	21	15	1	3	0	\N	\N	\N	4	\N	0	1
2778	1	mario.paez@navy.mil	Mario		Paez	3	2524648648			CN=PAEZ.MARIO.A.1297539589,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1297539589	PAEZ.MARIO.A	21	15	1	18	0	\N	\N	\N	4	\N	0	1
2780	1	garrett.h.page@navy.mil	Garrett		Page	3	2524646199	4516199		CN=PAGE.GARRETT.H.1455290380,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1455290380	PAGE.GARRETT.H	21	10	1	18	0	\N	\N	\N	4	\N	0	1
2782	0	ian.page@usmc.mil	Ian	R	Page	\N				CN=PAGE.IAN.RUSSELL.1366778612,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1	PAGE.IAN.RUSSELL	\N	\N	\N	\N	1	\N	\N	\N	\N	\N	0	\N
2784	1	casey.parkins@usmc.mil	Casey		Parkins	5	3156366249	3156366		CN=PARKINS.CASEY.LEE.1276588997,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1276588997	PARKINS.CASEY.LEE	6	50	3	7	0	\N	\N	\N	3	\N	0	1
2786	1	edwin.partridge@usmc.mil	Edwin		Partridge	5	9282696834			CN=PARTRIDGE.EDWIN.JAMES.1283144344,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1283144344	PARTRIDGE.EDWIN.JAMES	6	62	3	4	0	\N	\N	\N	3	\N	0	1
2788	1	michell.n.patrick@boeing.com	Michell		Patrick	5	8582455974			CN=PATRICK.MICHELL.N.JR.1155108602,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1133281564	PATRICK.MICHELL.N.JR	20	31	2	4	0	\N	\N	\N	3	\N	0	1
2790	1	nicholas.paulson@whmo.mil	Nicholas		Paulson	5	5714944730			CN=PAULSON.NICHOLAS.BRADFORD.1260253260,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1260253260	PAULSON.NICHOLAS.BRADFORD	7	17	3	9	0	\N	\N	\N	3	\N	0	1
2792	1	adil.pence@boxer.usmc.mil	Adil		Pence	5	8585778087			CN=PENCE.ADIL.MEGUINJESSE.1279863905,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1279863905	PENCE.ADIL.MEGUINJESSE	6	48	3	4	0	\N	\N	\N	3	\N	0	1
2794	1	aimee.perkins@usmc.mil	Aimee		Perkins	3	8585778349			CN=PERKINS.AIMEE.LYNN.1279371166,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1279371166	PERKINS.AIMEE.LYNN	21	15	1	4	0	\N	\N	\N	3	\N	0	1
2796	1	torey.pesterre@usmc.mil	Torey		Pesterre	5	8585779388			CN=PESTERRE.TOREY.WILLIAM.1299547007,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1299547007	PESTERRE.TOREY.WILLIAM	5	60	3	4	0	\N	\N	\N	3	\N	0	1
2798	1	jonathan.peter@us.af.mil	Jonathan		Peter	5	8508841309	5791309		CN=PETER.JONATHAN.ROBERT.1391455178,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1391455178	PETER.JONATHAN.ROBERT	5	2	3	11	0	\N	\N	\N	1	\N	0	2
2800	0	marion.phelps@usmc.mil	Marion	R	Phelps	\N				CN=PHELPS.MARION.RYAN.1141912018,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1	PHELPS.MARION.RYAN	\N	\N	\N	\N	1	\N	\N	\N	\N	\N	0	\N
2802	1	roger.phillip@usmc.mil	Roger		Phillip	5	8585778105			CN=PHILLIP.ROGER.GILLIAN.1268617228,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1268617228	PHILLIP.ROGER.GILLIAN	6	48	3	4	0	\N	\N	\N	3	\N	0	\N
2804	1	chad.phillipp@makin-islandusmc.mil	Chad		Phillipp	5	8585779485	2679485		CN=PHILLIPP.CHAD.D.1137880373,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1137880373	PHILLIPP.CHAD.D	7	45	3	4	0	\N	\N	\N	3	\N	0	\N
2806	1	steven.pickering@usmc.mil	Steven		Pickering	1	9104497225			CN=PICKERING.STEVEN.DUANE.1367858776,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1367858776	PICKERING.STEVEN.DUANE	5	25	3	2	0	\N	\N	\N	3	\N	0	1
2808	1	irving.pierson@navy.mil	Irving		Pierson	1	3019954372			CN=PIERSON.IRVING.T.1034644868,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1034644868	PIERSON.IRVING.T	20	39	2	9	0	\N	\N	\N	3	\N	0	\N
2810	1	robert.pike.11@us.af.mil	Robert		Pike	4	8508814312	6414312		CN=PIKE.ROBERT.L.1170175782,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1060319371	PIKE.ROBERT.L	20	15	1	11	0	\N	\N	\N	4	\N	0	2
2812	1	cory.pinkelton@navy.mil	Cory		Pinkelton	3	2524648912			CN=PINKELTON.CORY.A.1454889696,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1454889696	PINKELTON.CORY.A	21	10	1	18	0	\N	\N	\N	4	\N	0	\N
2814	1	daniel.plank@usmc.mil	Daniel		Plank	5	8585778050			CN=PLANK.DANIEL.CHARLES.1264228995,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1264228995	PLANK.DANIEL.CHARLES	6	56	3	4	0	\N	\N	\N	3	\N	0	\N
2816	1	isaac.plummer@us.af.mil	Isaac		Plummer	1	5058535752			CN=PLUMMER.ISAAC.H.1110186769,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1110186769	PLUMMER.ISAAC.H	7	6	3	5	0	\N	\N	\N	1	\N	0	\N
2818	1	douglas.pope.1@us.af.mil	Douglas		Pope	5	5055635089			CN=POPE.DOUGLAS.SHANE.1257580152,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1257580152	POPE.DOUGLAS.SHANE	6	6	3	5	0	\N	\N	\N	1	\N	0	2
2820	1	richard.pope@us.af.mil	Richard		Pope	5	8508841313	5791313		CN=POPE.RICHARD.PATRICK.1173558631,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1173558631	POPE.RICHARD.PATRICK	5	2	3	11	0	\N	\N	\N	1	\N	0	2
2822	0	brandon.porter@navy.mil	Brandon	E	Porter	\N				CN=PORTER.BRANDON.E.1274371125,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1	PORTER.BRANDON.E	\N	\N	\N	\N	1	\N	\N	\N	\N	\N	0	\N
2824	1	darren.pugh@usmc.mil	Darren		Pugh	5	9104496267			CN=PUGH.DARREN.TAYLOR.1471128593,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1471128593	PUGH.DARREN.TAYLOR	3	25	3	2	0	\N	\N	\N	3	\N	0	\N
2826	1	erick.ramirez2@usmc.mil	Erick		Ramirez	4	8183708395			CN=RAMIREZ.ERICK.ALBERT.1465235728,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1465235728	RAMIREZ.ERICK.ALBERT	4	25	3	2	0	\N	\N	\N	3	\N	0	1
2828	1	christopher.ramos3@usmc.mil	Christopher		Ramos	5	3156366230			CN=RAMOS.CHRISTOPHER.1386546840,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1386546840	RAMOS.CHRISTOPHER	15	50	3	7	0	\N	\N	\N	3	\N	0	1
2830	1	garrett.rayfield@us.af.mil	Garrett		Rayfield	3	0162381862			CN=RAYFIELD.GARRETT.WILLIAM.1404262374,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1404262374	RAYFIELD.GARRETT.WILLIAM	5	4	3	13	0	\N	\N	\N	1	\N	0	2
2832	1	jay.raymond@usmc.mil	Jay		Raymond	1	9104497225			CN=RAYMOND.JAY.LYNN.1409033730,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1409033730	RAYMOND.JAY.LYNN	5	25	3	2	0	\N	\N	\N	3	\N	0	1
2834	1	abdul.rehman@navy.mil	Abdul		Rehman	3	2524646152	12365455		CN=REHMAN.ABDUL.1387296073,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1065484494	REHMAN.ABDUL	21	15	1	18	0	\N	\N	\N	4	\N	0	\N
2836	1	daniel.reinbolz@us.af.mil	Daniel		Reinbolz	4	3142384613	2384613		CN=REINBOLZ.DANIEL.JOSEPH.1374792764,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1374792764	REINBOLZ.DANIEL.JOSEPH	5	4	3	13	0	\N	\N	\N	1	\N	0	2
2838	1	ryan.w.reinhart@navy.mil	Ryan		Reinhart	1	2527208289			CN=REINHART.RYAN.W.1079107022,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1079107022	REINHART.RYAN.W	20	15	1	18	0	\N	\N	\N	4	\N	0	\N
2840	1	kenneth.rhoades@usmc.mil	Kenneth		Rhoades	5	9104494684	7524684		CN=RHOADES.KENNETH.J.1024284928,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1024284928	RHOADES.KENNETH.J	7	61	3	2	0	\N	\N	\N	3	\N	0	\N
2842	0	matthew.richter@whmo.mil	Matthew	R	Richter	\N				CN=RICHTER.MATTHEW.R.1185849089,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1	RICHTER.MATTHEW.R	\N	\N	\N	\N	1	\N	\N	\N	\N	\N	0	\N
2844	1	louann.rickley.ctr@usmc.mil	Louann		Rickley	5	7607253800	3653800		CN=RICKLEY.LOUANN.1038732605,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1038732605	RICKLEY.LOUANN	20	28	2	8	0	\N	\N	\N	3	\N	0	\N
3190	1	nichole.gill@navy.mil	Nichole		Gill	3	2524646246	4516246		CN=GILL.NICHOLE.A.1385637230,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1051055540		21	15	1	18	0	\N	\N	\N	4	\N	0	1
2848	1	frederick.m.ridenour@boeing.com	Mike		Ridenour	5	9104494161			CN=RIDENOUR.FREDERICK.M.JR.1183962520,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1183962520	RIDENOUR.FREDERICK.M.JR	20	32	2	2	0	\N	\N	\N	3	\N	0	\N
2850	1	justin.rivenburgh@usmc.mil	Justin		Rivenburgh	3	8585779107			CN=RIVENBURGH.JUSTIN.MICHAEL.1248797335,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1248797335	RIVENBURGH.JUSTIN.MICHAEL	6	45	3	4	0	\N	\N	\N	3	\N	0	1
2852	1	michael.rivera.41.ctr@us.af.mil	Michael		Rivera	5	8508812529			CN=RIVERA.MICHAEL.A.1025058026,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1025058026	RIVERA.MICHAEL.A	21	2	2	11	0	\N	\N	\N	1	\N	0	2
2854	1	john.w.roberts1@usmc.mil	John		Roberts	4	8585779409			CN=ROBERTS.JOHN.WESLEY.1233747765,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1233747765	ROBERTS.JOHN.WESLEY	6	60	3	4	0	\N	\N	\N	3	\N	0	\N
2856	0	shawn.roberts@usmc.mil	Shawn	A	Roberts	\N				CN=ROBERTS.SHAWN.A.1252406359, OU=USMC, OU=PKI, OU=DoD, O=U.S. Government, C=US	1	robertssa	\N	\N	\N	\N	1	\N	\N	\N	\N	\N	0	\N
2858	1	kevin.robertson.6@us.af.mil	Kevin		Robertson	4	1638543195	2383195		CN=ROBERTSON.KEVIN.N.JR.1241713888,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1241713888	ROBERTSON.KEVIN.N.JR	7	4	3	13	0	\N	\N	\N	1	\N	0	2
2860	1	noah.robertson@navy.mil	Noah		Robertson	3	2524646690			CN=ROBERTSON.NOAH.DON.1248051350,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1248051350	ROBERTSON.NOAH.DON	21	15	1	18	0	\N	\N	\N	4	\N	0	\N
2862	0	edwin.e.rodriguez@usmc.mil	Edwin	E	Rodriguez	\N				CN=RODRIGUEZ.EDWIN.E.1182147350,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1	RODRIGUEZ.EDWIN.E	\N	\N	\N	\N	1	\N	\N	\N	\N	\N	0	\N
2864	1	harry.rodriguez.2@us.af.mil	Harry		Rodriguez	5	5757840529	6810529		CN=RODRIGUEZ.HARRY.W.1236518481,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1236518481	RODRIGUEZ.HARRY.W	7	3	3	12	0	\N	\N	\N	1	\N	0	2
2866	1	larodriguez@bh.com	Luis		Rodriguez	5	9102657199			CN=RODRIGUEZ.LUIS.A.JR.1256874810,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1256874810	RODRIGUEZ.LUIS.A.JR	20	17	2	80	0	\N	\N	\N	3	\N	0	1
2868	0	richard.l.rodriguez2@usmc.mil	Richard	L	Rodriguez	\N				CN=RODRIGUEZ.RICHARD.L.1018270567,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1	RODRIGUEZ.RICHARD.L	\N	\N	\N	\N	1	\N	\N	\N	\N	\N	0	\N
2870	1	lance.roe@us.af.mil	Lance		Roe	4	8508841310	5791310		CN=ROE.LANCE.W.1106116489,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1106116489	ROE.LANCE.W	7	2	3	11	0	\N	\N	\N	1	\N	0	\N
2872	1	edward.g.roeloffzen2@boeing.com	Edward		Roeloffzen	5	3142384654			CN=ROELOFFZEN.EDWARD.G.1084094958,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1060319371	ROELOFFZEN.EDWARD.G	20	21	2	13	0	\N	\N	\N	1	\N	0	2
2874	1	alan.roos.1@us.af.mil	Alan		Roos	5	5058464841	2464841		CN=ROOS.ALAN.L.1178650668,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1178650668	ROOS.ALAN.L	21	6	1	5	0	\N	\N	\N	1	\N	0	2
2876	1	pwrosenberger@bh.com	Paul		Rosenberger	5	3017570077			CN=ROSENBERGER.PAUL.WARREN.JR.1042638699,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1042638699	ROSENBERGER.PAUL.WARREN.JR	20	39	2	9	0	\N	\N	\N	3	\N	0	1
2878	1	eric.rowland@usmc.mil	Eric		Rowland	5	9104497247			CN=ROWLAND.ERIC.TODD.1298377981,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1298377981	ROWLAND.ERIC.TODD	5	25	3	2	0	\N	\N	\N	3	\N	0	\N
2880	1	stephen.rubel@usmc.mil	Stephen		Rubel	5	7574447818			CN=RUBEL.STEPHEN.LINCOLN.JR.1240844237,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1240844237	RUBEL.STEPHEN.LINCOLN.JR	11	149	3	79	0	\N	\N	\N	3	\N	0	1
2882	1	damien.ruggieri@usmc.mil	Damien		Ruggieri	5	9175179492			CN=RUGGIERI.DAMIEN.JOSEPH.1018541323,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1018541323	RUGGIERI.DAMIEN.JOSEPH	6	51	3	2	0	\N	\N	\N	3	\N	0	\N
2884	1	antonio.ruiz@usmc.mil	Antonio		Ruiz	2	9104497368			CN=RUIZ.ANTONIO.RAMOS.JR.1362432266,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1362432266	RUIZ.ANTONIO.RAMOS.JR	5	54	3	2	0	\N	\N	\N	3	\N	0	1
2886	1	adam.ruse@usmc.mil	Adam		Ruse	5	9104495661			CN=RUSE.ADAM.CHRISTOPHER.1250422365,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1250422365	RUSE.ADAM.CHRISTOPHER	6	61	3	2	0	\N	\N	\N	3	\N	0	1
2888	1	michael.rusinchak@us.af.mil	Michael		Rusinchak	4	8508846492	5796492		CN=RUSINCHAK.MICHAEL.J.1038598208,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1038598208	RUSINCHAK.MICHAEL.J	7	2	3	11	0	\N	\N	\N	1	\N	0	2
2890	1	matthew.russell1@usmc.mil	Matthew		Russell	5	9104497073			CN=RUSSELL.MATTHEW.ROY.1258748294,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1258748294	RUSSELL.MATTHEW.ROY	16	52	3	2	0	\N	\N	\N	3	\N	0	1
2892	1	westley.sage@us.af.mil	Westley		Sage	1	5757847040	6817040		CN=SAGE.WESTLEY.G.1140992590,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1140992590	SAGE.WESTLEY.G	7	3	3	12	0	\N	\N	\N	1	\N	0	2
2894	1	jerome.salabye@usmc.mil	Jerome		Salabye	5	8585779409	8582789		CN=SALABYE.JEROME.1233500999,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1233500999	SALABYE.JEROME	6	60	3	4	0	\N	\N	\N	3	\N	0	\N
2896	1	paul.salay@whmo.mil	Paul		Salay	5	1571494473			CN=SALAY.PAUL.M.1029001010,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1029001010	SALAY.PAUL.M	7	17	3	80	0	\N	\N	\N	3	\N	0	1
2898	1	ulises.sanchezmartin@usmc.mil	Ulises		Sanchez-Martinez	5	3156362024			CN=SANCHEZMARTINEZ.ULISES.1385011233,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1385011233	SANCHEZMARTINEZ.ULISES	5	50	3	7	0	\N	\N	\N	3	\N	0	\N
2900	1	brian.sandoval@usmc.mil	Brian		Sandoval	5	8585779406			CN=SANDOVAL.BRIAN.S.1244394929,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1244394929	SANDOVAL.BRIAN.S	7	60	3	4	0	\N	\N	\N	3	\N	0	\N
2902	0	sherri.santos.1@us.af.mil	Sherri	L	Santos	\N				CN=SANTOS.SHERRI.LYNN.1284784096,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1	SANTOS.SHERRI.LYNN	\N	\N	\N	\N	1	\N	\N	\N	\N	\N	0	\N
2904	1	herman.sargent@us.af.mil	Herman		Sargent	5	3122384595	2384595		CN=SARGENT.HERMAN.R.1125881307,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1125881307	SARGENT.HERMAN.R	8	4	3	13	0	\N	\N	\N	1	\N	0	2
2906	1	andrew.schellenger@us.af.mil	Andrew		Schellenger	2	5757847040			CN=SCHELLENGER.ANDREW.DAVID.1293709706,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1293709706	SCHELLENGER.ANDREW.DAVID	6	3	3	12	0	\N	\N	\N	1	\N	0	2
2908	1	matthew.s.scherhaufe.ctr@navy.mil	Matthew		Scherhaufer	5	3019954632			CN=SCHERHAUFER.MATTHEW.SCOTT.1364481469,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1364481469	SCHERHAUFER.MATTHEW.SCOTT	20	39	2	9	0	\N	\N	\N	4	\N	0	1
2910	1	james.d.schmidt@usmc.mil	James		Schmidt	5	3156366229			CN=SCHMIDT.JAMES.DANIEL.1367062939,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1367062939	SCHMIDT.JAMES.DANIEL	6	50	3	18	0	\N	\N	\N	3	\N	0	1
2912	1	david.schnorenberg@navy.mil	David		Schnorenberg	3	9104495219			CN=SCHNORENBERG.DAVID.GERARD.1099651969,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1229745480	SCHNORENBERG.DAVID.GERARD	21	15	1	2	0	\N	\N	\N	3	\N	0	1
2914	1	paul.schroeder.2@us.af.mil	Paul		Schroeder	1	5058465409			CN=SCHROEDER.PAUL.CHRISTIAN.1244433860,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1244433860	SCHROEDER.PAUL.CHRISTIAN	6	6	3	5	0	\N	\N	\N	1	\N	0	2
2916	1	justin.r.schulz@usmc.mil	Justin		Schulz	5	9104497226			CN=SCHULZ.JUSTIN.RYAN.1380480138,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1380480138	schulzjr	5	25	3	2	0	\N	\N	\N	3	\N	0	1
2918	1	cory.schwendemann@usmc.mil	Cory		Schwendemann	5	7607253562			CN=SCHWENDEMANN.CORY.EDWARD.1404520489,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1404520489	SCHWENDEMANN.CORY.EDWARD	5	28	3	8	0	\N	\N	\N	3	\N	0	\N
2920	1	john.sciortino@navy.mil	John		Sciortino	3	2524645847			CN=SCIORTINO.JOHN.J.1256851187,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1256851187	SCIORTINO.JOHN.J	21	15	1	18	0	\N	\N	\N	3	\N	0	1
2922	1	kyle.b.scott@usmc.mil	Kyle		Scott	4	3156361189			CN=SCOTT.KYLE.BRADY.1362718976,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1362718976	SCOTT.KYLE.BRADY	5	27	3	7	0	\N	\N	\N	3	\N	0	1
2924	1	cameron.settle@us.af.mil	Cameron		Settle	1	5757847040	7847040		CN=SETTLE.CAMERON.CURTIS.1267965753,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1267965753	SETTLE.CAMERON.CURTIS	6	3	3	12	0	\N	\N	\N	1	\N	0	\N
2926	0	joshua.settles.4@us.af.mil	Joshua	M	Settles	\N				CN=SETTLES.JOSHUA.MICHAEL.1262984180,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1	SETTLES.JOSHUA.MICHAEL	\N	\N	\N	\N	1	\N	\N	\N	\N	\N	0	\N
2928	1	bridget.shideler@navy.mil	Bridget		Shideler	3	5714944760			CN=SHIDELER.BRIDGET.R.1136235962,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1136235962	SHIDELER.BRIDGET.R	21	15	1	80	0	\N	\N	\N	3	\N	0	\N
2930	1	donald.shiffer@us.af.mil	Donald		Shiffer	5	9408820939	2635089		CN=SHIFFER.DONALD.DALTON.1284944000,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1284944000	SHIFFER.DONALD.DALTON	5	6	3	5	0	\N	\N	\N	1	\N	0	2
2932	1	matthew.shiver@usmc.mil	Matthew		Shiver	5	3156362024			CN=SHIVER.MATTHEW.JAVIER.1279228525,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1279228525	SHIVER.MATTHEW.JAVIER	6	50	3	7	0	\N	\N	\N	3	\N	0	1
2934	1	paul.shutts@me.usmc.mil	Paul		Shutts	5	3183455277	3455277		CN=SHUTTS.PAUL.MATTHEW.1266865321,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1266865321	SHUTTS.PAUL.MATTHEW	6	47	3	4	0	\N	\N	\N	3	\N	0	\N
2936	0	bryant.silverio@usmc.mil	Bryant		Silverio	\N				CN=SILVERIO.BRYANT.1398343227,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1	SILVERIO.BRYANT	\N	\N	\N	\N	1	\N	\N	\N	\N	\N	0	\N
2938	1	jeffrey.simonton@usmc.mil	Jeffrey		Simonton	5	8585778090			CN=SIMONTON.JEFFREY.CHARLES.1260328260,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1260328260	SIMONTON.JEFFREY.CHARLES	15	48	3	6	0	\N	\N	\N	3	\N	0	\N
2940	1	chaka.d.smith@boeing.com	Chaka		Smith	5	9104495144			CN=SMITH.CHAKA.D A.1239277914,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1239277914	SMITH.CHAKA.D A	20	32	2	2	0	\N	\N	\N	3	\N	0	1
2942	1	ryan.smith1@usmc.mil	Ryan		Smith	5	8585778155			CN=SMITH.RYAN.C.1236371103,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1236371103	SMITH.RYAN.C	7	43	3	4	0	\N	\N	\N	3	\N	0	1
2944	1	trevor.m.smith2@usmc.mil	Trevor		Smith	5	8585776184			CN=SMITH.TREVOR.M.1234067059,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1234067059	SMITH.TREVOR.M	16	23	3	4	0	\N	\N	\N	3	\N	0	\N
2946	1	william.d.smith@usmc.mil	William		Smith	5	9104495643	7525643		CN=SMITH.WILLIAM.DANE.1129961879,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1129961879	SMITH.WILLIAM.DANE	6	44	3	2	0	\N	\N	\N	3	\N	0	1
2948	0	ryan.snipes@usmc.mil	Ryan	c	Snipes	\N				CN=SNIPES.RYAN.CULLAN.1281206938,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1	snipesrc	\N	\N	\N	\N	1	\N	\N	\N	\N	\N	0	\N
2432	1	jonathan.friscia@navy.mil	Jonathan		Friscia	4	3019954313			CN=FRISCIA.JONATHAN.R.1112747849,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1229745480	FRISCIA.JONATHAN.R	7	38	3	9	0	\N	\N	\N	1	\N	0	2
2434	1	evan.frock@us.af.mil	Evan		Frock	3	8508841313			CN=FROCK.EVAN.MICHAEL.1379386845,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1379386845	FROCK.EVAN.MICHAEL	5	2	3	11	0	\N	\N	\N	1	\N	0	2
2436	1	vincent.frosig@us.af.mil	Vincent		Frosig	5	5759046037	6406037		CN=FROSIG.VINCENT.EUGENE.1260822361,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1260822361	FROSIG.VINCENT.EUGENE	6	3	3	12	0	\N	\N	\N	1	\N	0	\N
2438	1	robert.gallipeau.ctr@navy.mil	Robert		Gallipeau	5	3019954633			CN=GALLIPEAU.ROBERT.FRANCIS.III.1025068528,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1141323233	GALLIPEAU.ROBERT.FRANCIS.III	20	19	2	9	0	\N	\N	\N	3	\N	0	1
2440	1	timothy.d.gamble.ctr@usmc.mil	Timothy		Gamble	5	8048788468	6367658		CN=GAMBLE.TIMOTHY.D.1075539688,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1133281564	GAMBLE.TIMOTHY.D	21	27	2	7	0	\N	\N	\N	3	\N	0	1
2442	1	john.gann@navy.mil	John		Gann	3	2524645729			CN=GANN.JOHN.C.1395131296,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1395131296	GANN.JOHN.C	21	15	1	18	0	\N	\N	\N	4	\N	0	1
2444	1	carlos.r.garcia@usmc.mil	Carlos		Garcia	5	3156362583	6362583		CN=GARCIA.CARLOS.R.1243291280,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1243291280	GARCIA.CARLOS.R	7	27	3	7	0	\N	\N	\N	3	\N	0	\N
2446	0	ericjay.garcia@afg.usmc.mil	Ericjay	K	Garcia	\N				CN=GARCIA.ERICJAY.KONA.1150722116, OU=USMC, OU=PKI, OU=DoD, O=U.S. Government, C=US	1	garcia,e,k	\N	\N	\N	\N	1	\N	\N	\N	\N	\N	0	\N
2448	1	marcos.garcia@usmc.mil	Marcos		Garcia	5	8064921809	6361171		CN=GARCIA.MARCOS.ANTONIO.1288493266,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1288493266	GARCIA.MARCOS.ANTONIO	6	27	3	7	0	\N	\N	\N	3	\N	0	\N
2450	0	michale.gardner@us.af.mil	Michale	T	Gardner	\N				CN=GARDNER.MICHALE.TIMOTHY.1271462170, OU=USAF, OU=PKI, OU=DoD, O=U.S. Government, C=US	1	gardnermt	\N	\N	\N	\N	1	\N	\N	\N	\N	\N	0	\N
2452	1	samuel.garrison@usmc.mil	Samuel		Garrison	5	8585779406			CN=GARRISON.SAMUEL.PAUL.1379018870,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1379018870	GARRISON.SAMUEL.PAUL	5	60	3	4	0	\N	\N	\N	3	\N	0	\N
2454	1	eric.giannettino@usmc.mil	Eric		Giannettino	5	8585779127	2679127		CN=GIANNETTINO.ERIC.J.1027326818,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1027326818	GIANNETTINO.ERIC.J	11	45	3	4	0	\N	\N	\N	3	\N	0	1
2456	1	jeremy.gilbertson@wasp.usmc.mil	Jeremy		Gilbertson	5	9104497087			CN=GILBERTSON.JEREMY.ALLEN.1276637785,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1276637785	GILBERTSON.JEREMY.ALLEN	6	52	3	2	0	\N	\N	\N	3	\N	0	\N
2458	1	neal.j.gilbreth@boeing.com	Neal		Gilbreth	5	6199950784			CN=GILBRETH.NEAL.JOHN.1115841455,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1133281564	GILBRETH.NEAL.JOHN	20	31	2	4	0	\N	\N	\N	3	\N	0	1
2460	1	kglavin@bh.com	Kenneth		Glavin	5	5759045250	6405250		CN=GLAVIN.KENNETH.WAYNE.1166920953,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1166920953	GLAVIN.KENNETH.WAYNE	20	13	2	12	0	\N	\N	\N	1	\N	0	2
2462	1	luis.f.godoy@usmc.mil	Luis		Godoy	5	9105464283	3156362		CN=GODOY.LUIS.FELIPE.1256873040,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1256873040	godoylf1	7	27	3	7	0	\N	\N	\N	3	\N	0	1
2464	1	stephen.c.golden@navy.mil	Stephen		Golden	3	2524646256			CN=GOLDEN.STEPHEN.C.1454782522,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1051055540	GOLDEN.STEPHEN.C	20	15	1	18	0	\N	\N	\N	4	\N	0	1
2466	1	simon.gommesen@usmc.mil	Simon		Gommesen	5	9104497247			CN=GOMMESEN.SIMON.ENOCH.1412277798,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1412277798	GOMMESEN.SIMON.ENOCH	5	25	3	2	0	\N	\N	\N	3	\N	0	1
2468	0	kristopher.gonzalez@usmc.mil	Kristopher	A	Gonzalez	\N				CN=GONZALEZ.KRISTOPHER.ALLEN.1018540084, OU=USMC, OU=PKI, OU=DoD, O=U.S. Government, C=US	1	gonzalez,k,a	\N	\N	\N	\N	1	\N	\N	\N	\N	\N	0	\N
2470	1	randy.gonzalez@usmc.mil	Randy		Gonzalez	5	9104497252			CN=GONZALEZ.RANDY.1408065239,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1408065239	gonzalezr	5	25	3	2	0	\N	\N	\N	3	\N	0	1
2472	1	luis.a.gracia@navy.mil	Luis		Gracia	3	9104495215			CN=GRACIA.LUIS.ANGEL.1133447772,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1229745480	GRACIA.LUIS.ANGEL	21	15	1	2	0	\N	\N	\N	3	\N	0	1
2474	1	james.p.graham@navy.mil	James		Graham	5	9104495425			CN=GRAHAM.JAMES.P.1229441341,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1229441341	GRAHAM.JAMES.P	21	10	1	2	0	\N	\N	\N	3	\N	0	1
2476	1	kevin.graninger@usmc.mil	Kevin		Graninger	5	7607630972	3610972		CN=GRANINGER.KEVIN.MICHAEL.1268415196,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1268415196	GRANINGER.KEVIN.MICHAEL	11	46	3	8	0	\N	\N	\N	3	\N	0	\N
2478	1	cody.n.grant@usmc.mil	Cody		Grant	5	9104497367			CN=GRANT.CODY.NICHOLAS.1388577742,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1388577742	GRANT.CODY.NICHOLAS	5	54	3	2	0	\N	\N	\N	3	\N	0	1
2480	1	aaron.gray.3@us.af.mil	Aaronq		Gray	3	1231231234			CN=GRAY.AARON.MICHAEL.1288225946,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1141323233	GRAY.AARON.MICHAEL	18	17	1	77	0	\N	\N	\N	2	\N	0	\N
2482	1	john.h.grogan.ctr@navy.mil	John		Grogan	3	2524645750			CN=GROGAN.JOHN.HENRY.III.1116589300,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1116589300	GROGAN.JOHN.HENRY.III	20	15	2	18	0	\N	\N	\N	4	\N	0	\N
2484	1	charles.grove.2@us.af.mil	Charles		Grove	5	8508841309			CN=GROVE.CHARLES.DILLON.1292504892,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1292504892	GROVE.CHARLES.DILLON	6	2	3	11	0	\N	\N	\N	1	\N	0	2
1769	1	william.brickhouse@navy.mil	William		Brickhouse	5	2524645572	456547821		CN=BRICKHOUSE.WILLIAM.D.1461688841,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1065484494		21	15	1	18	0	\N	\N	\N	4	\N	0	\N
2486	1	barrie.m.grubbs@boeing.com	Barrie		Grubbs	5	9104495849	8526547896		CN=GRUBBS.BARRIE.M.1201153405,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1065484494	GRUBBS.BARRIE.M	20	32	2	2	0	\N	\N	\N	3	\N	0	\N
2488	1	enrique.guadalajara1.ctr@navy.mil	Enrique		Guadalajara	5	3019954631			CN=GUADALAJARA.ENRIQUE.NMN.1180700664,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1180700664	GUADALAJARA.ENRIQUE.NMN	20	39	2	9	0	\N	\N	\N	4	\N	0	\N
2490	1	wesley.guarino@usmc.mil	Wesley		Guarino	5	9104494541	7524541		CN=GUARINO.WESLEY.M.1186599949,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1186599949	GUARINO.WESLEY.M	12	25	3	2	0	\N	\N	\N	3	\N	0	\N
3121	0	richard.harrington2@navy.mil	Richard		Harrington	4	3013429846			CN=HARRINGTON.RICHARD.A.1080286097,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1229745480		20	38	1	9	0	\N	\N	\N	4	\N	0	1
3122	1	patrick.k.wyman@navy.mil	Patrick		Wyman	4	3017571986			CN=WYMAN.PATRICK.K.1033480705,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1033480705		20	38	1	9	0	\N	\N	\N	4	\N	0	1
3126	1	bryan.p.hill@navy.mil	Bryan		Hill	3	2524646267			CN=HILL.BRYAN.P.1108530800,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1108530800		21	10	1	18	0	\N	\N	\N	4	\N	0	1
3128	1	linda.macneil@navy.mil	Linda		Macneil	4	3017570150			CN=MACNEIL.LINDA.M.1027727936,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1027727936		21	38	1	9	0	\N	\N	\N	1	\N	1	2
3129	1	james.withers@navy.mil	James		Withers	1	2524648711	4518711		CN=WITHERS.JAMES.N.1229818054,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1229818054		21	15	1	18	0	\N	\N	\N	4	\N	0	\N
3140	1	james.w.paishon.ctr@navy.mil	James		Paishon	5	3019957694			CN=PAISHON.JAMES.WESLEY.1283619130,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1283619130		20	19	2	9	0	\N	\N	\N	4	\N	0	\N
3147	1	matthew.norton.2@us.af.mil	Matthew		Norton	1	5058535457			CN=NORTON.MATTHEW.JAMES.1374239810,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1374239810		6	6	3	5	0	\N	\N	\N	1	\N	1	2
3156	1	christopher.stamps@usmc.mil	Christopher		Stamps	5	7607630576			CN=STAMPS.CHRISTOPHER.ALLAN.1279222420,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1279222420		6	46	3	8	0	\N	\N	\N	3	\N	1	1
3159	1	robert.laliberte@usmc.mil	Robert		Laliberte	5	7607630576			CN=LALIBERTE.ROBERT.EARLE.1006756162,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1006756162		5	46	3	8	0	\N	\N	\N	3	\N	0	1
3164	1	david.jones.78@us.af.mil	David		Jones	5	5757847040	6817040		CN=JONES.DAVID.W.JR.1244632978,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1244632978		6	3	3	12	0	\N	\N	\N	1	\N	1	2
3166	1	amonte.latimer@usmc.mil	Amonte		Latimer	5	7607631468			CN=LATIMER.AMONTE.EDWARDKERRY.1291032610,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1291032610		5	57	3	8	0	\N	\N	\N	3	\N	0	1
3167	0	jonathan.joya@usmc.mil	Jonathan		Joya	5	7607253262			CN=JOYA.JONATHAN.ELIAS.1505871380,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1505871380		3	28	3	8	0	\N	\N	\N	3	\N	0	1
3170	1	cristobal.ceron@navy.mil	Cristobal		Ceron	4	3017575951			CN=CERON.CRISTOBAL.N.1513025412,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1513025412		21	38	1	9	0	\N	\N	\N	4	\N	1	1
3172	1	robert.puett@navy.mil	Robert		Puett	3	2524649430			CN=PUETT.ROBERT.E.II.1299008343,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1299008343		20	10	1	17	0	\N	\N	\N	4	\N	0	1
3177	1	aaron.watson@navy.mil	Aaron		Watsons	1	1234567890	1233654722		abc	1065484494		4	3	2	17	0	\N	\N	\N	2	\N	0	\N
3181	1	jeffrey.fender@usmc.mil	Jeffrey		Fender	5	8585779406			CN=FENDER.JEFFREY.SCOTT.1281421774,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1281421774		5	60	3	4	0	\N	\N	\N	3	\N	1	1
3183	1	jamie.r.jenkins@usmc.mil	Jamie		Jenkins	5	7607630529			CN=JENKINS.JAMIE.R.1055598556,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1055598556		7	46	3	8	0	\N	\N	\N	3	\N	0	\N
3184	1	samuel.n.stiles@boeing.com	Samuel		Stiles	3	6107425194			CN=Samuel Stiles,OU=The Boeing Company,OU=VeriSign\\, Inc.,OU=ECA,O=U.S. Government,C=US	-1		20	9	2	17	0	\N	\N	\N	3	\N	0	\N
3187	1	christopher.s.mccart@usmc.mil	Christopher		Mccarthy	5	8585779406			CN=MCCARTHY.CHRISTOPHER.SEAN.1376674670,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1376674670		5	60	3	4	0	\N	\N	\N	3	\N	0	1
3188	1	blake.shulsky@us.af.mil	Blake		Shulsky	1	8508847314	5797314		CN=SHULSKY.BLAKE.CAMERON.1266027598,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1266027598		6	2	3	11	0	\N	\N	\N	1	\N	0	\N
3200	1	jason.a.woodard@usmc.mil	Jason		Woodard	2	7024452533	5771318		CN=WOODARD.JASON.ANTHONY.1455243277,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1455243277		4	23	3	4	0	\N	\N	\N	3	\N	1	1
3208	1	demark.l.stewart1@navy.mil	Demark		Stewart	4	2524648719			CN=STEWART.DEMARK.L.1057676490,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1057676490		21	10	1	18	0	\N	\N	\N	4	\N	1	1
3211	1	jhoppe@bh.com	Justin		Hoppe	5	8177576690			CN=HOPPE.JUSTIN.PRESLEYWILLIAM.1279718875,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1279718875		20	13	2	12	0	\N	\N	\N	1	\N	0	2
3218	1	michael.howeth@navy.mil	Michael		Howeth	4	3017573165	7573165		CN=HOWETH.MICHAEL.D.SR.1042443715,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1042443715		21	38	1	9	0	\N	\N	\N	4	\N	0	\N
3223	1	hunter.johnson2@usmc.mil	Hunter		Johnson	5	3156363586			CN=JOHNSON.HUNTER.BURTON.1464534594,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1464534594		3	27	3	7	0	\N	\N	\N	3	\N	1	1
3232	1	matthew.ohler@wasp.usmc.mil	Matthew		Ohler	3	9104497087			CN=OHLER.MATTHEW.SCOTT.1381714892,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1381714892		5	52	3	2	0	\N	\N	\N	3	\N	0	1
3233	1	pernell.hepbourn@usmc.mil	Pernell		Hepbourn	4	9104497087	7527087		CN=HEPBOURN.PERNELL.ANSON.JR.1257569965,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1257569965		6	52	3	2	0	\N	\N	\N	3	\N	0	\N
3234	1	wesley.pevahouse@usmc.mil	Wesley		Pevahouse	5	8585778155			CN=PEVAHOUSE.WESLEY.MILES.1381367319,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1381367319		5	43	3	4	0	\N	\N	\N	3	\N	0	\N
3237	1	ismael.andradedelgado@usmc.mil	Ismael		Andradedelgado	4	7607253262			CN=ANDRADEDELGADO.ISMAEL.1468634690,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1468634690		4	28	3	8	0	\N	\N	\N	3	\N	1	1
3239	1	brandon.l.washington@usmc.mil	Brandon		Washington	3	8585779487			CN=WASHINGTON.BRANDON.LEE.1420540864,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1420540864		5	43	3	4	0	\N	\N	\N	3	\N	1	1
3240	1	matthew.v.le@usmc.mil	Mathew		Le	4	8585771318			CN=LE.MATHEW.VU.1464538115,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1464538115		3	23	3	4	0	\N	\N	\N	3	\N	1	1
3242	1	jonathan.wiley@navy.mil	Jonathan		Wiley	3	2524646637			CN=WILEY.JONATHAN.A.1513102247,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1513102247		21	10	1	18	0	\N	\N	\N	4	\N	0	\N
3245	1	jacob.b.lewis@usmc.mil	Jacob		Lewis	5	7607636391	3616391		CN=LEWIS.JACOB.BARTHOLOMEW.1118680290,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1118680290		13	28	3	8	0	\N	\N	\N	3	\N	1	1
3246	1	sheryl.l.hutchison@navy.mil	Sheryl		Hutchison	5	3019954282			CN=HUTCHISON.SHERYL.L.1162249238,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1162249238		20	38	1	9	0	\N	\N	\N	1	\N	1	2
3247	1	thomas.howard@sofsa.mil	Thomas		Howard	5	8595665104			CN=HOWARD.THOMAS.H.1062806482,OU=USA,OU=PKI,OU=DoD,O=U.S. Government,C=US	1062806482		10	42	1	11	0	\N	\N	\N	1	\N	1	2
3248	1	jason.fleming.5@us.af.mil	Jason		Fleming	1	3142387341			CN=FLEMING.JASON.ERIC.1273632480,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1273632480		6	4	3	13	0	\N	\N	\N	1	\N	1	2
3124	1	jared.byrd1@navy.mil	Jared		Byrd	4	3013428068			CN=BYRD.JARED.M.1113222170,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1229745480		21	38	1	9	0	\N	\N	\N	4	\N	0	1
3125	1	steven.j.kretschmer2@boeing.com	Steven		Kretschmer	5	5759045234	6405234		CN=KRETSCHMER.STEVEN.J.1099978739,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1099978739		20	13	2	12	0	\N	\N	\N	1	\N	0	2
3130	1	john.wasko.2@us.af.mil	John		Wasko	3	8508814304	6414304		CN=WASKO.JOHN.F.1266901352,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1266901352		20	15	1	11	0	\N	\N	\N	4	\N	0	2
3137	1	craig.kornely.2@us.af.mil	Craig		Kornely	4	8508812684	6412684		CN=KORNELY.CRAIG.R.1100976257,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1100976257		21	138	1	11	0	\N	\N	\N	1	\N	0	2
3141	1	joaquin.hernandez.2@us.af.mil	Joaquin		Hernandez	5	8508813669	6413669		CN=HERNANDEZ.JOAQUIN.1233757434,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1060319371		20	33	2	11	0	\N	\N	\N	1	\N	1	2
3142	1	joshua.duncan.1@us.af.mil	Joshua		Duncan	5	5757847040	6817040		CN=DUNCAN.JOSHUA.D.1144730824,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1144730824		7	3	3	12	0	\N	\N	\N	1	\N	1	2
3143	1	alvaro.velador@usmc.mil	Alvaro		Velador	5	7607253389			CN=VELADOR.ALVARO.1461573181,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1461573181		4	28	3	8	0	\N	\N	\N	3	\N	1	1
3144	1	manuel.santiago@usmc.mil	Manuel		Santiago	3	8585776832			CN=SANTIAGO.MANUEL.S.1380711075,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1380711075		20	15	1	4	0	\N	\N	\N	3	\N	0	\N
3148	1	alex.j.ramirez@usmc.mil	Alex		Ramirez	5	8585771318			CN=RAMIREZ.ALEX.JAMES.1455992989,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1455992989		5	23	3	4	0	\N	\N	\N	3	\N	1	1
3158	1	gregory.clayson@navy.mil	Gregory		Clayson	3	2524646123			CN=CLAYSON.GREGORY.ALLEN.1017366757,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1017366757		21	15	1	18	0	\N	\N	\N	3	\N	0	1
3173	1	garth.cook@usmc.mil	Garth		Cook	4	9104497252			CN=COOK.GARTH.JANES.1461779936,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1461779936		3	25	3	2	0	\N	\N	\N	3	\N	1	1
3175	1	robert.denecke@whmo.mil	Robert		Denecke	1	5714944803			CN=DENECKE.ROBERT.W.1277365304,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1277365304		20	17	2	80	0	\N	\N	\N	3	\N	1	1
3178	1	richard.collmann@whmo.mil	Richard		Collmann	5	5714944848			CN=COLLMANN.RICHARD.L.1201264886,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1201264886		20	17	2	80	0	\N	\N	\N	3	\N	0	1
3180	1	rlbrewer@bh.com	Randy		Brewer	5	9104497690			CN=BREWER.RANDY.L.1056030189,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1056030189		20	32	2	2	0	\N	\N	\N	3	\N	0	\N
3185	1	theodore.c.jones@boeing.com	Theodore		Jones	3	6105912709			CN=Theodore.C.Jones.212937,OU=people,O=boeing,C=us	1287802451		20	9	2	6	0	\N	\N	\N	3	\N	0	\N
3195	1	luis.a.mendoza1@usmc.mil	Luis		Mendoza	5	8082571424			CN=MENDOZA.LUIS.ANTHONY.1396422626,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1396422626		5	24	3	81	0	\N	\N	\N	3	\N	0	1
3199	1	john.h.rodrigues@navy.mil	John		Rodrigues	4	6195453097			CN=RODRIGUES.JOHN.H.1231746362,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1231746362		21	14	1	6	0	\N	\N	\N	4	\N	1	1
3210	1	brian.mays@usmc.mil	Brian		Mays	5	9104495661			CN=MAYS.BRIAN.DEE.1285995775,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1285995775		6	49	3	2	0	\N	\N	\N	3	\N	0	\N
3227	1	thoffer@bh.com	Thomas		Hoffer	4	8173726048			CN=Thomas Hoffer,OU=Bell Helicopter\\, Textron\\, INC,OU=VeriSign\\, Inc.,OU=ECA,O=U.S. Government,C=US	-1		20	9	2	17	0	\N	\N	\N	3	\N	1	1
3228	1	tamiller@bh.com	Todd		Miller	4	8175906047		8172806048	CN=Todd Allen Miller,OU=Bell Helicopter\\, Textron Inc.,OU=VeriSign\\, Inc.,OU=ECA,O=U.S. Government,C=US	1060319371		20	9	2	2	0	\N	\N	\N	3	\N	0	1
25	\N	claire.metcalfe@all.com	Claire	N	Metcalfe	\N	1115551212	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2019-05-10 13:40:38.362506	\N	\N	\N	\N	1	\N
3231	1	evan.hansen@usmc.mil	Evan		Hansen	5	8585774289			CN=HANSEN.EVAN.ALLEN.1501091940,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1501091940		3	23	3	6	0	\N	\N	\N	3	\N	1	1
3241	0	morgan.walker@boxer.usmc.mil	Morgan		Walker	5	8585778091	2678091		CN=WALKER.MORGAN.JONATHAN.1187212843,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1187212843		17	48	3	4	0	\N	\N	\N	3	\N	0	1
3249	1	mike.goncalves@usmc.mil	Mike		Goncalves	5	7607253262			CN=GONCALVES.MIKE.1460497953,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1460497953		4	28	3	8	0	\N	\N	\N	3	\N	1	1
3250	1	william.e.grantham@navy.mil	William		Grantham	2	2524647401	4517401	2524647337	CN=GRANTHAM.WILLIAM.ERWIN.1161530200,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1161530200		21	15	1	17	0	\N	\N	\N	4	\N	0	1
3251	1	vincent.taitingfong@navy.mil	Vincent		Taitingfong	4	2524648701	1231231236		CN=TAITINGFONG.VINCENT.C.1185485095,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1065484494		20	10	1	18	0	\N	\N	\N	4	\N	0	\N
3252	1	victor.cruz@usmc.mil	Victor		Cruz	5	3156367656			CN=CRUZ.VICTOR.THOMAS.1276005703,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1276005703		6	53	3	7	0	\N	\N	\N	3	\N	0	1
3253	1	joseph.gaccione@us.af.mil	Joseph		Gaccione	5	9105518686	7847040		CN=GACCIONE.JOSEPH.SAVERIO.1260552585,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1260552585		6	3	3	12	0	\N	\N	\N	1	\N	1	2
3254	1	brett.mckee@rolls-royce.com	Brett		Mckee	3	8585318608	2679537		CN=MCKEE.JONATHAN.BRETT.1266933254,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1266933254		20	34	2	4	0	\N	\N	\N	3	\N	0	\N
3255	0	samuel.w.tsu@boeing.com	Samuel		Tsu	3	6105917712			CN=Samuel Tsu,OU=The Boeing Company,OU=VeriSign\\, Inc.,OU=ECA,O=U.S. Government,C=US	-1		21	9	1	9	0	\N	\N	\N	3	\N	0	1
3256	1	brandon.newby@whmo.mil	Brandon		Newby	5	5714944730			CN=NEWBY.BRANDON.LAMONT.1250846610,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1250846610		7	17	3	80	0	\N	\N	\N	3	\N	0	1
3257	1	cory.w.demuth@rolls-royce.com	Cory		Demuth	5	8582648778	2679537		CN=DEMUTH.CORY.WAYNE.1241409461,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1241409461		20	34	2	4	0	\N	\N	\N	3	\N	0	\N
3258	1	brent.culp@usmc.mil	Brent		Culp	5	9104494326			CN=CULP.BRENT.D.1146969166,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1146969166		8	61	3	2	0	\N	\N	\N	3	\N	0	1
3259	1	jimmy.a.reimert@boeing.com	Jimmy		Reimert	5	6105912452			CN=Jimmy Reimert,OU=Boeing,OU=VeriSign\\, Inc.,OU=ECA,O=U.S. Government,C=US	1141323233		20	9	2	18	0	\N	\N	\N	3	\N	0	1
3260	0	daniel.vanhoven@usmc.mil	Daniel		Vanhoven	4	9104496267			CN=VANHOVEN.DANIEL.ROBERT.1409030137,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1409030137		4	25	3	2	0	\N	\N	\N	3	\N	0	1
3131	1	brittany.king@navy.mil	Brittany		King	4	3013421145			CN=KING.BRITTANY.RAYMOND.1395097560,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1395097560		21	38	1	9	0	\N	\N	\N	1	\N	1	1
3132	1	bryan.bunch@navy.mil	Bryan		Bunch	3	2527208014			CN=BUNCH.BRYAN.H.1368434830,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1368434830		21	15	1	18	0	\N	\N	\N	3	\N	0	\N
3133	0	matthew.e.stevenson@navy.mil	Matthew		Stevenson	4	3017571922	7571922		CN=STEVENSON.MATTHEW.E.1167948916,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1167948916		21	38	1	9	0	\N	\N	\N	4	\N	0	1
3134	1	troy.romenesko@us.af.mil	Troy		Romenesko	5	5058535089	8535089		CN=ROMENESKO.TROY.ROBERT.1285291204,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1285291204		5	6	3	5	0	\N	\N	\N	1	\N	0	2
3138	1	jason.l.badell@boeing.com	Jason		Badell	5	8582301973			CN=BADELL.JASON.L.1015925643,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1015925643		20	9	2	4	0	\N	\N	\N	3	\N	1	\N
3139	1	rufus.brenneman@us.af.mil	Rufus		Brenneman	5	3142383191			CN=BRENNEMAN.RUFUS.STRONG.II.1400458533,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1400458533		5	4	3	13	0	\N	\N	\N	1	\N	1	2
3146	1	andrew.patterson@usmc.mil	Andrew		Patterson	5	2526261618			CN=PATTERSON.ANDREW.THOMAS.1275422505,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1275422505		6	55	3	4	0	\N	\N	\N	3	\N	1	1
3151	1	stephen.trochesset@us.af.mil	Stephen		Trochesset	5	5757847040	6817040		CN=TROCHESSET.STEPHEN.A.JR.1114790113,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1114790113		8	3	3	12	0	\N	\N	\N	1	\N	1	2
3152	1	neason@bh.com	Nicholas		Eason	5	8176593111			CN=EASON.NICHOLAS.ANDREW.1299543230,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1060319371		20	31	2	4	0	\N	\N	\N	3	\N	0	1
3153	1	adam.shores@usmc.mil	Adam		Shores	2	8585771318			CN=SHORES.ADAM.JOSEPH.1454767574,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1454767574		4	23	3	4	0	\N	\N	\N	3	\N	1	1
3154	1	anthony.c.collins2@navy.mil	Anthony		Collins	4	3017575582			CN=COLLINS.ANTHONY.C.1240040200,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1240040200		6	38	3	9	0	\N	\N	\N	3	\N	1	1
3161	1	stalling.duenas@us.af.mil	Stalling		Duenas	5	3142384613			CN=DUENAS.STALLING.NMN.1365261420,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1365261420		5	4	3	13	0	\N	\N	\N	1	\N	1	2
3162	1	christopher.denver@usmc.mil	Christophe		Denver	5	3156363740	3156363		CN=DENVER.CHRISTOPHE.A.1270185904,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1270185904		17	53	3	7	0	\N	\N	\N	3	\N	0	1
3168	1	wonfung.lee@usmc.mil	Won Fung		Lee	3	8585779535			CN=LEE.WON.FUNG.1234320587,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1234320587		21	15	1	4	0	\N	\N	\N	4	\N	0	\N
3174	1	peter.dimartino@me.usmc.mil	Peter		Dimartino	1	8585778035	2678035		CN=DIMARTINO.PETER.J.III.1159556359,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1159556359		7	47	3	4	0	\N	\N	\N	3	\N	0	\N
3182	1	fletcher.james.ctr@navy.mil	Fletcher		James	3	9104494075			CN=JAMES.FLETCHER.LEE.1149843210,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1141323233		20	15	2	2	0	\N	\N	\N	3	\N	0	1
3189	1	jared.drew@usmc.mil	Jared		Drew	5	9104496059			CN=DREW.JARED.LEE.1243938925,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1243938925		6	49	3	2	0	\N	\N	\N	3	\N	0	1
3191	1	max.neighbors@usmc.mil	Max		Neighbors	4	9104495643			CN=NEIGHBORS.MAX.GREGORY.1286202396,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1286202396		6	44	3	2	0	\N	\N	\N	3	\N	0	1
3193	1	jared.barrow@usmc.mil	Jared		Barrow	3	8585774298			CN=BARROW.JARED.JOSEPH.1461992451,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1461992451		4	23	3	4	0	\N	\N	\N	3	\N	1	1
3196	1	edward.m.bolish@boeing.com	Edward		Bolish	3	6105914613	4566544566		CN=Edward.M.Bolish.14213,OU=people,O=boeing,C=us	1065484494		21	9	1	17	0	\N	\N	\N	3	\N	0	\N
3197	1	xerdan.canlas@lha6.navy.mil	Xerdan		Canlas	5	6195563897			CN=CANLAS.XERDAN.L.1265181585,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1265181585		5	158	3	6	0	\N	\N	\N	4	\N	1	1
26	\N	harry.berry@all.com	Harry	\N	Berry	\N	1115551212	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2019-05-10 13:41:00.863923	\N	\N	\N	\N	1	\N
3198	1	brandi.parker@us.af.mil	Brandi		Parker	5	8508841309			CN=PARKER.BRANDI.LEIGH.1178994138,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1178994138		6	2	3	11	0	\N	\N	\N	1	\N	0	2
3201	0	shival.ramroop@usmc.mil	Shival		Ramroop	5	8585778143			CN=RAMROOP.SHIVAL.NICHOLAS.1255481408,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1255481408		6	43	3	4	0	\N	\N	\N	3	\N	0	1
3202	1	gabriel.s.marrow@boeing.com	Gabriel		Marrow	3	2523674895	5714944		CN=MARROW.GABRIEL.S.III.1056554935,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1056554935		20	17	2	80	0	\N	\N	\N	3	\N	0	\N
3204	1	scot.kinnersley@usmc.mil	Scot		Kinnersley	3	8585779107			CN=KINNERSLEY.SCOT.THOMAS.1236940060,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1236940060		6	45	3	4	0	\N	\N	\N	3	\N	0	1
3205	1	daniel.s.nickle@boeing.com	Daniel		Nickle	3	2524645696	4515696		CN=NICKLE.DANIEL.S.1145264797,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1145264797		20	15	2	18	0	\N	\N	\N	4	\N	1	1
3206	1	maryjane.shofkom@navy.mil	Mary Jane		Shofkom	4	2524648744			CN=SHOFKOM.MARY JANE.1514583192,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1514583192		20	15	1	18	0	\N	\N	\N	4	\N	0	1
3207	1	brandon.s.dixon@navy.mil	Brandon		Dixon	4	2524649909	4549909		CN=DIXON.BRANDON.S.1270669324,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1270669324		21	15	1	18	0	\N	\N	\N	4	\N	1	1
3212	1	jeffrey.frost@usmc.mil	Jeffery		Frost	5	9104497228			CN=FROST.JEFFERY.BRIAN.1456145333,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1456145333		3	25	3	2	0	\N	\N	\N	3	\N	0	1
3213	1	benjamin.a.pugh@navy.mil	Benjamin		Pugh	3	9104495657			CN=PUGH.BENJAMIN.A.1516766359,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1516766359		21	10	1	17	0	\N	\N	\N	4	\N	0	\N
3214	1	dillon.waite@navy.mil	Dillon		Waite	3	2524646248	8522587893		CN=WAITE.DILLON.M.1521216499,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1065484494		21	10	1	18	0	\N	\N	\N	4	\N	0	\N
3215	1	patrick.nager@navy.mil	Patrick		Nager	3	2527208016			CN=NAGER.PATRICK.MICHAEL.1511421035,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1511421035		21	10	1	18	0	\N	\N	\N	4	\N	0	\N
2492	1	edwin.gunderson@us.af.mil	Edwin		Gunderson	5	3142384596	2384596		CN=GUNDERSON.EDWIN.JAMES.1276476897,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1276476897	GUNDERSON.EDWIN.JAMES	6	4	3	13	0	\N	\N	\N	1	\N	0	\N
2494	1	sarah.gurganus@navy.mil	Sarah		Gurganus	3	2524646667			CN=GURGANUS.SARAH.C.1501755431,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1141323233	GURGANUS.SARAH.C	20	10	1	18	0	\N	\N	\N	4	\N	0	1
2496	0	william.gurkin@navy.mil	William	H	Gurkin	\N				CN=GURKIN.WILLIAM.NMN.1501190817,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1	GURKIN.WILLIAM.NMN	\N	\N	\N	\N	1	\N	\N	\N	\N	\N	0	\N
2498	1	clifford.guthrie@navy.mil	Clifford		Guthrie	3	2524646631			CN=GUTHRIE.CLIFFORD.M.1257351382,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1229745480	GUTHRIE.CLIFFORD.M	21	10	1	18	0	\N	\N	\N	4	\N	0	1
2500	1	johnathan.hallford@us.af.mil	Johnathan		Hallford	5	8508841313	5791313		CN=HALLFORD.JOHNATHAN.TYLER.1297925977,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1297925977	HALLFORD.JOHNATHAN.TYLER	5	2	3	11	0	\N	\N	\N	1	\N	0	2
2502	1	david.halvorson.5.ctr@us.af.mil	David		Halvorson	5	8508812529			CN=HALVORSON.DAVID.L.1137297619,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1137297619	HALVORSON.DAVID.L	21	2	2	11	0	\N	\N	\N	1	\N	0	2
2504	1	carey.hamil@usmc.mil	Carey		Hamil	5	9104497090			CN=HAMIL.CAREY.ALLEN.1064525820,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1064525820	HAMIL.CAREY.ALLEN	7	52	3	2	0	\N	\N	\N	3	\N	0	\N
2506	1	mhamilton@bh.com	Michael		Hamilton	5	9104497690			CN=HAMILTON.MICHAEL.A.1126207499,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1141323233	HAMILTON.MICHAEL.A	20	32	2	2	0	\N	\N	\N	3	\N	0	1
2508	1	john.hamrick.3.ctr@us.af.mil	John		Hamrick	1	8502408496	6413669		CN=HAMRICK.JOHN.E.1156409339,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1156409339	HAMRICK.JOHN.E	20	33	2	11	0	\N	\N	\N	1	\N	0	\N
2510	1	kevin.hancock.1@us.af.mil	Kevin		Hancock	3	5058535089			CN=HANCOCK.KEVIN.GENE.1272815182,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1272815182	HANCOCK.KEVIN.GENE	5	6	3	5	0	\N	\N	\N	1	\N	0	2
2512	1	thomas.haney@navy.mil	Thomas		Haney	1	2527206932			CN=HANEY.THOMAS.A.1180877602,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1180877602	HANEY.THOMAS.A	21	15	1	17	0	\N	\N	\N	4	\N	0	1
2514	1	david.m.hanson1@usmc.mil	David		Hanson	4	9104497252			CN=HANSON.DAVID.MARK.1411137828,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1411137828	HANSON.DAVID.MARK	4	25	3	2	0	\N	\N	\N	3	\N	0	1
2516	1	lynell.hargrove@usmc.mil	Lynell		Hargrove	5	8585779400			CN=HARGROVE.LYNELL.KEVIN.1282223437,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1282223437	HARGROVE.LYNELL.KEVIN	5	60	3	4	0	\N	\N	\N	3	\N	0	\N
2518	0	michael.d.harmon@navy.mil	Michael	D	Harmon	\N				CN=HARMON.MICHAEL.DAVID.1010869087,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1	HARMON.MICHAEL.DAVID	\N	\N	\N	\N	1	\N	\N	\N	\N	\N	0	\N
2520	1	alonzo.harrelson@usmc.mil	Alonzo		Harrelson	5	7607250779			CN=HARRELSON.ALONZO.EUGENE.1037188715,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1037188715	HARRELSON.ALONZO.EUGENE	5	28	3	8	0	\N	\N	\N	3	\N	0	1
2522	1	eric.w.harris.ctr@navy.mil	Eric		Harris	1	3017571960			CN=HARRIS.ERIC.WILLIAM.1148220499,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1148220499	HARRIS.ERIC.WILLIAM	20	39	2	9	0	\N	\N	\N	3	\N	0	1
2524	1	robin.harton@navy.mil	Robin		Harton	3	2524646182			CN=HARTON.ROBIN.K.1053084628,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1229745480	HARTON.ROBIN.K	21	15	1	18	0	\N	\N	\N	3	\N	0	1
2526	1	michael.haskell@us.af.mil	Michael		Haskell	5	8508847659			CN=HASKELL.MICHAEL.H.1173288278,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1060319371	HASKELL.MICHAEL.H	7	8	3	4	0	\N	\N	\N	1	\N	0	2
2528	1	christopher.hawk@us.af.mil	Christopher		Hawk	5	8508841309			CN=HAWK.CHRISTOPHER.PAUL.1362430620,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1362430620	HAWK.CHRISTOPHER.PAUL	5	2	3	11	0	\N	\N	\N	1	\N	0	2
2530	1	jhaycraft@bh.com	Jason		Haycraft	5	8176023089	6362864		CN=HAYCRAFT.JASON.LEWIS.1258088650,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1133281564	Haycraft Jason L	20	31	2	7	0	\N	\N	\N	3	\N	0	1
2532	1	jered.healy@usmc.mil	Jered		Healy	5	6117367661	6367661		CN=HEALY.JERED.DOUGLAS.1117589559,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1117589559	HEALY.JERED.DOUGLAS	6	53	3	7	0	\N	\N	\N	3	\N	0	1
3243	1	james.g.butchko.ctr@navy.mil	James		Butchko	4	3013420257			CN=BUTCHKO.JAMES.G.JR.1017859974,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1017859974		20	38	2	9	0	\N	\N	\N	4	\N	0	\N
2536	1	edward.s.henderson@navy.mil	Edward		Henderson	4	3017578404	7578404		CN=HENDERSON.EDWARD.SCOTT.1019677822,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1229745480	HENDERSON.EDWARD.SCOTT	21	38	1	9	0	\N	\N	\N	4	\N	0	1
2538	1	gordon.henjum@usmc.mil	Gordon		Henjum	5	7605833979			CN=HENJUM.GORDON.IVAN.1293412622,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1293412622	HENJUM.GORDON.IVAN	6	24	3	81	0	\N	\N	\N	3	\N	0	\N
2540	1	michael.hensley.4@us.af.mil	Michael		Hensley	5	5058466764	2466764		CN=HENSLEY.MICHAEL.J.1234645060,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1234645060	HENSLEY.MICHAEL.J	7	6	3	5	0	\N	\N	\N	1	\N	0	\N
2542	1	brandon.herbert.1@us.af.mil	Brandon		Herbert	5	3142384613			CN=HERBERT.BRANDON.ANDRE.1267101317,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1267101317	HERBERT.BRANDON.ANDRE	5	4	3	13	0	\N	\N	\N	1	\N	0	\N
2544	0	rodrigo.hernandezpol@usmc.mil	Rodrigo	A	Hernandezpolindara	\N				CN=HERNANDEZPOLINDARA.RODRIGO.ALONSO.1292949924,OU	1	HernandezPolindara,R	\N	\N	\N	\N	1	\N	\N	\N	\N	\N	0	\N
2548	1	james.a.higgins@usmc.mil	James		Higgins	5	8585779406			CN=HIGGINS.JAMES.A.1250900810,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1250900810	HIGGINS.JAMES.A	7	60	3	4	0	\N	\N	\N	3	\N	0	\N
2552	1	tai.ho@navy.mil	Tai		Ho	3	2524646114			CN=HO.TAI.D.1256891804,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1256891804	HO.TAI.D	21	15	1	18	0	\N	\N	\N	4	\N	0	\N
3118	1	alex.thomason@usmc.mil	Alex		Thomason	5	7607630576			CN=THOMASON.ALEX.STEFAN.1284949095,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1287802451		6	46	3	8	0	\N	\N	\N	3	\N	0	1
3119	1	timothy.d.gamble@boeing.com	Timothy		Gamble	5	8048788468		314-545-8183	CN=Timothy Gamble,OU=The Boeing Company,OU=VeriSign\\, Inc.,OU=ECA,O=U.S. Government,C=US	-1		20	31	2	7	0	\N	\N	\N	3	\N	0	1
3120	1	william.b.ellington@usmc.mil	William		Ellington	5	0809708285	3156239		CN=ELLINGTON.WILLIAM.B.1058777249,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1058777249		7	50	3	7	0	\N	\N	\N	3	\N	1	1
2302	1	john.clayman@us.af.mil	John		Clayman	1	5058532956			CN=CLAYMAN.JOHN.WILLIAM.III.1255368679,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1255368679	CLAYMAN.JOHN.WILLIAM.III	6	6	3	5	0	\N	\N	\N	1	\N	0	2
2306	1	eddie.clemmons@navy.mil	Eddie		Clemmons	3	2524645846			CN=CLEMMONS.EDDIE.J.1386686030,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1386686030	Clemmonsej	20	10	1	18	0	\N	\N	\N	3	\N	0	1
2308	0	james.cliffe@usmc.mil	James	E	Cliffe	\N				CN=CLIFFE.JAMES.EDWARD.III.1387063010,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1	cliffeje	\N	\N	\N	\N	1	\N	\N	\N	\N	\N	0	\N
2310	1	caspar.cogar@usmc.mil	Caspar		Cogar	5	3092028556			CN=COGAR.CASPAR.JACEY.1456296854,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1456296854	COGAR.CASPAR.JACEY	4	25	3	2	0	\N	\N	\N	3	\N	0	1
2312	1	michael.coker@wasp.usmc.mil	Michael		Coker	5	9104495849			CN=COKER.MICHAEL.R.1059711900,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1059711900	COKER.MICHAEL.R	20	32	2	2	0	\N	\N	\N	3	\N	0	1
2314	1	raymond.r.cole@usmc.mil	Raymond		Cole	5	9104495126			CN=COLE.RAYMOND.ROYCE.1276757764,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1276757764	COLE.RAYMOND.ROYCE	6	58	3	2	0	\N	\N	\N	3	\N	0	1
2316	1	todd.cook@navy.mil	Todd		Cook	3	2524646165			CN=COOK.TODD.J.1230207174,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1230207174	COOK.TODD.J	20	15	1	18	0	\N	\N	\N	4	\N	0	\N
2318	1	james.coons@usmc.mil	James		Coons	5	9104495160			CN=COONS.JAMES.LEVI.IV.1119361946,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1119361946	COONS.JAMES.LEVI.IV	7	51	3	2	0	\N	\N	\N	3	\N	0	1
2320	1	mihai.g.cosarca@boeing.com	Mihai		Cosarca	5	5058460252	2460252		CN=COSARCA.MIHAI.GABRIEL.1274133364,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1274133364	COSARCA.MIHAI.GABRIEL	20	20	2	5	0	\N	\N	\N	1	\N	0	2
2322	1	roger.counts@navy.mil	Roger		Counts	3	2524647814	4517814		CN=COUNTS.ROGER.D.JR.1229693626,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1229693626	COUNTS.ROGER.D.JR	21	15	1	18	0	\N	\N	\N	4	\N	0	1
2324	1	barry.courie@navy.mil	Barry		Courie	3	9104495213			CN=COURIE.BARRY.R.1229760790,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1229818054	COURIE.BARRY.R	21	15	1	2	0	\N	\N	\N	3	\N	0	1
2326	1	michael.cowan@usmc.mil	Michael		Cowan	5	9104496953			CN=COWAN.MICHAEL.ANDREW.1296825090,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1296825090	COWAN.MICHAEL.ANDREW	6	51	3	2	0	\N	\N	\N	3	\N	0	1
2328	1	edmond.cox@usmc.mil	Edmond		Cox	5	7574447818			CN=COX.EDMOND.PAUL.II.1299738112,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1299738112	COX.EDMOND.PAUL.II	6	149	3	79	0	\N	\N	\N	3	\N	0	\N
2330	0	eric.crespo@usmc.mil	Eric	N	Crespo	\N				CN=CRESPO.ERIC.NICHOLAS.1295281630, OU=USMC, OU=PKI, OU=DoD, O=U.S. Government, C=US	1	CRESPOEN	\N	\N	\N	\N	1	\N	\N	\N	\N	\N	0	\N
2332	1	paul.croom@navy.mil	Paul		Croom	3	2524645665	4515665		CN=CROOM.PAUL.H.1229985783,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1229985783	CROOM.PAUL.H	21	15	1	18	0	\N	\N	\N	4	\N	0	\N
2334	1	forest.cunningham@whmo.mil	Forest		Cunningham	5	5714944729			CN=CUNNINGHAM.FOREST.J.1253120947,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1253120947	CUNNINGHAM.FOREST.J	7	17	3	80	0	\N	\N	\N	3	\N	0	\N
2336	1	jason.darrow@whmo.mil	Jason		Darrow	5	5714944736			CN=DARROW.JASON.W.1065583026,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1141323233	DARROW.JASON.W	8	17	3	80	0	\N	\N	\N	3	\N	0	\N
2338	1	james.d.davenport@usmc.mil	James		Davenport	5	3156361174			CN=DAVENPORT.JAMES.D.1059336858,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1059336858	DAVENPORT.JAMES.D	8	27	3	7	0	\N	\N	\N	3	\N	0	1
2340	0	william.dean@usmc.mil	William	H	Dean	\N				CN=DEAN.WILLIAM.H.1167478995,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1	DEAN.WILLIAM.H	\N	\N	\N	\N	1	\N	\N	\N	\N	\N	0	\N
2342	1	adam.decker.2.ctr@us.af.mil	Adam		Decker	3	8508812503	6412503		CN=DECKER.ADAM.L.1077015740,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1060319371	DECKER.ADAM.L	20	15	2	11	0	\N	\N	\N	1	\N	0	2
2344	1	keith.decker.ctr@navy.mil	Keith		Decker	5	3017572020			CN=DECKER.KEITH.A.1045531291,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1045531291	DECKER.KEITH.A	20	39	2	9	0	\N	\N	\N	3	\N	0	\N
2348	1	randal.degrave@us.af.mil	Randal		Degrave	5	3142384613	3142384		CN=DEGRAVE.RANDAL.NEAL.JR.1381755220,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1381755220	DEGRAVE.RANDAL.NEAL.JR	5	4	3	13	0	\N	\N	\N	1	\N	0	2
2350	1	walter.dehaan@usmc.mil	Walter		Dehaan	5	9104497367	7527367		CN=DEHAAN.WALTER.ALLEN.1254285583,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1254285583	DEHAAN.WALTER.ALLEN	7	54	3	2	0	\N	\N	\N	3	\N	0	1
2352	1	michael.demars@usmc.mil	Michael		Demars	1	9104497376	7228011		CN=DEMARS.MICHAEL.JOSEPH.1283462230,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1283462230	DEMARS.MICHAEL.JOSEPH	11	54	3	2	0	\N	\N	\N	3	\N	0	\N
2354	1	rose.denbleyker@usmc.mil	Rose		Denbleyker	3	8585778349			CN=DENBLEYKER.ROSE.VICTORIA.1395330345,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1395330345	DENBLEYKER.ROSE.VICTORIA	21	15	1	4	0	\N	\N	\N	3	\N	0	1
36	\N	carol.fisher@fst.mil	Carol	D	Fisher	\N	1115551212	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2019-05-16 17:02:21.730429	\N	\N	\N	\N	1	\N
2356	0	ryan.dibble@whmo.mil	Ryan	C	Dibble	\N				CN=DIBBLE.RYAN.CHRISTOPHER.1266320694,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1	DIBBLE.RYAN.CHRISTOPHER	\N	\N	\N	\N	1	\N	\N	\N	\N	\N	0	\N
2358	1	walker.dillenbeck@usmc.mil	Walker		Dillenbeck	5	8585779400			CN=DILLENBECK.WALKER.JARRED.1454460622,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1454460622	DILLENBECK.WALKER.JARRED	5	60	3	4	0	\N	\N	\N	3	\N	0	\N
2360	0	james.dodson@navy.mil	James	L	Dodson	\N				CN=DODSON.JAMES.LEONARD.1122247453, OU=USN, OU=PKI, OU=DoD, O=U.S. Government, C=US	1	Dodson,James L	\N	\N	\N	\N	1	\N	\N	\N	\N	\N	0	\N
2362	0	phillip.downey.1@us.af.mil	Phillip	E	Downey Ii	\N				CN=DOWNEY.PHILLIP.ERIC.II.1072326500,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1	DOWNEY.PHILLIP.ERIC.II	\N	\N	\N	\N	1	\N	\N	\N	\N	\N	0	\N
2364	1	shawn.drake.3@us.af.mil	Shawn		Drake	4	2106529543	487954333		CN=DRAKE.SHAWN.G.1082896933,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1065484494	DRAKE.SHAWN.G	7	8	3	5	0	\N	\N	\N	1	\N	0	\N
2368	0	mitchell.duffy@usmc.mil	Mitchell	R	Duffy	\N				CN=DUFFY.MITCHELL.RYAN.1392591385,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1	DUFFY.MITCHELL.RYAN	\N	\N	\N	\N	1	\N	\N	\N	\N	\N	0	\N
2370	1	daniel.duggan.1@us.af.mil	Daniel		Duggan	3	8508847104	5797104		CN=DUGGAN.DANIEL.A.1247703280,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1247703280	DUGGAN.DANIEL.A	6	2	3	11	0	\N	\N	\N	1	\N	0	\N
2372	1	michael.dumestre@us.af.mil	Michael		Dumestre	5	3142384613	2384613		CN=DUMESTRE.MICHAEL.EDMOND.1121636600,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1121636600	DUMESTRE.MICHAEL.EDMOND	5	4	3	13	0	\N	\N	\N	1	\N	0	2
2374	1	joshua.durnell@usmc.mil	Joshua		Durnell	3	7607631468			CN=DURNELL.JOSHUA.STEVEN.1256242105,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1256242105	DURNELL.JOSHUA.STEVEN	7	57	3	8	0	\N	\N	\N	3	\N	0	\N
2376	1	andrew.p.dyke@navy.mil	Andrew		Dyke	3	9105452464			CN=DYKE.ANDREW.P.1118364992,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1118364992	DYKE.ANDREW.P	21	35	1	3	0	\N	\N	\N	3	\N	0	\N
2380	1	donny.j.east@boeing.com	Donny		East	5	5058538062	2638062		CN=EAST.DONNY.JEROME.1186078523,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1186078523	EAST.DONNY.JEROME	20	20	2	5	0	\N	\N	\N	1	\N	0	\N
2382	1	mark.eastmead@me.usmc.mil	Mark		Eastmead	5	8585774132			CN=EASTMEAD.MARK.ALLEN.JR.1105983251,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1105983251	EASTMEADMA	7	56	3	4	0	\N	\N	\N	3	\N	0	\N
2384	1	william.eatmon.2@us.af.mil	William		Eatmon	5	5058465067	2465067		CN=EATMON.WILLIAM.S.1133312290,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1133312290	EATMON.WILLIAM.S	20	6	1	5	0	\N	\N	\N	1	\N	0	\N
2388	1	john.engvik@wasp.usmc.mil	John		Engvik	5	9014497090			CN=ENGVIK.JOHN.ANDREW.1292289592,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1292289592	ENGVIK.JOHN.ANDREW	6	52	3	2	0	\N	\N	\N	3	\N	0	1
2390	1	jose.j.escarcega2@boeing.com	Jose		Escarcega	5	5058460315	2460315		CN=ESCARCEGA.JOSE.J.1156718382,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1156718382	ESCARCEGA.JOSE.J	20	20	2	5	0	\N	\N	\N	1	\N	0	2
2392	1	juandiego.escobedo@usmc.mil	Juandiego		Escobedo	5	3156363509			CN=ESCOBEDO.JUANDIEGO.CRUZ.1384366470,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1384366470	escobedojc	5	27	3	7	0	\N	\N	\N	3	\N	0	\N
2394	1	richard.a.evans3.ctr@navy.mil	Richard		Evans	5	3017570078			CN=EVANS.RICHARD.ALLEN.1267382995,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1267382995	EVANS.RICHARD.ALLEN	21	39	2	9	0	\N	\N	\N	4	\N	0	1
2396	1	robert.evans1@usmc.mil	Robert		Evans	5	8082571191			CN=EVANS.ROBERT.ALAN.1250902626,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1250902626	EVANS.ROBERT.ALAN	7	24	3	81	0	\N	\N	\N	3	\N	0	\N
2398	1	todd.l.farrand@boeing.com	Todd		Farrand	5	4256159739			CN=FARRAND.TODD.L.1094805216,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1133281564	FARRAND.TODD.L	20	31	2	7	0	\N	\N	\N	3	\N	0	\N
2400	1	chad.fields@us.af.mil	Chad		Fields	3	8508813612	6413612		CN=FIELDS.CHAD.EVERETT.1127984774,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1127984774	FIELDS.CHAD.EVERETT	6	2	3	11	0	\N	\N	\N	1	\N	0	\N
2402	0	michael.fincik@usmc.mil	Michael	A	Fincik	\N				CN=FINCIK.MICHAEL.ALAN.1454201503,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1	FINCIK.MICHAEL.ALAN	\N	\N	\N	\N	1	\N	\N	\N	\N	\N	0	\N
2404	0	matthew.e.fish@usmc.mil	Matthew	E	Fish	\N				CN=FISH.MATTHEW.E.1254614382,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1	FISH.MATTHEW.E	\N	\N	\N	\N	1	\N	\N	\N	\N	\N	0	\N
2406	1	randal.fitzgerald@usmc.mil	Randal		Fitzgerald	5	7607258076			CN=FITZGERALD.RANDAL.SCOTT.1257450186,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1257450186	FITZGERALD.RANDAL.SCOTT	6	28	3	8	0	\N	\N	\N	3	\N	0	\N
2408	1	daniel.k.flaherty@usmc.mil	Daniel		Flaherty	5	8064970775	6367658		CN=FLAHERTY.DANIEL.KEVIN.JR.1362566181,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1362566181	FLAHERTY.DANIEL.KEVIN.JR	5	53	3	7	0	\N	\N	\N	3	\N	0	\N
2410	1	anthony.fontanetta@usmc.mil	Anthony		Fontanetta	4	9104497252			CN=FONTANETTA.ANTHONY.CONRAD.1455839269,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1455839269	FONTANETTA.ANTHONY.CONRAD	4	25	3	2	0	\N	\N	\N	3	\N	0	1
2412	0	brandon.ford.9@us.af.mil	Brandon	M	Ford	\N				CN=FORD.BRANDON.MICHAEL.1365721617,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1	FORD.BRANDON.MICHAEL	\N	\N	\N	\N	1	\N	\N	\N	\N	\N	0	\N
2414	1	thomas.forney@usmc.mil	Thomas		Forney	5	8585774132			CN=FORNEY.THOMAS.CHARLES.1032775000,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1032775000	FORNEY.THOMAS.CHARLES	5	56	3	4	0	\N	\N	\N	3	\N	0	\N
2416	1	dencil.foster@navy.mil	Paul		Foster	3	2524645618			CN=FOSTER.DENCIL.PAUL.1246896514,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1246896514	fosterdp	20	15	1	18	0	\N	\N	\N	4	\N	0	1
2418	1	heath.foster@usmc.mil	Heath		Foster	5	3156362583			CN=FOSTER.HEATH.ELLIOT.1132448236,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1132448236	FOSTER.HEATH.ELLIOT	7	27	3	7	0	\N	\N	\N	3	\N	0	1
2420	1	jonathan.foster@navy.mil	Jonathan		Foster	3	2524645642			CN=FOSTER.JONATHAN.R.1505512991,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1505512991	FOSTER.JONATHAN.R	21	10	1	18	0	\N	\N	\N	4	\N	0	1
2422	1	mathew.foster@us.af.mil	Mathew		Foster	3	5759046031			CN=FOSTER.MATHEW.GREG.1256388509,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1256388509	fostermg	6	3	3	12	0	\N	\N	\N	1	\N	0	2
1768	1	lori.birchfield@navy.mil	Lori		Birchfield	5	2522692150	123123123		CN=BIRCHFIELD.LORI.A.1051055540,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1065484494		21	10	1	18	0	\N	\N	\N	4	\N	0	\N
2006	1	lawrinda.stone@navy.mil	Lawrinda		Stone	3	2524648770			CN=STONE.LAWRINDA.M.1230678274,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1141323233		21	15	1	18	0	\N	\N	\N	3	\N	0	1
2065	1	jchmartin@bh.com	Joseph		Martin	5	8508812651			CN=MARTIN.JOSEPH.CURT.1130630924,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1130630924		20	16	2	11	0	\N	\N	\N	1	\N	0	2
35	\N	brian.davidson@fst.mil	Brian	C	Davidson	\N	1115551212	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2019-05-16 21:01:55.564	\N	\N	\N	\N	1	\N
2066	1	ronald.d.page@boeing.com	Ronald		Page	5	8508812645	6412645		CN=PAGE.RONALD.D.1170990079,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1060319371		20	16	2	11	0	\N	\N	\N	1	\N	0	2
2426	1	william.j.frazier@usmc.mil	William		Frazier	5	9104497127			CN=FRAZIER.WILLIAM.JAMES.1385724485,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1385724485	FRAZIER.WILLIAM.JAMES	15	49	3	2	0	\N	\N	\N	3	\N	0	1
2428	1	brian.freeman@usmc.mil	Brian		Freeman	5	9102651561			CN=FREEMAN.BRIAN.SHAWN.1186089118,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1186089118	FREEMAN.BRIAN.SHAWN	7	49	3	77	0	\N	\N	\N	3	\N	0	1
2430	0	william.friend@usmc.mil	William	A	Friend	\N				CN=FRIEND.WILLIAM.ALLAN.1266873243, OU=USMC, OU=PKI, OU=DoD, O=U.S. Government, C=US	1	friendwa	\N	\N	\N	\N	1	\N	\N	\N	\N	\N	0	\N
3512	1	liann.karni@usmc.mil	Liann		Karni	5	8585778155			CN=KARNI.LIANN.1411524791,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1411524791		5	43	3	4	0	\N	\N	\N	3	\N	1	\N
3321	1	stephanie.dunks@usmc.mil	Stephanie		Dunks	4	9104497252			CN=DUNKS.STEPHANIE.MELIN.1407332810,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1407332810		5	25	3	2	0	\N	\N	\N	3	\N	0	1
3275	1	xuewen.yin@usmc.mil	Xuewen		Yin	5	8585774289			CN=YIN.XUEWEN.1460937430,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1460937430		4	23	3	4	0	\N	\N	\N	3	\N	1	1
3277	1	christian.b.tocatlian@boeing.com	Christian		Tocatlian	5	6105916086			CN=Christian Tocatlian,OU=The Boeing Company,OU=VeriSign\\, Inc.,OU=ECA,O=U.S. Government,C=US	1141323233		20	9	2	9	0	\N	\N	\N	3	\N	0	\N
3280	1	roderick.marcum@rolls-royce.com	Roderick		Marcum	5	9104495212			CN=MARCUM.RODERICK.DEAN.1084123877,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1084123877		20	32	2	2	0	\N	\N	\N	3	\N	0	\N
3285	1	robert.graf.1.ctr@us.af.mil	Robert		Graf	5	5058534650	8634650		CN=GRAF.ROBERT.W.1021390271,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1060319371		20	6	2	5	0	\N	\N	\N	1	\N	1	2
3289	1	james.m.gawne@rolls-royce.com	James		Gawne	3	3172306238			CN=James Gawne,OU=Rolls-Royce Corporation,OU=VeriSign\\, Inc.,OU=ECA,O=U.S. Government,C=US	-1		20	34	2	18	0	\N	\N	\N	3	\N	0	\N
3290	1	christopher.hazel@navy.mil	Christopher		Hazel	3	2524646193	4516193		CN=HAZEL.CHRISTOPHER.J.1503481797,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1503481797		20	10	1	17	0	\N	\N	\N	4	\N	0	\N
3291	1	lauren.vachio@usmc.mil	Lauren		Vachio	5	9104497245			CN=VACHIO.LAUREN.ALISON.1463451750,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1463451750		4	25	3	2	0	\N	\N	\N	3	\N	0	\N
3313	1	gregory.atchley@usmc.mil	Gregory		Atchleymartin	5	8082570084			CN=ATCHLEYMARTIN.GREGORY.MICHAEL.1454923584,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1454923584		5	24	3	81	0	\N	\N	\N	3	\N	1	1
3350	1	daniel.whalen@navy.mil	Daniel		Whalen	3	2524646288			CN=WHALEN.DANIEL.JAY.1523353914,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1523353914		20	10	1	18	0	\N	\N	\N	4	\N	0	\N
3364	1	robert.pike.11@us.af.mil	Robert		Pike	4	8508814312	6414312		CN=PIKE.ROBERT.L.1170175782,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1170175782		20	15	1	11	0	\N	\N	\N	4	\N	0	2
3377	1	ryan.schuster@navy.mil	Ryan		Schuster	3	2527208013			CN=SCHUSTER.RYAN.D.1521678506,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1521678506		21	10	1	18	0	\N	\N	\N	4	\N	0	\N
3382	1	winhou.chow@navy.mil	Win-Hou		Chow	3	2524646156			CN=CHOW.WIN-HOU.T.1516739009,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1516739009		20	10	1	17	0	\N	\N	\N	4	\N	0	\N
3390	1	patrick.hoagland.1@us.af.mil	Patrick		Hoagland	4	5058531155	2431155		CN=HOAGLAND.PATRICK.EDWARD.1289528080,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1289528080		20	6	1	5	0	\N	\N	\N	1	\N	1	2
3410	1	isa.merkt@navy.mil	Isa		Merkt	3	2524646717			CN=MERKT.ISA.E C.1514174730,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1514174730		21	15	1	17	0	\N	\N	\N	4	\N	0	1
3419	1	jacob.eddleman@usmc.mil	Jacob		Eddleman	5	8585774298			CN=EDDLEMAN.JACOB.RAY.1399692888,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1399692888		5	23	3	4	0	\N	\N	\N	3	\N	0	1
3460	1	matthew.h.bruce@navy.mil	Matthew		Bruce	3	2524646173			CN=BRUCE.MATTHEW.H.1527682467,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1527682467		21	10	1	18	0	\N	\N	\N	4	\N	0	1
3466	1	cody.c.cook@usmc.mil	Cody		Cook	5	8585774298	5774298		CN=COOK.CODY.CHRISTOPHER.1502417629,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1502417629		3	23	3	4	0	\N	\N	\N	3	\N	1	1
3483	1	philip.hindson@me.usmc.mil	Philip		Hindson	5	8585778044	3455286		CN=HINDSON.PHILIP.DALE.1299744970,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1299744970		5	47	3	4	0	\N	\N	\N	3	\N	0	\N
3486	1	michael.holzheimer@us.af.mil	Michael		Holzheimer	5	5058535089			CN=HOLZHEIMER.MICHAEL.ROBERT.1290767209,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1290767209		5	6	3	5	0	\N	\N	\N	1	\N	1	\N
3496	1	auraya.calcote.ctr@us.af.mil	Auraya		Calcote	3	8508813105	6413105		CN=CALCOTE.AURAYA.1534032060,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1060319371		20	15	2	11	0	\N	\N	\N	1	\N	0	\N
3502	1	arthur.douglas@navy.mil	Arthur		Douglas	4	2527206935	590693522		CN=DOUGLAS.ARTHUR.S.1140116170,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1065484494		21	15	1	18	0	\N	\N	\N	4	\N	0	\N
3504	0	shawn.bryant@usmc.mil	Shawn		Bryant	5	8585778090	2678090		CN=BRYANT.SHAWN.M.1243937350,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1243937350		11	48	3	4	0	\N	\N	\N	3	\N	0	\N
3516	1	michael.d.jones2@usmc.mil	Michael		Jones	5	8503464744	6367657		CN=JONES.MICHAEL.DAVID.1298995820,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1298995820		5	53	3	7	0	\N	\N	\N	3	\N	1	\N
3517	1	richard.go@usmc.mil	Richard		Go	5	8585778105			CN=GO.RICHARD.SOTTO.1239092183,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1239092183		7	48	3	4	0	\N	\N	\N	3	\N	1	\N
3518	1	bradley.oneill@us.af.mil	Bradley		Oneill	5	5757840919			CN=ONEILL.BRADLEY.M.1020630031,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1020630031		6	3	3	12	0	\N	\N	\N	1	\N	1	\N
3522	1	jose.ramos1@usmc.mil	Jose		Ramos	3	8585779472			CN=RAMOS.JOSE.OCTAVIO.1018706209,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1018706209		20	10	1	4	0	\N	\N	\N	3	\N	0	\N
3524	1	bradford.yazzie@us.af.mil	Bradford		Yazzie	5	5058535089			CN=YAZZIE.BRADFORD.RYAN.1292988091,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1292988091		5	6	3	5	0	\N	\N	\N	1	\N	1	\N
3525	1	charles.beltram@usmc.mil	Charles		Beltram	3	7607631487			CN=BELTRAM.CHARLES.AARON.II.1246365705,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1246365705		7	57	3	8	0	\N	\N	\N	3	\N	1	\N
3528	1	timothy.stumpf@us.af.mil	Timothy		Stumpf	5	3122381862			CN=STUMPF.TIMOTHY.GEORGE.1252608911,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1252608911		7	4	3	13	0	\N	\N	\N	1	\N	1	\N
37	\N	alexandra.poole@oem.com	Alexandra	E	Poole	\N	1115551212	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2019-05-16 17:03:54.621326	\N	\N	\N	\N	1	\N
3530	1	howard.pinnell@navy.mil	Howard		Pinnell	4	3017575186			CN=PINNELL.HOWARD.PERRY.1051795578,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1051795578		21	38	1	9	0	\N	\N	\N	4	\N	1	\N
3535	1	christopher.stinnett@usmc.mil	Christopher		Stinnett	5	6109555149			CN=STINNETT.CHRISTOPHER.LOREN.1265628873,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1265628873		7	55	3	81	0	\N	\N	\N	3	\N	1	\N
3536	1	james.dodson@navy.mil	James		Dodson	4	3013427483			CN=DODSON.JAMES.LEONARD.1122247453,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1122247453		21	38	1	9	0	\N	\N	\N	4	\N	1	\N
3537	1	brandon.mick@usmc.mil	Brandon		Mick	5	8082573562			CN=MICK.BRANDON.JAMES.1174363842,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1174363842		6	55	3	81	0	\N	\N	\N	3	\N	1	\N
3538	1	jeremy.shedlock@usmc.mil	Jeremy		Shedlock	5	8585779400			CN=SHEDLOCK.JEREMY.DENNIS.1454456153,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1454456153		5	60	3	4	0	\N	\N	\N	3	\N	0	\N
3279	1	david.rupp@usmc.mil	David		Rupp	5	9104497374	7527374		CN=RUPP.DAVID.CHARLES.1036552197,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1036552197		8	54	3	2	0	\N	\N	\N	3	\N	0	\N
3283	1	teodoro.luna@usmc.mil	Teodoro		Luna	5	9282696873			CN=LUNA.TEODORO.III.1265180554,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1265180554		6	62	3	4	0	\N	\N	\N	3	\N	0	1
3294	1	michael.a.mitchell@navy.mil	Michael		Mitchell	4	2524648744	2524518		CN=MITCHELL.MICHAEL.A.JR.1275574836,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1275574836		21	10	1	18	0	\N	\N	\N	4	\N	0	1
3296	1	jerusha.kaapa@us.af.mil	Jerusha		Kaapa	5	5058533490			CN=KAAPA.JERUSHA.EMALANI LUAIPOU.1179193015,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1179193015		6	6	3	5	0	\N	\N	\N	1	\N	0	\N
3300	1	carl.decker@usmc.mil	Carl		Decker	5	9104495971			CN=DECKER.CARL.ALBERT.JR.1080103405,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1080103405		7	51	3	2	0	\N	\N	\N	3	\N	0	1
3303	1	christopher.battiest@usmc.mil	Christophe		Battiest	5	7607630576			CN=BATTIEST.CHRISTOPHE.M.1144405346,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1144405346		7	46	3	8	0	\N	\N	\N	3	\N	0	1
3304	1	cliff.champ@usmc.mil	Cliff		Champ	5	7607631468			CN=CHAMP.CLIFF.HENRY.1293829248,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1293829248		6	57	3	8	0	\N	\N	\N	3	\N	0	\N
3319	1	timothy.lopez@usmc.mil	Timothy		Lopez	5	8082570100			CN=LOPEZ.TIMOTHY.1234071498,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1234071498		6	24	3	81	0	\N	\N	\N	4	\N	1	1
3323	1	adrian.almanza@usmc.mil	Adrian		Almanza	5	9093467728			CN=ALMANZA.ADRIAN.1462829848,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1462829848		4	27	3	7	0	\N	\N	\N	3	\N	0	\N
3325	1	john.whelton@usmc.mil	John		Whelton	5	3156363344	6363344		CN=WHELTON.JOHN.JOSEPH.1465174559,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1465174559		4	27	3	7	0	\N	\N	\N	3	\N	0	1
3328	1	luis.correa.4@us.af.mil	Luis		Correa	5	5053589695			CN=CORREA.LUIS.FERNANDO.1374252891,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1060319371		5	6	3	5	0	\N	\N	\N	1	\N	1	2
3329	1	john.recio@usmc.mil	John		Recio	5	6613438860	6362763		CN=RECIO.JOHN.PAUL.1405128396,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1405128396		5	27	3	7	0	\N	\N	\N	3	\N	0	1
3331	1	joshua.barefoot@navy.mil	Joshua		Barefoot	3	2524646189	4516189		CN=BAREFOOT.JOSHUA.H.1454667502,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1454667502		21	15	1	18	0	\N	\N	\N	4	\N	0	1
3339	1	emmanuel.gaffud1@navy.mil	Emmanuel		Gaffud	3	3017571159			CN=GAFFUD.EMMANUEL.AMADA.1172246113,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1172246113		21	38	1	9	0	\N	\N	\N	4	\N	0	2
3375	1	david.jones@usmc.mil	David		Jones	5	8082570084			CN=JONES.DAVID.MATTHEW.1020739408,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1020739408		6	24	3	18	0	\N	\N	\N	3	\N	1	1
3391	1	earl.clowers@navy.mil	E		Clowers	3	2524646202			CN=CLOWERS.E.ROGER.1229860190,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1229860190		20	10	1	18	0	\N	\N	\N	4	\N	1	1
3394	1	joseph.parvin@usmc.mil	Joseph		Parvin	5	9104496419			CN=PARVIN.JOSEPH.MICHAEL.1286657105,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1286657105		6	49	3	2	0	\N	\N	\N	3	\N	1	1
3397	1	nkosi.leary@yahoo.com	Nkosi		Leary	5	8082575025	4575025	8082575491	CN=LEARY.NKOSI.AMAN.1172350654,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1172350654		8	24	3	81	0	\N	\N	\N	3	\N	1	1
3407	1	charles.coleman@usmc.mil	Charles		Coleman	5	9104497368			CN=COLEMAN.CHARLES.LEE.1406551128,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1406551128		5	54	3	2	0	\N	\N	\N	3	\N	0	1
3413	1	wyatt.dodge@usmc.mil	Wyatt		Dodge	5	8082571424			CN=DODGE.WYATT.AUSTYN.1510388620,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1510388620		3	23	3	81	0	\N	\N	\N	4	\N	1	1
3415	1	katherine.cunningham.3.ctr@us.af.mil	Katherine		Cunningham	4	6182566351			CN=CUNNINGHAM.KATHERINE.S.1007236278,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1007236278		20	9	2	11	0	\N	\N	\N	1	\N	1	2
3428	1	antonio.benitez1@usmc.mil	Antonio		Benitez	3	3156362583	3156362		CN=BENITEZ.ANTONIO.1282984691,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1282984691		7	27	3	7	0	\N	\N	\N	3	\N	0	1
3431	1	daniel.bock@us.af.mil	Daniel		Bock	5	8508815007			CN=BOCK.DANIEL.STEWART.1042849010,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1042849010		5	2	3	11	0	\N	\N	\N	1	\N	0	\N
3432	1	rupert.m.mighty@usmc.mil	Rupert		Mighty	5	7607258087			CN=MIGHTY.RUPERT.MAURICECLAY.1500469788,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1500469788		4	28	3	8	0	\N	\N	\N	3	\N	1	2
3435	1	brian.cauguiran@navy.mil	Brian		Cauguiranevans	5	8157628450			CN=CAUGUIRANEVANS.BRIAN.JAMES.1367582460,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1367582460		5	24	3	81	0	\N	\N	\N	4	\N	1	1
3449	1	nicholas.cox.1@us.af.mil	Nicholas		Cox	5	8508841309	5791309		CN=COX.NICHOLAS.S.1233857889,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1233857889		6	2	3	11	0	\N	\N	\N	1	\N	1	2
3500	1	richard.mccoy@usmc.mil	Richard		Mccoy	5	9702346732	6362896		CN=MCCOY.RICHARD.ALEXANDER.1410315714,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1410315714		5	53	3	7	0	\N	\N	\N	3	\N	1	\N
3510	1	thomas.gaskell.2.ctr@us.af.mil	Thomas		Gaskell	5	3142384396	2384396		CN=GASKELL.THOMAS.P.1093078221,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1060319371		20	21	2	13	0	\N	\N	\N	1	\N	1	\N
3511	1	eric.crespo@usmc.mil	Eric		Crespo	3	9104494794	9104494		CN=CRESPO.ERIC.NICHOLAS.1295281630,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1295281630		6	25	3	2	0	\N	\N	\N	3	\N	0	\N
3527	1	calieb.prunty@usmc.mil	Calieb		Prunty	3	7607253262			CN=PRUNTY.CALIEB.LEROY.1465177779,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1465177779		4	28	3	8	0	\N	\N	\N	3	\N	1	\N
38	\N	sally.graham@oem.com	Sally	F	Graham	\N	1115551212	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2019-05-16 17:04:20.433573	\N	\N	\N	\N	1	\N
3529	1	joseph.alarcon@us.af.mil	Joseph		Alarcon	3	5058533497	2533497		CN=ALARCON.JOSEPH.E.1137307177,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1137307177		8	6	3	5	0	\N	\N	\N	1	\N	1	\N
3534	1	david.e.carlson@navy.mil	David		Carlson	3	7323231805			CN=CARLSON.DAVID.E.1228939338,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1228939338		21	35	1	3	0	\N	\N	\N	3	\N	1	\N
3539	1	dustin.g.jones@usmc.mil	Dustin		Jones	5	9282696874			CN=JONES.DUSTIN.GENE.1365911734,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1365911734		5	62	3	2	0	\N	\N	\N	3	\N	0	\N
3540	1	edmond.e.madden@usmc.mil	Edmond		Madden	5	9282696874			CN=MADDEN.EDMOND.EARL.1282243179,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1282243179		6	62	3	2	0	\N	\N	\N	3	\N	0	\N
3267	1	frank.a.mazza@boeing.com	Frank		Mazza	3	6107428861			CN=Frank Mazza,OU=The Boeing Company,OU=VeriSign\\, Inc.,OU=ECA,O=U.S. Government,C=US	1060319371		20	9	2	17	0	\N	\N	\N	3	\N	0	1
3278	1	charles.yetman@navy.mil	Charles		Yetman	4	6197674603			CN=YETMAN.CHARLES.F.1258522857,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1258522857		20	38	1	6	0	\N	\N	\N	4	\N	1	1
3286	1	cablair@bh.com	Cory		Blair	4	8172808249			CN=Cory Blair,OU=Bell Helicopter Textron Inc.,OU=VeriSign\\, Inc.,OU=ECA,O=U.S. Government,C=US	-1		20	9	2	9	0	\N	\N	\N	3	\N	0	1
3288	1	christopher.scism@us.af.mil	Christopher		Scism	5	3142384613			CN=SCISM.CHRISTOPHER.J.1298384759,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1298384759		5	4	3	13	0	\N	\N	\N	1	\N	1	2
3301	1	john.detwiler@usmc.mil	John		Detwiler	5	9104497376			CN=DETWILER.JOHN.RICHARD.1245754597,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1245754597		7	54	3	2	0	\N	\N	\N	3	\N	1	1
3302	1	douglas.friedlund@us.af.mil	Douglas		Friedlund	5	5757846516	6816516		CN=FRIEDLUND.DOUGLAS.PALMER.1266361749,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1266361749		7	3	3	12	0	\N	\N	\N	1	\N	0	\N
3305	1	joshua.collins@usmc.mil	Joshua		Collins	5	7607631058			CN=COLLINS.JOSHUA.LEE.1462830056,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1462830056		4	28	3	8	0	\N	\N	\N	3	\N	1	1
3306	1	widler@bh.com	Werner		Idler	3	8172807681			CN=Werner Idler,OU=Bell Helicopter\\, Textron Inc.,OU=VeriSign\\, Inc.,OU=ECA,O=U.S. Government,C=US	-1		20	9	2	17	0	\N	\N	\N	3	\N	0	1
3320	0	patrick.cowden@usmc.mil	Patrick		Cowden	5	3156363344			CN=COWDEN.PATRICK.HERBERT.III.1455396723,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1455396723		5	27	3	7	0	\N	\N	\N	3	\N	0	1
3327	1	alexander.sasseen@usmc.mil	Alexander		Sasseen	5	7607254754			CN=SASSEEN.ALEXANDER.GILLESPIE.1142034049,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1142034049		4	28	3	8	0	\N	\N	\N	3	\N	1	1
3333	1	pedro.r.hernandez@usmc.mil	Pedro		Hernandez	5	3156363977	3153977		CN=HERNANDEZ.PEDRO.RAFAEL.1133107645,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1133107645		8	53	3	7	0	\N	\N	\N	3	\N	0	1
3337	1	ksem@bh.com	Karen		Sem	3	8172807880			CN=Karen Sem,OU=Bell Helicopter\\, Textron Inc.,OU=VeriSign\\, Inc.,OU=ECA,O=U.S. Government,C=US	1141323233		20	9	2	18	0	\N	\N	\N	3	\N	0	1
3343	1	mickenzi.schank@navy.mil	Mickenzi		Schank	3	2524646179			CN=SCHANK.MICKENZI.V.1523584894,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1523584894		21	10	1	18	0	\N	\N	\N	4	\N	1	1
3349	1	jordan.stringfellow@navy.mil	Jordan		Stringfellow	3	2524646158			CN=STRINGFELLOW.JORDAN.BAYNE.1523355445,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1523355445		20	10	1	18	0	\N	\N	\N	4	\N	1	2
3354	1	xavier.collier@navy.mil	Xavier		Collier	3	2524646481			CN=COLLIER.XAVIER.E.1114468793,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1114468793		20	10	1	18	0	\N	\N	\N	4	\N	1	1
3357	1	kidd.hu@usmc.mil	Kidd		Hu	4	9104496267	4496267		CN=HU.KIDD.KT.1469932466,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1469932466		4	25	3	2	0	\N	\N	\N	3	\N	0	\N
3363	1	riaan.coetsee@navy.mil	Riaan		Coetsee	3	2524646654			CN=COETSEE.RIAAN.1522893982,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1522893982		21	10	1	18	0	\N	\N	\N	4	\N	0	1
3372	1	mhaugan@bh.com	Michael		Michael Haugan	3	8175010519			CN=Michael Haugan,OU=Bell Helicopter\\, Textron Inc.,OU=VeriSign\\, Inc.,OU=ECA,O=U.S. Government,C=US	-1		20	9	2	17	0	\N	\N	\N	3	\N	0	1
3388	1	heather.pesante.ctr@navy.mil	Heather		Pesante	4	3019952893			CN=PESANTE.HEATHER.LYNN.1260646814,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1260646814		20	38	2	9	0	\N	\N	\N	4	\N	1	1
3393	0	bryce.cartrette@usmc.mil	Bryce		Cartrette	5	9105154403			CN=CARTRETTE.BRYCE.WAYNE.1287678629,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1287678629		6	24	3	81	0	\N	\N	\N	4	\N	0	1
3396	1	tyler.s.martin1@navy.mil	Tyler		Martin	3	2524646653			CN=MARTIN.TYLER.SETH.1525518384,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1525518384		21	10	1	18	0	\N	\N	\N	4	\N	0	1
3403	1	joshua.j.pannell@navy.mil	Joshua		Pannell	3	2524646231			CN=PANNELL.JOSHUA.JAMES.1525518368,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1525518368		21	15	1	17	0	\N	\N	\N	4	\N	0	\N
3404	1	mathew.clifford@us.af.mil	Mathew		Clifford	5	5757840919			CN=CLIFFORD.MATHEW.PATRICK.1252171033,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1252171033		6	3	3	12	0	\N	\N	\N	1	\N	1	2
3409	1	cody.bowman@usmc.mil	Cody		Bowman	5	8082572513			CN=BOWMAN.CODY.RYAN.1300611377,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1300611377		5	24	3	81	0	\N	\N	\N	3	\N	1	1
3421	1	sergio.valentin@whmo.mil	Sergio		Valentin	5	5714944730			CN=VALENTIN.SERGIO.ANTONIO.1295412263,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1295412263		5	17	3	80	0	\N	\N	\N	3	\N	0	1
3444	1	matthew.r.martin1@usmc.mil	Matthew		Martin	5	9104496267			CN=MARTIN.MATTHEW.RICHARDMAC.1392134073,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1392134073		5	25	3	2	0	\N	\N	\N	3	\N	1	1
3448	1	michael.simon.3@us.af.mil	Michael		Simon	5	8508813412	6713412		CN=SIMON.MICHAEL.D.II.1240995952,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1240995952		8	2	3	11	0	\N	\N	\N	1	\N	0	2
3452	1	daniel.stagg@marine.mil	Daniel		Stagg	5	8082571191			CN=STAGG.DANIEL.WEBSTER.III.1370159455,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1370159455		5	24	3	81	0	\N	\N	\N	4	\N	1	1
3456	1	v327mxgqa@us.af.mil	Derek		Bean	5	5757840919			CN=BEAN.DEREK.REED.1420537189,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1420537189		5	3	3	12	0	\N	\N	\N	1	\N	0	\N
3471	1	thomas.francoeur@usmc.mil	Thomas		Francoeur	5	3156362583			CN=FRANCOEUR.THOMAS.W.1006168058,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1006168058		8	27	3	7	0	\N	\N	\N	3	\N	0	1
3472	1	michael.winn@usmc.mil	Michael		Winn	5	7607253262			CN=WINN.MICHAEL.ROBERT.1395235954,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1395235954		5	28	3	8	0	\N	\N	\N	3	\N	1	\N
39	\N	michelle.bower@modapprover.org	Michelle	G	Bower	\N	1115551212	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2019-05-16 17:06:08.204674	\N	\N	\N	\N	1	\N
3474	0	berry.tanner@usmc.mil	Tanner		Berry	5	7607253262			CN=BERRY.TANNER.MICHAEL.1502277223,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1502277223		3	28	3	8	0	\N	\N	\N	3	\N	0	\N
3482	1	kendrick.anderson@usmc.mil	Kendrick		Anderson	5	7607255871			CN=ANDERSON.KENDRICK.ROBERT.1465553410,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1465553410		4	28	3	8	0	\N	\N	\N	3	\N	1	\N
3217	1	daryl.henderson@us.af.mil	Daryl		Henderson	4	8508842091	5792091		CN=HENDERSON.DARYL.LEON.1275484519,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1275484519		6	8	3	11	0	\N	\N	\N	1	\N	1	2
3123	1	richard.martin@navy.mil	Richard		Martin	4	3017575849			CN=MARTIN.RICHARD.CURRAN.JR.1157752517,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1157752517		18	38	3	9	0	\N	\N	\N	3	\N	0	1
3127	1	bryant.knox@navy.mil	Bryant		Knox	4	3013427258			CN=KNOX.BRYANT.D.1111311710,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1111311710		21	38	1	9	0	\N	\N	\N	4	\N	1	1
3135	1	micah.kennedy@navy.mil	Micah		Kennedy	3	2524646162			CN=KENNEDY.MICAH.A.1503429094,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1503429094		21	15	1	18	0	\N	\N	\N	4	\N	0	\N
3136	1	jrieschick.rieschick.3.ctr@us.af.mil	Jeremy		Rieschick	1	5752181387	6413175		CN=RIESCHICK.JEREMY.DAVID.1253825460,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1253825460		20	33	2	12	0	\N	\N	\N	1	\N	0	2
3145	1	donald.toro@usmc.mil	Donald		Toro	4	9104494794			CN=TORO.DONALD.J.II.1093851427,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1093851427		6	25	3	2	0	\N	\N	\N	3	\N	1	1
3149	1	james.r.guffey@boeing.com	James		Guffey	5	8583573100			CN=GUFFEY.JAMES.REID.1063817143,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1063817143		20	31	1	4	0	\N	\N	\N	3	\N	0	1
3150	1	kelsey.brown@us.af.mil	Kelsey		Brown	1	5058535091	2635091		CN=BROWN.KELSEY.DESHOHN.1065234862,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1065234862		6	6	3	5	0	\N	\N	\N	1	\N	1	2
3155	1	larry.jones.16@us.af.mil	Larry		Jones	5	5757847040	6817040		CN=JONES.LARRY.L.1248529047,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1248529047		6	3	3	12	0	\N	\N	\N	1	\N	1	2
3157	1	dustin.riegel@usmc.mil	Dustin		Riegel	5	9104497932			CN=RIEGEL.DUSTIN.CODY.1370052723,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1370052723		5	25	3	2	0	\N	\N	\N	3	\N	1	1
3160	1	kevin.stanton@us.af.mil	Kevin		Stanton	5	1638544613	2384613		CN=STANTON.KEVIN.TOSHIO.1124217810,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1124217810		6	4	3	13	0	\N	\N	\N	1	\N	0	\N
3163	1	lauren.campbell@usmc.mil	Lauren		Campbell	5	3156367659	3156367		CN=CAMPBELL.LAUREN.EILEEN.1503508679,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1503508679		15	53	3	7	0	\N	\N	\N	3	\N	0	1
3165	1	jared.mccarthy@usmc.mil	Jared		Mccarthy	4	7015109661	6362217		CN=MCCARTHY.JARED.LAYNE.1020421157,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1020421157		5	27	3	7	0	\N	\N	\N	3	\N	1	1
3169	1	kyle.squires@usmc.mil	Kyle		Squires	4	9104496065			CN=SQUIRES.KYLE.LANE.1273325065,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1273325065		4	25	3	2	0	\N	\N	\N	3	\N	0	1
3171	1	john.d.berryhill@navy.mil	John		Berryhill	5	2524648362	4518362	n/a	CN=BERRYHILL.JOHN.D.JR.1230165510,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1230165510		21	10	1	18	0	\N	\N	\N	4	\N	0	\N
3179	1	cory.bolick@usmc.mil	Cory		Bolick	5	8585779146			CN=BOLICK.CORY.ALEXANDER.1411138832,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1411138832		5	23	3	4	0	\N	\N	\N	3	\N	1	1
3186	1	jack.h.martinez@boeing.com	Jack		Martinez	3	4847684996		6105912112	CN=Jack Martinez Jr,OU=The Boeing Company..,OU=VeriSign\\, Inc.,OU=ECA,O=U.S. Government,C=US	-1		20	9	2	17	0	\N	\N	\N	3	\N	0	\N
3192	1	greg.blackburn.1@us.af.mil	Gregory		Blackburn	5	8508847314			CN=BLACKBURN.GREGORY.L.1281590495,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1281590495		5	2	3	11	0	\N	\N	\N	1	\N	1	2
3194	1	nicholas.read@usmc.mil	Nicholas		Read	5	8585774289			CN=READ.NICHOLAS.ANDREW.1456464218,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1456464218		4	23	3	4	0	\N	\N	\N	3	\N	1	1
3203	1	nicholas.ceo@usmc..mil	Nicholas		Ceo	1	8585774289			CN=CEO.NICHOLAS.JOHN.1283954478,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1283954478		6	23	3	4	0	\N	\N	\N	3	\N	1	1
3209	1	augie.bravo@boeing.com	Augustine		Bravo	3	6105918587			CN=Augustine Bravo,OU=The Boeing Company,OU=VeriSign\\, Inc.,OU=ECA,O=U.S. Government,C=US	-1		20	9	2	9	0	\N	\N	\N	3	\N	1	1
3216	1	michale.gardner@us.af.mil	Michale		Gardner	5	5759045252			CN=GARDNER.MICHALE.TIMOTHY.1271462170,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1271462170		6	3	3	12	0	\N	\N	\N	1	\N	0	2
3219	1	thornton.west@whmo.mil	Thornton		West	5	5714944730			CN=WEST.THORNTON.DOUGLAS.1365254920,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1365254920		6	17	3	80	0	\N	\N	\N	3	\N	0	\N
3220	0	chase.travis@usmc.mil	Chase		Travis	5	7607253052			CN=TRAVIS.CHASE.LAWRENCE.1411013207,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1411013207		5	28	3	8	0	\N	\N	\N	3	\N	0	1
3221	1	ferdinand.hooper@us.af.mil	Ferdinand		Hooper	4	5058531363	2531363		CN=HOOPER.FERDINAND.MIRABEL.1176699228,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1176699228		6	6	3	5	0	\N	\N	\N	1	\N	1	2
3222	1	irving.gutierrez.mx@usmc.mil	Irving		Gutierrez	5	3156363586	6363586		CN=GUTIERREZ.IRVING.NAHIM.1369504807,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1369504807		4	27	3	7	0	\N	\N	\N	3	\N	1	1
3224	1	john.j.spinelli@boeing.com	John		Spinelli	3	6105915142			CN=John Spinelli,OU=The Boeing Company,OU=VeriSign\\, Inc.,OU=ECA,O=U.S. Government,C=US	-1		20	9	2	9	0	\N	\N	\N	3	\N	1	1
3225	1	casey.grobelny@navy.mil	Casey		Grobelny	3	2524646156			CN=GROBELNY.CASEY.A.1515716307,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1515716307		21	10	1	18	0	\N	\N	\N	4	\N	0	\N
3226	1	matthew.cosner@navy.mil	Matthew		Cosner	3	2524646203			CN=COSNER.MATTHEW.E.1093488845,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1093488845		21	15	1	18	0	\N	\N	\N	3	\N	1	1
3229	1	jacob.gatliff@usmc.mil	Jacob		Gatliff	4	8585771318			CN=GATLIFF.JACOB.CHRISTOPHER.1502274127,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1502274127		3	23	3	4	0	\N	\N	\N	3	\N	1	1
3230	1	william.friend@usmc.mil	William		Friend	5	9104497374			CN=FRIEND.WILLIAM.ALLAN.1266873243,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1266873243		11	54	3	2	0	\N	\N	\N	3	\N	0	1
3235	1	roberts.fitzsimmons@usmc.mil	Robert		Fitzsimmons	5	8585778151			CN=FITZSIMMONS.ROBERT.JAMESHANLAN.1019182050,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1019182050		7	43	3	4	0	\N	\N	\N	3	\N	1	1
3236	1	ryan.guilfoy@usmc.mil	Ryan		Guilfoy	5	7574447818			CN=GUILFOY.RYAN.KENDALL.1269266313,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1269266313		6	149	3	79	0	\N	\N	\N	3	\N	1	1
3238	1	oliver.salder.uk@usmc.mil	Oliver		Salder	5	9282696869			CN=SALDER.OLIVER.JAMES.1237549933,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1237549933		7	62	3	6	0	\N	\N	\N	3	\N	1	1
3244	1	anthony.chiappetta@us.af.mil	Anthony		Chiappetta	5	8508812565	8812565		CN=CHIAPPETTA.ANTHONY.RAY.1277462970,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1277462970		6	2	3	11	0	\N	\N	\N	1	\N	1	2
3261	1	brenda.hathcock@navy.mil	Brenda		Hathcock	3	2524646665			CN=HATHCOCK.BRENDA.ANN.1454292754,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1454292754		20	10	1	18	0	\N	\N	\N	4	\N	1	1
3284	1	robert.north.2@us.af.mil	Robert		North	5	8508812682	6412682		CN=NORTH.ROBERT.C.JR.1040693102,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1060319371		7	2	3	11	0	\N	\N	\N	1	\N	1	2
3293	1	thomas.mcartor@usmc.mil	Thomas		Mcartor	1	5404467585			CN=MCARTOR.THOMAS.CARL.1396412809,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1396412809		5	54	3	2	0	\N	\N	\N	3	\N	0	1
3311	1	kenneth.lafauci@us.af.mil	Kenneth		Lafauci	5	5058467456			CN=LAFAUCI.KENNETH.ALAN.JR.1298544675,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1298544675		5	6	3	5	0	\N	\N	\N	1	\N	1	2
3314	1	levi.bither@usmc.mil	Levi		Bither	5	9104497228			CN=BITHER.LEVI.PATRICK.1416964935,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1141323233		4	25	3	2	0	\N	\N	\N	3	\N	1	1
3322	0	wesley.mciver@usmc.mil	Wesley		Mciver	4	8585776624			CN=MCIVER.WESLEY.ROY.1453939614,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1453939614		4	23	3	4	0	\N	\N	\N	3	\N	0	1
3335	1	randy.price@usmc.mil	Randy		Price	5	9282696875			CN=PRICE.RANDY.EARL.1367501665,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1367501665		5	62	3	6	0	\N	\N	\N	3	\N	0	\N
3359	1	bo.norman@navy.mil	Bo		Norman	2	2524648609	4518609		CN=NORMAN.BO.TRAVIS.1267159420,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1267159420		21	15	1	18	0	\N	\N	\N	4	\N	0	1
3367	1	darrell.l.stanley@boeing.com	Darrell		Stanley	5	2525148292			CN=Darrell Stanley,OU=The Boeing Company,OU=VeriSign\\, Inc.,OU=ECA,O=U.S. Government,C=USxx	1141323233		20	31	2	7	0	\N	\N	\N	3	\N	1	1
3370	0	koen.keith@usmc.mil	Koen		Keith	5	9104497228			CN=KEITH.KOEN.JEFFERSON.1455869680,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1455869680		4	25	3	2	0	\N	\N	\N	3	\N	0	1
3371	1	edgar.k.gutierrez@usmc.mil	Edgar		Gutierrezvillalta	5	9104497225			CN=GUTIERREZVILLALTA.EDGAR.KEVIN.1454198588,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1454198588		4	25	3	2	0	\N	\N	\N	3	\N	1	1
3400	1	daniel.westphal.ctr@usmc.mil	Daniel		Westphal	4	8082575487	4575487		CN=WESTPHAL.DANIEL.ROBERT.1095996562,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1095996562		21	24	2	81	0	\N	\N	\N	3	\N	0	\N
3414	1	amit.doshi.ctr@navy.mil	Amit		Doshi	3	3017570153			CN=DOSHI.AMIT.R.1378374959,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1378374959		20	38	2	9	0	\N	\N	\N	4	\N	1	2
3416	1	lucas.saavedra.1@us.af.mil	Lucas		Saavedra	3	5058535470	2535470		CN=SAAVEDRA.LUCAS.CHRISTOPHE.1183960217,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1183960217		7	6	1	5	0	\N	\N	\N	1	\N	1	2
3426	1	danielle.rogowski@navy.mil	Danielle		Rogowski	4	3019953696			CN=ROGOWSKI.DANIELLE.MARIE.1283425270,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1283425270		16	19	3	9	0	\N	\N	\N	1	\N	0	2
3430	1	thomas.beams@usmc.mil	Thomas		Beams	5	7608051755			CN=BEAMS.THOMAS.GEORGE.1283623129,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1283623129		6	55	3	81	0	\N	\N	\N	3	\N	0	\N
3439	1	michael.frenia@navy.mil	Michael		Frenia	5	9194495051	7515051		CN=FRENIA.MICHAEL.R.1229564613,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1229564613		21	10	1	2	0	\N	\N	\N	4	\N	0	2
3440	1	jmallwein1@gmail.com	Joshua		Allwein	5	6104204322			CN=ALLWEIN.JOSHUA.MICHAEL.1300409225,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1300409225		6	24	3	81	0	\N	\N	\N	4	\N	1	1
3443	0	ryan.ostrowski@us.af.mil	Ryan		Ostrowski	3	8508841313			CN=OSTROWSKI.RYAN.MICHEAL.1264558154,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1264558154		6	2	3	11	0	\N	\N	\N	1	\N	0	2
3461	1	elaine.wiegman.ctr@navy.mil	Elaine		Wiegman	4	3018636512			CN=WIEGMAN.ELAINE.L.1046831710,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1046831710		21	38	2	9	0	\N	\N	\N	4	\N	1	1
3465	1	james.fogel@usmc.mil	James		Fogel	5	9104495961			CN=FOGEL.JAMES.KENNETH.1037810912,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1037810912		8	51	3	2	0	\N	\N	\N	3	\N	1	1
3467	1	blake.tucker@usmc.mil	Blake		Tucker	5	5022190161	5774298		CN=TUCKER.BLAKE.ALEXANDER.1502986887,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1502986887		3	23	3	4	0	\N	\N	\N	3	\N	1	1
3470	1	samuel.c.garcia@usmc.mil	Samuel		Garcia	5	9092614731	4497224		CN=GARCIA.SAMUEL.CARRILLO.1256879626,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1256879626		6	25	3	2	0	\N	\N	\N	3	\N	1	1
3478	1	joseph.tharpe.1@us.af.mil	Joseph		Tharpe	5	5058467611	2467611		CN=THARPE.JOSEPH.GENE.1113754547,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1113754547		7	6	3	5	0	\N	\N	\N	1	\N	1	\N
3484	1	daniel.m.fletcher2@usmc.mil	Daniel		Fletcher	5	5183663454	7228011		CN=FLETCHER.DANIEL.MICHAEL.1254754133,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1254754133		7	54	3	2	0	\N	\N	\N	3	\N	0	\N
3488	1	james.charles@us.af.mil	James		Charles	5	5058466777	5058466		CN=CHARLES.JAMES.MICHAEL.1275862238,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1275862238		6	6	3	5	0	\N	\N	\N	1	\N	0	\N
3495	1	allen.lieber@usmc.mil	Allen		Lieber	5	8587615995	5778087		CN=LIEBER.ALLEN.JEFFREY.1270603897,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1270603897		6	48	3	4	0	\N	\N	\N	3	\N	0	\N
3497	1	james.e.garner@usmc.mil	James		Garner	5	9104495971	7525971		CN=GARNER.JAMES.ERICH.1239849446,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1239849446		11	51	3	2	0	\N	\N	\N	3	\N	1	\N
3505	1	austin.hathaway@usmc.mil	Austin		Hathaway	5	9104497252			CN=HATHAWAY.AUSTIN.WILLIAM.1465551620,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1287802451		3	25	3	2	0	\N	\N	\N	3	\N	0	\N
3508	1	charles.bartlett.3@us.af.mil	Charles		Bartlett	3	8508841313			CN=BARTLETT.CHARLES.VALENTINE.JR.1284166120,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1284166120		5	2	3	11	0	\N	\N	\N	1	\N	1	\N
3509	1	devin.guthrie@navy.mil	Devin		Guthrie	3	2424646282			CN=GUTHRIE.DEVIN.G.1028980694,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1028980694		20	10	1	17	0	\N	\N	\N	4	\N	1	\N
3514	1	michael.long2@navy.mil	Michael		Long	3	7323234212			CN=LONG.MICHAEL.JOSEPH.JR.1517656549,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1517656549		20	35	1	3	0	\N	\N	\N	4	\N	1	\N
3532	1	gary.holland.6@us.af.mil	Gary		Holland	5	5058535089	2535089		CN=HOLLAND.GARY.ALLEN.1136944408,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1136944408		7	6	1	5	0	\N	\N	\N	1	\N	1	\N
40	\N	jane.mcgrath@modapprover.org	Jane	H	McGrath	\N	1115551212	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2019-05-16 17:06:31.403728	\N	\N	\N	\N	1	\N
3533	1	marcelle.novak@navy.mil	Marcelle		Novak	3	2524646690			CN=NOVAK.MARCELLE.E.1091131311,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1091131311		20	15	1	18	0	\N	\N	\N	3	\N	0	\N
3268	1	eric.t.quigley@boeing.com	Eric		Quigley	3	6105917641			CN=QUIGLEY.ERIC.T.1025976920,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1025976920		20	9	2	18	0	\N	\N	\N	3	\N	0	\N
3272	1	steven.westerdale@us.af.mil	Steven		Westerdale	5	5757840919			CN=WESTERDALE.STEVEN.CRAIG.1364003150,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1364003150		5	3	3	12	0	\N	\N	\N	1	\N	1	2
3274	1	frank.eason@n-t-a.com	Frankie		Eason	3	2524445411			CN=EASON.FRANKIE.R.JR.1229777501,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1229777501		20	15	2	18	0	\N	\N	\N	3	\N	1	1
3298	1	gage.a.griffith@usmc.mil	Gage		Griffith	5	8585774298	5774298		CN=GRIFFITH.GAGE.ANDREW.1503236938,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1141323233		4	23	3	4	0	\N	\N	\N	3	\N	0	\N
3312	1	carl.kleinow@us.af.mil	Carl		Kleinow	5	5757847828			CN=KLEINOW.CARL.RICHARD.1286672252,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1286672252		7	3	3	12	0	\N	\N	\N	1	\N	1	2
3324	1	cameron.whyte@usmc.mil	Cameron		Whyte	5	3156363487			CN=WHYTE.CAMERON.COURTNEY.1467975621,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1467975621		4	27	3	7	0	\N	\N	\N	3	\N	0	1
3332	1	steven.a.hartman@usmc.mil	Steven		Hartman	5	8585771280	2671280		CN=HARTMAN.STEVEN.A.1187442482,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1187442482		7	60	3	4	0	\N	\N	\N	3	\N	1	1
3334	1	john.pilson@usmc.mil	John		Pilson	5	9104494331			CN=PILSON.JOHN.R.1250937489,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1250937489		7	61	3	2	0	\N	\N	\N	3	\N	0	\N
3340	1	luis.juarez@usmc.mil	Luis		Juarez	5	8585778694			CN=JUAREZ.LUIS.HUMBERTO.1271471838,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1271471838		7	23	3	4	0	\N	\N	\N	3	\N	0	\N
3342	1	joshua.g.webster@navy.mil	Joshua		Webster	3	2524649831			CN=WEBSTER.JOSHUA.G.1523082171,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1523082171		21	10	1	18	0	\N	\N	\N	4	\N	0	\N
3345	1	ricky.pate@usmc.mil	Ricky		Pate	5	9104495126			CN=PATE.RICKY.GLENN.1275035323,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1275035323		6	58	3	2	0	\N	\N	\N	3	\N	0	1
3346	1	christopher.habersha@usmc.mil	Christopher		Habershaw	5	9104495126			CN=HABERSHAW.CHRISTOPHER.ANDRE.1053443610,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1053443610		7	58	3	2	0	\N	\N	\N	3	\N	1	1
3360	1	kyle.bowler@us.af.mil	Kyle		Bowler	5	5058534765			CN=BOWLER.KYLE.ROBERT.1292333842,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1292333842		6	6	3	5	0	\N	\N	\N	1	\N	1	2
3365	1	tyler.tarr@usmc.mil	Tyler		Tarr	5	9104494683			CN=TARR.TYLER.ALLEN.1268075948,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1268075948		6	44	3	2	0	\N	\N	\N	3	\N	1	1
3366	0	jedidiah.larabee@usmc.mil	Jedidiah		Larabee	5	9104497121	7527121		CN=LARABEE.JEDIDIAH.JOSHUA.1267439750,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1267439750		10	49	3	2	0	\N	\N	\N	3	\N	0	1
3373	1	robert.beeton.3@us.af.mil	Robert		Beeton	4	8508814301	6414301		CN=BEETON.ROBERT.ANDREW.1110660363,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1110660363		20	15	1	11	0	\N	\N	\N	4	\N	0	2
3376	1	curtis.lowe@usmc.com	Curtis		Lowe	5	9104495643			CN=LOWE.CURTIS.RICHARD.1300282071,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1300282071		5	44	3	2	0	\N	\N	\N	3	\N	0	\N
3378	1	mark.oleksy@navy.mil	Mark		Oleksy	3	2524648634	4518634	2524646400	CN=OLEKSY.MARK.STANLEY.1091276034,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1091276034		20	10	1	18	0	\N	\N	\N	3	\N	0	1
3379	1	joel.warren@navy.mil	Joel		Warren	3	2524649113			CN=WARREN.JOEL.PHILLIP.1523846961,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1523846961		21	10	1	18	0	\N	\N	\N	4	\N	1	1
3380	1	kristopher.gonzalez@usmc.mil	Kristopher		Gonzalez	5	9104494357			CN=GONZALEZ.KRISTOPHER.ALLEN.1018540084,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1018540084		5	25	3	2	0	\N	\N	\N	3	\N	1	1
3381	1	judge@lhd6.navy.mil	Jamel		Judgeowens	5	3152523914			CN=JUDGEOWENS.JAMEL.SHAMEKE.1402736492,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1402736492		6	11	3	7	0	\N	\N	\N	4	\N	1	1
3392	1	michael.g.culbert@boeing.com	Michael		Culbert	3	6105919527	4569874563		CN=Michael Culbert,OU=The Boeing Company,OU=VeriSign\\, Inc.,OU=ECA,O=U.S. Government,C=US	1065484494		20	9	2	17	0	\N	\N	\N	3	\N	0	\N
3395	1	charles.a.winslow@usmc.mil	Charles		Winslow	5	9104496669			CN=WINSLOW.CHARLES.ATHOL.1368365250,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1368365250		5	61	3	2	0	\N	\N	\N	3	\N	1	1
3401	1	andrew.p.white@usmc.mil	Andrew		White	4	7607253562			CN=WHITE.ANDREW.PAUL.1399624068,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1399624068		5	28	3	8	0	\N	\N	\N	3	\N	1	1
3405	1	marshel.hargrove@usmc.mil	Marshel		Hargrove	3	8082571194			CN=HARGROVE.MARSHEL.LEEVAN.II.1392281653,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1392281653		5	24	3	81	0	\N	\N	\N	3	\N	1	1
3417	1	samuel.axtman@navy.mil	Samuel		Axtman	3	2524646263			CN=AXTMAN.SAMUEL.J.1525519143,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1525519143		20	10	1	18	0	\N	\N	\N	4	\N	1	1
3418	1	francisco.cortez@me.usmc.mil	Francisco		Cortezjasso	5	7605476106	3455277		CN=CORTEZJASSO.FRANCISCO.JAVIER.1267245610,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1267245610		6	56	3	4	0	\N	\N	\N	3	\N	1	1
3425	0	benjamin.goss@usmc.mil	Benjamin		Goss	5	9104496267			CN=GOSS.BENJAMIN.CHRISTOPHER.1460928750,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1460928750		3	25	3	2	0	\N	\N	\N	3	\N	0	1
3427	1	daniel.blocker@navy.mil	Daniel		Blocker	4	2524649824	4519824		CN=BLOCKER.DANIEL.KEITH.1126306845,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1126306845		6	15	1	18	0	\N	\N	\N	1	\N	1	2
3433	1	clinton.e.salter@navy.mil	Clinton		Salter	3	2524645339			CN=SALTER.CLINTON.E.JR.1243841409,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1243841409		20	10	1	18	0	\N	\N	\N	4	\N	0	1
3434	1	christopher.e.norman@usmc.mil	Christophe		Norman	5	8587407929	3658087		CN=NORMAN.CHRISTOPHE.ELLIOT.1272289227,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1272289227		6	28	3	8	0	\N	\N	\N	3	\N	1	1
3437	1	frederick.thomason@navy.mil	Frederick		Thomason	5	9104495424			CN=THOMASON.FREDERICK.I.JR.1229504602,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1229504602		21	10	1	11	0	\N	\N	\N	4	\N	0	\N
3438	1	david.e.pope@navy.mil	David		Pope	5	9104495708	7515708		CN=POPE.DAVID.E.1192399749,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1060319371		21	10	1	11	0	\N	\N	\N	4	\N	1	1
3453	1	david.gullick.ctr@navy.mil	David		Gullick	3	2405614519			CN=GULLICK.DAVID.RAY.1032094313,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1032094313		20	38	2	9	0	\N	\N	\N	1	\N	0	2
41	\N	jan.nolan@modteam.org	Jan		Nolan	\N	1115551212	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2019-05-16 17:08:55.160078	\N	\N	\N	\N	1	\N
3262	1	andrew.torres@usmc.mil	Andrew		Torres	5	8585776624			CN=TORRES.ANDREW.1367369244,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1367369244		5	23	3	4	0	\N	\N	\N	3	\N	0	\N
3264	1	megan.graf@us.af.mil	Megan		Graf	4	3084337595			CN=GRAF.MEGAN.VANESSA.1273642494,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1273642494		6	3	3	12	0	\N	\N	\N	1	\N	1	2
3266	1	ellick.wilson.ctr@navy.mil	Ellick		Wilson	3	2524646639			CN=WILSON.ELLICK.R.1229776009,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1229776009		21	10	2	18	0	\N	\N	\N	3	\N	1	1
3269	1	christopher.hurd.4@af.mil	Christopher		Hurd	5	5757847828			CN=HURD.CHRISTOPHER.J.1236894327,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1236894327		6	3	3	12	0	\N	\N	\N	1	\N	1	2
3270	0	gabriel.arrieta@usmc.mil	Gabriel		Arrieta	5	7607253262			CN=ARRIETA.GABRIEL.1405128108,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1405128108		5	28	3	8	0	\N	\N	\N	3	\N	0	1
3276	1	thomas.woloszyk@us.af.mil	Thomas		Woloszyk	5	3122382456	2382456		CN=WOLOSZYK.THOMAS.ANTHONY.1276270075,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1276270075		7	4	3	13	0	\N	\N	\N	1	\N	1	2
3281	1	matthew.dalton@usmc.mil	Matthew		Dalton	5	9104497228			CN=DALTON.MATTHEW.THOMAS.1469936895,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1469936895		3	25	3	2	0	\N	\N	\N	3	\N	1	1
3282	1	jon.hutchison@usmc.mil	Jon		Hutchison	5	7607630576			CN=HUTCHISON.JON.BRYAN.1410448552,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1410448552		4	46	3	8	0	\N	\N	\N	3	\N	0	1
3292	1	richard.j.ytzen@boeing.com	Richard		Ytzen	5	8586927204			CN=Richard Ytzen,OU=BOEING,OU=VeriSign\\, Inc.,OU=ECA,O=U.S. Government,C=US	1141323233		20	31	2	8	0	\N	\N	\N	3	\N	1	1
3308	1	jeremie.baldwin.1@us.af.mil	Jeremie		Baldwin	5	5058533490	2633490		CN=BALDWIN.JEREMIE.W.1110742904,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1110742904		7	6	3	5	0	\N	\N	\N	1	\N	1	2
3326	1	keven.snyder@navy.mil	Keven		Snyder	3	2524645685			CN=SNYDER.KEVEN.M.1251892128,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1251892128		20	15	1	18	0	\N	\N	\N	4	\N	0	1
3338	1	james.fortenberry@us.af.mil	James		Fortenberry	5	3142386143	2386143		CN=FORTENBERRY.JAMES.MATTHEW.1115151483,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1060319371		6	4	3	13	0	\N	\N	\N	1	\N	1	2
3341	1	raymond.chamberlain@us.af.mil	Raymond		Chamberlain	5	8508815007	6415007		CN=CHAMBERLAIN.RAYMOND.LEE.1118455386,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1118455386		6	2	3	11	0	\N	\N	\N	1	\N	0	2
3344	1	karl.w.moheiser@gmail.com	Karl		Moheiser	4	2524646859			CN=MOHEISER.KARL.WILLIAM.1092667410,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1092667410		21	10	1	17	0	\N	\N	\N	3	\N	0	1
3353	1	david.wachs@navy.mil	David		Wachs	5	2524645573	4515573		CN=WACHS.DAVID.G.1040836744,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1065484494		20	10	1	18	0	\N	\N	\N	3	\N	0	\N
3355	1	kenneth.flores@us.af.mil	Kenneth		Flores	5	8508841313			CN=FLORES.KENNETH.JOEL.1255198528,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1255198528		6	2	3	11	0	\N	\N	\N	1	\N	1	2
3356	1	joe.quintero@usmc.mil	Joe		Quintero	5	9104495643			CN=QUINTERO.JOE.JESSIE.JR.1174141750,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1174141750		6	25	3	2	0	\N	\N	\N	3	\N	1	1
3362	1	william.hood.1@us.af.mil	William		Hood	5	3142384613			CN=HOOD.WILLIAM.LARRY.1290112512,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1290112512		6	4	3	13	0	\N	\N	\N	1	\N	0	\N
3368	1	v327mxgqa@us.af.mil	Keaton		Manshaem	5	5757840919			CN=MANSHAEM.KEATON.CHARLES.1383251709,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1383251709		5	3	3	12	0	\N	\N	\N	1	\N	0	2
3383	0	kenneth.johnson.28@us.af.mil	Kenneth		Johnson	5	8505822258			CN=JOHNSON.KENNETH.G.1052153219,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1052153219		6	6	3	5	0	\N	\N	\N	1	\N	0	2
3389	0	james.w.parker@usmc.mil	James		Parker	5	9105468691			CN=PARKER.JAMES.WILLIAM.1287858627,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1287858627		6	149	3	79	0	\N	\N	\N	3	\N	0	1
3398	0	kayla.lopez@usmc.mil	Kayla		Lopez	5	8082571084			CN=LOPEZ.KAYLA.MISHELL.1405128060,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1405128060		5	24	3	81	0	\N	\N	\N	3	\N	0	1
3406	0	gabirel.donovan@usmc.mil	Gabriel		Donovan	3	8082571194			CN=DONOVAN.GABRIEL.LOUIS.1410933540,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1410933540		5	24	3	81	0	\N	\N	\N	4	\N	0	1
3420	0	matthew.belser@navy.mil	Matthew		Belser	3	2524646171			CN=BELSER.MATTHEW.S.1144683494,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1141323233		20	10	1	18	0	\N	\N	\N	4	\N	0	2
3429	1	adrian.dorsman.1.ctr@us.af.mil	Adrian		Dorsman	5	8508813669			CN=DORSMAN.ADRIAN.K.II.1139382770,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1139382770		20	33	2	11	0	\N	\N	\N	1	\N	1	2
3436	1	william.pearce@navy.mil	William		Pearce	5	2524647592			CN=PEARCE.WILLIAM.J.JR.1229505250,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1060319371		21	10	1	11	0	\N	\N	\N	4	\N	1	2
3447	1	david.j.jankowski@boeing.com	David		Jankowski	5	2524445648			CN=David Jankowski,OU=The Boeing Company,OU=VeriSign\\, Inc.,OU=ECA,O=U.S. Government,C=US	-1		21	10	2	18	0	\N	\N	\N	3	\N	0	\N
3454	1	anthony.novelly@usmc.mil	Anthony		Novelly	5	9104496870			CN=NOVELLY.ANTHONY.VINCENT.1456298806,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1456298806		5	44	3	2	0	\N	\N	\N	3	\N	0	1
3459	1	philip.a.bell@navy.mil	Philip		Bell	3	2524646258			CN=BELL.PHILIP.A.1525518350,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1525518350		21	10	1	18	0	\N	\N	\N	3	\N	0	1
3464	1	nicholas.j.harrel@usmc.mil	Nicholas		Harrel	1	9105541950			CN=HARREL.NICHOLAS.JAMES.1266124976,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1266124976		6	49	3	2	0	\N	\N	\N	3	\N	0	\N
3473	1	vance.baumer@whmo.mil	Vance		Baumer	5	5714944753			CN=BAUMER.VANCE.MATTHEW.1145594657,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1145594657		8	17	3	80	0	\N	\N	\N	3	\N	0	\N
3477	1	christopher.cook.14@us.af.mil	Christopher		Cook	4	5757845029			CN=COOK.CHRISTOPHER.A.1082162379,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1082162379		7	3	3	12	0	\N	\N	\N	1	\N	1	\N
3479	1	andre.l.johnson@usmc.mil	Andre		Johnson	5	8582573656			CN=JOHNSON.ANDRE.LAVAL TYLER.1143765977,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1143765977		10	55	3	81	0	\N	\N	\N	3	\N	0	\N
3480	1	jpimentel@bh.com	Jeremy		Pimentel	3	8585776833			CN=PIMENTEL.JEREMY.RUBEN.1298072811,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1141323233		21	31	2	4	0	\N	\N	\N	3	\N	0	\N
3487	1	michael.p.williams1@usmc.mil	Michael		Williams	4	7607255871	7607255		CN=WILLIAMS.MICHAEL.PATRICK.1463032609,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1463032609		4	28	3	8	0	\N	\N	\N	3	\N	1	\N
42	\N	charles.walsh@modteam.org	Charles	\N	Walsh	\N	1115551212	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2019-05-16 17:09:16.745487	\N	\N	\N	\N	1	\N
3263	1	gary.karlson@us.af.mil	Gary		Karlson	1	5058535593	2635593		CN=KARLSON.GARY.LEON.JR.1250591337,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1060319371		7	6	3	5	0	\N	\N	\N	1	\N	1	2
3271	1	sikhan.chin@usmc.mil	Sikhan		Chin	5	3156366206	6366206		CN=CHIN.SIKHAN.ELIJAH.1235601415,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1235601415		12	50	3	7	0	\N	\N	\N	3	\N	0	\N
3273	1	marquis.little@usmc.mil	Marquis		Little	5	7574445453			CN=LITTLE.MARQUIS.NATHANIEL.1246103964,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1246103964		5	149	3	79	0	\N	\N	\N	3	\N	1	1
3295	1	richard.d.ricardo@boeing.com	Richard		Ricardo	3	6105918755			CN=Richard.D.Ricardo.163506,OU=people,O=boeing,C=us	1141323233		20	9	2	17	0	\N	\N	\N	3	\N	0	\N
3297	1	matthew.sentore@usmc.mil	Matthew		Sentore	5	3156362763			CN=SENTORE.MATTHEW.NICHOLAS.1501605685,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1501605685		3	27	3	7	0	\N	\N	\N	3	\N	0	\N
3307	1	david.k.dennis@usmc.mil	David		Dennis	5	9104495126			CN=DENNIS.DAVID.KEITH.1269890033,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1269890033		6	58	3	2	0	\N	\N	\N	3	\N	0	1
3309	1	brandon.delgado@usmc.mil	Brandon		Delgado	5	8082572513			CN=DELGADO.BRANDON.KYLE.1169587244,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1133281564		5	24	3	81	0	\N	\N	\N	3	\N	0	1
3316	1	noah.wu@usmc.mil	Noah		Wu	3	8082570084			CN=WU.NOAH.SONG.1398220664,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1398220664		5	24	3	81	0	\N	\N	\N	3	\N	1	1
3317	1	chase.lennon.ctr@navy.mil	Chase		Lennon	5	3019954632			CN=LENNON.CHASE.ALEXANDER.1275242752,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1275242752		21	39	2	9	0	\N	\N	\N	3	\N	1	1
3336	1	daniel.j.myers2@usmc.mil	Daniel		Myers	5	3156367655			CN=MYERS.DANIEL.JAMES.1379756529,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1379756529		5	53	3	7	0	\N	\N	\N	3	\N	0	\N
3348	1	donald.c.devor1@navy.mil	Donald		Devor	4	2524647986	4517986		CN=DEVOR.DONALD.CLAIR.III.1038774375,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1038774375		21	10	1	18	0	\N	\N	\N	4	\N	0	\N
3361	1	benjamin.westbrook@us.af.mil	Benjamin		Westbrook	5	3142383690			CN=WESTBROOK.BENJAMIN.RAY.1061845077,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1061845077		5	4	3	13	0	\N	\N	\N	1	\N	0	\N
3369	1	erik.werhner@usmc.mil	Erik		Werhner	4	9104497266	752		CN=WERHNER.ERIK.J.1029371756,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1029371756		8	25	3	2	0	\N	\N	\N	3	\N	1	1
3374	1	thomas.colville@usmc.mil	Thomas		Colville	5	9104497252			CN=COLVILLE.THOMAS.JOSEPH.1458509715,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1458509715		4	25	3	2	0	\N	\N	\N	3	\N	0	\N
3385	1	zackary.barnard@navy.mil	Zackary		Barnard	3	2524646116	4516116		CN=BARNARD.ZACKARY.LANDON.1523846902,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1523846902		21	15	1	18	0	\N	\N	\N	4	\N	0	\N
3386	1	rodney.hose.ctr@navy.mil	Rodney		Hose	5	2524645544			CN=HOSE.RODNEY.D.1043651818,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1043651818		20	10	2	18	0	\N	\N	\N	4	\N	1	1
3387	1	daniel.mier@us.af.mil	Daniel		Mier	4	8508847621	5797621		CN=MIER.DANIEL.L.1099209212,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1099209212		7	2	3	11	0	\N	\N	\N	1	\N	1	2
3399	1	david.a.murray@usmc.mil	David		Murray	5	8082572513			CN=MURRAY.DAVID.A.1293442785,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1293442785		5	24	3	81	0	\N	\N	\N	4	\N	1	1
3411	1	gerald.vosburg@navy.mil	Gerald		Vosburg	3	2524646173			CN=VOSBURG.GERALD.R.1523846970,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1523846970		21	10	1	18	0	\N	\N	\N	3	\N	1	1
3424	1	rocky.rodriguez@usmc.mil	Rocky		Rodriguez	5	3156363744			CN=RODRIGUEZ.ROCKY.1396239619,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1396239619		5	27	3	7	0	\N	\N	\N	3	\N	1	1
3441	1	jacob.silva@usmc.mil	Jacob		Silva	5	7607253994			CN=SILVA.JACOB.GEORGE.1287355765,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1287355765		6	28	3	8	0	\N	\N	\N	3	\N	1	1
3442	1	jason.morris@usmc.mil	Jason		Morris	5	7607253994			CN=MORRIS.JASON.CHARLES.1288350910,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1288350910		6	28	3	8	0	\N	\N	\N	3	\N	1	1
3450	1	stonej@lhd6.navy.mil	Joshua		Stone	5	4045362070			CN=STONE.JOSHUA.KEITH.1453935279,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1453935279		4	10	3	18	0	\N	\N	\N	3	\N	1	1
3455	1	captain.mullins@usmc.mil	Captain		Mullins	5	9104497363			CN=MULLINS.CAPTAIN.BRACK.JR.1103149386,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1103149386		8	54	3	2	0	\N	\N	\N	3	\N	1	1
3458	1	john.hendrick.1@us.af.mil	John		Hendrick	3	5759045248	6405248		CN=HENDRICK.JOHN.ALAN.1023007491,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1023007491		20	3	1	12	0	\N	\N	\N	1	\N	0	2
3463	1	ryan.bullock@navy.mil	Ryan		Bullock	4	2524649583	4519583	2524648566	CN=BULLOCK.RYAN.ASHELY.1265338395,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1141323233		20	15	1	18	0	\N	\N	\N	4	\N	0	\N
3468	1	larry.villafana@usmc.mil	Larry		Villafana	5	9495723838			CN=VILLAFANA.LARRY.JOHN.1460513223,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1460513223		4	27	3	7	0	\N	\N	\N	3	\N	1	1
3476	1	brandon.darke@whmo.mil	Brandon		Darke	5	5714944729			CN=DARKE.BRANDON.CHRISTOPHER.1131856098,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1131856098		6	17	3	80	0	\N	\N	\N	3	\N	0	\N
3489	1	timothy.sampley@usmc.mil	Timothy		Sampley	5	8585778155			CN=SAMPLEY.TIMOTHY.SCOT.II.1264711769,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1264711769		6	43	3	4	0	\N	\N	\N	3	\N	1	\N
3493	1	jerrod.hammes@usmc.mil	Jerrod		Hammes	5	8585778075			CN=HAMMES.JERROD.CHRISTOPHER.1082923426,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1082923426		16	48	3	4	0	\N	\N	\N	3	\N	0	\N
3499	1	brandon.m.jackson@boeing.com	Brandon		Jackson	1	8587806027			CN=Brandon.M.Jackson.1834895,OU=people,O=boeing,C=us	1133281564		20	9	2	4	0	\N	\N	\N	3	\N	1	\N
3501	1	robyn.kanter@navy.mil	Robyn		Kanter	4	3013426726	3426826		CN=KANTER.ROBYN.H.1239711355,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1239711355		21	38	1	9	0	\N	\N	\N	4	\N	0	\N
3503	1	salvatore.cialino@usmc.mil	Salvatore		Cialino	5	8585778151	2678151		CN=CIALINO.SALVATORE.JR.1384359694,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1384359694		5	43	3	4	0	\N	\N	\N	3	\N	1	\N
3507	1	abraham.vallejo@us.af.mil	Abraham		Vallejo	2	5058465143			CN=VALLEJO.ABRAHAM.UNK.1295119132,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1295119132		5	6	3	5	0	\N	\N	\N	1	\N	1	\N
3491	1	tara.netayavichitr@usmc.mil	Tara		Netayavichitr	5	8585778092			CN=NETAYAVICHITR.TARA.1276749524,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1276749524		6	48	3	4	0	\N	\N	\N	3	\N	0	\N
3287	1	timothy.b.moore1@navy.mil	Timothy		Moore	1	6195453528			CN=MOORE.TIMOTHY.BRIAN.1116343793,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1116343793		21	14	1	6	0	\N	\N	\N	4	\N	1	1
3299	1	zachary.lott.1@us.af.mil	Zachary		Lott	5	8508841310	5791310		CN=LOTT.ZACHARY.BRIAN.1291654955,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1291654955		5	2	3	11	0	\N	\N	\N	1	\N	1	2
3310	1	cody.j.smith@usmc.mil	Cody		Smith	5	9104496267	7526267		CN=SMITH.CODY.JACOB.1503236733,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1503236733		3	25	3	2	0	\N	\N	\N	3	\N	1	1
3315	1	florencio.montanez@usmc.mil	Florencio		Montanez	5	8585776624			CN=MONTANEZ.FLORENCIO.JR.1471956364,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1471956364		3	23	3	4	0	\N	\N	\N	3	\N	0	\N
3318	0	tyler.shumaker@usmc.mil	Tyler		Shumaker	5	8082572513			CN=SHUMAKER.TYLER.RICHARD.1399469798,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1399469798		5	24	3	81	0	\N	\N	\N	3	\N	0	1
3330	1	travis.e.jones@usmc.mil	Travis		Jones	5	9104496870			CN=JONES.TRAVIS.EDRIS.1404378593,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1404378593		4	44	3	2	0	\N	\N	\N	3	\N	0	\N
3347	1	saul.moreno@usmc.mil	Saul		Moreno	5	3156366239			CN=MORENO.SAUL.1242981460,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1242981460		6	50	3	7	0	\N	\N	\N	3	\N	0	\N
3351	1	rodger.hibbard@usmc.mil	Rodger		Hibbard	5	7607253562	3613562		CN=HIBBARD.RODGER.JAMES.1289923205,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1289923205		6	28	3	8	0	\N	\N	\N	3	\N	1	1
3352	1	louis.poreider@usmc.mil	Louis		Poreider	5	9104496267			CN=POREIDER.LOUIS.EUGENE.IV.1459395730,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1459395730		4	25	3	2	0	\N	\N	\N	3	\N	1	2
3384	1	virginia.nethercutt@navy.mil	Virginia		Nethercutt	4	2524648529	4518529		CN=NETHERCUTT.VIRGINIA.DARLENE.1282019937,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1282019937		21	10	1	18	0	\N	\N	\N	4	\N	1	1
3402	1	jason.spruiell1@usmc.mil	Jason		Spruiell	3	8082571194			CN=SPRUIELL.JASON.DAVID.1279866874,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1279866874		5	24	3	81	0	\N	\N	\N	4	\N	1	1
3408	1	brandon.capley@us.af.mil	Brandon		Capley	5	8508841309	5791309		CN=CAPLEY.BRANDON.THOMAS.1368276835,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1368276835		5	2	3	11	0	\N	\N	\N	1	\N	0	2
3412	1	besmir.feka@usmc.mil	Besmir		Feka	5	8082571424			CN=FEKA.BESMIR.1469936933,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1469936933		3	24	3	81	0	\N	\N	\N	3	\N	1	1
3422	1	alfredo.sepulveda@usmc.mil	Alfredo		Sepulvedacolon	5	7872482292			CN=SEPULVEDACOLON.ALFREDO.JAVIER.1402898042,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1402898042		5	51	3	2	0	\N	\N	\N	3	\N	1	1
3423	1	abraham.velezrivera@usmc.mil	Abraham		Velezrivera	5	7607254754			CN=VELEZRIVERA.ABRAHAM.JUNIOR.1293830998,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1293830998		6	28	3	8	0	\N	\N	\N	3	\N	1	1
3445	1	james.w.becker@boeing.com	James		Becker	1	8588373084			CN=BECKER.JAMES.W.1250088368,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1141323233		20	31	2	4	0	\N	\N	\N	3	\N	0	\N
3446	1	christopher.sanford@usmc.mil	Christopher		Sanford	5	9104496412	7526412		CN=SANFORD.CHRISTOPHER.CHARLES.1122344238,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1122344238		11	49	3	2	0	\N	\N	\N	3	\N	0	1
3451	0	luis.murillovargas@usmc.mil	Luis		Murillovargas	5	2092779950			CN=MURILLOVARGAS.LUIS.ANGEL.1411043017,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1411043017		5	23	3	4	0	\N	\N	\N	3	\N	0	1
3457	1	matthew.sinsel@navy.mil	Matthew		Sinsel	5	2524648589			CN=SINSEL.MATTHEW.BERNARD.1233460601,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1233460601		20	10	1	18	0	\N	\N	\N	4	\N	0	2
3462	1	christian.martin.1@us.af.mil	Christian		Martin	5	5752190498	6812319		CN=MARTIN.CHRISTIAN.MATTHEW.1055749309,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1055749309		7	3	3	12	0	\N	\N	\N	1	\N	0	\N
3469	1	seungchul.roh@usmc.mil	Seungchul		Roh	4	9104497252			CN=ROH.SEUNGCHUL.1468209159,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1468209159		4	25	3	2	0	\N	\N	\N	3	\N	0	1
3475	1	justin.spritzer@us.af.mil	Justin		Spritzer	5	8508815007	6415007		CN=SPRITZER.JUSTIN.EDWARD.1261021915,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1261021915		6	2	3	11	0	\N	\N	\N	1	\N	1	\N
3485	1	jeremy.williams@usmc.mil	Jeremy		Williams	5	3183455286			CN=WILLIAMS.JEREMY.CLINTEL.1267924160,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1267924160		6	47	3	6	0	\N	\N	\N	3	\N	1	\N
3490	1	ericjay.garcia@usmc.mil	Ericjay		Garcia	5	7607250779	3650779		CN=GARCIA.ERICJAY.KONA.1150722116,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1150722116		6	28	3	8	0	\N	\N	\N	3	\N	1	\N
3492	1	willie.bostic@usmc.mil	Willie		Bostic	5	9104496419			CN=BOSTIC.WILLIE.JAMES.JR.1262067390,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1262067390		4	49	3	2	0	\N	\N	\N	3	\N	1	\N
3494	1	theirrien.davis@usmc.mil	Theirrien		Davis	5	8585778087	5778087		CN=DAVIS.THEIRRIEN.RAPHAEL.1461997143,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1461997143		5	48	3	4	0	\N	\N	\N	3	\N	1	\N
3506	1	jimmy.potter.2.ctr@us.af.mil	Jimmy		Potter	5	5058467435	2467435		CN=POTTER.JIMMY.HR.1108210350,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1108210350		20	20	2	5	0	\N	\N	\N	1	\N	1	\N
3513	1	maxim.lazoutchenkov@navy.mil	Maxim		Lazoutchenkov	3	7323237284			CN=LAZOUTCHENKOV.MAXIM.1514102283,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1514102283		20	35	1	3	0	\N	\N	\N	4	\N	0	\N
3515	1	gloria.wu@navy.mil	Gloria		Wu	3	7323235264			CN=WU.GLORIA.1512156130,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1512156130		21	35	1	3	0	\N	\N	\N	4	\N	1	\N
3523	1	adam.nalder@usmc.mil	Adam		Nalder	5	3156367657			CN=NALDER.ADAM.JOHN.1267095791,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1267095791		6	53	3	7	0	\N	\N	\N	3	\N	1	\N
3520	1	timothy.paterson@navy.mil	Timothy		Paterson	4	2524648231	451823		CN=PATERSON.TIMOTHY.ROBERT.1186333833,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1186333833		20	10	1	18	0	\N	\N	\N	4	\N	1	\N
3521	1	leobardo.cegueda@usmc.mil	Leobardo		Cegueda	5	9104497252			CN=CEGUEDA.LEOBARDO.III.1469327740,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1469327740		3	25	3	2	0	\N	\N	\N	3	\N	0	\N
3526	1	thomas.asplund@usmc.mil	Thomas		Asplund	5	5202271822			CN=ASPLUND.THOMAS.ERIC.1092417383,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1092417383		3	28	3	8	0	\N	\N	\N	3	\N	1	\N
3531	1	myron.burrows.ctr@navy.mil	Myron		Burrows	4	2524646219			CN=BURROWS.MYRON.R.1024668360,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1024668360		20	10	2	18	0	\N	\N	\N	4	\N	1	\N
3542	1	rodrigo.hernandezpol@navy.mil	Rodrigo		Hernandezpolindara	5	9104495710			CN=HERNANDEZPOLINDARA.RODRIGO.ALONSO.1292949924,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1292949924		6	41	3	2	0	\N	\N	\N	3	\N	1	\N
3549	1	george.graves@navy.mil	George		Graves	5	3017575550			CN=GRAVES.GEORGE.REUBEN.III.1117542552,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1117542552		21	38	1	9	0	\N	\N	\N	4	\N	1	\N
3550	1	toby.hansenbrown@navy.mil	Toby		Hansen-Brown	5	3017572965			CN=HANSEN-BROWN.TOBY.C.1501755369,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1501755369		20	40	2	9	0	\N	\N	\N	4	\N	1	\N
3555	1	robert.w.kirk@navy.mil	Robert		Kirk	3	2524646968			CN=KIRK.ROBERT.WILLIAM.III.1384613906,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1384613906		21	10	1	17	0	\N	\N	\N	4	\N	1	\N
3561	1	clinton.duclos@usmc.mil	Clinton		Duclos	5	7167773682	6363245		CN=DUCLOS.CLINTON.JOHN.1233636122,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1233636122		7	50	3	7	0	\N	\N	\N	3	\N	1	\N
3554	1	anthony.mccalpin@us.af.mil	Anthony		Mccalpin	5	5058535089	35089		CN=MCCALPIN.ANTHONY.JAMES.1287399649,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1141323233		5	20	3	5	0	\N	\N	\N	1	\N	0	\N
3565	1	benjamin.glenn@us.af.mil	Benjamin		Glenn	2	3142381862	2381862		CN=GLENN.BENJAMIN.SCOTT.1387595887,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1387595887		5	4	3	13	0	\N	\N	\N	1	\N	1	\N
3541	1	jesse.meno@us.af.mil	Jesse		Meno	4	8508844990	5794990		CN=MENO.JESSE.D.1184796771,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1184796771		9	8	3	11	0	\N	\N	\N	1	\N	1	\N
3559	1	austin.m.lewis@usmc.mil	Austin		Lewis	5	8585776624			CN=LEWIS.AUSTIN.MICHAEL.1459200165,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1459200165		4	23	3	4	0	\N	\N	\N	3	\N	1	\N
3567	1	john.hannah.1@us.af.mil	John		Hannah	5	5058467990	2467990		CN=HANNAH.JOHN.B.1058520400,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1058520400		8	6	3	5	0	\N	\N	\N	1	\N	1	\N
3560	0	destin.lett@usmc.mil	Destin		Lett	5	3343980021			CN=LETT.DESTIN.TODD.1460082893,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1460082893		4	23	3	4	0	\N	\N	\N	3	\N	0	\N
3548	1	sung.m.kim@navy.mil	Sung		Kim	3	9104490013			CN=KIM.SUNG.MIN.1270032059,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1270032059		20	10	1	18	0	\N	\N	\N	4	\N	1	\N
3551	1	michael.zier@navy.mil	Michael		Zier	3	2524646240			CN=ZIER.MICHAEL.J.1525518104,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1525518104		21	15	1	18	0	\N	\N	\N	4	\N	1	\N
3543	1	amie.sparnell@navy.mil	Amie		Sparnell	3	2524646152			CN=SPARNELL.AMIE.A.1394878142,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1394878142		21	15	1	18	0	\N	\N	\N	3	\N	0	\N
3544	1	jpimentel@bh.com	Jeremy		Pimentel	5	8582459987	5776833		CN=PIMENTEL.JEREMY.RUBEN.1298072811,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US11	1133281564		21	31	2	4	0	\N	\N	\N	3	\N	1	\N
3546	1	drew.w.phillips@usmc.mil	Drew		Phillips	5	9104497226			CN=PHILLIPS.DREW.WILLIAM.1411144611,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1411144611		5	25	3	2	0	\N	\N	\N	3	\N	1	\N
3547	1	kristopher.n.turner@usmc.mil	Kristopher		Turner	5	9104497252			CN=TURNER.KRISTOPHER.NOAHKOHL.1510348083,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1510348083		3	25	3	2	0	\N	\N	\N	3	\N	1	\N
3553	1	scott.r.porter@usmc.mil	Scott		Porter	5	8585779400			CN=PORTER.SCOTT.RUSSELL.1400420684,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1400420684		5	60	3	4	0	\N	\N	\N	3	\N	1	\N
3558	1	danny.hare.ctr@navy.mil	Danny		Hare	4	2527207969			CN=HARE.DANNY.MACK.1185447940,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1185447940		20	10	2	18	0	\N	\N	\N	4	\N	1	\N
3562	1	jacob.leckie@usmc.mil	Jacob		Leckie	5	3156366230			CN=LECKIE.JACOB.MATTHEW.1395164933,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1395164933		15	50	3	7	0	\N	\N	\N	3	\N	1	\N
3563	0	andrew.ohlrich@lhd1.navy.mil	Andrew		Ohlrich	5	9104497073			CN=OHLRICH.ANDREW.R.1249318864,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1249318864		11	52	3	2	0	\N	\N	\N	3	\N	0	\N
3566	1	gamal.meyers@navy.mil	Ga'Mal		Meyers	3	2524646248			CN=MEYERS.GA'MAL.Q.1057774823,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1057774823		21	10	1	17	0	\N	\N	\N	3	\N	1	\N
3545	1	jared.brady@usmc.mil	Jared		Brady	5	9104495661	7525661		CN=BRADY.JARED.WESLEY.1272943202,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1272943202		20	61	2	2	0	\N	\N	\N	3	\N	1	\N
3552	1	holly.ramirez.ctr@navy.mil	Holly		Ramirez	5	3017570314			CN=RAMIREZ.HOLLY.K.1134056726,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1134056726		20	40	2	9	0	\N	\N	\N	4	\N	1	\N
3556	1	robert.crims@usmc.mil	Robert		Crims	5	8082571191			CN=CRIMS.ROBERT.LEE.1247526141,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1247526141		7	24	3	81	0	\N	\N	\N	3	\N	1	\N
3557	1	johan.cotto@usmc.mil	Johan		Cotto	5	4132414747			CN=COTTO.JOHAN.ALBERTO.1396410695,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1396410695		5	57	3	8	0	\N	\N	\N	3	\N	1	\N
3564	1	garrett.hurtt@usmc.mil	Garrett		Hurtt	5	9104497226			CN=HURTT.GARRETT.ALEXANDER.1387728100,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1387728100		5	25	3	2	0	\N	\N	\N	3	\N	1	\N
3568	1	josh.wetlesen@usmc.mil	Josh		Wetlesen	5	8585776624			CN=WETLESEN.JOSH.RAY.1461783119,OU=USMC,OU=PKI,OU=DoD,O=U.S. Government,C=US	1461783119		4	23	3	4	0	\N	\N	\N	3	\N	1	\N
3572	1	bob@bob.com	Travis		Makarowski	4	2524646396			CN=MAKAROWSKI.TRAVIS.W.1141323233xd,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1065484494		19	159	2	17	0	\N	\N	\N	2	\N	0	\N
3574	1	travis.maka@navy.mil	Travis		Makarowski	1	2343455432			CN=MAKAROWSKI.TRAVIS.W.1141323233x,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	-1		4	3	1	18	0	\N	\N	\N	2	\N	0	\N
2	1	david.abbott.16@us.af.mil	David		Test	5	5058537389	2637389113	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1	\N
3573	1	steven.groninga@navy.mil	Steven		Groninga	4	2527208500			CN=GRONINGA.STEVEN.CHARLES.1065484494,OU=USN,OU=PKI,OU=DoD,O=U.S. Government,C=US	1065484494		12	10	1	18	0	\N	\N	\N	2	\N	0	\N
6	\N	dave.tdtracker1@email.com	Dave		Tdtracker1	\N		\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2018-12-07 23:37:29.847	\N	\N	\N	\N	1	\N
7	\N	donna.tdtracker2	Donna	\N	Tdtracker2	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2018-12-07 18:39:39.899019	\N	\N	\N	\N	1	\N
8	\N	sean.tdtracker3@email.com	Sean	\N	Tdtracker3	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2018-12-07 18:40:00.711216	\N	\N	\N	\N	1	\N
9	\N	superuser.tdtrackeradmin@email.com	Superuser		Tdtrackeradmin	\N		\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2018-12-07 19:12:40.507562	\N	\N	\N	\N	1	\N
4	\N	blah.blahblah@email.com	Blah	A	Blahblah	\N	1231231234	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2018-12-09 05:18:50.651	\N	\N	\N	\N	1	\N
15	\N	smanager2@navy.mil	Sue	B	Manager2	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2019-02-28 01:53:18.479	\N	\N	\N	\N	1	\N
16	\N	gmanager3@navy.mil	Guy	C	Manager3	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2019-02-28 01:53:40.896	\N	\N	\N	\N	1	\N
2174	1	david.abbott.16@us.af.mil	David		Abbott	5	5058537389	2637389113		CN=ABBOTT.DAVID.J.1248049800,OU=USAF,OU=PKI,OU=DoD,O=U.S. Government,C=US	1065484494	ABBOTT.DAVID.J	20	6	1	5	0	\N	\N	\N	1	\N	0	\N
33	\N	matt.bailey@fsr.mil	Matt	A	Bailey	\N	111-555-1212	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2019-05-16 19:14:55.885	\N	\N	\N	\N	1	\N
3	1	testing.test.16@us.af.mil	Testing	Q	Test	5	1112223333	9999999999	\N	CN=TEST.TESTING.Q.12345,OU=Contractor,OU=PKI,OU=Dod,O=U.S. Government,C=US	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1	\N
11	\N	fred.projecttasks2@squadron.mil	Fred	Q	Projecttasks2	\N	567-111-2234	\N	\N	CN=PROJECTTASKS2.FRED.Q.12345,OU=Contractor,OU=PKI,OU=Dod,O=U.S. Government,C=US	\N	\N	\N	\N	\N	\N	\N	2018-12-08 05:19:02.917	\N	\N	\N	\N	1	\N
3575	1	geoff.marshal.ctr@navy.mil	Geoff		Marshall	4	252-464-8744			CN=MARSHALL.GEOFFREY.EDWARD.1510036804,OU=CONTRACTOR,OU=PKI,OU=DoD,O=U.S. Government,C=US	1065484494		12	10	1	18	0	\N	\N	\N	2	\N	0	\N
10	\N	bob.projecttasks1@squadron.mil	Bob		Projecttasks1	\N	(111)555-1212	\N	\N	CN=PROJECTTASKS1.BOB.12345,OU=Contractor,OU=PKI,OU=Dod,O=U.S. Government,C=US	\N	\N	\N	\N	\N	\N	\N	2018-12-08 10:18:31.758	\N	\N	\N	\N	1	\N
13	\N	root.projecttasks4@navy.mil	Root	\N	Projecttasks4	\N	333-123-3333	\N	\N	CN=PROJECTTASKS4.ROOT.12345,OU=Contractor,OU=PKI,OU=Dod,O=U.S. Government,C=US	\N	\N	\N	\N	\N	\N	\N	2018-12-08 05:20:47.477	\N	\N	\N	\N	1	\N
12	\N	chris.projecttasks@squadron.mil	Chris	A	Projecttasks3	\N	123-111-1234	\N	\N	CN=PROJECTTASKS3.CHRIS.A.12345,OU=Contractor,OU=PKI,OU=Dod,O=U.S. Government,C=US	\N	\N	\N	\N	\N	\N	\N	2018-12-08 05:19:29.179	\N	\N	\N	\N	1	\N
\.


--
-- Data for Name: workflow_actions; Type: TABLE DATA; Schema: app; Owner: appowner
--

COPY app.workflow_actions (id, name, description, active, appid, jsondata, createdat, updatedat) FROM stdin;
\.


--
-- Data for Name: workflow_states; Type: TABLE DATA; Schema: app; Owner: appowner
--

COPY app.workflow_states (id, name, description, statusid, workflowstatusid, appid, issuetypeid, jsondata, initialstate, createdat, updatedat) FROM stdin;
\.


--
-- Data for Name: workflow_statetransitions; Type: TABLE DATA; Schema: app; Owner: appowner
--

COPY app.workflow_statetransitions (id, actionid, stateinid, stateoutid, label, appid, jsondata, createdat, updatedat, allowedroles) FROM stdin;
\.


--
-- Data for Name: workflow_status; Type: TABLE DATA; Schema: app; Owner: appowner
--

COPY app.workflow_status (id, name, description, createdat, updatedat, appid, jsondata) FROM stdin;
\.


--
-- Data for Name: actions; Type: TABLE DATA; Schema: metadata; Owner: appowner
--

COPY metadata.actions (name, id) FROM stdin;
navigate	1
clear	2
update	3
query	4
loadedit	5
loaddetail	6
userattachments	7
relatedrecord	8
\.


--
-- Data for Name: apiactions; Type: TABLE DATA; Schema: metadata; Owner: appowner
--

COPY metadata.apiactions (id, name, description) FROM stdin;
2	email	Send email to a list of recipients
3	debug	Debugger action for testing
1	database	Create database record as history or archive
4	log	Write a log record
\.


--
-- Data for Name: appcolumns; Type: TABLE DATA; Schema: metadata; Owner: appowner
--

COPY metadata.appcolumns (id, apptableid, columnname, label, datatypeid, length, jsonfield, createdat, updatedat, mastertable, mastercolumn, name, masterdisplay, displayorder, active, allowedroles, allowededitroles) FROM stdin;
\.


--
-- Data for Name: applications; Type: TABLE DATA; Schema: metadata; Owner: appowner
--

COPY metadata.applications (id, name, shortname, description) FROM stdin;
0	System		Application Factory System
\.


--
-- Data for Name: appqueries; Type: TABLE DATA; Schema: metadata; Owner: appowner
--

COPY metadata.appqueries (id, procname, appid, schema, description, createdat, updatedat, name, params) FROM stdin;
\.


--
-- Data for Name: apptables; Type: TABLE DATA; Schema: metadata; Owner: appowner
--

COPY metadata.apptables (id, appid, label, tablename, description, createdat, updatedat) FROM stdin;
\.


--
-- Data for Name: columntemplate; Type: TABLE DATA; Schema: metadata; Owner: appowner
--

COPY metadata.columntemplate (id, tablename, label, datatypeid, length, jsonfield, mastertable, mastercolumn, name, masterdisplay, columnname) FROM stdin;
1	activity	Label	7	128	f	\N	\N	\N	\N	label
2	activity	Description	7	128	f	\N	\N	\N	\N	description
3	issuetypes	Label	7	128	f	\N	\N	\N	\N	label
4	issuetypes	Description	7	128	f	\N	\N	\N	\N	description
5	priority	Label	7	128	f	\N	\N	\N	\N	label
6	priority	Description	7	128	f	\N	\N	\N	\N	description
7	status	Label	7	128	f	\N	\N	\N	\N	label
8	status	Description	7	128	f	\N	\N	\N	\N	description
9	userapp	User	1	\N	f	\N	\N	\N	\N	userid
10	users	First Name	7	100	f	\N	\N	\N	\N	firstname
11	users	Last Name	7	100	f	\N	\N	\N	\N	lastname
17	priority	ID	1	\N	f	\N	\N	\N	\N	id
18	activity	ID	1	\N	f	\N	\N	\N	\N	id
19	issuetypes	ID	1	\N	f	\N	\N	\N	\N	id
20	issues	ID	1	\N	f	\N	\N	\N	\N	id
21	status	ID	1	\N	f	\N	\N	\N	\N	id
22	userapp	ID	1	\N	f	\N	\N	\N	\N	id
23	users	ID	1	\N	f	\N	\N	\N	\N	id
25	masterdata	Name	7	60	f	\N	\N	\N	\N	name
26	masterdata	Description	7	1000	f	\N	\N	\N	\N	description
24	masterdata	ID	1	\N	f	\N	\N	\N	\N	id
27	masterdata	Table ID	1	\N	f	apptables	id	\N	\N	apptableid
28	appdata	Table ID	1	\N	f	apptables	id	\N	\N	apptableid
29	appdata	ID	1	\N	f	\N	\N	\N	\N	id
30	appdata	JSON data	5	\N	t	\N	\N	\N	\N	jsondata
34	issues	JSON data	5	\N	t	\N	\N	\N	\N	jsondata
13	issues	Subject	7	1000	f	\N	\N	\N	\N	subject
32	roleassignments	ID	1	\N	f	\N	\N	\N	\N	id
38	appbunos	ID	1	\N	f	\N	\N	\N	\N	id
39	appbunos	Buno ID	1	\N	f	bunos	id	\N	identifier	bunoid
40	bunos	ID	1	\N	f	\N	\N	\N	\N	id
41	bunos	Identifier	7	40	f	\N	\N	\N	\N	identifier
42	bunos	Description	7	128	f	\N	\N	\N	\N	description
43	masterdata	JSON data	5	\N	t	\N	\N	\N	\N	jsondata
44	issuetypes	JSON data	5	\N	t	\N	\N	\N	\N	jsondata
45	status	JSON data	5	\N	t	\N	\N	\N	\N	jsondata
46	workflow_status	Name	7	20	f	\N	\N	\N	\N	name
47	workflow_status	Description	7	20	f	\N		\N	\N	description
48	workflow_status	ID	1	\N	f	\N	\N	\N	\N	id
49	workflow_actions	ID	1	\N	f	\N	\N	\N	\N	id
50	workflow_actions	Name	7	100	f	\N	\N	\N	\N	name
51	workflow_actions	Description	7	128	f	\N		\N	\N	description
52	workflow_statetransitions	ID	1	\N	f	\N	\N	\N	\N	id
53	workflow_statetransitions	Label	7	100	f	\N	\N	\N	\N	label
54	workflow_statetransitions	Action ID	1	\N	f	workflow_actions	id	\N	workflow_actions.name	actionid
55	workflow_statetransitions	State In ID	1	\N	f	workflow_states	id	\N	workflow_states.name	stateinid
56	workflow_statetransitions	State Out ID	1	\N	f	workflow_states	id	\N	workflow_states.name	stateoutid
57	workflow_states	ID	1	\N	f	\N	\N	\N	\N	id
58	workflow_states	Name	7	50	f	\N	\N	\N	\N	name
59	workflow_states	Description	7	1000	f	\N	\N	\N	\N	description
60	workflow_states	Status ID	1	\N	f	status	id	\N	status.label	statusid
61	workflow_states	Workflows Status ID	1	\N	f	workflow_status	id	\N	workflow_status.name	workflowstatusid
62	workflow_states	Issue Type ID	1	\N	f	issuetypes	id	\N	issuetypes.label	issuetypeid
65	activity	JSON data	5	\N	t	\N	\N	\N	\N	jsondata
66	workflow_states	JSON data	5	\N	t	\N	\N	\N	\N	jsondata
67	workflow_states	Initial State	3	\N	f	\N	\N	\N	\N	initialstate
15	issues	Priority	1	\N	f	priority	id	\N	label	priorityid
16	issues	Status	1	\N	f	status	id	\N	label	statusid
14	issues	Activity	1	\N	f	activity	id	\N	label	activityid
68	priority	JSON data	5	\N	t	\N	\N	\N	\N	jsondata
12	issues	Issue Type	1	100	f	issuetypes	id	\N	label	issuetypeid
69	roles	ID	1	\N	f	\N	\N	\N	\N	id
70	roles	Name	7	60	f	\N	\N	\N	\N	name
71	roles	Description	7	256	f	\N	\N	\N	\N	description
\.


--
-- Data for Name: controltypes; Type: TABLE DATA; Schema: metadata; Owner: appowner
--

COPY metadata.controltypes (id, controlname, multiselect, datatypeid) FROM stdin;
1	select	f	1
2	label	f	2
\.


--
-- Data for Name: datatypes; Type: TABLE DATA; Schema: metadata; Owner: appowner
--

COPY metadata.datatypes (id, name) FROM stdin;
1	integer
2	text
3	boolean
4	decimal
5	json
6	timestamp
7	varchar
8	varchar[]
9	integer[]
\.


--
-- Data for Name: events; Type: TABLE DATA; Schema: metadata; Owner: appowner
--

COPY metadata.events (id, name, "description ") FROM stdin;
1	add	\N
2	edit	\N
3	delete	\N
4	load	\N
5	submit	\N
6	goto	Simple navigation to another page
7	gotoDataItem	Save a specified data element for editing and navigate to another page.
\.


--
-- Data for Name: fieldcategories; Type: TABLE DATA; Schema: metadata; Owner: appowner
--

COPY metadata.fieldcategories (id, name, label) FROM stdin;
1	issues	Issues
2	workflow	Workflow
\.


--
-- Data for Name: formeventactions; Type: TABLE DATA; Schema: metadata; Owner: appowner
--

COPY metadata.formeventactions (id, eventid, actionid, actiondata, pageformid, reporttemplateid) FROM stdin;
\.


--
-- Data for Name: formresources; Type: TABLE DATA; Schema: metadata; Owner: appowner
--

COPY metadata.formresources (id, title, tablename, description, apipath, createdat, updatedat, specialprocessing, formid, appcolumnid, appid) FROM stdin;
\.


--
-- Data for Name: images; Type: TABLE DATA; Schema: metadata; Owner: appowner
--

COPY metadata.images (id, appid, url) FROM stdin;
\.


--
-- Data for Name: menuicons; Type: TABLE DATA; Schema: metadata; Owner: appowner
--

COPY metadata.menuicons (id, icon, iconname) FROM stdin;
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
-- Data for Name: menuitems; Type: TABLE DATA; Schema: metadata; Owner: appowner
--

COPY metadata.menuitems (id, parentid, label, iconid, appid, pageid, active, "position", pathid, routerpath) FROM stdin;
6	\N	Help	18	0	8	1	6	1	\N
1	\N	Dashboard	6	0	4	1	2	1	\N
2	\N	Home	11	0	1	1	1	1	\N
5	\N	Support	26	0	7	1	5	1	\N
3	\N	Applications	27	0	0	1	3	1	apps
4	\N	Administration	9	0	0	1	4	1	\N
162	4	Application Bunos	9	0	76	1	3	10	appbunos
41	4	Menu Maintenance	\N	0	0	1	5	10	sysadmin
45	44	Applications	\N	0	36	1	1	10	appmaint
44	4	App Maintenance	\N	0	0	1	4	10	\N
46	44	Pages	\N	0	37	1	2	10	pagemaint
131	4	User / Role Maintenance	\N	0	0	1	6	10	\N
130	44	App Resources	\N	0	75	1	6	10	appresources
133	131	User Maintenance	\N	0	76	1	1	10	usermaint
134	131	Group Maintenance	\N	0	76	1	2	10	groupmaint
137	131	Role Maintenance	\N	0	76	1	3	10	rolemaint
118	4	Lookup Tables	9	0	68	1	2	10	lookuptable
120	44	Form Actions	\N	0	70	1	4	10	actionmaint
33	4	Form Builder	9	0	29	1	1	10	formbuilder
111	44	Tables & Columns	\N	0	77	\N	3	10	tablemaint
172	44	Server Request Actions	\N	0	78	1	5	10	requestactionmaint
43	41	Menu Tree	\N	0	35	1	5	10	menutree
36	4	App Access Request	9	0	30	1	7	10	appaccessrequest
\.


--
-- Data for Name: menupaths; Type: TABLE DATA; Schema: metadata; Owner: appowner
--

COPY metadata.menupaths (syspath, sysname, shortname, id) FROM stdin;
/	root	Main	1
/apps	apps	Applications	2
/apps/vtamp	vtamp	VTAMP	3
/apps/ecp	ecp	ECP	4
/apps/dcn	dcn	DCN	5
/apps/vtamp/admin	admin	VTAMP Admin	6
/apps/dcn/admin	admin	DCN Admin	8
/apps/ecp/admin	admin	ECP Admin	7
/apps/vtamp/reports	reports	VTAMP Reports	9
/Administration	sysadmin	Form Builder	10
/Administration/contact	sysadmincontact	Admin Contact	11
/apps/testapp	testapp	Test App	12
/Administration/menu	sysadminmenu	Menu Maintenance	13
\.


--
-- Data for Name: pageforms; Type: TABLE DATA; Schema: metadata; Owner: appowner
--

COPY metadata.pageforms (id, pageid, jsondata, createdat, updatedat, systemcategoryid, appcolumnid, description) FROM stdin;
18	1	{"components": [{"id": "emrhfm", "key": "textField", "mask": false, "type": "textfield", "input": true, "label": "Text Field", "hidden": false, "prefix": "", "suffix": "", "unique": false, "dbIndex": false, "tooltip": "", "disabled": false, "multiple": false, "tabindex": "", "validate": {"custom": "", "pattern": "", "maxWords": "", "minWords": "", "required": false, "maxLength": "", "minLength": "", "customPrivate": false}, "autofocus": false, "hideLabel": false, "inputMask": "", "inputType": "text", "protected": false, "tableView": true, "errorLabel": "", "labelWidth": 30, "persistent": true, "validateOn": "change", "clearOnHide": true, "conditional": {"eq": "", "show": null, "when": null}, "customClass": "", "description": "", "labelMargin": 3, "placeholder": "", "defaultValue": null, "dataGridLabel": false, "labelPosition": "top", "calculateValue": "", "customDefaultValue": ""}, {"id": "eah2di8", "key": "submit", "size": "md", "type": "button", "block": false, "input": true, "label": "Submit", "theme": "primary", "action": "submit", "hidden": false, "prefix": "", "suffix": "", "unique": false, "dbIndex": false, "tooltip": "", "disabled": false, "leftIcon": "", "multiple": false, "tabindex": "", "validate": {"custom": "", "required": false, "customPrivate": false}, "autofocus": false, "hideLabel": false, "protected": false, "rightIcon": "", "tableView": true, "errorLabel": "", "labelWidth": 30, "persistent": false, "validateOn": "change", "clearOnHide": true, "conditional": {"eq": "", "show": null, "when": null}, "customClass": "", "description": "", "labelMargin": 3, "placeholder": "", "defaultValue": null, "dataGridLabel": true, "labelPosition": "top", "calculateValue": "", "disableOnInvalid": true, "customDefaultValue": ""}]}	2018-08-09 20:06:36.487981	2018-08-09 20:06:36.487981	\N	\N	\N
29	1	{"components": [{"id": "e1uiyjn", "key": "htmlelement", "tag": "p", "mask": false, "type": "htmlelement", "attrs": [{"attr": "", "value": ""}], "input": false, "label": "", "hidden": false, "prefix": "", "suffix": "", "unique": false, "content": "Simple Page <br/>\\n<br/>\\nWith Custom Component", "dbIndex": false, "tooltip": "", "disabled": false, "multiple": false, "tabindex": "", "validate": {"custom": "", "required": false, "customPrivate": false}, "autofocus": false, "className": "", "hideLabel": false, "protected": false, "tableView": true, "errorLabel": "", "labelWidth": 30, "persistent": false, "validateOn": "change", "clearOnHide": true, "conditional": {"eq": "", "show": null, "when": null}, "customClass": "", "description": "", "labelMargin": 3, "placeholder": "", "defaultValue": null, "dataGridLabel": false, "labelPosition": "top", "calculateValue": "", "refreshOnChange": false, "customDefaultValue": ""}, {"id": "euxhscr", "key": "myBtn", "mask": false, "size": "lg", "type": "customcomponent", "block": false, "input": true, "label": "My Custom Component", "theme": "warning", "action": "submit", "hidden": false, "prefix": "", "suffix": "", "unique": false, "dbIndex": false, "tooltip": "", "disabled": false, "leftIcon": "", "multiple": false, "tabindex": "", "validate": {"custom": "", "required": false, "customPrivate": false}, "autofocus": false, "hideLabel": false, "protected": false, "rightIcon": "", "tableView": true, "errorLabel": "", "labelWidth": 30, "persistent": false, "validateOn": "change", "clearOnHide": true, "conditional": {"eq": "", "show": null, "when": null}, "customClass": "", "description": "", "labelMargin": 3, "placeholder": "", "defaultValue": null, "dataGridLabel": true, "labelPosition": "top", "calculateValue": "", "disableOnInvalid": false, "customDefaultValue": ""}, {"id": "e6xcskc", "key": "submit", "size": "md", "type": "button", "block": false, "input": true, "label": "Submit", "theme": "primary", "action": "submit", "hidden": false, "prefix": "", "suffix": "", "unique": false, "dbIndex": false, "tooltip": "", "disabled": false, "leftIcon": "", "multiple": false, "tabindex": "", "validate": {"custom": "", "required": false, "customPrivate": false}, "autofocus": false, "hideLabel": false, "protected": false, "rightIcon": "", "tableView": true, "errorLabel": "", "labelWidth": 30, "persistent": false, "validateOn": "change", "clearOnHide": true, "conditional": {"eq": "", "show": null, "when": null}, "customClass": "", "description": "", "labelMargin": 3, "placeholder": "", "defaultValue": null, "dataGridLabel": true, "labelPosition": "top", "calculateValue": "", "disableOnInvalid": true, "customDefaultValue": ""}]}	2018-08-17 15:47:42.089989	2018-08-17 15:47:42.089989	\N	\N	\N
\.


--
-- Data for Name: pages; Type: TABLE DATA; Schema: metadata; Owner: appowner
--

COPY metadata.pages (id, appid, title, name, description, allowedroles, helppath) FROM stdin;
4	0	Dashboard	dashboard	system dashboard	\N	\N
8	0	Help	help	system help	\N	\N
7	0	Support	support	system support	\N	\N
1	0	Home	home	system home	\N	\N
6	0	Administration	administration	system administration	\N	\N
0	0	NONE	nopage	empty page	\N	\N
31	0	Create Change Request	websiteissues	Admin website issues	\N	\N
37	0	Page Maintenance	pagemaint	Page maintainance page	{36}	\N
34	0	Menu Item Maintenance	menumaint	Add/Edit Menu Item	{36}	\N
35	0	Menu Tree	menutree	Show menu items as a tree	{36}	\N
70	0	Form Actions Maintenance	actionmaint	Form actions maintenance	{36}	\N
68	0	Lookup Table Maintenance	lookuptable	Lookup table record maintenance by application.	{36}	\N
29	0	Form Builder	formbuilder	Form Builder Page	{36}	\N
75	0	Application Resources	appresources	Application Resource Maintenance	{36}	\N
76	0	Application Users	appusers	Application users maintenance	{36}	\N
36	0	Application Maintenance	appmaint	Application maintainance page	{36}	\N
77	0	Table and Column Maintenance	tablemaint	Application Table and Columns Maintenance	{36}	\N
78	0	Server Actions Maitenance	serveractionmaint	Application server actions maintenance	{36}	\N
30	0	App Access Request	appaccessrequest	Application access request	\N	\N
\.


--
-- Data for Name: systemcategories; Type: TABLE DATA; Schema: metadata; Owner: appowner
--

COPY metadata.systemcategories (id, name, description, prefix) FROM stdin;
1	issues	Issue related procedures	issues
2	workflow	Workflow related procedures	workflow
3	users	User related procedures	users
4	cms	Content Management related procedures	cms
5	activity	Activity related procedures	activity
6	status	Status related procedures	status
7	priority	Priority related procedures	priority
8	issuetype	Issue Types related procedures	issuetypes
\.


--
-- Data for Name: systemtables; Type: TABLE DATA; Schema: metadata; Owner: appowner
--

COPY metadata.systemtables (id, label, tablename, description, systemtabletypeid) FROM stdin;
3	Issues	issues	Application issue data.	2
9	Users	users	System users.	1
6	Priorities	priority	Application priority types.	1
7	Status	status	Application status types.	1
4	Issue Types	issuetypes	Application issue types.	1
2	Custom	appdata	Data that is not supported in other tables.	3
5	Master Table	masterdata	Custom lookup data not supported in other tables.	4
1	Activities	activity	Application activity types.	1
8	Application Users	roleassignments	Application user links.	1
10	App Bunos	appbunos	Application buno numbers.	1
11	Bunos	bunos	Buno numbers.	1
13	Workflow States	workflow_states	Workflow states.	1
14	Workflow Actions	workflow_actions	Workflow actions.	1
15	Workflow Transitions	workflow_statetransitions	Workflow state transitions.	1
16	Workflow Status	workflow_status	Workflow additional statuses.	1
18	Roles	roles	Application roles.	1
\.


--
-- Data for Name: systemtabletypes; Type: TABLE DATA; Schema: metadata; Owner: appowner
--

COPY metadata.systemtabletypes (id, name, label) FROM stdin;
1	lookup	Lookup Table
2	issue	Issue Table
3	customTable	Custom Table
4	customLookup	Custom Lookup
\.


--
-- Data for Name: urlactions; Type: TABLE DATA; Schema: metadata; Owner: appowner
--

COPY metadata.urlactions (id, url, apiactionid, actiondata, appid, pre, post, method, description, pageformid, template) FROM stdin;
\.


--
-- Name: activities_id_seq; Type: SEQUENCE SET; Schema: app; Owner: appowner
--

SELECT pg_catalog.setval('app.activities_id_seq', 88, true);


--
-- Name: adhoc_queries_id_seq; Type: SEQUENCE SET; Schema: app; Owner: appowner
--

SELECT pg_catalog.setval('app.adhoc_queries_id_seq', 59, true);


--
-- Name: appbunos_id_seq; Type: SEQUENCE SET; Schema: app; Owner: appowner
--

SELECT pg_catalog.setval('app.appbunos_id_seq', 1078, true);


--
-- Name: appdata_id_seq; Type: SEQUENCE SET; Schema: app; Owner: appowner
--

SELECT pg_catalog.setval('app.appdata_id_seq', 1405, true);


--
-- Name: appdataattachments_id_seq; Type: SEQUENCE SET; Schema: app; Owner: appowner
--

SELECT pg_catalog.setval('app.appdataattachments_id_seq', 158, true);


--
-- Name: attachments_id_seq; Type: SEQUENCE SET; Schema: app; Owner: appowner
--

SELECT pg_catalog.setval('app.attachments_id_seq', 196, true);


--
-- Name: bunos_id_seq; Type: SEQUENCE SET; Schema: app; Owner: appowner
--

SELECT pg_catalog.setval('app.bunos_id_seq', 4469, true);


--
-- Name: dashboardreport_id_seq; Type: SEQUENCE SET; Schema: app; Owner: appowner
--

SELECT pg_catalog.setval('app.dashboardreport_id_seq', 1, true);


--
-- Name: groups_id_seq; Type: SEQUENCE SET; Schema: app; Owner: appowner
--

SELECT pg_catalog.setval('app.groups_id_seq', 18, true);


--
-- Name: issueattachments_id_seq; Type: SEQUENCE SET; Schema: app; Owner: appowner
--

SELECT pg_catalog.setval('app.issueattachments_id_seq', 1, false);


--
-- Name: issues_id_seq; Type: SEQUENCE SET; Schema: app; Owner: appowner
--

SELECT pg_catalog.setval('app.issues_id_seq', 402, true);


--
-- Name: issuetypes_id_seq; Type: SEQUENCE SET; Schema: app; Owner: appowner
--

SELECT pg_catalog.setval('app.issuetypes_id_seq', 39, true);


--
-- Name: mastertypes_id_seq; Type: SEQUENCE SET; Schema: app; Owner: appowner
--

SELECT pg_catalog.setval('app.mastertypes_id_seq', 832, true);


--
-- Name: priority_id_seq; Type: SEQUENCE SET; Schema: app; Owner: appowner
--

SELECT pg_catalog.setval('app.priority_id_seq', 14, true);


--
-- Name: reporttemplates_id_seq; Type: SEQUENCE SET; Schema: app; Owner: appowner
--

SELECT pg_catalog.setval('app.reporttemplates_id_seq', 4, true);


--
-- Name: resourcetypes_id_seq; Type: SEQUENCE SET; Schema: app; Owner: appowner
--

SELECT pg_catalog.setval('app.resourcetypes_id_seq', 1, false);


--
-- Name: roleassignments_id_seq; Type: SEQUENCE SET; Schema: app; Owner: appowner
--

SELECT pg_catalog.setval('app.roleassignments_id_seq', 95, true);


--
-- Name: rolepermissions_id_seq; Type: SEQUENCE SET; Schema: app; Owner: appowner
--

SELECT pg_catalog.setval('app.rolepermissions_id_seq', 1, false);


--
-- Name: roles_id_seq; Type: SEQUENCE SET; Schema: app; Owner: appowner
--

SELECT pg_catalog.setval('app.roles_id_seq', 41, true);


--
-- Name: status_id_seq; Type: SEQUENCE SET; Schema: app; Owner: appowner
--

SELECT pg_catalog.setval('app.status_id_seq', 45, true);


--
-- Name: support_id_seq; Type: SEQUENCE SET; Schema: app; Owner: appowner
--

SELECT pg_catalog.setval('app.support_id_seq', 16, true);


--
-- Name: userattachments_id_seq; Type: SEQUENCE SET; Schema: app; Owner: appowner
--

SELECT pg_catalog.setval('app.userattachments_id_seq', 190, true);


--
-- Name: usergroups_id_seq; Type: SEQUENCE SET; Schema: app; Owner: appowner
--

SELECT pg_catalog.setval('app.usergroups_id_seq', 49, true);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: app; Owner: appowner
--

SELECT pg_catalog.setval('app.users_id_seq', 42, true);


--
-- Name: workflow_actionresponse_id_seq; Type: SEQUENCE SET; Schema: app; Owner: appowner
--

SELECT pg_catalog.setval('app.workflow_actionresponse_id_seq', 30, true);


--
-- Name: workflow_actions_id_seq; Type: SEQUENCE SET; Schema: app; Owner: appowner
--

SELECT pg_catalog.setval('app.workflow_actions_id_seq', 39, true);


--
-- Name: workflow_states_id_seq; Type: SEQUENCE SET; Schema: app; Owner: appowner
--

SELECT pg_catalog.setval('app.workflow_states_id_seq', 107, true);


--
-- Name: workflow_statetransitions_id_seq; Type: SEQUENCE SET; Schema: app; Owner: appowner
--

SELECT pg_catalog.setval('app.workflow_statetransitions_id_seq', 218, true);


--
-- Name: actions_id_seq; Type: SEQUENCE SET; Schema: metadata; Owner: appowner
--

SELECT pg_catalog.setval('metadata.actions_id_seq', 8, true);


--
-- Name: apiactions_id_seq; Type: SEQUENCE SET; Schema: metadata; Owner: appowner
--

SELECT pg_catalog.setval('metadata.apiactions_id_seq', 4, true);


--
-- Name: appcolumns_id_seq; Type: SEQUENCE SET; Schema: metadata; Owner: appowner
--

SELECT pg_catalog.setval('metadata.appcolumns_id_seq', 552, true);


--
-- Name: applications_id_seq; Type: SEQUENCE SET; Schema: metadata; Owner: appowner
--

SELECT pg_catalog.setval('metadata.applications_id_seq', 76, true);


--
-- Name: appquery_id_seq; Type: SEQUENCE SET; Schema: metadata; Owner: appowner
--

SELECT pg_catalog.setval('metadata.appquery_id_seq', 1, true);


--
-- Name: apptables_id_seq; Type: SEQUENCE SET; Schema: metadata; Owner: appowner
--

SELECT pg_catalog.setval('metadata.apptables_id_seq', 128, true);


--
-- Name: columntemplate_id_seq; Type: SEQUENCE SET; Schema: metadata; Owner: appowner
--

SELECT pg_catalog.setval('metadata.columntemplate_id_seq', 71, true);


--
-- Name: controltypes_id_seq; Type: SEQUENCE SET; Schema: metadata; Owner: appowner
--

SELECT pg_catalog.setval('metadata.controltypes_id_seq', 2, true);


--
-- Name: datatypes_id_seq; Type: SEQUENCE SET; Schema: metadata; Owner: appowner
--

SELECT pg_catalog.setval('metadata.datatypes_id_seq', 9, true);


--
-- Name: events_id_seq; Type: SEQUENCE SET; Schema: metadata; Owner: appowner
--

SELECT pg_catalog.setval('metadata.events_id_seq', 7, true);


--
-- Name: fieldcategories_id_seq; Type: SEQUENCE SET; Schema: metadata; Owner: appowner
--

SELECT pg_catalog.setval('metadata.fieldcategories_id_seq', 2, true);


--
-- Name: formeventactions_id_seq; Type: SEQUENCE SET; Schema: metadata; Owner: appowner
--

SELECT pg_catalog.setval('metadata.formeventactions_id_seq', 272, true);


--
-- Name: formresources_id_seq; Type: SEQUENCE SET; Schema: metadata; Owner: appowner
--

SELECT pg_catalog.setval('metadata.formresources_id_seq', 51, true);


--
-- Name: images_id_seq; Type: SEQUENCE SET; Schema: metadata; Owner: appowner
--

SELECT pg_catalog.setval('metadata.images_id_seq', 1, false);


--
-- Name: issues_id_seq; Type: SEQUENCE SET; Schema: metadata; Owner: appowner
--

SELECT pg_catalog.setval('metadata.issues_id_seq', 1, false);


--
-- Name: menuicons_id_seq; Type: SEQUENCE SET; Schema: metadata; Owner: appowner
--

SELECT pg_catalog.setval('metadata.menuicons_id_seq', 28, true);


--
-- Name: menuitems_id_seq; Type: SEQUENCE SET; Schema: metadata; Owner: appowner
--

SELECT pg_catalog.setval('metadata.menuitems_id_seq', 200, true);


--
-- Name: menupaths_id_seq; Type: SEQUENCE SET; Schema: metadata; Owner: appowner
--

SELECT pg_catalog.setval('metadata.menupaths_id_seq', 13, true);


--
-- Name: pageforms_id_seq; Type: SEQUENCE SET; Schema: metadata; Owner: appowner
--

SELECT pg_catalog.setval('metadata.pageforms_id_seq', 82, true);


--
-- Name: pages_id_seq; Type: SEQUENCE SET; Schema: metadata; Owner: appowner
--

SELECT pg_catalog.setval('metadata.pages_id_seq', 119, true);


--
-- Name: systemcategories_id_seq; Type: SEQUENCE SET; Schema: metadata; Owner: appowner
--

SELECT pg_catalog.setval('metadata.systemcategories_id_seq', 8, true);


--
-- Name: systemtables_id_seq; Type: SEQUENCE SET; Schema: metadata; Owner: appowner
--

SELECT pg_catalog.setval('metadata.systemtables_id_seq', 18, true);


--
-- Name: systemtabletypes_id_seq; Type: SEQUENCE SET; Schema: metadata; Owner: appowner
--

SELECT pg_catalog.setval('metadata.systemtabletypes_id_seq', 4, true);


--
-- Name: urlactions_id_seq; Type: SEQUENCE SET; Schema: metadata; Owner: appowner
--

SELECT pg_catalog.setval('metadata.urlactions_id_seq', 23, true);


--
-- Name: adhoc_queries_id_seq; Type: SEQUENCE SET; Schema: public; Owner: appowner
--

SELECT pg_catalog.setval('public.adhoc_queries_id_seq', 1, false);


--
-- Name: activity activities_pkey; Type: CONSTRAINT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.activity
    ADD CONSTRAINT activities_pkey PRIMARY KEY (id);


--
-- Name: adhoc_queries adhoc_queries_pk; Type: CONSTRAINT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.adhoc_queries
    ADD CONSTRAINT adhoc_queries_pk PRIMARY KEY (id);


--
-- Name: adhoc_queries adhoc_queries_pk_2; Type: CONSTRAINT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.adhoc_queries
    ADD CONSTRAINT adhoc_queries_pk_2 UNIQUE (appid, name);


--
-- Name: appbunos appbunos_pk; Type: CONSTRAINT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.appbunos
    ADD CONSTRAINT appbunos_pk PRIMARY KEY (id);


--
-- Name: appdata appdata_pkey; Type: CONSTRAINT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.appdata
    ADD CONSTRAINT appdata_pkey PRIMARY KEY (id);


--
-- Name: attachments attachments_pkey; Type: CONSTRAINT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.attachments
    ADD CONSTRAINT attachments_pkey PRIMARY KEY (id);


--
-- Name: bunos bunos_pk; Type: CONSTRAINT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.bunos
    ADD CONSTRAINT bunos_pk PRIMARY KEY (id);


--
-- Name: dashboardreports dashboardreport_pk; Type: CONSTRAINT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.dashboardreports
    ADD CONSTRAINT dashboardreport_pk PRIMARY KEY (id);


--
-- Name: groups groups_pkey; Type: CONSTRAINT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.groups
    ADD CONSTRAINT groups_pkey PRIMARY KEY (id);


--
-- Name: issueattachments issueattachments_pkey; Type: CONSTRAINT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.issueattachments
    ADD CONSTRAINT issueattachments_pkey PRIMARY KEY (id);


--
-- Name: issues issues_pkey; Type: CONSTRAINT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.issues
    ADD CONSTRAINT issues_pkey PRIMARY KEY (id);


--
-- Name: issuetypes issuetypes_pkey; Type: CONSTRAINT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.issuetypes
    ADD CONSTRAINT issuetypes_pkey PRIMARY KEY (id);


--
-- Name: masterdata mastertypes_pkey; Type: CONSTRAINT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.masterdata
    ADD CONSTRAINT mastertypes_pkey PRIMARY KEY (id);


--
-- Name: users pk_users_id; Type: CONSTRAINT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.users
    ADD CONSTRAINT pk_users_id PRIMARY KEY (id);


--
-- Name: priority priority_pkey; Type: CONSTRAINT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.priority
    ADD CONSTRAINT priority_pkey PRIMARY KEY (id);


--
-- Name: reporttemplates reporttemplates_pkey; Type: CONSTRAINT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.reporttemplates
    ADD CONSTRAINT reporttemplates_pkey PRIMARY KEY (id);


--
-- Name: resourcetypes resourcetypes_pk; Type: CONSTRAINT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.resourcetypes
    ADD CONSTRAINT resourcetypes_pk PRIMARY KEY (id);


--
-- Name: roleassignments roleassignments_pk; Type: CONSTRAINT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.roleassignments
    ADD CONSTRAINT roleassignments_pk PRIMARY KEY (id);


--
-- Name: rolerestrictions rolepermissions_pk; Type: CONSTRAINT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.rolerestrictions
    ADD CONSTRAINT rolepermissions_pk PRIMARY KEY (id);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: status status_pkey; Type: CONSTRAINT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.status
    ADD CONSTRAINT status_pkey PRIMARY KEY (id);


--
-- Name: support support_pk; Type: CONSTRAINT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.support
    ADD CONSTRAINT support_pk PRIMARY KEY (id);


--
-- Name: tableattachments tableattachments_pk; Type: CONSTRAINT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.tableattachments
    ADD CONSTRAINT tableattachments_pk PRIMARY KEY (id);


--
-- Name: userattachments userattachments_pkey; Type: CONSTRAINT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.userattachments
    ADD CONSTRAINT userattachments_pkey PRIMARY KEY (id);


--
-- Name: usergroups usergroups_pk; Type: CONSTRAINT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.usergroups
    ADD CONSTRAINT usergroups_pk PRIMARY KEY (id);


--
-- Name: workflow_actions workflow_actions_pk; Type: CONSTRAINT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.workflow_actions
    ADD CONSTRAINT workflow_actions_pk PRIMARY KEY (id);


--
-- Name: workflow_states workflow_states_pk; Type: CONSTRAINT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.workflow_states
    ADD CONSTRAINT workflow_states_pk PRIMARY KEY (id);


--
-- Name: workflow_statetransitions workflow_statetransitions_pk; Type: CONSTRAINT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.workflow_statetransitions
    ADD CONSTRAINT workflow_statetransitions_pk PRIMARY KEY (id);


--
-- Name: workflow_status workflow_status_pk; Type: CONSTRAINT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.workflow_status
    ADD CONSTRAINT workflow_status_pk PRIMARY KEY (id);


--
-- Name: actions actions_pk; Type: CONSTRAINT; Schema: metadata; Owner: appowner
--

ALTER TABLE ONLY metadata.actions
    ADD CONSTRAINT actions_pk PRIMARY KEY (id);


--
-- Name: apiactions apiactions_pk; Type: CONSTRAINT; Schema: metadata; Owner: appowner
--

ALTER TABLE ONLY metadata.apiactions
    ADD CONSTRAINT apiactions_pk PRIMARY KEY (id);


--
-- Name: appcolumns appcolumns_pkey; Type: CONSTRAINT; Schema: metadata; Owner: appowner
--

ALTER TABLE ONLY metadata.appcolumns
    ADD CONSTRAINT appcolumns_pkey PRIMARY KEY (id);


--
-- Name: appqueries appquery_pk; Type: CONSTRAINT; Schema: metadata; Owner: appowner
--

ALTER TABLE ONLY metadata.appqueries
    ADD CONSTRAINT appquery_pk PRIMARY KEY (id);


--
-- Name: apptables apptables_pkey; Type: CONSTRAINT; Schema: metadata; Owner: appowner
--

ALTER TABLE ONLY metadata.apptables
    ADD CONSTRAINT apptables_pkey PRIMARY KEY (id);


--
-- Name: columntemplate columntemplate_pkey; Type: CONSTRAINT; Schema: metadata; Owner: appowner
--

ALTER TABLE ONLY metadata.columntemplate
    ADD CONSTRAINT columntemplate_pkey PRIMARY KEY (id);


--
-- Name: datatypes datatypes_pkey; Type: CONSTRAINT; Schema: metadata; Owner: appowner
--

ALTER TABLE ONLY metadata.datatypes
    ADD CONSTRAINT datatypes_pkey PRIMARY KEY (id);


--
-- Name: events events_pkey; Type: CONSTRAINT; Schema: metadata; Owner: appowner
--

ALTER TABLE ONLY metadata.events
    ADD CONSTRAINT events_pkey PRIMARY KEY (id);


--
-- Name: fieldcategories fieldcategories_pkey; Type: CONSTRAINT; Schema: metadata; Owner: appowner
--

ALTER TABLE ONLY metadata.fieldcategories
    ADD CONSTRAINT fieldcategories_pkey PRIMARY KEY (id);


--
-- Name: formeventactions formeventactions_pkey; Type: CONSTRAINT; Schema: metadata; Owner: appowner
--

ALTER TABLE ONLY metadata.formeventactions
    ADD CONSTRAINT formeventactions_pkey PRIMARY KEY (id);


--
-- Name: formresources formresources_pkey; Type: CONSTRAINT; Schema: metadata; Owner: appowner
--

ALTER TABLE ONLY metadata.formresources
    ADD CONSTRAINT formresources_pkey PRIMARY KEY (id);


--
-- Name: menuicons menuicons_pkey; Type: CONSTRAINT; Schema: metadata; Owner: appowner
--

ALTER TABLE ONLY metadata.menuicons
    ADD CONSTRAINT menuicons_pkey PRIMARY KEY (id);


--
-- Name: menuitems menuitems_pkey; Type: CONSTRAINT; Schema: metadata; Owner: appowner
--

ALTER TABLE ONLY metadata.menuitems
    ADD CONSTRAINT menuitems_pkey PRIMARY KEY (id);


--
-- Name: menupaths menupaths_id_pk; Type: CONSTRAINT; Schema: metadata; Owner: appowner
--

ALTER TABLE ONLY metadata.menupaths
    ADD CONSTRAINT menupaths_id_pk PRIMARY KEY (id);


--
-- Name: pageforms pageforms_pkey; Type: CONSTRAINT; Schema: metadata; Owner: appowner
--

ALTER TABLE ONLY metadata.pageforms
    ADD CONSTRAINT pageforms_pkey PRIMARY KEY (id);


--
-- Name: applications pk_applications_id; Type: CONSTRAINT; Schema: metadata; Owner: appowner
--

ALTER TABLE ONLY metadata.applications
    ADD CONSTRAINT pk_applications_id PRIMARY KEY (id);


--
-- Name: controltypes pk_controltypes_id; Type: CONSTRAINT; Schema: metadata; Owner: appowner
--

ALTER TABLE ONLY metadata.controltypes
    ADD CONSTRAINT pk_controltypes_id PRIMARY KEY (id);


--
-- Name: images pk_images_id; Type: CONSTRAINT; Schema: metadata; Owner: appowner
--

ALTER TABLE ONLY metadata.images
    ADD CONSTRAINT pk_images_id PRIMARY KEY (id);


--
-- Name: pages pk_pages_id; Type: CONSTRAINT; Schema: metadata; Owner: appowner
--

ALTER TABLE ONLY metadata.pages
    ADD CONSTRAINT pk_pages_id PRIMARY KEY (id);


--
-- Name: systemcategories systemcategories_pkey; Type: CONSTRAINT; Schema: metadata; Owner: appowner
--

ALTER TABLE ONLY metadata.systemcategories
    ADD CONSTRAINT systemcategories_pkey PRIMARY KEY (id);


--
-- Name: systemtables systemtables_pkey; Type: CONSTRAINT; Schema: metadata; Owner: appowner
--

ALTER TABLE ONLY metadata.systemtables
    ADD CONSTRAINT systemtables_pkey PRIMARY KEY (id);


--
-- Name: systemtabletypes systemtabletypes_pkey; Type: CONSTRAINT; Schema: metadata; Owner: appowner
--

ALTER TABLE ONLY metadata.systemtabletypes
    ADD CONSTRAINT systemtabletypes_pkey PRIMARY KEY (id);


--
-- Name: urlactions urlactions_pk; Type: CONSTRAINT; Schema: metadata; Owner: appowner
--

ALTER TABLE ONLY metadata.urlactions
    ADD CONSTRAINT urlactions_pk PRIMARY KEY (id);


--
-- Name: activities_id_uindex; Type: INDEX; Schema: app; Owner: appowner
--

CREATE UNIQUE INDEX activities_id_uindex ON app.activity USING btree (id);


--
-- Name: adhoc_queries_id_uindex; Type: INDEX; Schema: app; Owner: appowner
--

CREATE UNIQUE INDEX adhoc_queries_id_uindex ON app.adhoc_queries USING btree (id);


--
-- Name: appbunos_id_uindex; Type: INDEX; Schema: app; Owner: appowner
--

CREATE UNIQUE INDEX appbunos_id_uindex ON app.appbunos USING btree (id);


--
-- Name: appdata_id_uindex; Type: INDEX; Schema: app; Owner: appowner
--

CREATE UNIQUE INDEX appdata_id_uindex ON app.appdata USING btree (id);


--
-- Name: attachments_id_uindex; Type: INDEX; Schema: app; Owner: appowner
--

CREATE UNIQUE INDEX attachments_id_uindex ON app.attachments USING btree (id);


--
-- Name: attachments_uniquename_uindex; Type: INDEX; Schema: app; Owner: appowner
--

CREATE UNIQUE INDEX attachments_uniquename_uindex ON app.attachments USING btree (uniquename);


--
-- Name: bunos_id_uindex; Type: INDEX; Schema: app; Owner: appowner
--

CREATE UNIQUE INDEX bunos_id_uindex ON app.bunos USING btree (id);


--
-- Name: bunos_label_uindex; Type: INDEX; Schema: app; Owner: appowner
--

CREATE UNIQUE INDEX bunos_label_uindex ON app.bunos USING btree (identifier);


--
-- Name: dashboardreport_id_uindex; Type: INDEX; Schema: app; Owner: appowner
--

CREATE UNIQUE INDEX dashboardreport_id_uindex ON app.dashboardreports USING btree (id);


--
-- Name: groups_id_uindex; Type: INDEX; Schema: app; Owner: appowner
--

CREATE UNIQUE INDEX groups_id_uindex ON app.groups USING btree (id);


--
-- Name: issueattachments_id_uindex; Type: INDEX; Schema: app; Owner: appowner
--

CREATE UNIQUE INDEX issueattachments_id_uindex ON app.issueattachments USING btree (id);


--
-- Name: issues_id_uindex; Type: INDEX; Schema: app; Owner: appowner
--

CREATE UNIQUE INDEX issues_id_uindex ON app.issues USING btree (id);


--
-- Name: issuetypes_id_uindex; Type: INDEX; Schema: app; Owner: appowner
--

CREATE UNIQUE INDEX issuetypes_id_uindex ON app.issuetypes USING btree (id);


--
-- Name: mastertypes_id_uindex; Type: INDEX; Schema: app; Owner: appowner
--

CREATE UNIQUE INDEX mastertypes_id_uindex ON app.masterdata USING btree (id);


--
-- Name: priority_id_uindex; Type: INDEX; Schema: app; Owner: appowner
--

CREATE UNIQUE INDEX priority_id_uindex ON app.priority USING btree (id);


--
-- Name: reporttemplates_id_uindex; Type: INDEX; Schema: app; Owner: appowner
--

CREATE UNIQUE INDEX reporttemplates_id_uindex ON app.reporttemplates USING btree (id);


--
-- Name: resourcetypes_id_uindex; Type: INDEX; Schema: app; Owner: appowner
--

CREATE UNIQUE INDEX resourcetypes_id_uindex ON app.resourcetypes USING btree (id);


--
-- Name: roleassignments_id_uindex; Type: INDEX; Schema: app; Owner: appowner
--

CREATE UNIQUE INDEX roleassignments_id_uindex ON app.roleassignments USING btree (id);


--
-- Name: rolepermissions_id_uindex; Type: INDEX; Schema: app; Owner: appowner
--

CREATE UNIQUE INDEX rolepermissions_id_uindex ON app.rolerestrictions USING btree (id);


--
-- Name: roles_id_uindex; Type: INDEX; Schema: app; Owner: appowner
--

CREATE UNIQUE INDEX roles_id_uindex ON app.roles USING btree (id);


--
-- Name: status_id_uindex; Type: INDEX; Schema: app; Owner: appowner
--

CREATE UNIQUE INDEX status_id_uindex ON app.status USING btree (id);


--
-- Name: support_id_uindex; Type: INDEX; Schema: app; Owner: appowner
--

CREATE UNIQUE INDEX support_id_uindex ON app.support USING btree (id);


--
-- Name: tableattachments_id_uindex; Type: INDEX; Schema: app; Owner: appowner
--

CREATE UNIQUE INDEX tableattachments_id_uindex ON app.tableattachments USING btree (id);


--
-- Name: userattachments_id_uindex; Type: INDEX; Schema: app; Owner: appowner
--

CREATE UNIQUE INDEX userattachments_id_uindex ON app.userattachments USING btree (id);


--
-- Name: usergroups_id_uindex; Type: INDEX; Schema: app; Owner: appowner
--

CREATE UNIQUE INDEX usergroups_id_uindex ON app.usergroups USING btree (id);


--
-- Name: workflow_actionresponse_id_uindex; Type: INDEX; Schema: app; Owner: appowner
--

CREATE UNIQUE INDEX workflow_actionresponse_id_uindex ON app.workflow_status USING btree (id);


--
-- Name: workflow_actions_id_uindex; Type: INDEX; Schema: app; Owner: appowner
--

CREATE UNIQUE INDEX workflow_actions_id_uindex ON app.workflow_actions USING btree (id);


--
-- Name: workflow_states_id_uindex; Type: INDEX; Schema: app; Owner: appowner
--

CREATE UNIQUE INDEX workflow_states_id_uindex ON app.workflow_states USING btree (id);


--
-- Name: workflow_statetransitions_id_uindex; Type: INDEX; Schema: app; Owner: appowner
--

CREATE UNIQUE INDEX workflow_statetransitions_id_uindex ON app.workflow_statetransitions USING btree (id);


--
-- Name: actions_id_uindex; Type: INDEX; Schema: metadata; Owner: appowner
--

CREATE UNIQUE INDEX actions_id_uindex ON metadata.actions USING btree (id);


--
-- Name: apiactions_id_uindex; Type: INDEX; Schema: metadata; Owner: appowner
--

CREATE UNIQUE INDEX apiactions_id_uindex ON metadata.apiactions USING btree (id);


--
-- Name: appcolumns_id_uindex; Type: INDEX; Schema: metadata; Owner: appowner
--

CREATE UNIQUE INDEX appcolumns_id_uindex ON metadata.appcolumns USING btree (id);


--
-- Name: appquery_id_uindex; Type: INDEX; Schema: metadata; Owner: appowner
--

CREATE UNIQUE INDEX appquery_id_uindex ON metadata.appqueries USING btree (id);


--
-- Name: apptables_id_uindex; Type: INDEX; Schema: metadata; Owner: appowner
--

CREATE UNIQUE INDEX apptables_id_uindex ON metadata.apptables USING btree (id);


--
-- Name: columntemplate_id_uindex; Type: INDEX; Schema: metadata; Owner: appowner
--

CREATE UNIQUE INDEX columntemplate_id_uindex ON metadata.columntemplate USING btree (id);


--
-- Name: datatypes_id_uindex; Type: INDEX; Schema: metadata; Owner: appowner
--

CREATE UNIQUE INDEX datatypes_id_uindex ON metadata.datatypes USING btree (id);


--
-- Name: events_id_uindex; Type: INDEX; Schema: metadata; Owner: appowner
--

CREATE UNIQUE INDEX events_id_uindex ON metadata.events USING btree (id);


--
-- Name: fieldcategories_id_uindex; Type: INDEX; Schema: metadata; Owner: appowner
--

CREATE UNIQUE INDEX fieldcategories_id_uindex ON metadata.fieldcategories USING btree (id);


--
-- Name: formeventactions_id_uindex; Type: INDEX; Schema: metadata; Owner: appowner
--

CREATE UNIQUE INDEX formeventactions_id_uindex ON metadata.formeventactions USING btree (id);


--
-- Name: formresources_formid_uindex; Type: INDEX; Schema: metadata; Owner: appowner
--

CREATE UNIQUE INDEX formresources_formid_uindex ON metadata.formresources USING btree (formid);


--
-- Name: formresources_id_uindex; Type: INDEX; Schema: metadata; Owner: appowner
--

CREATE UNIQUE INDEX formresources_id_uindex ON metadata.formresources USING btree (id);


--
-- Name: idx_images_appid; Type: INDEX; Schema: metadata; Owner: appowner
--

CREATE INDEX idx_images_appid ON metadata.images USING btree (appid);


--
-- Name: menuicons_id_uindex; Type: INDEX; Schema: metadata; Owner: appowner
--

CREATE UNIQUE INDEX menuicons_id_uindex ON metadata.menuicons USING btree (id);


--
-- Name: menuitems_id_uindex; Type: INDEX; Schema: metadata; Owner: appowner
--

CREATE UNIQUE INDEX menuitems_id_uindex ON metadata.menuitems USING btree (id);


--
-- Name: menupaths_id_uindex; Type: INDEX; Schema: metadata; Owner: appowner
--

CREATE UNIQUE INDEX menupaths_id_uindex ON metadata.menupaths USING btree (id);


--
-- Name: pageforms_id_uindex; Type: INDEX; Schema: metadata; Owner: appowner
--

CREATE UNIQUE INDEX pageforms_id_uindex ON metadata.pageforms USING btree (id);


--
-- Name: systemcategories_id_uindex; Type: INDEX; Schema: metadata; Owner: appowner
--

CREATE UNIQUE INDEX systemcategories_id_uindex ON metadata.systemcategories USING btree (id);


--
-- Name: systemtables_id_uindex; Type: INDEX; Schema: metadata; Owner: appowner
--

CREATE UNIQUE INDEX systemtables_id_uindex ON metadata.systemtables USING btree (id);


--
-- Name: systemtabletypes_id_uindex; Type: INDEX; Schema: metadata; Owner: appowner
--

CREATE UNIQUE INDEX systemtabletypes_id_uindex ON metadata.systemtabletypes USING btree (id);


--
-- Name: urlactions_id_uindex; Type: INDEX; Schema: metadata; Owner: appowner
--

CREATE UNIQUE INDEX urlactions_id_uindex ON metadata.urlactions USING btree (id);


--
-- Name: activity activities_applications_id_fk; Type: FK CONSTRAINT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.activity
    ADD CONSTRAINT activities_applications_id_fk FOREIGN KEY (appid) REFERENCES metadata.applications(id);


--
-- Name: adhoc_queries adhoc_queries_applications_id_fk; Type: FK CONSTRAINT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.adhoc_queries
    ADD CONSTRAINT adhoc_queries_applications_id_fk FOREIGN KEY (appid) REFERENCES metadata.applications(id);


--
-- Name: adhoc_queries adhoc_queries_reporttemplates_id_fk; Type: FK CONSTRAINT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.adhoc_queries
    ADD CONSTRAINT adhoc_queries_reporttemplates_id_fk FOREIGN KEY (reporttemplateid) REFERENCES app.reporttemplates(id);


--
-- Name: adhoc_queries adhoc_queries_users_id_fk; Type: FK CONSTRAINT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.adhoc_queries
    ADD CONSTRAINT adhoc_queries_users_id_fk FOREIGN KEY (ownerid) REFERENCES app.users(id);


--
-- Name: appbunos appbunos_applications_id_fk; Type: FK CONSTRAINT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.appbunos
    ADD CONSTRAINT appbunos_applications_id_fk FOREIGN KEY (appid) REFERENCES metadata.applications(id);


--
-- Name: appbunos appbunos_bunos_id_fk; Type: FK CONSTRAINT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.appbunos
    ADD CONSTRAINT appbunos_bunos_id_fk FOREIGN KEY (bunoid) REFERENCES app.bunos(id);


--
-- Name: appdata appdata_applications_id_fk; Type: FK CONSTRAINT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.appdata
    ADD CONSTRAINT appdata_applications_id_fk FOREIGN KEY (appid) REFERENCES metadata.applications(id);


--
-- Name: appdata appdata_apptables_id_fk; Type: FK CONSTRAINT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.appdata
    ADD CONSTRAINT appdata_apptables_id_fk FOREIGN KEY (apptableid) REFERENCES metadata.apptables(id);


--
-- Name: dashboardreports dashboardreport_users_id_fk; Type: FK CONSTRAINT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.dashboardreports
    ADD CONSTRAINT dashboardreport_users_id_fk FOREIGN KEY (userid) REFERENCES app.users(id);


--
-- Name: dashboardreports dashboardreports_adhoc_queries_id_fk; Type: FK CONSTRAINT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.dashboardreports
    ADD CONSTRAINT dashboardreports_adhoc_queries_id_fk FOREIGN KEY (adhocqueryid) REFERENCES app.adhoc_queries(id);


--
-- Name: issueattachments issueattachments_attachments_id_fk; Type: FK CONSTRAINT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.issueattachments
    ADD CONSTRAINT issueattachments_attachments_id_fk FOREIGN KEY (attachmentid) REFERENCES app.attachments(id);


--
-- Name: issueattachments issueattachments_issues_id_fk; Type: FK CONSTRAINT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.issueattachments
    ADD CONSTRAINT issueattachments_issues_id_fk FOREIGN KEY (issueid) REFERENCES app.issues(id);


--
-- Name: issues issues_activity_id_fk; Type: FK CONSTRAINT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.issues
    ADD CONSTRAINT issues_activity_id_fk FOREIGN KEY (activityid) REFERENCES app.activity(id);


--
-- Name: issues issues_issuetypes_id_fk; Type: FK CONSTRAINT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.issues
    ADD CONSTRAINT issues_issuetypes_id_fk FOREIGN KEY (issuetypeid) REFERENCES app.issuetypes(id);


--
-- Name: issues issues_priority_id_fk; Type: FK CONSTRAINT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.issues
    ADD CONSTRAINT issues_priority_id_fk FOREIGN KEY (priorityid) REFERENCES app.priority(id);


--
-- Name: issues issues_status_id_fk; Type: FK CONSTRAINT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.issues
    ADD CONSTRAINT issues_status_id_fk FOREIGN KEY (statusid) REFERENCES app.status(id);


--
-- Name: issues issues_workflow_actions_id_fk; Type: FK CONSTRAINT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.issues
    ADD CONSTRAINT issues_workflow_actions_id_fk FOREIGN KEY (workflowactionid) REFERENCES app.workflow_actions(id);


--
-- Name: issues issues_workflow_states_id_fk; Type: FK CONSTRAINT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.issues
    ADD CONSTRAINT issues_workflow_states_id_fk FOREIGN KEY (workflowstateid) REFERENCES app.workflow_states(id);


--
-- Name: issuetypes issuetypes_applications_id_fk; Type: FK CONSTRAINT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.issuetypes
    ADD CONSTRAINT issuetypes_applications_id_fk FOREIGN KEY (appid) REFERENCES metadata.applications(id);


--
-- Name: masterdata masterdata_applications_id_fk; Type: FK CONSTRAINT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.masterdata
    ADD CONSTRAINT masterdata_applications_id_fk FOREIGN KEY (appid) REFERENCES metadata.applications(id);


--
-- Name: masterdata masterdata_apptables_id_fk; Type: FK CONSTRAINT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.masterdata
    ADD CONSTRAINT masterdata_apptables_id_fk FOREIGN KEY (apptableid) REFERENCES metadata.apptables(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: priority priority_applications_id_fk; Type: FK CONSTRAINT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.priority
    ADD CONSTRAINT priority_applications_id_fk FOREIGN KEY (appid) REFERENCES metadata.applications(id);


--
-- Name: reporttemplates reporttemplates_applications_id_fk; Type: FK CONSTRAINT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.reporttemplates
    ADD CONSTRAINT reporttemplates_applications_id_fk FOREIGN KEY (appid) REFERENCES metadata.applications(id);


--
-- Name: reporttemplates reporttemplates_apptables_id_fk; Type: FK CONSTRAINT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.reporttemplates
    ADD CONSTRAINT reporttemplates_apptables_id_fk FOREIGN KEY (primarytableid) REFERENCES metadata.apptables(id);


--
-- Name: reporttemplates reporttemplates_users_id_fk; Type: FK CONSTRAINT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.reporttemplates
    ADD CONSTRAINT reporttemplates_users_id_fk FOREIGN KEY (ownerid) REFERENCES app.users(id);


--
-- Name: roleassignments roleassignments_groups_id_fk; Type: FK CONSTRAINT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.roleassignments
    ADD CONSTRAINT roleassignments_groups_id_fk FOREIGN KEY (groupid) REFERENCES app.groups(id);


--
-- Name: roleassignments roleassignments_roles_id_fk; Type: FK CONSTRAINT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.roleassignments
    ADD CONSTRAINT roleassignments_roles_id_fk FOREIGN KEY (roleid) REFERENCES app.roles(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: roleassignments roleassignments_users_id_fk; Type: FK CONSTRAINT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.roleassignments
    ADD CONSTRAINT roleassignments_users_id_fk FOREIGN KEY (userid) REFERENCES app.users(id);


--
-- Name: rolerestrictions rolepermissions_applications_id_fk; Type: FK CONSTRAINT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.rolerestrictions
    ADD CONSTRAINT rolepermissions_applications_id_fk FOREIGN KEY (appid) REFERENCES metadata.applications(id);


--
-- Name: rolerestrictions rolepermissions_resourcetypes_id_fk; Type: FK CONSTRAINT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.rolerestrictions
    ADD CONSTRAINT rolepermissions_resourcetypes_id_fk FOREIGN KEY (resourcetypeid) REFERENCES app.resourcetypes(id);


--
-- Name: rolerestrictions rolepermissions_roles_id_fk; Type: FK CONSTRAINT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.rolerestrictions
    ADD CONSTRAINT rolepermissions_roles_id_fk FOREIGN KEY (roleid) REFERENCES app.roles(id);


--
-- Name: rolerestrictions rolerestrictions_workflow_states_id_fk; Type: FK CONSTRAINT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.rolerestrictions
    ADD CONSTRAINT rolerestrictions_workflow_states_id_fk FOREIGN KEY (workflowstateid) REFERENCES app.workflow_states(id);


--
-- Name: roles roles_applications_id_fk; Type: FK CONSTRAINT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.roles
    ADD CONSTRAINT roles_applications_id_fk FOREIGN KEY (appid) REFERENCES metadata.applications(id);


--
-- Name: status status_applications_id_fk; Type: FK CONSTRAINT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.status
    ADD CONSTRAINT status_applications_id_fk FOREIGN KEY (appid) REFERENCES metadata.applications(id);


--
-- Name: support support_applications_id_fk; Type: FK CONSTRAINT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.support
    ADD CONSTRAINT support_applications_id_fk FOREIGN KEY (appid) REFERENCES metadata.applications(id);


--
-- Name: support support_users_id_fk; Type: FK CONSTRAINT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.support
    ADD CONSTRAINT support_users_id_fk FOREIGN KEY (userid) REFERENCES app.users(id);


--
-- Name: tableattachments tableattachments_attachments_id_fk; Type: FK CONSTRAINT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.tableattachments
    ADD CONSTRAINT tableattachments_attachments_id_fk FOREIGN KEY (attachmentid) REFERENCES app.attachments(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: userattachments userattachments_attachments_id_fk; Type: FK CONSTRAINT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.userattachments
    ADD CONSTRAINT userattachments_attachments_id_fk FOREIGN KEY (attachmentid) REFERENCES app.attachments(id);


--
-- Name: userattachments userattachments_users_id_fk; Type: FK CONSTRAINT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.userattachments
    ADD CONSTRAINT userattachments_users_id_fk FOREIGN KEY (userid) REFERENCES app.users(id);


--
-- Name: usergroups usergroups_groups_id_fk; Type: FK CONSTRAINT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.usergroups
    ADD CONSTRAINT usergroups_groups_id_fk FOREIGN KEY (groupid) REFERENCES app.groups(id);


--
-- Name: usergroups usergroups_users_id_fk; Type: FK CONSTRAINT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.usergroups
    ADD CONSTRAINT usergroups_users_id_fk FOREIGN KEY (userid) REFERENCES app.users(id);


--
-- Name: workflow_states workflow_states_applications_id_fk; Type: FK CONSTRAINT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.workflow_states
    ADD CONSTRAINT workflow_states_applications_id_fk FOREIGN KEY (appid) REFERENCES metadata.applications(id);


--
-- Name: workflow_states workflow_states_issuetypes_id_fk; Type: FK CONSTRAINT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.workflow_states
    ADD CONSTRAINT workflow_states_issuetypes_id_fk FOREIGN KEY (issuetypeid) REFERENCES app.issuetypes(id);


--
-- Name: workflow_states workflow_states_status_id_fk; Type: FK CONSTRAINT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.workflow_states
    ADD CONSTRAINT workflow_states_status_id_fk FOREIGN KEY (statusid) REFERENCES app.status(id);


--
-- Name: workflow_states workflow_states_workflow_status_id_fk; Type: FK CONSTRAINT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.workflow_states
    ADD CONSTRAINT workflow_states_workflow_status_id_fk FOREIGN KEY (workflowstatusid) REFERENCES app.workflow_status(id);


--
-- Name: workflow_status workflow_status_applications_id_fk; Type: FK CONSTRAINT; Schema: app; Owner: appowner
--

ALTER TABLE ONLY app.workflow_status
    ADD CONSTRAINT workflow_status_applications_id_fk FOREIGN KEY (appid) REFERENCES metadata.applications(id);


--
-- Name: appcolumns appcolumns_apptables_id_fk; Type: FK CONSTRAINT; Schema: metadata; Owner: appowner
--

ALTER TABLE ONLY metadata.appcolumns
    ADD CONSTRAINT appcolumns_apptables_id_fk FOREIGN KEY (apptableid) REFERENCES metadata.apptables(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: appcolumns appcolumns_datatypes_id_fk; Type: FK CONSTRAINT; Schema: metadata; Owner: appowner
--

ALTER TABLE ONLY metadata.appcolumns
    ADD CONSTRAINT appcolumns_datatypes_id_fk FOREIGN KEY (datatypeid) REFERENCES metadata.datatypes(id);


--
-- Name: appqueries appquery_applications_id_fk; Type: FK CONSTRAINT; Schema: metadata; Owner: appowner
--

ALTER TABLE ONLY metadata.appqueries
    ADD CONSTRAINT appquery_applications_id_fk FOREIGN KEY (appid) REFERENCES metadata.applications(id);


--
-- Name: apptables apptables_applications_id_fk; Type: FK CONSTRAINT; Schema: metadata; Owner: appowner
--

ALTER TABLE ONLY metadata.apptables
    ADD CONSTRAINT apptables_applications_id_fk FOREIGN KEY (appid) REFERENCES metadata.applications(id);


--
-- Name: controltypes controltypes_datatypes_id_fk; Type: FK CONSTRAINT; Schema: metadata; Owner: appowner
--

ALTER TABLE ONLY metadata.controltypes
    ADD CONSTRAINT controltypes_datatypes_id_fk FOREIGN KEY (datatypeid) REFERENCES metadata.datatypes(id);


--
-- Name: images fk_images_applications; Type: FK CONSTRAINT; Schema: metadata; Owner: appowner
--

ALTER TABLE ONLY metadata.images
    ADD CONSTRAINT fk_images_applications FOREIGN KEY (appid) REFERENCES metadata.applications(id);


--
-- Name: pages fk_pages_applications; Type: FK CONSTRAINT; Schema: metadata; Owner: appowner
--

ALTER TABLE ONLY metadata.pages
    ADD CONSTRAINT fk_pages_applications FOREIGN KEY (appid) REFERENCES metadata.applications(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: formeventactions formeventactions_actions_id_fk; Type: FK CONSTRAINT; Schema: metadata; Owner: appowner
--

ALTER TABLE ONLY metadata.formeventactions
    ADD CONSTRAINT formeventactions_actions_id_fk FOREIGN KEY (actionid) REFERENCES metadata.actions(id);


--
-- Name: formeventactions formeventactions_events_id_fk; Type: FK CONSTRAINT; Schema: metadata; Owner: appowner
--

ALTER TABLE ONLY metadata.formeventactions
    ADD CONSTRAINT formeventactions_events_id_fk FOREIGN KEY (eventid) REFERENCES metadata.events(id);


--
-- Name: formeventactions formeventactions_pageforms_id_fk; Type: FK CONSTRAINT; Schema: metadata; Owner: appowner
--

ALTER TABLE ONLY metadata.formeventactions
    ADD CONSTRAINT formeventactions_pageforms_id_fk FOREIGN KEY (pageformid) REFERENCES metadata.pageforms(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: formeventactions formeventactions_reporttemplates_id_fk; Type: FK CONSTRAINT; Schema: metadata; Owner: appowner
--

ALTER TABLE ONLY metadata.formeventactions
    ADD CONSTRAINT formeventactions_reporttemplates_id_fk FOREIGN KEY (reporttemplateid) REFERENCES app.reporttemplates(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: formresources formresources_appcolumns_id_fk; Type: FK CONSTRAINT; Schema: metadata; Owner: appowner
--

ALTER TABLE ONLY metadata.formresources
    ADD CONSTRAINT formresources_appcolumns_id_fk FOREIGN KEY (appcolumnid) REFERENCES metadata.appcolumns(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: formresources formresources_applications_id_fk; Type: FK CONSTRAINT; Schema: metadata; Owner: appowner
--

ALTER TABLE ONLY metadata.formresources
    ADD CONSTRAINT formresources_applications_id_fk FOREIGN KEY (appid) REFERENCES metadata.applications(id);


--
-- Name: menuitems menuitems_applications_id_fk; Type: FK CONSTRAINT; Schema: metadata; Owner: appowner
--

ALTER TABLE ONLY metadata.menuitems
    ADD CONSTRAINT menuitems_applications_id_fk FOREIGN KEY (appid) REFERENCES metadata.applications(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: menuitems menuitems_menuicons_id_fk; Type: FK CONSTRAINT; Schema: metadata; Owner: appowner
--

ALTER TABLE ONLY metadata.menuitems
    ADD CONSTRAINT menuitems_menuicons_id_fk FOREIGN KEY (iconid) REFERENCES metadata.menuicons(id);


--
-- Name: menuitems menuitems_menuitems_id_fk; Type: FK CONSTRAINT; Schema: metadata; Owner: appowner
--

ALTER TABLE ONLY metadata.menuitems
    ADD CONSTRAINT menuitems_menuitems_id_fk FOREIGN KEY (parentid) REFERENCES metadata.menuitems(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: menuitems menuitems_menupaths_id_fk; Type: FK CONSTRAINT; Schema: metadata; Owner: appowner
--

ALTER TABLE ONLY metadata.menuitems
    ADD CONSTRAINT menuitems_menupaths_id_fk FOREIGN KEY (pathid) REFERENCES metadata.menupaths(id);


--
-- Name: menuitems menuitems_pages_id_fk; Type: FK CONSTRAINT; Schema: metadata; Owner: appowner
--

ALTER TABLE ONLY metadata.menuitems
    ADD CONSTRAINT menuitems_pages_id_fk FOREIGN KEY (pageid) REFERENCES metadata.pages(id);


--
-- Name: pageforms pageforms_appcolumns_id_fk; Type: FK CONSTRAINT; Schema: metadata; Owner: appowner
--

ALTER TABLE ONLY metadata.pageforms
    ADD CONSTRAINT pageforms_appcolumns_id_fk FOREIGN KEY (appcolumnid) REFERENCES metadata.appcolumns(id);


--
-- Name: pageforms pageforms_pages_id_fk; Type: FK CONSTRAINT; Schema: metadata; Owner: appowner
--

ALTER TABLE ONLY metadata.pageforms
    ADD CONSTRAINT pageforms_pages_id_fk FOREIGN KEY (pageid) REFERENCES metadata.pages(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: pageforms pageforms_systemcategories_id_fk; Type: FK CONSTRAINT; Schema: metadata; Owner: appowner
--

ALTER TABLE ONLY metadata.pageforms
    ADD CONSTRAINT pageforms_systemcategories_id_fk FOREIGN KEY (systemcategoryid) REFERENCES metadata.systemcategories(id);


--
-- Name: systemtables systemtables_systemtabletypes_id_fk; Type: FK CONSTRAINT; Schema: metadata; Owner: appowner
--

ALTER TABLE ONLY metadata.systemtables
    ADD CONSTRAINT systemtables_systemtabletypes_id_fk FOREIGN KEY (systemtabletypeid) REFERENCES metadata.systemtabletypes(id);


--
-- Name: urlactions urlactions_apiactions_id_fk; Type: FK CONSTRAINT; Schema: metadata; Owner: appowner
--

ALTER TABLE ONLY metadata.urlactions
    ADD CONSTRAINT urlactions_apiactions_id_fk FOREIGN KEY (apiactionid) REFERENCES metadata.apiactions(id);


--
-- Name: urlactions urlactions_pageforms_id_fk; Type: FK CONSTRAINT; Schema: metadata; Owner: appowner
--

ALTER TABLE ONLY metadata.urlactions
    ADD CONSTRAINT urlactions_pageforms_id_fk FOREIGN KEY (pageformid) REFERENCES metadata.pageforms(id);


--
-- Name: SCHEMA app; Type: ACL; Schema: -; Owner: appowner
--

GRANT USAGE ON SCHEMA app TO appuser;


--
-- Name: SCHEMA metadata; Type: ACL; Schema: -; Owner: appowner
--

GRANT USAGE ON SCHEMA metadata TO appuser;


--
-- Name: FUNCTION findbunos(jsonarray jsonb); Type: ACL; Schema: app; Owner: appowner
--

GRANT ALL ON FUNCTION app.findbunos(jsonarray jsonb) TO appuser;


--
-- Name: FUNCTION findmls(jsonarray jsonb); Type: ACL; Schema: app; Owner: appowner
--

GRANT ALL ON FUNCTION app.findmls(jsonarray jsonb) TO appuser;


--
-- Name: FUNCTION findrolesbystatetransition(idtable integer, idstatetransition integer); Type: ACL; Schema: app; Owner: appowner
--

GRANT ALL ON FUNCTION app.findrolesbystatetransition(idtable integer, idstatetransition integer) TO appuser;


--
-- Name: FUNCTION findtransitionnotificationusers(idtable integer, idstatetransition integer); Type: ACL; Schema: app; Owner: appowner
--

GRANT ALL ON FUNCTION app.findtransitionnotificationusers(idtable integer, idstatetransition integer) TO appuser;


--
-- Name: FUNCTION getappusers(idapp integer); Type: ACL; Schema: app; Owner: appowner
--

GRANT ALL ON FUNCTION app.getappusers(idapp integer) TO appuser;


--
-- Name: FUNCTION getuserroles(iduser integer); Type: ACL; Schema: app; Owner: appowner
--

GRANT ALL ON FUNCTION app.getuserroles(iduser integer) TO appuser;


--
-- Name: FUNCTION getuserrolesasarray(iduser integer); Type: ACL; Schema: app; Owner: appowner
--

GRANT ALL ON FUNCTION app.getuserrolesasarray(iduser integer) TO appuser;


--
-- Name: FUNCTION getusersinroles(roleids integer[]); Type: ACL; Schema: app; Owner: appowner
--

GRANT ALL ON FUNCTION app.getusersinroles(roleids integer[]) TO appuser;


--
-- Name: FUNCTION issuetypesselectvalues(idapp numeric); Type: ACL; Schema: app; Owner: appowner
--

GRANT ALL ON FUNCTION app.issuetypesselectvalues(idapp numeric) TO appuser;


--
-- Name: FUNCTION roleassignmentsbulkupdate(idrole integer, addgroupids integer[], removegroupids integer[], adduserids integer[], removeuserids integer[]); Type: ACL; Schema: app; Owner: appowner
--

GRANT ALL ON FUNCTION app.roleassignmentsbulkupdate(idrole integer, addgroupids integer[], removegroupids integer[], adduserids integer[], removeuserids integer[]) TO appuser;


--
-- Name: FUNCTION tdfindallwithdeps(idtable numeric, iddeps numeric); Type: ACL; Schema: app; Owner: appowner
--

GRANT ALL ON FUNCTION app.tdfindallwithdeps(idtable numeric, iddeps numeric) TO appuser;


--
-- Name: FUNCTION usergroupsbulkupdate(iduser integer, addids integer[], removeids integer[]); Type: ACL; Schema: app; Owner: appowner
--

GRANT ALL ON FUNCTION app.usergroupsbulkupdate(iduser integer, addids integer[], removeids integer[]) TO appuser;


--
-- Name: FUNCTION workflowstatebyid(idissuetype numeric); Type: ACL; Schema: app; Owner: appowner
--

GRANT ALL ON FUNCTION app.workflowstatebyid(idissuetype numeric) TO appuser;


--
-- Name: FUNCTION workflowstatetransitionbyid(idissuetype numeric); Type: ACL; Schema: app; Owner: appowner
--

GRANT ALL ON FUNCTION app.workflowstatetransitionbyid(idissuetype numeric) TO appuser;


--
-- Name: FUNCTION actionfindall(); Type: ACL; Schema: metadata; Owner: appowner
--

GRANT ALL ON FUNCTION metadata.actionfindall() TO appuser;


--
-- Name: FUNCTION addtablecolumns(idtbl numeric, tblname text); Type: ACL; Schema: metadata; Owner: appowner
--

GRANT ALL ON FUNCTION metadata.addtablecolumns(idtbl numeric, tblname text) TO appuser;


--
-- Name: FUNCTION appbunosbulkadd(idapp integer, bunoids integer[]); Type: ACL; Schema: metadata; Owner: appowner
--

GRANT ALL ON FUNCTION metadata.appbunosbulkadd(idapp integer, bunoids integer[]) TO appuser;


--
-- Name: FUNCTION appdataadd(idtable integer, fieldids integer[], fieldvals text[]); Type: ACL; Schema: metadata; Owner: appowner
--

GRANT ALL ON FUNCTION metadata.appdataadd(idtable integer, fieldids integer[], fieldvals text[]) TO appuser;


--
-- Name: FUNCTION appdatadelete(idtable integer, idrec integer); Type: ACL; Schema: metadata; Owner: appowner
--

GRANT ALL ON FUNCTION metadata.appdatadelete(idtable integer, idrec integer) TO appuser;


--
-- Name: FUNCTION appdatafindbyid(idtable integer, idrec integer); Type: ACL; Schema: metadata; Owner: appowner
--

GRANT ALL ON FUNCTION metadata.appdatafindbyid(idtable integer, idrec integer) TO appuser;


--
-- Name: FUNCTION appdataupdate(idtable integer, idrec integer, fieldids integer[], fieldvals text[]); Type: ACL; Schema: metadata; Owner: appowner
--

GRANT ALL ON FUNCTION metadata.appdataupdate(idtable integer, idrec integer, fieldids integer[], fieldvals text[]) TO appuser;


--
-- Name: FUNCTION appformfindbyid(idrec numeric); Type: ACL; Schema: metadata; Owner: appowner
--

GRANT ALL ON FUNCTION metadata.appformfindbyid(idrec numeric) TO appuser;


--
-- Name: FUNCTION appformgetformtables(); Type: ACL; Schema: metadata; Owner: appowner
--

GRANT ALL ON FUNCTION metadata.appformgetformtables() TO appuser;


--
-- Name: FUNCTION applicationsfindall(); Type: ACL; Schema: metadata; Owner: appowner
--

GRANT ALL ON FUNCTION metadata.applicationsfindall() TO appuser;


--
-- Name: FUNCTION applicationsgetselections(); Type: ACL; Schema: metadata; Owner: appowner
--

GRANT ALL ON FUNCTION metadata.applicationsgetselections() TO appuser;


--
-- Name: FUNCTION appusersbulkadd(idapp integer, userids integer[]); Type: ACL; Schema: metadata; Owner: appowner
--

GRANT ALL ON FUNCTION metadata.appusersbulkadd(idapp integer, userids integer[]) TO appuser;


--
-- Name: FUNCTION datamapgetcategories(); Type: ACL; Schema: metadata; Owner: appowner
--

GRANT ALL ON FUNCTION metadata.datamapgetcategories() TO appuser;


--
-- Name: FUNCTION datamapgetfields(idtable numeric); Type: ACL; Schema: metadata; Owner: appowner
--

GRANT ALL ON FUNCTION metadata.datamapgetfields(idtable numeric) TO appuser;


--
-- Name: FUNCTION datamapgettableoptions(idapp numeric); Type: ACL; Schema: metadata; Owner: appowner
--

GRANT ALL ON FUNCTION metadata.datamapgettableoptions(idapp numeric) TO appuser;


--
-- Name: FUNCTION formrecorddelete(idform integer, idrec integer); Type: ACL; Schema: metadata; Owner: appowner
--

GRANT ALL ON FUNCTION metadata.formrecorddelete(idform integer, idrec integer) TO appuser;


--
-- Name: FUNCTION getappresources(idapp numeric); Type: ACL; Schema: metadata; Owner: appowner
--

GRANT ALL ON FUNCTION metadata.getappresources(idapp numeric) TO appuser;


--
-- Name: FUNCTION loadappbunos(idapp integer); Type: ACL; Schema: metadata; Owner: appowner
--

GRANT ALL ON FUNCTION metadata.loadappbunos(idapp integer) TO appuser;


--
-- Name: FUNCTION menubulkadd(nodes json[]); Type: ACL; Schema: metadata; Owner: appowner
--

GRANT ALL ON FUNCTION metadata.menubulkadd(nodes json[]) TO appuser;


--
-- Name: FUNCTION menubulkdelete(nodes json[]); Type: ACL; Schema: metadata; Owner: appowner
--

GRANT ALL ON FUNCTION metadata.menubulkdelete(nodes json[]) TO appuser;


--
-- Name: FUNCTION menubulkupdate(nodes json[]); Type: ACL; Schema: metadata; Owner: appowner
--

GRANT ALL ON FUNCTION metadata.menubulkupdate(nodes json[]) TO appuser;


--
-- Name: FUNCTION menuitemadd(item json); Type: ACL; Schema: metadata; Owner: appowner
--

GRANT ALL ON FUNCTION metadata.menuitemadd(item json) TO appuser;


--
-- Name: FUNCTION pageadd(item json); Type: ACL; Schema: metadata; Owner: appowner
--

GRANT ALL ON FUNCTION metadata.pageadd(item json) TO appuser;


--
-- Name: FUNCTION pagedelete(idpage integer); Type: ACL; Schema: metadata; Owner: appowner
--

GRANT ALL ON FUNCTION metadata.pagedelete(idpage integer) TO appuser;


--
-- Name: FUNCTION pagefindbyid(idpage numeric); Type: ACL; Schema: metadata; Owner: appowner
--

GRANT ALL ON FUNCTION metadata.pagefindbyid(idpage numeric) TO appuser;


--
-- Name: FUNCTION pageformsadd(idapp numeric, idpage numeric, idappcolumn numeric, descr text, jsonvalue jsonb); Type: ACL; Schema: metadata; Owner: appowner
--

GRANT ALL ON FUNCTION metadata.pageformsadd(idapp numeric, idpage numeric, idappcolumn numeric, descr text, jsonvalue jsonb) TO appuser;


--
-- Name: FUNCTION pageformsgetactionsbypage(idpage numeric); Type: ACL; Schema: metadata; Owner: appowner
--

GRANT ALL ON FUNCTION metadata.pageformsgetactionsbypage(idpage numeric) TO appuser;


--
-- Name: FUNCTION pageformsupdate(idform numeric, idappcolumn numeric, descr text, jsonvalue jsonb); Type: ACL; Schema: metadata; Owner: appowner
--

GRANT ALL ON FUNCTION metadata.pageformsupdate(idform numeric, idappcolumn numeric, descr text, jsonvalue jsonb) TO appuser;


--
-- Name: FUNCTION pageupdate(item json); Type: ACL; Schema: metadata; Owner: appowner
--

GRANT ALL ON FUNCTION metadata.pageupdate(item json) TO appuser;


--
-- Name: FUNCTION testarrays(idform integer, arr1 integer[]); Type: ACL; Schema: metadata; Owner: appowner
--

GRANT ALL ON FUNCTION metadata.testarrays(idform integer, arr1 integer[]) TO appuser;


--
-- Name: FUNCTION testarrays(idform integer, arr1 integer[], arr2 text[]); Type: ACL; Schema: metadata; Owner: appowner
--

GRANT ALL ON FUNCTION metadata.testarrays(idform integer, arr1 integer[], arr2 text[]) TO appuser;


--
-- Name: FUNCTION workflowstateadd(idtable integer, idissuetype integer); Type: ACL; Schema: metadata; Owner: appowner
--

GRANT ALL ON FUNCTION metadata.workflowstateadd(idtable integer, idissuetype integer) TO appuser;


--
-- Name: FUNCTION workflowstatebyid(idissuetype numeric); Type: ACL; Schema: metadata; Owner: appowner
--

GRANT ALL ON FUNCTION metadata.workflowstatebyid(idissuetype numeric) TO appuser;


--
-- Name: FUNCTION workflowstatetransition(idtable integer, initialstate boolean, idkey integer); Type: ACL; Schema: metadata; Owner: appowner
--

GRANT ALL ON FUNCTION metadata.workflowstatetransition(idtable integer, initialstate boolean, idkey integer) TO appuser;


--
-- Name: FUNCTION workflowstateupdate(idtable integer, idtransition integer); Type: ACL; Schema: metadata; Owner: appowner
--

GRANT ALL ON FUNCTION metadata.workflowstateupdate(idtable integer, idtransition integer) TO appuser;


--
-- Name: TABLE activity; Type: ACL; Schema: app; Owner: appowner
--

GRANT ALL ON TABLE app.activity TO appuser;


--
-- Name: SEQUENCE activities_id_seq; Type: ACL; Schema: app; Owner: appowner
--

GRANT ALL ON SEQUENCE app.activities_id_seq TO appuser;


--
-- Name: TABLE adhoc_queries; Type: ACL; Schema: app; Owner: appowner
--

GRANT ALL ON TABLE app.adhoc_queries TO appuser;


--
-- Name: SEQUENCE adhoc_queries_id_seq; Type: ACL; Schema: app; Owner: appowner
--

GRANT ALL ON SEQUENCE app.adhoc_queries_id_seq TO appuser;


--
-- Name: TABLE appbunos; Type: ACL; Schema: app; Owner: appowner
--

GRANT ALL ON TABLE app.appbunos TO appuser;


--
-- Name: SEQUENCE appbunos_id_seq; Type: ACL; Schema: app; Owner: appowner
--

GRANT ALL ON SEQUENCE app.appbunos_id_seq TO appuser;


--
-- Name: TABLE appdata; Type: ACL; Schema: app; Owner: appowner
--

GRANT ALL ON TABLE app.appdata TO appuser;


--
-- Name: SEQUENCE appdata_id_seq; Type: ACL; Schema: app; Owner: appowner
--

GRANT ALL ON SEQUENCE app.appdata_id_seq TO appuser;


--
-- Name: TABLE tableattachments; Type: ACL; Schema: app; Owner: appowner
--

GRANT ALL ON TABLE app.tableattachments TO appuser;


--
-- Name: SEQUENCE appdataattachments_id_seq; Type: ACL; Schema: app; Owner: appowner
--

GRANT ALL ON SEQUENCE app.appdataattachments_id_seq TO appuser;


--
-- Name: TABLE attachments; Type: ACL; Schema: app; Owner: appowner
--

GRANT ALL ON TABLE app.attachments TO appuser;


--
-- Name: SEQUENCE attachments_id_seq; Type: ACL; Schema: app; Owner: appowner
--

GRANT ALL ON SEQUENCE app.attachments_id_seq TO appuser;


--
-- Name: TABLE bunos; Type: ACL; Schema: app; Owner: appowner
--

GRANT ALL ON TABLE app.bunos TO appuser;


--
-- Name: SEQUENCE bunos_id_seq; Type: ACL; Schema: app; Owner: appowner
--

GRANT ALL ON SEQUENCE app.bunos_id_seq TO appuser;


--
-- Name: TABLE dashboardreports; Type: ACL; Schema: app; Owner: appowner
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE app.dashboardreports TO appuser;


--
-- Name: SEQUENCE dashboardreport_id_seq; Type: ACL; Schema: app; Owner: appowner
--

GRANT SELECT,USAGE ON SEQUENCE app.dashboardreport_id_seq TO appuser;


--
-- Name: TABLE groups; Type: ACL; Schema: app; Owner: appowner
--

GRANT ALL ON TABLE app.groups TO appuser;


--
-- Name: SEQUENCE groups_id_seq; Type: ACL; Schema: app; Owner: appowner
--

GRANT ALL ON SEQUENCE app.groups_id_seq TO appuser;


--
-- Name: TABLE issueattachments; Type: ACL; Schema: app; Owner: appowner
--

GRANT ALL ON TABLE app.issueattachments TO appuser;


--
-- Name: SEQUENCE issueattachments_id_seq; Type: ACL; Schema: app; Owner: appowner
--

GRANT ALL ON SEQUENCE app.issueattachments_id_seq TO appuser;


--
-- Name: TABLE issues; Type: ACL; Schema: app; Owner: appowner
--

GRANT ALL ON TABLE app.issues TO appuser;


--
-- Name: SEQUENCE issues_id_seq; Type: ACL; Schema: app; Owner: appowner
--

GRANT ALL ON SEQUENCE app.issues_id_seq TO appuser;


--
-- Name: TABLE issuetypes; Type: ACL; Schema: app; Owner: appowner
--

GRANT ALL ON TABLE app.issuetypes TO appuser;


--
-- Name: SEQUENCE issuetypes_id_seq; Type: ACL; Schema: app; Owner: appowner
--

GRANT ALL ON SEQUENCE app.issuetypes_id_seq TO appuser;


--
-- Name: TABLE masterdata; Type: ACL; Schema: app; Owner: appowner
--

GRANT ALL ON TABLE app.masterdata TO appuser;


--
-- Name: SEQUENCE mastertypes_id_seq; Type: ACL; Schema: app; Owner: appowner
--

GRANT ALL ON SEQUENCE app.mastertypes_id_seq TO appuser;


--
-- Name: TABLE priority; Type: ACL; Schema: app; Owner: appowner
--

GRANT ALL ON TABLE app.priority TO appuser;


--
-- Name: SEQUENCE priority_id_seq; Type: ACL; Schema: app; Owner: appowner
--

GRANT ALL ON SEQUENCE app.priority_id_seq TO appuser;


--
-- Name: TABLE reporttemplates; Type: ACL; Schema: app; Owner: appowner
--

GRANT ALL ON TABLE app.reporttemplates TO appuser;


--
-- Name: SEQUENCE reporttemplates_id_seq; Type: ACL; Schema: app; Owner: appowner
--

GRANT ALL ON SEQUENCE app.reporttemplates_id_seq TO appuser;


--
-- Name: TABLE resourcetypes; Type: ACL; Schema: app; Owner: appowner
--

GRANT ALL ON TABLE app.resourcetypes TO appuser;


--
-- Name: SEQUENCE resourcetypes_id_seq; Type: ACL; Schema: app; Owner: appowner
--

GRANT ALL ON SEQUENCE app.resourcetypes_id_seq TO appuser;


--
-- Name: TABLE roleassignments; Type: ACL; Schema: app; Owner: appowner
--

GRANT ALL ON TABLE app.roleassignments TO appuser;


--
-- Name: SEQUENCE roleassignments_id_seq; Type: ACL; Schema: app; Owner: appowner
--

GRANT ALL ON SEQUENCE app.roleassignments_id_seq TO appuser;


--
-- Name: TABLE rolerestrictions; Type: ACL; Schema: app; Owner: appowner
--

GRANT ALL ON TABLE app.rolerestrictions TO appuser;


--
-- Name: SEQUENCE rolepermissions_id_seq; Type: ACL; Schema: app; Owner: appowner
--

GRANT ALL ON SEQUENCE app.rolepermissions_id_seq TO appuser;


--
-- Name: TABLE roles; Type: ACL; Schema: app; Owner: appowner
--

GRANT ALL ON TABLE app.roles TO appuser;


--
-- Name: SEQUENCE roles_id_seq; Type: ACL; Schema: app; Owner: appowner
--

GRANT ALL ON SEQUENCE app.roles_id_seq TO appuser;


--
-- Name: TABLE status; Type: ACL; Schema: app; Owner: appowner
--

GRANT ALL ON TABLE app.status TO appuser;


--
-- Name: SEQUENCE status_id_seq; Type: ACL; Schema: app; Owner: appowner
--

GRANT ALL ON SEQUENCE app.status_id_seq TO appuser;


--
-- Name: TABLE support; Type: ACL; Schema: app; Owner: appowner
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE app.support TO appuser;


--
-- Name: SEQUENCE support_id_seq; Type: ACL; Schema: app; Owner: appowner
--

GRANT SELECT,USAGE ON SEQUENCE app.support_id_seq TO appuser;


--
-- Name: TABLE userattachments; Type: ACL; Schema: app; Owner: appowner
--

GRANT ALL ON TABLE app.userattachments TO appuser;


--
-- Name: SEQUENCE userattachments_id_seq; Type: ACL; Schema: app; Owner: appowner
--

GRANT ALL ON SEQUENCE app.userattachments_id_seq TO appuser;


--
-- Name: TABLE usergroups; Type: ACL; Schema: app; Owner: appowner
--

GRANT ALL ON TABLE app.usergroups TO appuser;


--
-- Name: SEQUENCE usergroups_id_seq; Type: ACL; Schema: app; Owner: appowner
--

GRANT ALL ON SEQUENCE app.usergroups_id_seq TO appuser;


--
-- Name: TABLE users; Type: ACL; Schema: app; Owner: appowner
--

GRANT ALL ON TABLE app.users TO appuser;


--
-- Name: SEQUENCE users_id_seq; Type: ACL; Schema: app; Owner: appowner
--

GRANT ALL ON SEQUENCE app.users_id_seq TO appuser;


--
-- Name: TABLE workflow_status; Type: ACL; Schema: app; Owner: appowner
--

GRANT ALL ON TABLE app.workflow_status TO appuser;


--
-- Name: SEQUENCE workflow_actionresponse_id_seq; Type: ACL; Schema: app; Owner: appowner
--

GRANT ALL ON SEQUENCE app.workflow_actionresponse_id_seq TO appuser;


--
-- Name: TABLE workflow_actions; Type: ACL; Schema: app; Owner: appowner
--

GRANT ALL ON TABLE app.workflow_actions TO appuser;


--
-- Name: SEQUENCE workflow_actions_id_seq; Type: ACL; Schema: app; Owner: appowner
--

GRANT ALL ON SEQUENCE app.workflow_actions_id_seq TO appuser;


--
-- Name: TABLE workflow_states; Type: ACL; Schema: app; Owner: appowner
--

GRANT ALL ON TABLE app.workflow_states TO appuser;


--
-- Name: SEQUENCE workflow_states_id_seq; Type: ACL; Schema: app; Owner: appowner
--

GRANT ALL ON SEQUENCE app.workflow_states_id_seq TO appuser;


--
-- Name: TABLE workflow_statetransitions; Type: ACL; Schema: app; Owner: appowner
--

GRANT ALL ON TABLE app.workflow_statetransitions TO appuser;


--
-- Name: SEQUENCE workflow_statetransitions_id_seq; Type: ACL; Schema: app; Owner: appowner
--

GRANT ALL ON SEQUENCE app.workflow_statetransitions_id_seq TO appuser;


--
-- Name: TABLE actions; Type: ACL; Schema: metadata; Owner: appowner
--

GRANT ALL ON TABLE metadata.actions TO appuser;


--
-- Name: SEQUENCE actions_id_seq; Type: ACL; Schema: metadata; Owner: appowner
--

GRANT SELECT,USAGE ON SEQUENCE metadata.actions_id_seq TO appuser;


--
-- Name: TABLE apiactions; Type: ACL; Schema: metadata; Owner: appowner
--

GRANT ALL ON TABLE metadata.apiactions TO appuser;


--
-- Name: SEQUENCE apiactions_id_seq; Type: ACL; Schema: metadata; Owner: appowner
--

GRANT SELECT,USAGE ON SEQUENCE metadata.apiactions_id_seq TO appuser;


--
-- Name: TABLE appcolumns; Type: ACL; Schema: metadata; Owner: appowner
--

GRANT ALL ON TABLE metadata.appcolumns TO appuser;


--
-- Name: SEQUENCE appcolumns_id_seq; Type: ACL; Schema: metadata; Owner: appowner
--

GRANT SELECT,USAGE ON SEQUENCE metadata.appcolumns_id_seq TO appuser;


--
-- Name: TABLE applications; Type: ACL; Schema: metadata; Owner: appowner
--

GRANT ALL ON TABLE metadata.applications TO appuser;


--
-- Name: SEQUENCE applications_id_seq; Type: ACL; Schema: metadata; Owner: appowner
--

GRANT SELECT,USAGE ON SEQUENCE metadata.applications_id_seq TO appuser;


--
-- Name: TABLE appqueries; Type: ACL; Schema: metadata; Owner: appowner
--

GRANT ALL ON TABLE metadata.appqueries TO appuser;


--
-- Name: TABLE apptables; Type: ACL; Schema: metadata; Owner: appowner
--

GRANT ALL ON TABLE metadata.apptables TO appuser;


--
-- Name: SEQUENCE apptables_id_seq; Type: ACL; Schema: metadata; Owner: appowner
--

GRANT SELECT,USAGE ON SEQUENCE metadata.apptables_id_seq TO appuser;


--
-- Name: TABLE columntemplate; Type: ACL; Schema: metadata; Owner: appowner
--

GRANT ALL ON TABLE metadata.columntemplate TO appuser;


--
-- Name: SEQUENCE columntemplate_id_seq; Type: ACL; Schema: metadata; Owner: appowner
--

GRANT SELECT,USAGE ON SEQUENCE metadata.columntemplate_id_seq TO appuser;


--
-- Name: TABLE controltypes; Type: ACL; Schema: metadata; Owner: appowner
--

GRANT ALL ON TABLE metadata.controltypes TO appuser;


--
-- Name: SEQUENCE controltypes_id_seq; Type: ACL; Schema: metadata; Owner: appowner
--

GRANT SELECT,USAGE ON SEQUENCE metadata.controltypes_id_seq TO appuser;


--
-- Name: TABLE datatypes; Type: ACL; Schema: metadata; Owner: appowner
--

GRANT ALL ON TABLE metadata.datatypes TO appuser;


--
-- Name: SEQUENCE datatypes_id_seq; Type: ACL; Schema: metadata; Owner: appowner
--

GRANT SELECT,USAGE ON SEQUENCE metadata.datatypes_id_seq TO appuser;


--
-- Name: TABLE events; Type: ACL; Schema: metadata; Owner: appowner
--

GRANT ALL ON TABLE metadata.events TO appuser;


--
-- Name: SEQUENCE events_id_seq; Type: ACL; Schema: metadata; Owner: appowner
--

GRANT SELECT,USAGE ON SEQUENCE metadata.events_id_seq TO appuser;


--
-- Name: TABLE fieldcategories; Type: ACL; Schema: metadata; Owner: appowner
--

GRANT ALL ON TABLE metadata.fieldcategories TO appuser;


--
-- Name: SEQUENCE fieldcategories_id_seq; Type: ACL; Schema: metadata; Owner: appowner
--

GRANT SELECT,USAGE ON SEQUENCE metadata.fieldcategories_id_seq TO appuser;


--
-- Name: TABLE formeventactions; Type: ACL; Schema: metadata; Owner: appowner
--

GRANT ALL ON TABLE metadata.formeventactions TO appuser;


--
-- Name: SEQUENCE formeventactions_id_seq; Type: ACL; Schema: metadata; Owner: appowner
--

GRANT SELECT,USAGE ON SEQUENCE metadata.formeventactions_id_seq TO appuser;


--
-- Name: TABLE formresources; Type: ACL; Schema: metadata; Owner: appowner
--

GRANT ALL ON TABLE metadata.formresources TO appuser;


--
-- Name: SEQUENCE formresources_id_seq; Type: ACL; Schema: metadata; Owner: appowner
--

GRANT SELECT,USAGE ON SEQUENCE metadata.formresources_id_seq TO appuser;


--
-- Name: TABLE images; Type: ACL; Schema: metadata; Owner: appowner
--

GRANT ALL ON TABLE metadata.images TO appuser;


--
-- Name: SEQUENCE images_id_seq; Type: ACL; Schema: metadata; Owner: appowner
--

GRANT SELECT,USAGE ON SEQUENCE metadata.images_id_seq TO appuser;


--
-- Name: SEQUENCE issues_id_seq; Type: ACL; Schema: metadata; Owner: appowner
--

GRANT SELECT,USAGE ON SEQUENCE metadata.issues_id_seq TO appuser;


--
-- Name: TABLE menuicons; Type: ACL; Schema: metadata; Owner: appowner
--

GRANT ALL ON TABLE metadata.menuicons TO appuser;


--
-- Name: SEQUENCE menuicons_id_seq; Type: ACL; Schema: metadata; Owner: appowner
--

GRANT SELECT,USAGE ON SEQUENCE metadata.menuicons_id_seq TO appuser;


--
-- Name: TABLE menuitems; Type: ACL; Schema: metadata; Owner: appowner
--

GRANT ALL ON TABLE metadata.menuitems TO appuser;


--
-- Name: SEQUENCE menuitems_id_seq; Type: ACL; Schema: metadata; Owner: appowner
--

GRANT SELECT,USAGE ON SEQUENCE metadata.menuitems_id_seq TO appuser;


--
-- Name: TABLE menupaths; Type: ACL; Schema: metadata; Owner: appowner
--

GRANT ALL ON TABLE metadata.menupaths TO appuser;


--
-- Name: SEQUENCE menupaths_id_seq; Type: ACL; Schema: metadata; Owner: appowner
--

GRANT SELECT,USAGE ON SEQUENCE metadata.menupaths_id_seq TO appuser;


--
-- Name: TABLE pageforms; Type: ACL; Schema: metadata; Owner: appowner
--

GRANT ALL ON TABLE metadata.pageforms TO appuser;


--
-- Name: SEQUENCE pageforms_id_seq; Type: ACL; Schema: metadata; Owner: appowner
--

GRANT SELECT,USAGE ON SEQUENCE metadata.pageforms_id_seq TO appuser;


--
-- Name: TABLE pages; Type: ACL; Schema: metadata; Owner: appowner
--

GRANT ALL ON TABLE metadata.pages TO appuser;


--
-- Name: SEQUENCE pages_id_seq; Type: ACL; Schema: metadata; Owner: appowner
--

GRANT SELECT,USAGE ON SEQUENCE metadata.pages_id_seq TO appuser;


--
-- Name: TABLE systemcategories; Type: ACL; Schema: metadata; Owner: appowner
--

GRANT ALL ON TABLE metadata.systemcategories TO appuser;


--
-- Name: SEQUENCE systemcategories_id_seq; Type: ACL; Schema: metadata; Owner: appowner
--

GRANT SELECT,USAGE ON SEQUENCE metadata.systemcategories_id_seq TO appuser;


--
-- Name: TABLE systemtables; Type: ACL; Schema: metadata; Owner: appowner
--

GRANT ALL ON TABLE metadata.systemtables TO appuser;


--
-- Name: SEQUENCE systemtables_id_seq; Type: ACL; Schema: metadata; Owner: appowner
--

GRANT SELECT,USAGE ON SEQUENCE metadata.systemtables_id_seq TO appuser;


--
-- Name: TABLE systemtabletypes; Type: ACL; Schema: metadata; Owner: appowner
--

GRANT ALL ON TABLE metadata.systemtabletypes TO appuser;


--
-- Name: SEQUENCE systemtabletypes_id_seq; Type: ACL; Schema: metadata; Owner: appowner
--

GRANT SELECT,USAGE ON SEQUENCE metadata.systemtabletypes_id_seq TO appuser;


--
-- Name: TABLE urlactions; Type: ACL; Schema: metadata; Owner: appowner
--

GRANT ALL ON TABLE metadata.urlactions TO appuser;


--
-- Name: SEQUENCE urlactions_id_seq; Type: ACL; Schema: metadata; Owner: appowner
--

GRANT SELECT,USAGE ON SEQUENCE metadata.urlactions_id_seq TO appuser;


--
-- PostgreSQL database dump complete
--

