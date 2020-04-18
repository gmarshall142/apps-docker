-- app.*
delete from app.issues where appid = 66;
delete from app.activity where appid = 66;
delete from app.appdata where appid = 66;
delete from app.workflow_statetransitions where appid = 66;
delete from app.workflow_states where appid = 66;
delete from app.workflow_status where appid = 66;
delete from app.workflow_actions where appid = 66;
delete from app.issuetypes where appid = 66;
delete from app.masterdata where appid = 66;
delete from app.priority where appid = 66;
delete from app.status where appid = 66;
delete from app.appbunos where appid = 66;
-- metadata.formresources
delete from metadata.formresources where appid = 66;
-- metadata.urlactions
delete from metadata.urlactions where appid = 66;
-- metadata.formeventactions
delete from metadata.formeventactions where pageformid = 66;
delete from metadata.formeventactions where pageformid = 67;
delete from metadata.formeventactions where pageformid = 68;
delete from metadata.formeventactions where pageformid = 69;
delete from metadata.formeventactions where pageformid = 70;
-- metadata.menuitems
delete from metadata.menuitems where parentid = 160;
delete from metadata.menuitems where parentid = 153;
delete from metadata.menuitems where parentid = 146;
delete from metadata.menuitems where parentid = 138;
delete from metadata.menuitems where id = 138;
-- metadata.pageforms
delete from metadata.pageforms where pageid = 84;
delete from metadata.pageforms where pageid = 85;
delete from metadata.pageforms where pageid = 86;
delete from metadata.pageforms where pageid = 87;
delete from metadata.pageforms where pageid = 88;
delete from metadata.pageforms where pageid = 89;
delete from metadata.pageforms where pageid = 90;
-- metadata.pages
delete from metadata.pages where appid = 66;
-- metadata.appcolumns
delete from metadata.appcolumns where apptableid = 92;
delete from metadata.appcolumns where apptableid = 93;
delete from metadata.appcolumns where apptableid = 94;
delete from metadata.appcolumns where apptableid = 95;
delete from metadata.appcolumns where apptableid = 96;
delete from metadata.appcolumns where apptableid = 97;
-- metadata.apptables
delete from metadata.apptables where appid = 66;
-- app.roleassignments
delete from app.roleassignments where roleid = 13;
delete from app.roleassignments where roleid = 14;
-- app.roles
delete from app.roles where appid = 66;
-- metadata.applications
delete from metadata.applications where id = 66;

