-- app.*
delete from app.issues where appid = 6;
delete from app.activity where appid = 6;
delete from app.appdata where appid = 6;
delete from app.issuetypes where appid = 6;
delete from app.masterdata where appid = 6;
delete from app.priority where appid = 6;
delete from app.status where appid = 6;
delete from app.appbunos where appid = 6;
-- metadata.formresources
delete from metadata.formresources where appid = 6;
-- metadata.formeventactions
delete from metadata.formeventactions where pageformid = 61;
delete from metadata.formeventactions where pageformid = 62;
delete from metadata.formeventactions where pageformid = 63;
-- metadata.menuitems
delete from metadata.menuitems where parentid = 143;
delete from metadata.menuitems where parentid = 71;
delete from metadata.menuitems where parentid = 38;
delete from metadata.menuitems where id = 38;
-- metadata.pageforms
delete from metadata.pageforms where pageid = 79;
delete from metadata.pageforms where pageid = 80;
delete from metadata.pageforms where pageid = 81;
-- metadata.pages
delete from metadata.pages where appid = 6;
-- metadata.appcolumns
delete from metadata.appcolumns where apptableid = 82;
delete from metadata.appcolumns where apptableid = 83;
delete from metadata.appcolumns where apptableid = 84;
delete from metadata.appcolumns where apptableid = 85;
delete from metadata.appcolumns where apptableid = 86;
-- metadata.apptables
delete from metadata.apptables where appid = 6;
-- app.roleassignments
delete from app.roleassignments where roleid = 3;
delete from app.roleassignments where roleid = 15;
-- app.roles
delete from app.roles where appid = 6;
-- metadata.applications
delete from metadata.applications where id = 6;

