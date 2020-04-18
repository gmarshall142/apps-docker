-- metadata.applications
INSERT INTO metadata.applications (id, name, shortname, description) VALUES (69, 'Harrier', 'harrier', 'Test app harrier');
INSERT INTO metadata.applications (id, name, shortname, description) VALUES (70, 'Hercules', 'hercules', 'Test app hercules');
INSERT INTO metadata.applications (id, name, shortname, description) VALUES (71, 'Prowler', 'prowler', 'Test app prowler');
INSERT INTO metadata.applications (id, name, shortname, description) VALUES (72, 'Fleet Readiness Center', 'frc', 'Test app fleet readiness center');-- app.adhoc_queries
-- app.users email like '%@test%' or email like '%@harrier%' or email like '%@hercules%' or email like '%@prowler%' or email like '%@frc%'
INSERT INTO app.users (id, active, email, firstname, mi, lastname, designationid, phone, dsn, fax, npke_subject, npke_edipi, npke_user, rankid, activityid, affiliationid, siteid, saarn, initialdate, updatedate, lastlogindate, branchid, approvaldate, disabled, aircrafttypeid) VALUES (17, null, 'alison.abraham@harrier.mil', 'Alison', '', 'Abraham', null, '111-555.1212', null, null, 'CN=ABRAHAM.ALISON.12345,OU=Contractor,OU=PKI,OU=Dod,O=U.S. Government,C=US', null, null, null, null, null, null, null, '2019-05-10 13:32:39.847701', null, null, null, null, 1, null);
INSERT INTO app.users (id, active, email, firstname, mi, lastname, designationid, phone, dsn, fax, npke_subject, npke_edipi, npke_user, rankid, activityid, affiliationid, siteid, saarn, initialdate, updatedate, lastlogindate, branchid, approvaldate, disabled, aircrafttypeid) VALUES (18, null, 'tim.slater@harrier.mil', 'Tim', null, 'Slater', null, '111-555.1212', null, null, 'CN=SLATER.TIM.12345,OU=Contractor,OU=PKI,OU=Dod,O=U.S. Government,C=US', null, null, null, null, null, null, null, '2019-05-10 13:33:19.151415', null, null, null, null, 1, null);
INSERT INTO app.users (id, active, email, firstname, mi, lastname, designationid, phone, dsn, fax, npke_subject, npke_edipi, npke_user, rankid, activityid, affiliationid, siteid, saarn, initialdate, updatedate, lastlogindate, branchid, approvaldate, disabled, aircrafttypeid) VALUES (19, null, 'leonard.morgan@hercules.mil', 'Leonard', 'Q', 'Morgan', null, '111.555.1212', null, null, 'CN=MORGAN.LEONARD.Q.12345,OU=Contractor,OU=PKI,OU=Dod,O=U.S. Government,C=US', null, null, null, null, null, null, null, '2019-05-10 13:35:31.721547', null, null, null, null, 1, null);
INSERT INTO app.users (id, active, email, firstname, mi, lastname, designationid, phone, dsn, fax, npke_subject, npke_edipi, npke_user, rankid, activityid, affiliationid, siteid, saarn, initialdate, updatedate, lastlogindate, branchid, approvaldate, disabled, aircrafttypeid) VALUES (20, null, 'fiona.paige@hercules.mil', 'Fiona', 'L', 'Paige', null, '1115551212', null, null, 'CN=PAIGE.FIONA.L.12345,OU=Contractor,OU=PKI,OU=Dod,O=U.S. Government,C=US', null, null, null, null, null, null, null, '2019-05-10 13:36:08.654187', null, null, null, null, 1, null);
INSERT INTO app.users (id, active, email, firstname, mi, lastname, designationid, phone, dsn, fax, npke_subject, npke_edipi, npke_user, rankid, activityid, affiliationid, siteid, saarn, initialdate, updatedate, lastlogindate, branchid, approvaldate, disabled, aircrafttypeid) VALUES (21, null, 'natalie.hart@prowler.mil', 'Natalie', null, 'Hart', null, '1115551212', null, null, 'CN=HART.NATALIE.12345,OU=Contractor,OU=PKI,OU=Dod,O=U.S. Government,C=US', null, null, null, null, null, null, null, '2019-05-10 13:36:53.595822', null, null, null, null, 1, null);
INSERT INTO app.users (id, active, email, firstname, mi, lastname, designationid, phone, dsn, fax, npke_subject, npke_edipi, npke_user, rankid, activityid, affiliationid, siteid, saarn, initialdate, updatedate, lastlogindate, branchid, approvaldate, disabled, aircrafttypeid) VALUES (22, null, 'blake.fraser@prowler.mil', 'Blake', 'M', 'Fraser', null, '1115551212', null, null, 'CN=FRASER.BLAKE.M.12345,OU=Contractor,OU=PKI,OU=Dod,O=U.S. Government,C=US', null, null, null, null, null, null, null, '2019-05-10 13:37:16.288774', null, null, null, null, 1, null);
INSERT INTO app.users (id, active, email, firstname, mi, lastname, designationid, phone, dsn, fax, npke_subject, npke_edipi, npke_user, rankid, activityid, affiliationid, siteid, saarn, initialdate, updatedate, lastlogindate, branchid, approvaldate, disabled, aircrafttypeid) VALUES (23, null, 'steven.mcgrath@frc.org', 'Steven', 'I', 'McGrath', null, '1115551212', null, null, 'CN=MCGRATH.STEVEN.I.12345,OU=Contractor,OU=PKI,OU=Dod,O=U.S. Government,C=US', null, null, null, null, null, null, null, '2019-05-10 13:37:50.319268', null, null, null, null, 1, null);
INSERT INTO app.users (id, active, email, firstname, mi, lastname, designationid, phone, dsn, fax, npke_subject, npke_edipi, npke_user, rankid, activityid, affiliationid, siteid, saarn, initialdate, updatedate, lastlogindate, branchid, approvaldate, disabled, aircrafttypeid) VALUES (24, null, 'matt.black@frc.org', 'Matt', null, 'Black', null, '1115551212', null, null, 'CN=BLACK.MATT.12345,OU=Contractor,OU=PKI,OU=Dod,O=U.S. Government,C=US', null, null, null, null, null, null, null, '2019-05-10 13:38:11.794907', null, null, null, null, 1, null);
INSERT INTO app.users (id, active, email, firstname, mi, lastname, designationid, phone, dsn, fax, npke_subject, npke_edipi, npke_user, rankid, activityid, affiliationid, siteid, saarn, initialdate, updatedate, lastlogindate, branchid, approvaldate, disabled, aircrafttypeid) VALUES (27, null, 'lauren.mcgrath@testallapps.com', 'Lauren', 'A', 'McGrath', null, '1115551212', null, null, 'CN=MCGRATH.LAUREN.A.12345,OU=Contractor,OU=PKI,OU=Dod,O=U.S. Government,C=US', null, null, null, null, null, null, null, '2019-05-10 17:55:05.939000', null, null, null, null, 1, null);
INSERT INTO app.users (id, active, email, firstname, mi, lastname, designationid, phone, dsn, fax, npke_subject, npke_edipi, npke_user, rankid, activityid, affiliationid, siteid, saarn, initialdate, updatedate, lastlogindate, branchid, approvaldate, disabled, aircrafttypeid) VALUES (28, null, 'neil.scott@testallapps.com', 'Neil', 'B', 'Scott', null, '1115551212', null, null, 'CN=SCOTT.NEIL.B.12345,OU=Contractor,OU=PKI,OU=Dod,O=U.S. Government,C=US', null, null, null, null, null, null, null, '2019-05-10 17:55:28.034000', null, null, null, null, 1, null);
INSERT INTO app.users (id, active, email, firstname, mi, lastname, designationid, phone, dsn, fax, npke_subject, npke_edipi, npke_user, rankid, activityid, affiliationid, siteid, saarn, initialdate, updatedate, lastlogindate, branchid, approvaldate, disabled, aircrafttypeid) VALUES (29, null, 'jake.wilson@test2apps.com', 'Jake', 'C', 'Wilson', null, '1115551212', null, null, 'CN=WILSON.JAKE.C.12345,OU=Contractor,OU=PKI,OU=Dod,O=U.S. Government,C=US', null, null, null, null, null, null, null, '2019-05-10 17:55:59.893000', null, null, null, null, 1, null);
INSERT INTO app.users (id, active, email, firstname, mi, lastname, designationid, phone, dsn, fax, npke_subject, npke_edipi, npke_user, rankid, activityid, affiliationid, siteid, saarn, initialdate, updatedate, lastlogindate, branchid, approvaldate, disabled, aircrafttypeid) VALUES (30, null, 'paul.allan@test2apps.com', 'Paul', 'D', 'Allan', null, 'OU=PKI', 'OU=Dod', 'O=U.S. Government', 'CN=ALLAN.PAULD.12345,OU=Contractor,OU=PKI,OU=Dod,O=U.S. Government,C=US', null, null, null, null, null, null, null, '2019-05-10 17:56:21.231000', null, null, null, null, 1, null);
INSERT INTO app.users (id, active, email, firstname, mi, lastname, designationid, phone, dsn, fax, npke_subject, npke_edipi, npke_user, rankid, activityid, affiliationid, siteid, saarn, initialdate, updatedate, lastlogindate, branchid, approvaldate, disabled, aircrafttypeid) VALUES (31, null, 'leah.fisher@test3apps.com', 'Leah', 'E', 'Fisher', null, '1115551212', null, null, 'CN=FISHER.LEAH.E.12345,OU=Contractor,OU=PKI,OU=Dod,O=U.S. Government,C=US', null, null, null, null, null, null, null, '2019-05-10 17:57:05.852000', null, null, null, null, 1, null);
INSERT INTO app.users (id, active, email, firstname, mi, lastname, designationid, phone, dsn, fax, npke_subject, npke_edipi, npke_user, rankid, activityid, affiliationid, siteid, saarn, initialdate, updatedate, lastlogindate, branchid, approvaldate, disabled, aircrafttypeid) VALUES (32, null, 'maria.rampling@test3apps.com', 'Maria', 'F', 'Rampling', null, '1115551212', null, null, 'CN=RAMPLING.MARIA.F.12345,OU=Contractor,OU=PKI,OU=Dod,O=U.S. Government,C=US', null, null, null, null, null, null, null, '2019-05-10 17:57:28.141000', null, null, null, null, 1, null);
-- app.groups
INSERT INTO app.groups (id, name, description, createdat, updatedat) VALUES (12, 'TestAllApps', 'Test group that have access to all test apps', '2019-05-10 14:04:00.025000', '2019-05-10 14:04:00.025000');
INSERT INTO app.groups (id, name, description, createdat, updatedat) VALUES (13, 'Test2Apps', 'Test group that has access to Harrier and Hercules apps', '2019-05-10 14:04:29.588000', '2019-05-10 14:04:29.588000');
INSERT INTO app.groups (id, name, description, createdat, updatedat) VALUES (14, 'Test3Apps', 'Test group that has acess to Harrier, Prowler, and FRC apps', '2019-05-10 14:04:53.248000', '2019-05-10 14:04:53.248000');
-- app.roles
INSERT INTO app.roles (id, name, description, appid, createdat, updatedat) VALUES (28, 'Harrier Users', 'Harrier app access group', 69, '2019-05-10 14:18:05.426000', '2019-05-10 14:18:05.426000');
INSERT INTO app.roles (id, name, description, appid, createdat, updatedat) VALUES (29, 'Hercules users group', 'Hercules app access group', 70, '2019-05-10 14:19:08.003000', '2019-05-10 14:19:08.003000');
INSERT INTO app.roles (id, name, description, appid, createdat, updatedat) VALUES (30, 'Prowler Users', 'Prowler app access group', 71, '2019-05-10 14:19:59.416000', '2019-05-10 14:19:59.416000');
INSERT INTO app.roles (id, name, description, appid, createdat, updatedat) VALUES (31, 'FRC Users', 'Fleet Readiness Center app access group', 72, '2019-05-10 14:20:39.183000', '2019-05-10 14:20:39.183000');
INSERT INTO app.roles (id, name, description, appid, createdat, updatedat) VALUES (32, 'Harrier Admins', 'Harrier admins', 69, '2019-05-10 15:14:42.937000', '2019-05-10 15:14:42.937000');
INSERT INTO app.roles (id, name, description, appid, createdat, updatedat) VALUES (33, 'Hercules Admins', 'Hercules admins', 70, '2019-05-10 15:15:10.859000', '2019-05-10 15:15:10.859000');
INSERT INTO app.roles (id, name, description, appid, createdat, updatedat) VALUES (34, 'Prowler Admins', 'Prowler admins', 71, '2019-05-10 15:15:29.331000', '2019-05-10 15:15:29.331000');
INSERT INTO app.roles (id, name, description, appid, createdat, updatedat) VALUES (35, 'FRC Admins', 'Fleet Readiness Center admins', 72, '2019-05-10 15:15:52.991000', '2019-05-10 15:15:52.991000');
-- app.usergroups
INSERT INTO app.usergroups (id, userid, groupid, createdat, updatedat) VALUES (35, 27, 12, '2019-05-10 14:06:32.881271', '2019-05-10 14:06:32.881271');
INSERT INTO app.usergroups (id, userid, groupid, createdat, updatedat) VALUES (36, 28, 12, '2019-05-10 14:06:41.161548', '2019-05-10 14:06:41.161548');
INSERT INTO app.usergroups (id, userid, groupid, createdat, updatedat) VALUES (37, 30, 13, '2019-05-10 14:10:01.470405', '2019-05-10 14:10:01.470405');
INSERT INTO app.usergroups (id, userid, groupid, createdat, updatedat) VALUES (38, 29, 13, '2019-05-10 14:10:09.023193', '2019-05-10 14:10:09.023193');
INSERT INTO app.usergroups (id, userid, groupid, createdat, updatedat) VALUES (39, 31, 14, '2019-05-10 14:10:40.350972', '2019-05-10 14:10:40.350972');
INSERT INTO app.usergroups (id, userid, groupid, createdat, updatedat) VALUES (40, 32, 14, '2019-05-10 14:10:46.199960', '2019-05-10 14:10:46.199960');
-- app.roleassignments
INSERT INTO app.roleassignments (id, roleid, userid, groupid, createdat, updatedat) VALUES (55, 28, null, 13, '2019-05-10 14:18:05.556019', '2019-05-10 14:18:05.556019');
INSERT INTO app.roleassignments (id, roleid, userid, groupid, createdat, updatedat) VALUES (56, 28, null, 14, '2019-05-10 14:18:05.556019', '2019-05-10 14:18:05.556019');
INSERT INTO app.roleassignments (id, roleid, userid, groupid, createdat, updatedat) VALUES (57, 28, 17, null, '2019-05-10 14:18:05.556019', '2019-05-10 14:18:05.556019');
INSERT INTO app.roleassignments (id, roleid, userid, groupid, createdat, updatedat) VALUES (58, 28, 18, null, '2019-05-10 14:18:05.556019', '2019-05-10 14:18:05.556019');
INSERT INTO app.roleassignments (id, roleid, userid, groupid, createdat, updatedat) VALUES (59, 29, null, 13, '2019-05-10 14:19:08.123599', '2019-05-10 14:19:08.123599');
INSERT INTO app.roleassignments (id, roleid, userid, groupid, createdat, updatedat) VALUES (61, 29, 19, null, '2019-05-10 14:19:08.123599', '2019-05-10 14:19:08.123599');
INSERT INTO app.roleassignments (id, roleid, userid, groupid, createdat, updatedat) VALUES (62, 29, 20, null, '2019-05-10 14:19:08.123599', '2019-05-10 14:19:08.123599');
INSERT INTO app.roleassignments (id, roleid, userid, groupid, createdat, updatedat) VALUES (64, 30, null, 14, '2019-05-10 14:19:59.547008', '2019-05-10 14:19:59.547008');
INSERT INTO app.roleassignments (id, roleid, userid, groupid, createdat, updatedat) VALUES (65, 30, 22, null, '2019-05-10 14:19:59.547008', '2019-05-10 14:19:59.547008');
INSERT INTO app.roleassignments (id, roleid, userid, groupid, createdat, updatedat) VALUES (66, 30, 21, null, '2019-05-10 14:19:59.547008', '2019-05-10 14:19:59.547008');
INSERT INTO app.roleassignments (id, roleid, userid, groupid, createdat, updatedat) VALUES (68, 31, null, 14, '2019-05-10 14:20:39.300648', '2019-05-10 14:20:39.300648');
INSERT INTO app.roleassignments (id, roleid, userid, groupid, createdat, updatedat) VALUES (69, 31, 24, null, '2019-05-10 14:20:39.300648', '2019-05-10 14:20:39.300648');
INSERT INTO app.roleassignments (id, roleid, userid, groupid, createdat, updatedat) VALUES (70, 31, 23, null, '2019-05-10 14:20:39.300648', '2019-05-10 14:20:39.300648');
INSERT INTO app.roleassignments (id, roleid, userid, groupid, createdat, updatedat) VALUES (71, 32, null, 1, '2019-05-10 15:14:43.045461', '2019-05-10 15:14:43.045461');
INSERT INTO app.roleassignments (id, roleid, userid, groupid, createdat, updatedat) VALUES (72, 33, null, 1, '2019-05-10 15:15:10.979722', '2019-05-10 15:15:10.979722');
INSERT INTO app.roleassignments (id, roleid, userid, groupid, createdat, updatedat) VALUES (73, 34, null, 1, '2019-05-10 15:15:29.443316', '2019-05-10 15:15:29.443316');
INSERT INTO app.roleassignments (id, roleid, userid, groupid, createdat, updatedat) VALUES (74, 35, null, 1, '2019-05-10 15:15:53.099402', '2019-05-10 15:15:53.099402');
INSERT INTO app.roleassignments (id, roleid, userid, groupid, createdat, updatedat) VALUES (75, 32, null, 12, '2019-05-13 19:10:32.986666', '2019-05-13 19:10:32.986666');
INSERT INTO app.roleassignments (id, roleid, userid, groupid, createdat, updatedat) VALUES (76, 33, null, 12, '2019-05-13 19:10:57.051038', '2019-05-13 19:10:57.051038');
INSERT INTO app.roleassignments (id, roleid, userid, groupid, createdat, updatedat) VALUES (77, 34, null, 12, '2019-05-13 19:11:15.358755', '2019-05-13 19:11:15.358755');
INSERT INTO app.roleassignments (id, roleid, userid, groupid, createdat, updatedat) VALUES (78, 35, null, 12, '2019-05-13 19:11:34.550553', '2019-05-13 19:11:34.550553');
-- metadata.apptables
-- metadata.appcolumns
-- users
-- app users
-- metadata.appcolumns

-- metadata.pages
INSERT INTO metadata.pages (id, appid, title, name, description, allowedroles, helppath) VALUES (101, 69, 'Harrier Page 3', 'harrier3', 'Harrier app page 3', '{32}', null);
INSERT INTO metadata.pages (id, appid, title, name, description, allowedroles, helppath) VALUES (100, 69, 'Harrier Page 2', 'harrier2', 'Harrier app page 2', '{28,32}', null);
INSERT INTO metadata.pages (id, appid, title, name, description, allowedroles, helppath) VALUES (99, 69, 'Harrier Page 1', 'harrier1', 'Harrier app page 1', '{28,32}', null);
INSERT INTO metadata.pages (id, appid, title, name, description, allowedroles, helppath) VALUES (104, 70, 'Hercules Page 3', 'hercules3', 'Hercules app page 3', '{29,33}', null);
INSERT INTO metadata.pages (id, appid, title, name, description, allowedroles, helppath) VALUES (102, 70, 'Hercules Page 1', 'hercules1', 'Hercules app page 1', '{29,33}', null);
INSERT INTO metadata.pages (id, appid, title, name, description, allowedroles, helppath) VALUES (103, 70, 'Hercules Page 2', 'hercules2', 'Hercules app page 2', '{33}', null);
INSERT INTO metadata.pages (id, appid, title, name, description, allowedroles, helppath) VALUES (107, 71, 'Prowler Page 3', 'prowler3', 'Prowler app page 3', '{30,34}', null);
INSERT INTO metadata.pages (id, appid, title, name, description, allowedroles, helppath) VALUES (106, 71, 'Prowler Page 2', 'prowler2', 'Prowler app page 2', '{30,34}', null);
INSERT INTO metadata.pages (id, appid, title, name, description, allowedroles, helppath) VALUES (105, 71, 'Prowler Page 1', 'prowler1', 'Prowler app page 1', '{34}', null);
INSERT INTO metadata.pages (id, appid, title, name, description, allowedroles, helppath) VALUES (108, 72, 'FRC Page 1', 'frc1', 'FRC app page 1', '{31,35}', null);
INSERT INTO metadata.pages (id, appid, title, name, description, allowedroles, helppath) VALUES (110, 72, 'FRC Page 3', 'frc3', 'FRC app page 3', '{31,35}', null);
INSERT INTO metadata.pages (id, appid, title, name, description, allowedroles, helppath) VALUES (109, 72, 'FRC Page 2', 'frc2', 'FRC app page 2', '{31,35}', null);

-- metadata.pageforms

-- metadata.urlactions
-- metadata.menuitems
INSERT INTO metadata.menuitems (id, parentid, label, iconid, appid, pageid, active, position, pathid, routerpath) VALUES (175, 3, 'Harrier', null, 69, 0, 1, 2, null, 'harrier');
INSERT INTO metadata.menuitems (id, parentid, label, iconid, appid, pageid, active, position, pathid, routerpath) VALUES (179, 175, 'Harrier Page 1', null, 69, 99, 1, 1, null, '');
INSERT INTO metadata.menuitems (id, parentid, label, iconid, appid, pageid, active, position, pathid, routerpath) VALUES (180, 175, 'Harrier Page 2', null, 69, 100, 1, 2, null, '');
INSERT INTO metadata.menuitems (id, parentid, label, iconid, appid, pageid, active, position, pathid, routerpath) VALUES (181, 175, 'Harrier Page 3', null, 69, 101, 1, 3, null, '');
INSERT INTO metadata.menuitems (id, parentid, label, iconid, appid, pageid, active, position, pathid, routerpath) VALUES (176, 3, 'Hercules', null, 70, 0, 1, 3, null, 'hercules');
INSERT INTO metadata.menuitems (id, parentid, label, iconid, appid, pageid, active, position, pathid, routerpath) VALUES (182, 176, 'Hercules Page 1', null, 70, 102, 1, 1, null, '');
INSERT INTO metadata.menuitems (id, parentid, label, iconid, appid, pageid, active, position, pathid, routerpath) VALUES (183, 176, 'Hercules Page 2', null, 70, 103, 1, 2, null, '');
INSERT INTO metadata.menuitems (id, parentid, label, iconid, appid, pageid, active, position, pathid, routerpath) VALUES (184, 176, 'Hercules Page 3', null, 70, 104, 1, 3, null, '');
INSERT INTO metadata.menuitems (id, parentid, label, iconid, appid, pageid, active, position, pathid, routerpath) VALUES (177, 3, 'Prowler', null, 71, 0, 1, 4, null, 'prowler');
INSERT INTO metadata.menuitems (id, parentid, label, iconid, appid, pageid, active, position, pathid, routerpath) VALUES (185, 177, 'Prowler Page 1', null, 71, 105, 1, 1, null, '');
INSERT INTO metadata.menuitems (id, parentid, label, iconid, appid, pageid, active, position, pathid, routerpath) VALUES (186, 177, 'Prowler Page 2', null, 71, 106, 1, 2, null, '');
INSERT INTO metadata.menuitems (id, parentid, label, iconid, appid, pageid, active, position, pathid, routerpath) VALUES (187, 177, 'Prowler Page 3', null, 71, 107, 1, 3, null, '');
INSERT INTO metadata.menuitems (id, parentid, label, iconid, appid, pageid, active, position, pathid, routerpath) VALUES (178, 3, 'Fleet Readiness Center', null, 72, 0, 1, 5, null, 'frc');
INSERT INTO metadata.menuitems (id, parentid, label, iconid, appid, pageid, active, position, pathid, routerpath) VALUES (188, 178, 'FRC Page 1', null, 72, 108, 1, 1, null, '');
INSERT INTO metadata.menuitems (id, parentid, label, iconid, appid, pageid, active, position, pathid, routerpath) VALUES (189, 178, 'FRC Page 2', null, 72, 109, 1, 2, null, '');
INSERT INTO metadata.menuitems (id, parentid, label, iconid, appid, pageid, active, position, pathid, routerpath) VALUES (190, 178, 'FRC Page 3', null, 72, 110, 1, 3, null, '');
-- metadata.formeventactions
-- metadata.formresources
-- app.status
-- app.activity
-- app.priority
-- app.appbunos
-- app.issuetypes
-- app.workflow_actions
-- app.workflow_status
-- app.workflow_states
-- app.workflow_statetransitions

-- app.masterdata

-- app.appdata

-- app.issues
-- app.support: appid >=69 and appid <=72
INSERT INTO app.support (id, title, value, hours, userid, createdat, updatedat, displayorder, appid) VALUES (9, 'Navy / Marine Corps East Coast', null, null, 10, '2019-10-17 12:50:25.000000', '2019-10-17 12:50:27.000000', 1, 72);
INSERT INTO app.support (id, title, value, hours, userid, createdat, updatedat, displayorder, appid) VALUES (10, 'Navy / Marine Corps West Coast', null, null, 11, '2019-10-17 12:50:56.000000', '2019-10-17 12:50:58.000000', 2, 72);
INSERT INTO app.support (id, title, value, hours, userid, createdat, updatedat, displayorder, appid) VALUES (11, 'Navy / Marine Corps East Coast', null, null, 29, '2019-10-17 12:51:58.000000', '2019-10-17 12:52:00.000000', 1, 69);
INSERT INTO app.support (id, title, value, hours, userid, createdat, updatedat, displayorder, appid) VALUES (12, 'Navy / Marine Corps West Coast', null, null, 31, '2019-10-17 12:52:31.000000', '2019-10-17 12:52:33.000000', 2, 69);
INSERT INTO app.support (id, title, value, hours, userid, createdat, updatedat, displayorder, appid) VALUES (13, 'Navy / Marine Corps East Coast', null, null, 30, '2019-10-17 12:53:46.000000', '2019-10-17 12:53:48.000000', 1, 70);
INSERT INTO app.support (id, title, value, hours, userid, createdat, updatedat, displayorder, appid) VALUES (14, 'Navy / Marine Corps East Coast', null, null, 32, '2019-10-17 12:53:46.000000', '2019-10-17 12:53:48.000000', 1, 71);
INSERT INTO app.support (id, title, value, hours, userid, createdat, updatedat, displayorder, appid) VALUES (15, 'Navy / Marine Corps West Coast', null, null, 27, '2019-10-17 12:52:31.000000', '2019-10-17 12:52:33.000000', 2, 70);
INSERT INTO app.support (id, title, value, hours, userid, createdat, updatedat, displayorder, appid) VALUES (16, 'Navy / Marine Corps West Coast', null, null, 28, '2019-10-17 12:52:31.000000', '2019-10-17 12:52:33.000000', 2, 71);
