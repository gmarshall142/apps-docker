-- app.*
delete from app.issues where appid = 1;
delete from app.activity where appid = 1;
delete from app.appdata where appid = 1;
delete from app.workflow_statetransitions where appid = 1;
delete from app.workflow_states where appid = 1;
delete from app.workflow_status where appid = 1;
delete from app.workflow_actions where appid = 1;
delete from app.issuetypes where appid = 1;
delete from app.masterdata where appid = 1;
delete from app.priority where appid = 1;
delete from app.status where appid = 1;
delete from app.appbunos where appid = 1;
-- metadata.formresources
delete from metadata.formresources where appid = 1;
-- metadata.urlactions
delete from metadata.urlactions where appid = 1;
-- metadata.formeventactions
delete from metadata.formeventactions where pageformid = 19;
delete from metadata.formeventactions where pageformid = 27;
delete from metadata.formeventactions where pageformid = 72;
delete from metadata.formeventactions where pageformid = 73;
delete from metadata.formeventactions where pageformid = 74;
-- metadata.menuitems
delete from metadata.menuitems where parentid = 29;
delete from metadata.menuitems where parentid = 28;
delete from metadata.menuitems where parentid = 8;
delete from metadata.menuitems where id = 8;
-- metadata.pageforms
delete from metadata.pageforms where pageid = 9;
delete from metadata.pageforms where pageid = 10;
delete from metadata.pageforms where pageid = 11;
delete from metadata.pageforms where pageid = 93;
delete from metadata.pageforms where pageid = 94;
-- metadata.pages
delete from metadata.pages where appid = 1;
-- metadata.appcolumns
delete from metadata.appcolumns where apptableid = 102;
delete from metadata.appcolumns where apptableid = 103;
delete from metadata.appcolumns where apptableid = 104;
delete from metadata.appcolumns where apptableid = 105;
delete from metadata.appcolumns where apptableid = 106;
delete from metadata.appcolumns where apptableid = 107;
delete from metadata.appcolumns where apptableid = 108;
delete from metadata.appcolumns where apptableid = 109;
delete from metadata.appcolumns where apptableid = 110;
delete from metadata.appcolumns where apptableid = 111;
delete from metadata.appcolumns where apptableid = 112;
delete from metadata.appcolumns where apptableid = 113;
delete from metadata.appcolumns where apptableid = 114;
delete from metadata.appcolumns where apptableid = 115;
delete from metadata.appcolumns where apptableid = 116;
delete from metadata.appcolumns where apptableid = 117;
-- metadata.apptables
delete from metadata.apptables where appid = 1;
-- app.roleassignments
delete from app.roleassignments where roleid = 16;
delete from app.roleassignments where roleid = 17;
delete from app.roleassignments where roleid = 21;
delete from app.roleassignments where roleid = 26;
-- app.roles
delete from app.roles where appid = 1;
-- metadata.applications
delete from metadata.applications where id = 1;

