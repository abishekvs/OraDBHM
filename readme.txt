RTPA Readme File

Initial Setup.
rtpa_pre.sql script file has to be run on all the databases as sysdba, it is mandatory that this script is run as SYS as only SYS user can grant a few privileges to other users. The script will create a user called cis$$rtpa$$ which is used to generate the RTPA report.

Once the rtpa_pre.sql script has been run on all the databases on all servers, please add entries for all databases in the file dblist.cfg, one line for each database with the format HOSTNAME<TAB>PORT<TAB>DBNAME, Run the rtpa_setup.cmd batch script from the central server.

Optional cleanup
Though it is optional it is highly recommended to run the script rtpa_post.sql on each database as sysdba, this will ensure some system privileges are revoked from cis$$rtpa$$ as these privileges are needed only to run the setup.

Generating the report
To generate the report run the batch script rtpa.cmd, this will generate reports for all DBs listed in the file dblist.cfg
The report files are placed in a folder called "reports" created under the current directory, the main report file is called RTPA_MAIN.html, this file is overwritten every time you generate a new set of reports, it is advisable to backup/rename this file before generating a new set of rtpa reports, please note that though the rtpa_main.html is overwritten the actual report data is still in tact, please do not delete any files in the report folder manually to avoid mal formed reports.

For any questions write to abishek.vidyashanker@in.unisys.com