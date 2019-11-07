-- app.support
delete from app.support where appid >=69 and appid <=72;

-- app.*
-- app.roleassignments
delete from app.roleassignments where roleid >= 28 and roleid <= 35;
-- app.usergroups
delete from app.usergroups where groupid >= 12 and groupid <= 14;
-- app.roles
delete from app.roles where name like 'Harrier%' or name like 'Hercules%' or name like 'Prowler%' or name like 'FRC%';
-- app.groups
delete from app.groups where name like 'Test%';
-- app.users
delete from app.users where email like '%@test%' or email like '%@harrier%' or email like '%@hercules%' or email like '%@prowler%' or email like '%@frc%';

-- metadata.formresources
-- metadata.urlactions
-- metadata.formeventactions
-- metadata.menuitems
delete from metadata.menuitems where appid >= 69 and appid <=72;
-- metadata.pageforms
-- metadata.pages
delete from metadata.pages where appid >= 69 and appid <=72;
-- metadata.appcolumns
-- metadata.apptables
-- app.roleassignments
-- app.roles
-- metadata.applications
delete from metadata.applications where id >= 69 and id <= 72;
