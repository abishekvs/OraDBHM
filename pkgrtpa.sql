drop TYPE alert_table$$;
drop TYPE alert_row$$;
drop table alert_log_external$$;
CREATE OR REPLACE TYPE alert_row$$ AS OBJECT (
                item_date   date,
                item_desc  VARCHAR2(500)
              );
/              
              
CREATE OR REPLACE TYPE alert_table$$ IS TABLE OF alert_row$$;
/

  /**
    Procedure to create external table of alertlog
    
  */
  
CREATE OR REPLACE procedure external_alert_log 
is
  path_bdump varchar2(500);
  name_alert varchar2(100);
begin
  
    select value into path_bdump from 
      v$parameter
    where
      name = 'background_dump_dest';
  
    select
      'alert_' || value || '.log' into name_alert
    from
      v$parameter
    where
      name = 'db_name';
  
    execute immediate 'create or replace directory background_dump_dest_dir$$ as ''' || 
      path_bdump || '''';
  
    execute immediate 
      'create table alert_log_external$$ '              ||
      ' (line  varchar2(4000) ) '                     ||
      '  organization external '                      ||
      ' (type oracle_loader '                         ||
      '  default directory background_dump_dest_dir$$ ' ||
      '  access parameters ( '                        ||
      '    records delimited by newline '             ||
      '    nobadfile '                                ||
      '    nologfile '                                ||
      '    nodiscardfile '                            ||
      '    fields terminated by ''#$~=ui$X'''         ||
      '    missing field values are null '            ||
      '    (line)  '                                  ||
      '  ) '                                          ||
      '  location (''' || name_alert || ''') )'       ||
      '  reject limit unlimited ';
end;
/

begin
  external_alert_log;
end;
/

CREATE OR REPLACE
FUNCTION get_alert_table (log_date IN DATE DEFAULT SYSDATE - 7 ) 
RETURN alert_table$$ PIPELINED 
IS
  
  cursor alrtlog is select * from alert_log_external$$;
  
  l_line varchar2(500);
  item_date date;
  item_desc varchar2(500);

  FUNCTION ChkAlertDate (line in varchar2 default null) 
  return DATE
  as
  BEGIN
    return to_date(line,'DY Mon DD HH24:MI:SS YYYY');
  EXCEPTION
    when others then
      return null;
  END;
  --TYPE alert_row$$ AS OBJECT (  item_date   date,  item_desc  VARCHAR2(500) );
  --TYPE alert_table$$ IS TABLE OF alert_row$$;
BEGIN
  
  open alrtlog;
  loop
    <<start_loop>>
    fetch alrtlog into l_line;
    exit when alrtlog%NOTFOUND;
  
    if ChkAlertDate(l_line) is not null then
      item_date:=ChkAlertDate(l_line);
      goto start_loop;
    else
      item_desc:=l_line;
    end if;
  
  
    PIPE ROW(alert_row$$(item_date,item_desc));
    
    /*  
      FOR i IN 1 .. p_rows LOOP
        PIPE ROW(t_tf_row(i, 'Description for ' || i));   
      END LOOP;
    */
  end loop;
  RETURN;
END;
/


CREATE OR REPLACE PACKAGE PKGRTPA
AS
-- Global Variables
param_val   owa.vc_arr; /*This is used to init the OWA_UTIL */
------------------------
--PROCEDURE INTUTIL_INITOWA;
--PROCEDURE PRNPAGEHEADER;

PROCEDURE OOCIS_patchreport;
PROCEDURE OOCIS_DBINFO;
PROCEDURE OOCIS_INSTINFO;
/*
PROCEDURE OOCIS_CtrlFileCheck;
PROCEDURE OOCIS_LogFileCheck;
PROCEDURE OOCIS_ObjValidCheck;
PROCEDURE OOCIS_DBCompCheck;
PROCEDURE OOCIS_NonSysObjSystemTbs;
PROCEDURE OOCIS_RMANJobDetails;
PROCEDURE OOCIS_obsoleteparams;
PROCEDURE OOCIS_UsersElevatedRoles;
PROCEDURE OOCIS_UsersElevatedPrivs;
PROCEDURE OOCIS_GetAlertLogErrs;
PROCEDURE OOCIS_TbsSpaceUsageRpt;
*/
PROCEDURE OOCIS_OSStat;
PROCEDURE OOCIS_DBParams;

PROCEDURE OOCIS_obsoleteparams1;
PROCEDURE OOCIS_GetAlertLogErrs1;
PROCEDURE OOCIS_CtrlFileCheck1;
PROCEDURE OOCIS_LogFileCheck1;
PROCEDURE OOCIS_ObjValidCheck1;
PROCEDURE OOCIS_NonSysObjSystemTbs1;
PROCEDURE OOCIS_DBCompCheck1;
PROCEDURE OOCIS_RMANJobDetails1;
PROCEDURE OOCIS_UsersElevatedRoles1;
PROCEDURE OOCIS_UsersElevatedPrivs1;
PROCEDURE OOCIS_TbsSpaceUsageRpt1;


PROCEDURE SHOWREPORT3 (dblog in varchar2 default null);
PROCEDURE SHOWREPORT (dblog in varchar2 default null);
--PROCEDURE SHOWREPORT1 (dblog in varchar2 default null);
--PROCEDURE SHOWREPORT2 (dblog in varchar2 default null); 
PROCEDURE GENREPORT  (p_dir     in varchar2,   p_fname   in varchar2 default null, dblog in varchar2 default null);
-- HTML Utils
--PROCEDURE PRINTPARA (cText in varchar2);

END PKGRTPA;
/

CREATE OR REPLACE PACKAGE BODY PKGRTPA
AS

  YN_CtrlFileCheck varchar2(3):='YES';
  YN_LogFileCheck varchar2(3):='YES';
  YN_ObjValidCheck varchar2(3):='YES';
  YN_DBCompCheck varchar2(3):='YES';
  YN_NonSysObjSystemTbs varchar2(3):='YES';
  YN_RMANJobDetails varchar2(3):='YES';
  YN_obsoleteparams varchar2(3):='YES';
  YN_UsersElevatedRoles varchar2(3):='YES';
  YN_UsersElevatedPrivs varchar2(3):='YES';
  YN_GetAlertLogErrs varchar2(3):='YES';
  YN_TbsSpaceUsageRpt varchar2(3):='YES';
  

  PROCEDURE INITOWA
  IS
  begin
     if owa.num_cgi_vars is null
     then
      null;
        param_val (1) := 1;
        owa.init_cgi_env (param_val);
     end if;
  end;

  procedure dump_page( p_dir     in varchar2,   p_fname   in varchar2 default null)
  is
      l_thePage       htp.htbuf_arr;
      l_output        utl_file.file_type;
      l_lines         number default 99999999;
      
      filename varchar2(500):='';
      
  begin
      
      select 'RTPA_'||name||'_'||to_char(sysdate,'Mondd_hh24mi')||'.html' into filename from  v$database;
      
      if p_fname is not null then
        filename:=p_fname;
      end if;
      
      --l_output := utl_file.fopen( p_dir, p_fname, 'w' );
      l_output := utl_file.fopen( p_dir, filename, 'w' );
      
      owa.get_page( l_thePage, l_lines );
  
      for i in 1 .. l_lines loop
          utl_file.put( l_output, l_thePage(i) );
      end loop;
  
      utl_file.fclose( l_output );
  end dump_page;

  /**
    HTML Utility procs
  */
  
  PROCEDURE PRINTPARA (cText in varchar2)
  is
  begin
    HTP.PARAGRAPH;
    htp.print (ctext);
    htp.print ('</P>');
  end;

  PROCEDURE TBLOPEN (
         cborder        IN       VARCHAR2   DEFAULT NULL,
         calign         IN       VARCHAR2   DEFAULT NULL,
         cnowrap        IN       VARCHAR2   DEFAULT NULL,
         cclear         IN       VARCHAR2   DEFAULT NULL,
         cattributes    IN       VARCHAR2   DEFAULT NULL)
  is
  begin
    HTP.TABLEOPEN(cborder, calign, cnowrap, cclear, cattributes);
  end;
  
  PROCEDURE TBLCLOSE
  is
  begin
    HTP.TABLECLOSE;
  end;
  
  PROCEDURE BTR
  IS
  begin
    htp.tableRowOpen;
  end;

  PROCEDURE ETR
  IS
  begin
    htp.tableRowClose;
  end;
  
  PROCEDURE TDATA(
   cvalue         IN       VARCHAR2   DEFAULT NULL,
   calign         IN       VARCHAR2   DEFAULT NULL,
   cdp            IN       VARCHAR2   DEFAULT NULL,
   cnowrap        IN       VARCHAR2   DEFAULT NULL,
   crowspan       IN       VARCHAR2   DEFAULT NULL,
   ccolspan       IN       VARCHAR2   DEFAULT NULL,
   cattributes    IN       VARCHAR2   DEFAULT NULL)
  IS
    cattr varchar2(200);
  begin
    if cattributes is null then
      cattr:='class=awrc';
    else
      cattr := cattributes;
    end if;
    htp.tableData(cvalue,calign,cdp,cnowrap,crowspan,ccolspan,cattr);
  end;

  PROCEDURE THDATA(
   cvalue         IN       VARCHAR2   DEFAULT NULL,
   calign         IN       VARCHAR2   DEFAULT NULL,
   cdp            IN       VARCHAR2   DEFAULT NULL,
   cnowrap        IN       VARCHAR2   DEFAULT NULL,
   crowspan       IN       VARCHAR2   DEFAULT NULL,
   ccolspan       IN       VARCHAR2   DEFAULT NULL,
   cattributes    IN       VARCHAR2   DEFAULT NULL)
  IS
    cattr varchar2(200);
  begin
    if cattributes is null then
      cattr:='class=awrbg';
    else
      cattr := cattributes;
    end if;
    htp.tableHeader (cvalue,calign,cdp,cnowrap,crowspan,ccolspan,cattr);
  end;

  PROCEDURE PRINTPAGEHDR
  IS
  begin
    INITOWA;
    HTP.htmlopen;
    HTP.headopen;
    HTP.title('Oracle Database Healthcheck Report (Unisys CIS) v1.0');
    htp.print (
    /*'
<!--html><head><title>Oracle Database Healthcheck Report (Unisys CIS) v1.0</title--> */
'
<style type="text/css">
body.awr {font:bold 10pt Arial,Helvetica,Geneva,sans-serif;color:black; background:White;}
pre.awr  {font:8pt Courier;color:black; background:White;}
h1.awr   {font:bold 20pt Arial,Helvetica,Geneva,sans-serif;color:#336699;background-color:White;border-bottom:1px solid #cccc99;margin-top:0pt; margin-bottom:0pt;padding:0px 0px 0px 0px;}
h2.awr   {font:bold 18pt Arial,Helvetica,Geneva,sans-serif;color:#336699;background-color:White;margin-top:4pt; margin-bottom:0pt;}
h3.awr {font:bold 16pt Arial,Helvetica,Geneva,sans-serif;color:#336699;background-color:White;margin-top:4pt; margin-bottom:0pt;}
li.awr {font: 8pt Arial,Helvetica,Geneva,sans-serif; color:black; background:White;}
th.awrnobg {font:bold 8pt Arial,Helvetica,Geneva,sans-serif; color:black; background:White;padding-left:4px; padding-right:4px;padding-bottom:2px}
th.awrbg {font:bold 8pt Arial,Helvetica,Geneva,sans-serif; color:White; background:#0066CC;padding-left:4px; padding-right:4px;padding-bottom:2px}
td.awrbg {font:bold 8pt Arial,Helvetica,Geneva,sans-serif; color:White; background:#0066CC;padding-left:4px; padding-right:4px;padding-bottom:2px}
td.awrnc {font:8pt Arial,Helvetica,Geneva,sans-serif;color:black;background:White;vertical-align:top;}
td.awrc    {font:8pt Arial,Helvetica,Geneva,sans-serif;color:black;background:#FFFFCC; vertical-align:top;}
td.red   {font:8pt Arial,Helvetica,Geneva,sans-serif;color:yellow;background:#FF0000; vertical-align:top;}
td.yellow   {font:8pt Arial,Helvetica,Geneva,sans-serif;color:red;background:yellow; vertical-align:top;}
td.awrnclb {font:8pt Arial,Helvetica,Geneva,sans-serif;color:black;background:White;vertical-align:top;border-left: thin solid black;}
td.awrncbb {font:8pt Arial,Helvetica,Geneva,sans-serif;color:black;background:White;vertical-align:top;border-left: thin solid black;border-right: thin solid black;}
td.awrncrb {font:8pt Arial,Helvetica,Geneva,sans-serif;color:black;background:White;vertical-align:top;border-right: thin solid black;}
td.awrcrb    {font:8pt Arial,Helvetica,Geneva,sans-serif;color:black;background:#FFFFCC; vertical-align:top;border-right: thin solid black;}
td.awrclb    {font:8pt Arial,Helvetica,Geneva,sans-serif;color:black;background:#FFFFCC; vertical-align:top;border-left: thin solid black;}
td.awrcbb    {font:8pt Arial,Helvetica,Geneva,sans-serif;color:black;background:#FFFFCC; vertical-align:top;border-left: thin solid black;border-right: thin solid black;}
a.awr {font:bold 8pt Arial,Helvetica,sans-serif;color:#663300; vertical-align:top;margin-top:0pt; margin-bottom:0pt;}
td.awrnct {font:8pt Arial,Helvetica,Geneva,sans-serif;border-top: thin solid black;color:black;background:White;vertical-align:top;}
td.awrct   {font:8pt Arial,Helvetica,Geneva,sans-serif;border-top: thin solid black;color:black;background:#FFFFCC; vertical-align:top;}
td.awrnclbt  {font:8pt Arial,Helvetica,Geneva,sans-serif;color:black;background:White;vertical-align:top;border-top: thin solid black;border-left: thin solid black;}
td.awrncbbt  {font:8pt Arial,Helvetica,Geneva,sans-serif;color:black;background:White;vertical-align:top;border-left: thin solid black;border-right: thin solid black;border-top: thin solid black;}
td.awrncrbt {font:8pt Arial,Helvetica,Geneva,sans-serif;color:black;background:White;vertical-align:top;border-top: thin solid black;border-right: thin solid black;}
td.awrcrbt     {font:8pt Arial,Helvetica,Geneva,sans-serif;color:black;background:#FFFFCC; vertical-align:top;border-top: thin solid black;border-right: thin solid black;}
td.awrclbt     {font:8pt Arial,Helvetica,Geneva,sans-serif;color:black;background:#FFFFCC; vertical-align:top;border-top: thin solid black;border-left: thin solid black;}
td.awrcbbt   {font:8pt Arial,Helvetica,Geneva,sans-serif;color:black;background:#FFFFCC; vertical-align:top;border-top: thin solid black;border-left: thin solid black;border-right: thin solid black;}
table.tdiff {  border_collapse: collapse; }
</style>');
  HTP.headclose;
  HTP.print('<body class="awr">
<h1 class="awr">
Oracle Database RTPA Report (Unisys CIS) v1.0
</h1>
<p />

    ');
  end;

  PROCEDURE PRINTPAGEFTR
  IS
  begin
    htp.print ('
<br /><a class="awr" href="#top">Back to Top</a><p />
<p />
End of Report'
    );
    HTP.bodyclose;
    HTP.htmlclose;
  end;


  PROCEDURE OOCIS_DBINFO
  IS
    cursor c1 is 
    select dbid,name,log_mode,switchover_status,database_role from v$database;
    dbinfo c1%rowtype;

  begin
    open c1;
    printpara('Database Details');
     tblopen('border="1"');
     --loop
        btr;
        fetch c1 into dbinfo;
        --exit when c1%NOTFOUND;
        tdata ('DB ID',cattributes=>'class=awrbg');
        tdata (dbinfo.dbid);
        etr;btr;
        tdata ('Database Name',cattributes=>'class=awrbg');
        tdata (dbinfo.name);
        etr;btr;
        tdata ('DB Archivelog Mode',cattributes=>'class=awrbg');
        tdata (dbinfo.log_mode);
        etr;btr;
        tdata ('Dataguard Status',cattributes=>'class=awrbg');
        tdata (dbinfo.switchover_status);
        etr;btr;
        tdata ('Database Role',cattributes=>'class=awrbg');
        tdata (dbinfo.database_role);
        etr;
     --end loop; 
     tblclose;
  end;

  PROCEDURE OOCIS_INSTINFO
  IS
    cursor c1 is 
      select instance_number,
             instance_name, 
             host_name, 
             version,
             to_char(startup_time, 'dd-mon-yyyy:hh24:mi:ss') startup_time,
             status,
             PARALLEL
              from v$instance;
    instinfo c1%rowtype;

  begin
    open c1;
    printpara('Instance Details');
     tblopen('border="1"');
     --loop
        btr;
        fetch c1 into instinfo;
        --exit when c1%NOTFOUND;
        tdata ('Instance Number',cattributes=>'class=awrbg');
        tdata (instinfo.instance_number);
        etr;btr;
        tdata ('Instance Name',cattributes=>'class=awrbg');
        tdata (instinfo.instance_name);
        etr;btr;
        tdata ('Hostname',cattributes=>'class=awrbg');
        tdata (instinfo.host_name);
        etr;btr;
        tdata ('Version',cattributes=>'class=awrbg');
        tdata (instinfo.Version);
        etr;btr;
        tdata ('Startup Time',cattributes=>'class=awrbg');
        tdata (instinfo.startup_time);
        etr;btr;
        tdata ('Instance status',cattributes=>'class=awrbg');
        tdata (instinfo.status);
        etr;btr;
        tdata ('RAC/Parallel',cattributes=>'class=awrbg');
        tdata (instinfo.Parallel);
        etr;
     --end loop; 
     tblclose;
  end;
  
  PROCEDURE OOCIS_obsoleteparams
  IS
     cursor c1 is
      select * from v$obsolete_parameter where isspecified = 'TRUE' order by nlssort(name, 'NLS_SORT=BINARY');
      oparams c1%rowtype;
  begin
     open c1;
     printpara('Obsolete Parameters');
      
     tblopen('border="1"');
      thdata ('Parameter');
      thdata ('In Use');
     loop
        btr;
        fetch c1 into oparams;
        exit when c1%NOTFOUND;
        tdata (oparams.name);
        tdata (oparams.isspecified);
        etr;
     end loop; 
      if c1%ROWCOUNT = 0 then
          btr;
          tdata ('No obsolete parameters found.',ccolspan=>2);          
          etr;
      end if;
     tblclose;
  end;
  
  PROCEDURE OOCIS_patchreport
  IS
     cursor c1 is
     select * from dba_registry_history order by ACTION_TIME desc;
     reghist c1%rowtype;
     
  begin
     open c1;
     printpara('Patch History');
      
     tblopen('border="1"');
      thdata ('ACTION_TIME');
      thdata ('ACTION');
      thdata ('NAMESPACE');
      thdata ('VERSION');
      thdata ('ID');
      thdata ('COMMENTS');
     loop
        btr;
        fetch c1 into reghist;
        exit when c1%NOTFOUND;
        tdata (reghist.action_time);
        tdata (reghist.action);
        tdata (reghist.namespace);
        tdata (reghist.version);
        tdata (reghist.id);
        tdata (reghist.comments);
        etr;
     end loop; 
      if c1%ROWCOUNT = 0 then
          btr;
          tdata ('No patch history found.',ccolspan=>6);          
          etr;
      end if;
     tblclose;
  end;

              


  PROCEDURE OOCIS_GetAlertLogErrs
  is
        cursor c1 is 
        select trunc(item_date) Log_Date, item_desc Log_Message, count(*) occurrences  from table(get_alert_table) 
        where 
          item_date > sysdate - 31
        and
          item_desc like 'ORA-%'
        group by trunc(item_date), item_desc
        order by 1;
        
        dblog c1%rowtype;
               
  BEGIN
     open c1;
     printpara('Errors in the alert log (Last 30 days)');
      
     tblopen('border="1"');
      thdata ('Log_Date');
      thdata ('Log_Message');
      thdata ('Occurrences');
     loop
        btr;
        fetch c1 into dblog;
        exit when c1%NOTFOUND;
        tdata (dblog.Log_Date);
        tdata (dblog.Log_Message);
        tdata (dblog.Occurrences);
        etr;
     end loop; 
      if c1%ROWCOUNT = 0 then
          btr;
          tdata ('No errors found in the alert log.',ccolspan=>3);          
          etr;
      end if;
     tblclose;
  END;     




  PROCEDURE OOCIS_CtrlFileCheck
  is
    cursor c1 is select * from v$controlfile;
    cfinfo c1%ROWTYPE;
    
    total_files number;
    distinct_paths number;
    
    mplx_msg varchar2(120); -- message describing the multiplexing status.
    mplxcolor varchar2(20); --:='class="awrc"';
    
  begin
    select count(*) into total_files from v$controlfile;
    select count( distinct decode(substr(name,1,1),'/',substr(name, 1, instr(name,'/',-1)),substr(name, 1, instr(name,'\',-1)))) into distinct_paths from v$controlfile;

    open c1;

     printpara('Control File Details');
      
     tblopen('border="1"');
      thdata ('NAME');
      thdata ('STATUS');
      thdata ('IS_RECOVERY_DEST_FILE');
     loop
        btr;
        fetch c1 into cfinfo;
        exit when c1%NOTFOUND;
        if cfinfo.status is not null then
          mplxcolor:='class="red"';
        else
          mplxcolor:=NULL;
        end if;
        tdata (cfinfo.name,cattributes=>mplxcolor);
        tdata (cfinfo.status,cattributes=>mplxcolor);
        tdata (cfinfo.IS_RECOVERY_DEST_FILE,cattributes=>mplxcolor);
        etr;
     end loop; 
    btr;

    if distinct_paths < total_files then
      mplx_msg:='There are multiple controlfiles in the same path, it is recommended to spread them across different locations.';
      mplxcolor:='class="red"';
    elsif total_files = 1 then
      mplx_msg:='There is only one controlfile, it is highly recommended to multiplex controlfiles.';
      mplxcolor:='class="red"';
    else
      mplx_msg:='Control files are multiplexed appropriately, However please ensure they are placed across separate disks.';
    end if;
    
    tdata(mplx_msg,cattributes=>mplxcolor,ccolspan=>3);
    etr;
    tblclose;

  end;


  
  PROCEDURE OOCIS_LogFileCheck
  is
  
    cursor c1 is select * from v$logfile;
    lfinfo c1%ROWTYPE;
    
    group_count number :=0;
    grp_min_members number :=0;
    grp_max_members number :=0;
    min_dist_paths number :=0;
    max_dist_paths number :=0;
    
    
    mplx_msg varchar2(120); -- message describing the multiplexing status.
    mplxcolor varchar2(20); --:='class="awrc"';
    
  begin

    
    select min(path_count), max(path_count) into min_dist_paths, max_dist_paths from (select count( distinct decode(substr(member,1,1),'/',substr(member, 1, instr(member,'/',-1)),substr(member, 1, instr(member,'\',-1)))) path_count from v$logfile group by GROUP#);
    select count(*) into  group_count from v$log;
    select min(members) into grp_min_members from v$log ; 
    select max(members) into grp_max_members from v$log ; 
   
    open c1;

     printpara('LogFile Details');
      
     tblopen('border="1"');
      thdata ('Group #');
      thdata ('Member');
      thdata ('Status');
     loop
        btr;
        fetch c1 into lfinfo;
        exit when c1%NOTFOUND;
        if lfinfo.status is not null then
          mplxcolor:='class="red"';
        else
          mplxcolor:=NULL;
        end if;
        tdata (lfinfo.group#);
        tdata (lfinfo.member);
        tdata (lfinfo.status, cattributes=>mplxcolor);
        etr;
     end loop; 
     
    if group_count  < 3 then
      mplx_msg:='It is recommended to have 3 or more log groups.';
      mplxcolor:='class="yellow"';
    elsif grp_min_members <> grp_max_members then
      mplx_msg:='It is recommended to have the same number of members in all the groups.';
      mplxcolor:='class="red"';
    elsif min_dist_paths  <> max_dist_paths then
      mplx_msg:='There are a few groups with members in the same location.';
      mplxcolor:='class="red"';
    elsif min_dist_paths  < 2 or  grp_min_members < 2 then
      mplx_msg:='There are few log groups with just one member, It is highly recommended to multiplex logfile group members.';
      mplxcolor:='class="red"';
    else
      mplx_msg:='Redo logfiles are multiplexed appropriately, However please ensure they are placed across separate disks.';
    end if;
     
    btr;
    tdata(mplx_msg,cattributes=>mplxcolor,ccolspan=>3);
    etr;
    tblclose;

  end;


  PROCEDURE OOCIS_ObjValidCheck
  is
      cursor c1 is 
      select owner, object_type, count(*) /*sum(decode(status,'VALID',0,1))*/ invalid_count from dba_objects 
      where status='INVALID'
      group by owner, object_type, status
      order by status;

      dbobj c1%ROWTYPE;
      mplx_msg varchar2(120); -- message describing the multiplexing status.
      color varchar2(20):=NULL; --:='class="awrc"';
  begin
    open c1;

     printpara('Invalid Objects Details');
      
     tblopen('border="1"');
      thdata ('OWNER');
      thdata ('OBJECT_TYPE');
      thdata ('INVALID_COUNT');
     loop
        btr;
        fetch c1 into dbobj;
        exit when c1%NOTFOUND;

        tdata (dbobj.OWNER, cattributes=>color);
        tdata (dbobj.OBJECT_TYPE, cattributes=>color);
        tdata (dbobj.INVALID_COUNT, cattributes=>color);

        etr;
     end loop;
      if c1%ROWCOUNT = 0 then
          btr;
          tdata ('No invalid objects found in the database.',ccolspan=>3);          
          etr;
      end if;
     tblclose;
  end;

  PROCEDURE OOCIS_NonSysObjSystemTbs
  is
      cursor c1 is 
      select owner, segment_name, segment_type, tablespace_name from dba_segments where tablespace_name='SYSTEM' and owner not in ('SYS','SYSTEM');  
      
      sysobj c1%ROWTYPE;
      mplx_msg varchar2(120); -- message describing the multiplexing status.
      color varchar2(20):=NULL; --:='class="awrc"';
  begin
    open c1;

     printpara('Non SYS objects in System tablespace');
      
     tblopen('border="1"');
      thdata ('OWNER');
      thdata ('SEGMENT_NAME');
      thdata ('SEGMENT_TYPE');
     loop
        btr;
        fetch c1 into sysobj;
        exit when c1%NOTFOUND;

        tdata (sysobj.OWNER, cattributes=>color);
        tdata (sysobj.SEGMENT_NAME, cattributes=>color);
        tdata (sysobj.SEGMENT_TYPE, cattributes=>color);

        etr;
     end loop;
      if c1%ROWCOUNT = 0 then
          btr;
          tdata ('No Non-SYS objects found in the tablespace.',ccolspan=>3);          
          etr;
      end if;
     tblclose;
  end;


  
  PROCEDURE OOCIS_DBCompCheck
  is
      cursor c1 is select * from dba_registry;
      dbcomp c1%ROWTYPE;
      mplx_msg varchar2(120); -- message describing the multiplexing status.
      color varchar2(20); --:='class="awrc"';
  begin
    open c1;

     printpara('Database Component Details');
      
     tblopen('border="1"');
      thdata ('COMP_ID');
      thdata ('COMP_NAME');
      thdata ('VERSION');
      thdata ('STATUS');
      thdata ('MODIFIED');
      thdata ('NAMESPACE');
      thdata ('CONTROL');
      thdata ('SCHEMA');
      thdata ('PROCEDURE');
      thdata ('STARTUP');
      thdata ('PARENT_ID');
      thdata ('OTHER_SCHEMAS');
     loop
        btr;
        fetch c1 into dbcomp;
        exit when c1%NOTFOUND;
        if dbcomp.STATUS <> 'VALID' then
          color:='class="red"';
        else
          color:= NULL;
        end if;
    
        tdata (dbcomp.COMP_ID, cattributes=>color);
        tdata (dbcomp.COMP_NAME, cattributes=>color);
        tdata (dbcomp."VERSION", cattributes=>color);
        tdata (dbcomp.STATUS , cattributes=>color);
        tdata (dbcomp.MODIFIED, cattributes=>color);
        tdata (dbcomp.NAMESPACE, cattributes=>color);
        tdata (dbcomp.CONTROL, cattributes=>color);
        tdata (dbcomp."SCHEMA", cattributes=>color);
        tdata (dbcomp."PROCEDURE", cattributes=>color);
        tdata (dbcomp."STARTUP", cattributes=>color);
        tdata (dbcomp.PARENT_ID, cattributes=>color);
        tdata (dbcomp.OTHER_SCHEMAS, cattributes=>color);

        etr;
     end loop;
    tblclose;
  end;


  PROCEDURE OOCIS_RMANJobDetails
  is
      cursor c1 
      is 
      SELECT SESSION_KEY, INPUT_TYPE, STATUS,
             TO_CHAR(START_TIME,'mm/dd/yy hh24:mi') start_time,
             TO_CHAR(END_TIME,'mm/dd/yy hh24:mi')   end_time,
             round(ELAPSED_SECONDS/3600,4)                   hrs
      FROM V$RMAN_BACKUP_JOB_DETAILS
      where 
        --start_time > sysdate - 10
        --and
        status<>'COMPLETED'
      ORDER BY SESSION_KEY;
      
      bkpinfo c1%ROWTYPE;


      cursor c2
      is 
      select input_type, status, count(*) Status_Count from V$RMAN_BACKUP_JOB_DETAILS group by input_type, status;      
      bkpsummary c2%ROWTYPE;


      mplx_msg varchar2(120); -- message describing the multiplexing status.
      color varchar2(20); --:='class="awrc"';
      c2zero number:=-1; -- exit flag if cursor c2 has zero rowcount
  begin

  
    open c2;

     printpara('RMAN Backup Summary.');
      
     tblopen('border="1"');
      thdata ('INPUT_TYPE');
      thdata ('STATUS');
      thdata ('STATUS_COUNT');
     loop
        btr;
        fetch c2 into bkpsummary;
        exit when c2%NOTFOUND;
        if bkpsummary.STATUS <> 'COMPLETED' and bkpsummary.STATUS <> 'FAILED' then
          color:='class="yellow"';
        elsif bkpsummary.STATUS = 'FAILED' then
          color:='class="red"';
        else
          color:= NULL;
        end if;
    
        tdata (bkpsummary.INPUT_TYPE, cattributes=>color);
        tdata (bkpsummary.STATUS, cattributes=>color);
        tdata (bkpsummary.STATUS_COUNT, cattributes=>color);

        etr;
     end loop;
      if c2%ROWCOUNT = 0 then
          c2zero:=0;
          btr;
          tdata ('There are no RMAN job details available for the database.',ccolspan=>3);          
          etr;
      end if;
     tblclose;
      
     if c2zero = 0 then /*Do not proceed if we don't have rows in the c2 cursor*/
      return;
     end if;
  
  
  
    open c1;

     printpara('RMAN Backup completed with Errors and Warnings.');
      
     tblopen('border="1"');
      thdata ('SESSION_KEY');
      thdata ('INPUT_TYPE');
      thdata ('STATUS');
      thdata ('START_TIME');
      thdata ('END_TIME');
      thdata ('Hours');
     loop
        btr;
        fetch c1 into bkpinfo;
        exit when c1%NOTFOUND;

        if bkpinfo.STATUS <> 'COMPLETED' and bkpinfo.STATUS <> 'FAILED' then
          color:='class="yellow"';
        elsif bkpinfo.STATUS = 'FAILED' then
          color:='class="red"';
        else
          color:= NULL;
        end if;
    
        tdata (bkpinfo.SESSION_KEY, cattributes=>color);
        tdata (bkpinfo.INPUT_TYPE, cattributes=>color);
        tdata (bkpinfo.STATUS, cattributes=>color);
        tdata (bkpinfo.START_TIME, cattributes=>color);
        tdata (bkpinfo.END_TIME, cattributes=>color);
        tdata (bkpinfo.Hrs, cattributes=>color);

        etr;
     end loop;
      if c1%ROWCOUNT = 0 then
          btr;
          tdata ('There are no backups with warnings or errors.',ccolspan=>6);          
          etr;
      end if;
     tblclose;
  end;

  PROCEDURE OOCIS_UsersElevatedRoles
  is
      cursor c1 
      is 
      select 
       grantee, 
       granted_role, 
       admin_option, 
       default_role
      from 
       dba_role_privs 
      where 
       granted_role in ('DBA','EXP_FULL_DATABASE','IMP_FULL_DATABASE','OEM_MONITOR')
      and 
       grantee not in ('SYS','SYSTEM','DBA')
      order by 1;

      usrroles c1%ROWTYPE;


      mplx_msg varchar2(120); -- message describing the multiplexing status.
      color varchar2(20); --:='class="awrc"';
  begin
    open c1;

     printpara('Users/Roles with elevated roles granted');
      
     tblopen('border="1"');
      thdata('GRANTEE');
      thdata('GRANTED_ROLE');
      thdata('ADMIN_OPTION');
      thdata('DEFAULT_ROLE');
     loop
        btr;
        fetch c1 into usrroles;
        exit when c1%NOTFOUND;
    
        tdata(usrroles.GRANTEE);
        tdata(usrroles.GRANTED_ROLE);
        tdata(usrroles.ADMIN_OPTION);
        tdata(usrroles.DEFAULT_ROLE);

        etr;
     end loop;
      if c1%ROWCOUNT = 0 then
          btr;
          tdata ('There are no users/roles who are granted super user roles.',ccolspan=>6);          
          etr;
      end if;
     tblclose;
  end;


  PROCEDURE OOCIS_UsersElevatedPrivs
  is
      cursor c1 
      is 
      select 
        grantee,
        privilege,
        admin_option
      from 
        dba_sys_privs 
      where privilege in 
        ('ALTER DATABASE',
        'ALTER PROFILE',
        'ALTER SYSTEM',
        'ALTER TABLESPACE',
        'BECOME USER',
        'BACKUP ANY TABLE',
        'ALTER USER',
        'CREATE ANY DIRECTORY',
        'CREATE DATABASE',
        'CREATE ROLLBACK SEGMENT',
        'CREATE TABLESPACE',
        'DROP ANY DIRECTORY',
        'DROP DATABASE',
        'DROP PROFILE',
        'DROP ROLLBACK SEGMENT',
        'DROP TABLESPACE',
        'DROP USER',
        'EXECUTE ANY PROCEDURE',
        'GRANT ANY OBJECT PRIVILEGE',
        'GRANT ANY PRIVILEGE',
        'GRANT ANY ROLE',
        'INSERT ANY TABLE',
        'MANAGE TABLESPACE',
        'UNDER ANY TABLE',
        'UNDER ANY TYPE',
        'UNDER ANY VIEW',
        'UPDATE ANY TABLE',
        'ALTER ANY PROCEDURE',
        'ALTER ANY ROLE',
        'ALTER ANY TABLE',
        'ALTER ANY TRIGGER',
        'ALTER ANY TYPE',
        'DELETE ANY TABLE',
        'DROP ANY PROCEDURE',
        'DROP ANY ROLE',
        'DROP ANY TABLE',
        'FORCE ANY TRANSACTION',
        'FORCE TRANSACTION',
        'ALTER ROLLBACK SEGMENT',
        'CREATE USER',
        'CREATE PUBLIC DATABASE LINK',
        'RESTRICTED SESSION',
        'SELECT ANY TABLE')
      and grantee not in 
       ('SYS',
        'SYSTEM',
        'WMSYS','OWBSYS','MDSYS',
        'DBA',
        'IMP_FULL_DATABASE',
        'EXP_FULL_DATABASE')
      order by 1;

      usrprivs c1%ROWTYPE;


      mplx_msg varchar2(120); -- message describing the multiplexing status.
      color varchar2(20); --:='class="awrc"';
  begin
    open c1;

     printpara('Users/Roles with elevated privileges granted');
      
     tblopen('border="1"');
      thdata('GRANTEE');
      thdata('PRIVILEGE');
      thdata('ADMIN_OPTION');
     loop
        btr;
        fetch c1 into usrprivs;
        exit when c1%NOTFOUND;
    
        tdata(usrprivs.GRANTEE);
        tdata(usrprivs."PRIVILEGE");
        tdata(usrprivs.ADMIN_OPTION);
        etr;
     end loop;
      if c1%ROWCOUNT = 0 then
          btr;
          tdata ('There are no users/roles who are granted elevated privileges.',ccolspan=>6);          
          etr;
      end if;
     tblclose;
  end;

  PROCEDURE OOCIS_TbsSpaceUsageRpt
  is
      cursor c1 
      is 
          SELECT  a.tablespace_name ts,
                 ROUND(a.bytes_alloc / 1024 / 1024, 2) megs_alloc,
          --       ROUND(NVL(b.bytes_free, 0) / 1024 / 1024, 2) megs_free,
                 ROUND((a.bytes_alloc - NVL(b.bytes_free, 0)) / 1024 / 1024, 2) megs_used,
                 ROUND((NVL(b.bytes_free, 0) / a.bytes_alloc) * 100,2) Pct_Free,
                 (case when ROUND((NVL(b.bytes_free, 0) / a.bytes_alloc) * 100,2)<=0 
                                                          then 'Immediate action required!'
                       when ROUND((NVL(b.bytes_free, 0) / a.bytes_alloc) * 100,2)<5  
                                                          then 'Critical (<5% free)'
                       when ROUND((NVL(b.bytes_free, 0) / a.bytes_alloc) * 100,2)<15 
                                                          then 'Warning (<15% free)'
                       when ROUND((NVL(b.bytes_free, 0) / a.bytes_alloc) * 100,2)<25 
                                                          then 'Warning (<25% free)'
                       when ROUND((NVL(b.bytes_free, 0) / a.bytes_alloc) * 100,2)>60 
                                                          then 'Waste of space? (>60% free)'
                       else 'OK'
                       end) msg
          FROM  ( SELECT  f.tablespace_name,
                         SUM(f.bytes) bytes_alloc,
                         SUM(DECODE(f.autoextensible, 'YES',f.maxbytes,'NO', f.bytes)) maxbytes
                  FROM DBA_DATA_FILES f
                  GROUP BY tablespace_name) a,
                ( SELECT  f.tablespace_name,
                         SUM(f.bytes)  bytes_free
                  FROM DBA_FREE_SPACE f
                  GROUP BY tablespace_name) b
          WHERE a.tablespace_name = b.tablespace_name (+)
          UNION
          SELECT h.tablespace_name,
                 ROUND(SUM(h.bytes_free + h.bytes_used) / 1048576, 2),
          --       ROUND(SUM((h.bytes_free + h.bytes_used) - NVL(p.bytes_used, 0)) / 1048576, 2),
                 ROUND(SUM(NVL(p.bytes_used, 0))/ 1048576, 2),
                 ROUND((SUM((h.bytes_free + h.bytes_used) - NVL(p.bytes_used, 0)) / SUM(h.bytes_used + h.bytes_free)) * 100,2),
                (case when ROUND((SUM((h.bytes_free + h.bytes_used) - NVL(p.bytes_used, 0)) / SUM(h.bytes_used + h.bytes_free)) * 100,2)<=0 then 'Immediate action required!'
                      when ROUND((SUM((h.bytes_free + h.bytes_used) - NVL(p.bytes_used, 0)) / SUM(h.bytes_used + h.bytes_free)) * 100,2)<5  then 'Critical (<5% free)'
                      when ROUND((SUM((h.bytes_free + h.bytes_used) - NVL(p.bytes_used, 0)) / SUM(h.bytes_used + h.bytes_free)) * 100,2)<15 then 'Warning (<15% free)'
                      when ROUND((SUM((h.bytes_free + h.bytes_used) - NVL(p.bytes_used, 0)) / SUM(h.bytes_used + h.bytes_free)) * 100,2)<25 then 'Warning (<25% free)'
                      when ROUND((SUM((h.bytes_free + h.bytes_used) - NVL(p.bytes_used, 0)) / SUM(h.bytes_used + h.bytes_free)) * 100,2)>60 then 'Waste of space? (>60% free)'
                      else 'OK'
                      end) msg
          FROM   v$TEMP_SPACE_HEADER h, v$TEMP_EXTENT_POOL p
          WHERE  p.file_id(+) = h.file_id
          AND    p.tablespace_name(+) = h.tablespace_name
          GROUP BY h.tablespace_name
          ORDER BY 1;
      
      tbsinfo c1%ROWTYPE;

      color varchar2(20); --:='class="awrc"';
  begin

  
    open c1;

     printpara('Tablespace Space Usage Details');
      
     tblopen('border="1"');
      thdata ('Tablespace');  --TS
      thdata ('Allocated (MB)'); --MEGS_ALLOC
      thdata ('Used (MB)'); --MEGS_USED
      thdata ('Pct Free'); --PCT_FREE
     loop
        btr;
        fetch c1 into tbsinfo;
        exit when c1%NOTFOUND;

        if tbsinfo.msg like 'Critical%' then
          color:='class="red"';
        elsif tbsinfo.msg like 'Warning%' then
          color:='class="yellow"';
        else
          color:= NULL;
        end if;
    
        tdata (tbsinfo.TS, cattributes=>color);
        tdata (tbsinfo.megs_alloc, cattributes=>color);
        tdata (tbsinfo.megs_used, cattributes=>color);
        tdata (tbsinfo.pct_free, cattributes=>color);

        etr;
     end loop;
      if c1%ROWCOUNT = 0 then
          btr;
          tdata ('Something does not look right ;-)',ccolspan=>4);          
          etr;
      end if;
     tblclose;
  end;

  PROCEDURE OOCIS_OSStat
  is
    cursor c1 is select * from v$osstat;
    osinfo c1%ROWTYPE;
    
  begin

    open c1;

     printpara('OS/System Metric Details');
      
     tblopen('border="1"');
      thdata ('NAME');
      thdata ('Value');
     loop
        btr;
        fetch c1 into osinfo;
        exit when c1%NOTFOUND;
        tdata (osinfo.stat_name);
        tdata (osinfo.value);
        etr;
     end loop; 
    tblclose;

  end;


  PROCEDURE OOCIS_DBParams
  is
    cursor c1 is select * from v$system_parameter where isdefault='FALSE';
    dbparam c1%ROWTYPE;
    
  begin

    open c1;

     printpara('Database Initialization Parameters (Current Values for the instance)');
      
     tblopen('border="1"');
      thdata ('Parameter Name');
      thdata ('Parameter Value');
     loop
        btr;
        fetch c1 into dbparam;
        exit when c1%NOTFOUND;
        tdata (dbparam.name);
        tdata (dbparam.value);
        etr;
     end loop; 
    tblclose;
  end;


  PROCEDURE OOCIS_obsoleteparams1
  IS
     cursor c1 is
      select * from v$obsolete_parameter where isspecified = 'TRUE' order by nlssort(name, 'NLS_SORT=BINARY');
      oparams c1%rowtype;
      
      ctr number :=0;
  begin
     open c1;
     loop
        btr;
        fetch c1 into oparams;
        ctr := ctr + 1;
        if c1%ROWCOUNT = 0 then
          return;
        end if;
        if ctr = 1 then
           printpara('Obsolete Parameters');
            
           tblopen('border="1"');
            thdata ('Parameter');
            thdata ('In Use');
        end if;
        exit when c1%NOTFOUND;
        tdata (oparams.name);
        tdata (oparams.isspecified);
        etr;
     end loop; 
      if c1%ROWCOUNT = 0 then
          btr;
          tdata ('No obsolete parameters found.',ccolspan=>2);          
          etr;
      end if;
     tblclose;
  end;
  
             


  PROCEDURE OOCIS_GetAlertLogErrs1
  is
        cursor c1 is 
        select trunc(item_date) Log_Date, item_desc Log_Message, count(*) occurrences  from table(get_alert_table) 
        where 
          item_date > sysdate - 31
        and
          item_desc like 'ORA-%'
        group by trunc(item_date), item_desc
        order by 1;
        
        dblog c1%rowtype;

        ctr number:=0;
               
  BEGIN
     open c1;
      
     loop
        fetch c1 into dblog;
        ctr := ctr + 1;
        if c1%ROWCOUNT = 0 then
          return;
        end if;
        if ctr = 1 then
          printpara('Errors in the alert log (Last 30 days)');
         tblopen('border="1"');
          thdata ('Log_Date');
          thdata ('Log_Message');
          thdata ('Occurrences');
        end if;
        exit when c1%NOTFOUND;
        btr;
        tdata (dblog.Log_Date);
        tdata (dblog.Log_Message);
        tdata (dblog.Occurrences);
        etr;
     end loop; 
      if c1%ROWCOUNT = 0 then
          btr;
          tdata ('No errors found in the alert log.',ccolspan=>3);          
          etr;
      end if;
     tblclose;
  END;     




  PROCEDURE OOCIS_CtrlFileCheck1
  is
    cursor c1 is select * from v$controlfile;
    cfinfo c1%ROWTYPE;
    
    total_files number;
    distinct_paths number;
    
    mplx_msg varchar2(120); -- message describing the multiplexing status.
    mplxcolor varchar2(20); --:='class="awrc"';
    mplxcolor1 varchar2(20); --:='class="awrc"';
    
  begin
    select count(*) into total_files from v$controlfile;
    select count( distinct decode(substr(name,1,1),'/',substr(name, 1, instr(name,'/',-1)),substr(name, 1, instr(name,'\',-1)))) into distinct_paths from v$controlfile;

    if distinct_paths < total_files then
      mplx_msg:='There are multiple controlfiles in the same path, it is recommended to spread them across different locations.';
      mplxcolor1:='class="red"';
    elsif total_files = 1 then
      mplx_msg:='There is only one controlfile, it is highly recommended to multiplex controlfiles.';
      mplxcolor1:='class="red"';
    else
      mplx_msg:='Control files are multiplexed appropriately, However please ensure they are placed across separate disks.';
      return;
    end if;

    open c1;
     printpara('Control File Details');
      
     tblopen('border="1"');
      thdata ('NAME');
      thdata ('STATUS');
      thdata ('IS_RECOVERY_DEST_FILE');
     loop
        btr;
        fetch c1 into cfinfo;
        exit when c1%NOTFOUND;
        if cfinfo.status is not null then
          mplxcolor:='class="red"';
        else
          mplxcolor:=NULL;
        end if;
        tdata (cfinfo.name,cattributes=>mplxcolor);
        tdata (cfinfo.status,cattributes=>mplxcolor);
        tdata (cfinfo.IS_RECOVERY_DEST_FILE,cattributes=>mplxcolor);
        etr;
     end loop; 
    btr;

    
    tdata(mplx_msg,cattributes=>mplxcolor1,ccolspan=>3);
    etr;
    tblclose;

  end;


  
  PROCEDURE OOCIS_LogFileCheck1
  is
  
    cursor c1 is select * from v$logfile;
    lfinfo c1%ROWTYPE;
    
    group_count number :=0;
    grp_min_members number :=0;
    grp_max_members number :=0;
    min_dist_paths number :=0;
    max_dist_paths number :=0;
    
    
    mplx_msg varchar2(120); -- message describing the multiplexing status.
    mplxcolor varchar2(20); --:='class="awrc"';
    mplxcolor1 varchar2(20); --:='class="awrc"';    
  begin

    
    select min(path_count), max(path_count) into min_dist_paths, max_dist_paths from (select count( distinct decode(substr(member,1,1),'/',substr(member, 1, instr(member,'/',-1)),substr(member, 1, instr(member,'\',-1)))) path_count from v$logfile group by GROUP#);
    select count(*) into  group_count from v$log;
    select min(members) into grp_min_members from v$log ; 
    select max(members) into grp_max_members from v$log ; 
   
    if group_count  < 3 then
      mplx_msg:='It is recommended to have 3 or more log groups.';
      mplxcolor1:='class="yellow"';
    elsif grp_min_members <> grp_max_members then
      mplx_msg:='It is recommended to have the same number of members in all the groups.';
      mplxcolor1:='class="red"';
    elsif min_dist_paths  <> max_dist_paths then
      mplx_msg:='There are a few groups with members in the same location.';
      mplxcolor1:='class="red"';
    elsif min_dist_paths  < 2 or  grp_min_members < 2 then
      mplx_msg:='There are few log groups with just one member, It is highly recommended to multiplex logfile group members.';
      mplxcolor1:='class="red"';
    else
      mplx_msg:='Redo logfiles are multiplexed appropriately, However please ensure they are placed across separate disks.';
      return;
    end if;


    open c1;

     printpara('LogFile Details');
      
     tblopen('border="1"');
      thdata ('Group #');
      thdata ('Member');
      thdata ('Status');
     loop
        btr;
        fetch c1 into lfinfo;
        exit when c1%NOTFOUND;
        if lfinfo.status is not null then
          mplxcolor:='class="red"';
        else
          mplxcolor:=NULL;
        end if;
        tdata (lfinfo.group#);
        tdata (lfinfo.member);
        tdata (lfinfo.status, cattributes=>mplxcolor);
        etr;
     end loop; 
     
    btr;
    tdata(mplx_msg,cattributes=>mplxcolor1,ccolspan=>3);
    etr;
    tblclose;

  end;


  PROCEDURE OOCIS_ObjValidCheck1
  is
      cursor c1 is 
      select owner, object_type, count(*) /*sum(decode(status,'VALID',0,1))*/ invalid_count from dba_objects 
      where status='INVALID'
      group by owner, object_type, status
      order by status;

      dbobj c1%ROWTYPE;
      mplx_msg varchar2(120); -- message describing the multiplexing status.
      color varchar2(20):=NULL; --:='class="awrc"';
      ctr number:=0;
  begin
    open c1;

     loop
        fetch c1 into dbobj;

        ctr := ctr + 1;
        if c1%ROWCOUNT = 0 then
          return;
        end if;

        if ctr = 1 then
           printpara('Invalid Objects Details');
            
           tblopen('border="1"');
            thdata ('OWNER');
            thdata ('OBJECT_TYPE');
            thdata ('INVALID_COUNT');
        end if;

        exit when c1%NOTFOUND;

        btr;
        tdata (dbobj.OWNER, cattributes=>color);
        tdata (dbobj.OBJECT_TYPE, cattributes=>color);
        tdata (dbobj.INVALID_COUNT, cattributes=>color);

        etr;
     end loop;
      if c1%ROWCOUNT = 0 then
          btr;
          tdata ('No invalid objects found in the database.',ccolspan=>3);          
          etr;
      end if;
     tblclose;
  end;

  PROCEDURE OOCIS_NonSysObjSystemTbs1
  is
      cursor c1 is 
      select owner, segment_name, segment_type, tablespace_name from dba_segments where tablespace_name='SYSTEM' and owner not in ('SYS','SYSTEM');  
      
      sysobj c1%ROWTYPE;
      mplx_msg varchar2(120); -- message describing the multiplexing status.
      color varchar2(20):=NULL; --:='class="awrc"';
      ctr number:=0;
  begin
    open c1;

     loop
        fetch c1 into sysobj;
        ctr := ctr + 1;
        if c1%ROWCOUNT = 0 then
          return;
        end if;
        if ctr = 1 then
           printpara('Non SYS objects in System tablespace');
            
           tblopen('border="1"');
            thdata ('OWNER');
            thdata ('SEGMENT_NAME');
            thdata ('SEGMENT_TYPE');
        end if;
        exit when c1%NOTFOUND;

        btr;
        tdata (sysobj.OWNER, cattributes=>color);
        tdata (sysobj.SEGMENT_NAME, cattributes=>color);
        tdata (sysobj.SEGMENT_TYPE, cattributes=>color);

        etr;
     end loop;
      if c1%ROWCOUNT = 0 then
          btr;
          tdata ('No Non-SYS objects found in the tablespace.',ccolspan=>3);          
          etr;
      end if;
     tblclose;
  end;


  
  PROCEDURE OOCIS_DBCompCheck1
  is
      cursor c1 is select * from dba_registry where STATUS <> 'VALID';
      dbcomp c1%ROWTYPE;
      mplx_msg varchar2(120); -- message describing the multiplexing status.
      color varchar2(20); --:='class="awrc"';
      ctr number :=0;

  begin
    open c1;

     loop
        fetch c1 into dbcomp;

        ctr := ctr + 1;
        if c1%ROWCOUNT = 0 then
          return;
        end if;

        if ctr = 1 then
           printpara('Database Component Details');
            
           tblopen('border="1"');
            thdata ('COMP_ID');
            thdata ('COMP_NAME');
            thdata ('VERSION');
            thdata ('STATUS');
            thdata ('MODIFIED');
            thdata ('NAMESPACE');
            thdata ('CONTROL');
            thdata ('SCHEMA');
            thdata ('PROCEDURE');
            thdata ('STARTUP');
            thdata ('PARENT_ID');
            thdata ('OTHER_SCHEMAS');
        end if;

        exit when c1%NOTFOUND;

        if dbcomp.STATUS <> 'VALID' then
          color:='class="red"';
        else
          color:= NULL;
        end if;
    
        btr;
        tdata (dbcomp.COMP_ID, cattributes=>color);
        tdata (dbcomp.COMP_NAME, cattributes=>color);
        tdata (dbcomp."VERSION", cattributes=>color);
        tdata (dbcomp.STATUS , cattributes=>color);
        tdata (dbcomp.MODIFIED, cattributes=>color);
        tdata (dbcomp.NAMESPACE, cattributes=>color);
        tdata (dbcomp.CONTROL, cattributes=>color);
        tdata (dbcomp."SCHEMA", cattributes=>color);
        tdata (dbcomp."PROCEDURE", cattributes=>color);
        tdata (dbcomp."STARTUP", cattributes=>color);
        tdata (dbcomp.PARENT_ID, cattributes=>color);
        tdata (dbcomp.OTHER_SCHEMAS, cattributes=>color);

        etr;
     end loop;
    tblclose;
  end;


  PROCEDURE OOCIS_RMANJobDetails1
  is
      cursor c1 
      is 
      SELECT SESSION_KEY, INPUT_TYPE, STATUS,
             TO_CHAR(START_TIME,'mm/dd/yy hh24:mi') start_time,
             TO_CHAR(END_TIME,'mm/dd/yy hh24:mi')   end_time,
             round(ELAPSED_SECONDS/3600,4)                   hrs
      FROM V$RMAN_BACKUP_JOB_DETAILS
      where 
        --start_time > sysdate - 10
        --and
        status<>'COMPLETED'
      ORDER BY SESSION_KEY;
      
      bkpinfo c1%ROWTYPE;


      cursor c2
      is 
      select input_type, status, count(*) Status_Count from V$RMAN_BACKUP_JOB_DETAILS where STATUS <> 'COMPLETED' group by input_type, status;      
      bkpsummary c2%ROWTYPE;


      mplx_msg varchar2(120); -- message describing the multiplexing status.
      color varchar2(20); --:='class="awrc"';
      c2zero number:=-1; -- exit flag if cursor c2 has zero rowcount
      
      ctr number :=0;
  begin

  
    open c2;

     loop
        fetch c2 into bkpsummary;
        ctr := ctr + 1;
        if c2%ROWCOUNT = 0 then
          return;
        end if;
        if ctr = 1 then
           printpara('RMAN Backup Summary');
            
           tblopen('border="1"');
            thdata ('INPUT_TYPE');
            thdata ('STATUS');
            thdata ('STATUS_COUNT');
        end if;
        exit when c2%NOTFOUND;
        if bkpsummary.STATUS <> 'COMPLETED' and bkpsummary.STATUS <> 'FAILED' then
          color:='class="yellow"';
        elsif bkpsummary.STATUS = 'FAILED' then
          color:='class="red"';
        else
          color:= NULL;
        end if;
    
        btr;
        tdata (bkpsummary.INPUT_TYPE, cattributes=>color);
        tdata (bkpsummary.STATUS, cattributes=>color);
        tdata (bkpsummary.STATUS_COUNT, cattributes=>color);

        etr;
     end loop;
      if c2%ROWCOUNT = 0 then
          c2zero:=0;
          btr;
          tdata ('There are no RMAN job details available for the database.',ccolspan=>3);          
          etr;
      end if;
     tblclose;
      
     if c2zero = 0 then /*Do not proceed if we don't have rows in the c2 cursor*/
      return;
     end if;
  
  
  
    open c1;

     printpara('RMAN Backup completed with Errors and Warnings.');
      
     tblopen('border="1"');
      thdata ('SESSION_KEY');
      thdata ('INPUT_TYPE');
      thdata ('STATUS');
      thdata ('START_TIME');
      thdata ('END_TIME');
      thdata ('Hours');
     loop
        btr;
        fetch c1 into bkpinfo;
        exit when c1%NOTFOUND;

        if bkpinfo.STATUS <> 'COMPLETED' and bkpinfo.STATUS <> 'FAILED' then
          color:='class="yellow"';
        elsif bkpinfo.STATUS = 'FAILED' then
          color:='class="red"';
        else
          color:= NULL;
        end if;
    
        tdata (bkpinfo.SESSION_KEY, cattributes=>color);
        tdata (bkpinfo.INPUT_TYPE, cattributes=>color);
        tdata (bkpinfo.STATUS, cattributes=>color);
        tdata (bkpinfo.START_TIME, cattributes=>color);
        tdata (bkpinfo.END_TIME, cattributes=>color);
        tdata (bkpinfo.Hrs, cattributes=>color);

        etr;
     end loop;
      if c1%ROWCOUNT = 0 then
          btr;
          tdata ('There are no backups with warnings or errors.',ccolspan=>6);          
          etr;
      end if;
     tblclose;
  end;

  PROCEDURE OOCIS_UsersElevatedRoles1
  is
      cursor c1 
      is 
      select 
       grantee, 
       granted_role, 
       admin_option, 
       default_role
      from 
       dba_role_privs 
      where 
       granted_role in ('DBA','EXP_FULL_DATABASE','IMP_FULL_DATABASE','OEM_MONITOR')
      and 
       grantee not in ('SYS','SYSTEM','DBA')
      order by 1;

      usrroles c1%ROWTYPE;


      mplx_msg varchar2(120); -- message describing the multiplexing status.
      color varchar2(20); --:='class="awrc"';
      ctr number :=0;
  begin
    open c1;

     loop
        fetch c1 into usrroles;
        ctr := ctr + 1;
        if c1%ROWCOUNT = 0 then
          return;
        end if;
        if ctr = 1 then
           printpara('Users/Roles with elevated roles granted');
            
           tblopen('border="1"');
            thdata('GRANTEE');
            thdata('GRANTED_ROLE');
            thdata('ADMIN_OPTION');
            thdata('DEFAULT_ROLE');
        end if;

        exit when c1%NOTFOUND;
    
        btr;
        tdata(usrroles.GRANTEE);
        tdata(usrroles.GRANTED_ROLE);
        tdata(usrroles.ADMIN_OPTION);
        tdata(usrroles.DEFAULT_ROLE);

        etr;
     end loop;
      if c1%ROWCOUNT = 0 then
          btr;
          tdata ('There are no users/roles who are granted super user roles.',ccolspan=>6);          
          etr;
      end if;
     tblclose;
  end;


  PROCEDURE OOCIS_UsersElevatedPrivs1
  is
      cursor c1 
      is 
      select 
        grantee,
        privilege,
        admin_option
      from 
        dba_sys_privs 
      where privilege in 
        ('ALTER DATABASE',
        'ALTER PROFILE',
        'ALTER SYSTEM',
        'ALTER TABLESPACE',
        'BECOME USER',
        'BACKUP ANY TABLE',
        'ALTER USER',
        'CREATE ANY DIRECTORY',
        'CREATE DATABASE',
        'CREATE ROLLBACK SEGMENT',
        'CREATE TABLESPACE',
        'DROP ANY DIRECTORY',
        'DROP DATABASE',
        'DROP PROFILE',
        'DROP ROLLBACK SEGMENT',
        'DROP TABLESPACE',
        'DROP USER',
        'EXECUTE ANY PROCEDURE',
        'GRANT ANY OBJECT PRIVILEGE',
        'GRANT ANY PRIVILEGE',
        'GRANT ANY ROLE',
        'INSERT ANY TABLE',
        'MANAGE TABLESPACE',
        'UNDER ANY TABLE',
        'UNDER ANY TYPE',
        'UNDER ANY VIEW',
        'UPDATE ANY TABLE',
        'ALTER ANY PROCEDURE',
        'ALTER ANY ROLE',
        'ALTER ANY TABLE',
        'ALTER ANY TRIGGER',
        'ALTER ANY TYPE',
        'DELETE ANY TABLE',
        'DROP ANY PROCEDURE',
        'DROP ANY ROLE',
        'DROP ANY TABLE',
        'FORCE ANY TRANSACTION',
        'FORCE TRANSACTION',
        'ALTER ROLLBACK SEGMENT',
        'CREATE USER',
        'CREATE PUBLIC DATABASE LINK',
        'RESTRICTED SESSION',
        'SELECT ANY TABLE')
      and grantee not in 
       ('SYS',
        'SYSTEM',
        'WMSYS','OWBSYS','MDSYS',
        'DBA',
        'IMP_FULL_DATABASE',
        'EXP_FULL_DATABASE')
      order by 1;

      usrprivs c1%ROWTYPE;


      mplx_msg varchar2(120); -- message describing the multiplexing status.
      color varchar2(20); --:='class="awrc"';
      
      ctr number:=0;

  begin
    open c1;

     loop
        fetch c1 into usrprivs;

        ctr := ctr + 1;
        if c1%ROWCOUNT = 0 then
          return;
        end if;
        if ctr = 1 then
           printpara('Users/Roles with elevated roles granted');
            
           tblopen('border="1"');
            thdata('GRANTEE');
            thdata('GRANTED_ROLE');
            thdata('ADMIN_OPTION');
--            thdata('DEFAULT_ROLE');
        end if;
        exit when c1%NOTFOUND;
    
        btr;
        tdata(usrprivs.GRANTEE);
        tdata(usrprivs."PRIVILEGE");
        tdata(usrprivs.ADMIN_OPTION);
        etr;
     end loop;
      if c1%ROWCOUNT = 0 then
          btr;
          tdata ('There are no users/roles who are granted elevated privileges.',ccolspan=>6);          
          etr;
      end if;
     tblclose;
  end;

  PROCEDURE OOCIS_TbsSpaceUsageRpt1
  is
      cursor c1 
      is 
      select * from (
                SELECT  a.tablespace_name ts,
                       ROUND(a.bytes_alloc / 1024 / 1024, 2) megs_alloc,
                --       ROUND(NVL(b.bytes_free, 0) / 1024 / 1024, 2) megs_free,
                       ROUND((a.bytes_alloc - NVL(b.bytes_free, 0)) / 1024 / 1024, 2) megs_used,
                       ROUND((NVL(b.bytes_free, 0) / a.bytes_alloc) * 100,2) Pct_Free,
                       (case when ROUND((NVL(b.bytes_free, 0) / a.bytes_alloc) * 100,2)<=0 
                                                                then 'Immediate action required!'
                             when ROUND((NVL(b.bytes_free, 0) / a.bytes_alloc) * 100,2)<5  
                                                                then 'Critical (<5% free)'
                             when ROUND((NVL(b.bytes_free, 0) / a.bytes_alloc) * 100,2)<15 
                                                                then 'Warning (<15% free)'
                             when ROUND((NVL(b.bytes_free, 0) / a.bytes_alloc) * 100,2)<25 
                                                                then 'Warning (<25% free)'
                             when ROUND((NVL(b.bytes_free, 0) / a.bytes_alloc) * 100,2)>60 
                                                                then 'Waste of space? (>60% free)'
                             else 'OK'
                             end) msg
                FROM  ( SELECT  f.tablespace_name,
                               SUM(f.bytes) bytes_alloc,
                               SUM(DECODE(f.autoextensible, 'YES',f.maxbytes,'NO', f.bytes)) maxbytes
                        FROM DBA_DATA_FILES f
                        GROUP BY tablespace_name) a,
                      ( SELECT  f.tablespace_name,
                               SUM(f.bytes)  bytes_free
                        FROM DBA_FREE_SPACE f
                        GROUP BY tablespace_name) b
                WHERE a.tablespace_name = b.tablespace_name (+)
                --AND b.msg not like 'Critical%' AND b.msg not like 'Warning%'
                UNION
                SELECT h.tablespace_name,
                       ROUND(SUM(h.bytes_free + h.bytes_used) / 1048576, 2),
                --       ROUND(SUM((h.bytes_free + h.bytes_used) - NVL(p.bytes_used, 0)) / 1048576, 2),
                       ROUND(SUM(NVL(p.bytes_used, 0))/ 1048576, 2),
                       ROUND((SUM((h.bytes_free + h.bytes_used) - NVL(p.bytes_used, 0)) / SUM(h.bytes_used + h.bytes_free)) * 100,2),
                      (case when ROUND((SUM((h.bytes_free + h.bytes_used) - NVL(p.bytes_used, 0)) / SUM(h.bytes_used + h.bytes_free)) * 100,2)<=0 then 'Immediate action required!'
                            when ROUND((SUM((h.bytes_free + h.bytes_used) - NVL(p.bytes_used, 0)) / SUM(h.bytes_used + h.bytes_free)) * 100,2)<5  then 'Critical (<5% free)'
                            when ROUND((SUM((h.bytes_free + h.bytes_used) - NVL(p.bytes_used, 0)) / SUM(h.bytes_used + h.bytes_free)) * 100,2)<15 then 'Warning (<15% free)'
                            when ROUND((SUM((h.bytes_free + h.bytes_used) - NVL(p.bytes_used, 0)) / SUM(h.bytes_used + h.bytes_free)) * 100,2)<25 then 'Warning (<25% free)'
                            when ROUND((SUM((h.bytes_free + h.bytes_used) - NVL(p.bytes_used, 0)) / SUM(h.bytes_used + h.bytes_free)) * 100,2)>60 then 'Waste of space? (>60% free)'
                            else 'OK'
                            end) msg
                FROM   v$TEMP_SPACE_HEADER h, v$TEMP_EXTENT_POOL p
                WHERE  p.file_id(+) = h.file_id
                --AND h.msg not like 'Critical%' AND h.msg not like 'Warning%'
                AND    p.tablespace_name(+) = h.tablespace_name
                GROUP BY h.tablespace_name
                ORDER BY 1
      ) WHERE msg like 'Critical%' OR msg like 'Warning%' OR msg like 'Immediate%'
      ;      

      tbsinfo c1%ROWTYPE;

      color varchar2(20); --:='class="awrc"';

      ctr number:=0;

  begin

  
    open c1;

     loop
        fetch c1 into tbsinfo;
        ctr := ctr + 1;
        if c1%ROWCOUNT = 0 then
          return;
        end if;
        if ctr = 1 then
           printpara('Tablespace Space Usage Details');
            
           tblopen('border="1"');
            thdata ('Tablespace');  --TS
            thdata ('Allocated (MB)'); --MEGS_ALLOC
            thdata ('Used (MB)'); --MEGS_USED
            thdata ('Pct Free'); --PCT_FREE
        end if;
        exit when c1%NOTFOUND;

        if tbsinfo.msg like 'Critical%' then
          color:='class="red"';
        elsif tbsinfo.msg like 'Warning%' then
          color:='class="yellow"';
        else
          color:= NULL;
        end if;
    
        btr;
        tdata (tbsinfo.TS, cattributes=>color);
        tdata (tbsinfo.megs_alloc, cattributes=>color);
        tdata (tbsinfo.megs_used, cattributes=>color);
        tdata (tbsinfo.pct_free, cattributes=>color);

        etr;
     end loop;
      if c1%ROWCOUNT = 0 then
          btr;
          tdata ('Something does not look right ;-)',ccolspan=>4);          
          etr;
      end if;
     tblclose;
  end;


  PROCEDURE SHOWREPORT3 (dblog in varchar2 default null)
  is
  begin
    INITOWA;
    htp.addDefaultHTMLHdr(false);
    PRINTPAGEHDR;
    OOCIS_INSTINFO;
    OOCIS_DBINFO;
--    OOCIS_OSStat;
--    OOCIS_DBParams;
--    OOCIS_patchreport;
    OOCIS_obsoleteparams1;
    OOCIS_CtrlFileCheck1;
    OOCIS_LogFileCheck1;
    OOCIS_ObjValidCheck1;
    OOCIS_NonSysObjSystemTbs1;
    OOCIS_DBCompCheck1;
    OOCIS_RMANJobDetails1;
    OOCIS_UsersElevatedRoles1;
    OOCIS_UsersElevatedPrivs1;
    if upper(dblog) = 'YES' then
      OOCIS_GetAlertLogErrs1;
    end if;
    OOCIS_TbsSpaceUsageRpt1;
    PRINTPAGEFTR;    
    htp.showpage;
  end;




  PROCEDURE SHOWREPORT (dblog in varchar2 default null)
  is
  begin
    INITOWA;
    PRINTPAGEHDR;
    OOCIS_INSTINFO;
    OOCIS_DBINFO;
    OOCIS_OSStat;
    OOCIS_DBParams;
    OOCIS_patchreport;
    OOCIS_obsoleteparams;
    OOCIS_CtrlFileCheck;
    OOCIS_LogFileCheck;
    OOCIS_ObjValidCheck;
    OOCIS_NonSysObjSystemTbs;
    OOCIS_DBCompCheck;
    OOCIS_RMANJobDetails;
    OOCIS_UsersElevatedRoles;
    OOCIS_UsersElevatedPrivs;
    if upper(dblog) = 'YES' then
      OOCIS_GetAlertLogErrs;
    end if;
    OOCIS_TbsSpaceUsageRpt;
    PRINTPAGEFTR;    
    --htp.showpage;
  end;

  PROCEDURE GENREPORT  (p_dir     in varchar2,   p_fname   in varchar2 default null, dblog in varchar2 default null)
  is
  begin
    INITOWA;
    PRINTPAGEHDR;
    OOCIS_INSTINFO;
    OOCIS_DBINFO;
    OOCIS_OSStat;
    OOCIS_DBParams;
    OOCIS_patchreport;
    OOCIS_obsoleteparams;
    OOCIS_CtrlFileCheck;
    OOCIS_LogFileCheck;
    OOCIS_ObjValidCheck;
    OOCIS_NonSysObjSystemTbs;
    OOCIS_DBCompCheck;
    OOCIS_RMANJobDetails;
    OOCIS_UsersElevatedRoles;
    OOCIS_UsersElevatedPrivs;
    if upper(dblog) = 'YES' then
      OOCIS_GetAlertLogErrs;
    end if;
    OOCIS_TbsSpaceUsageRpt;
    PRINTPAGEFTR;    
    dump_page(p_dir  ,   p_fname);
  end;

END PKGRTPA;
/

--drop package PKGRTPA;--drop package PKGRTPA;
