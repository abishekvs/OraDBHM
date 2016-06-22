set serveroutput on size unlimited
set term off
set echo off
set feed off
column fname new_value filename
column hname new_value hostname
column iname new_value instname
column ilink new_value ahref
select 'RTPA_'||to_char(sysdate,'DDMONYYYY-hh24MI')||'_'||name||'.html' fname from v$database;
select instance_name iname from v$instance;
select host_name hname from v$instance;
select '^<li^>^<a href="&&filename" target="report" ^>' || host_name ||' ('||instance_name ||')^</a^>^</li^>' ilink from v$instance;
spool reports\&&filename
exec pkgrtpa.showreport3('&1');
spool off
host echo &&ahref >> reports\&2
exit

