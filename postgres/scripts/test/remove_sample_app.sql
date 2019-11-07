-- app.support
delete from app.support where appid = 10;
-- tableattachments
delete from app.tableattachments where apptableid = 86;
delete from app.tableattachments where apptableid = 118;
-- attachments
delete from app.attachments where path = '/apps/10';
-- app.*
delete from app.issues where appid = 10;
delete from app.activity where appid = 10;
delete from app.appdata where appid = 10;
delete from app.workflow_statetransitions where appid = 10;
delete from app.workflow_states where appid = 10;
delete from app.workflow_status where appid = 10;
delete from app.workflow_actions where appid = 10;
delete from app.issuetypes where appid = 10;
delete from app.masterdata where appid = 10;
delete from app.priority where appid = 10;
delete from app.status where appid = 10;
delete from app.appbunos where appid = 10;
delete from app.adhoc_queries where appid = 10;
-- metadata.formresources
delete from metadata.formresources where appid = 10;
-- metadata.urlactions
delete from metadata.urlactions where appid = 10;
-- metadata.formeventactions
delete from metadata.formeventactions where (pageformid >= 61 and pageformid <= 63) or (pageformid >=75 and pageformid <= 81);
-- metadata.reporttemplates
delete from app.reporttemplates where appid = 10;
-- metadata.appqueries
delete from metadata.appqueries where appid = 10;
-- metadata.menuitems
delete from metadata.menuitems where appid = 10;
-- metadata.pageforms
delete from metadata.pageforms where (pageid >= 79 and pageid <= 81) or (pageid >= 95 and pageid <= 98) or (pageid >= 113 and pageid <= 116);
-- metadata.pages
delete from metadata.pages where appid = 10;
-- metadata.appcolumns
delete from metadata.appcolumns where apptableid = 82;
delete from metadata.appcolumns where apptableid = 83;
delete from metadata.appcolumns where apptableid = 84;
delete from metadata.appcolumns where apptableid = 85;
delete from metadata.appcolumns where apptableid = 86;
delete from metadata.appcolumns where apptableid = 98;
delete from metadata.appcolumns where apptableid = 99;
delete from metadata.appcolumns where apptableid = 100;
delete from metadata.appcolumns where apptableid = 118;
delete from metadata.appcolumns where apptableid = 119;
delete from metadata.appcolumns where apptableid = 120;
delete from metadata.appcolumns where apptableid = 121;
delete from metadata.appcolumns where apptableid = 122;
delete from metadata.appcolumns where apptableid = 123;
delete from metadata.appcolumns where apptableid = 124;
delete from metadata.appcolumns where apptableid = 125;
delete from metadata.appcolumns where apptableid = 126;
delete from metadata.appcolumns where apptableid = 128;
-- metadata.apptables
delete from metadata.apptables where appid = 10;
-- app.roleassignments : roleid = 3 or roleid = 15 or (roleid >= 37 and roleid <= 41)
delete from app.roleassignments where roleid = 3;
delete from app.roleassignments where roleid = 15;
delete from app.roleassignments where roleid >= 37 and roleid <= 41;
-- app.roles
delete from app.roles where appid = 10;
-- metadata.applications
delete from metadata.applications where id = 10;

