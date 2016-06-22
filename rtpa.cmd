@echo off 
mkdir reports
copy blank.htt reports\blank.html
copy head.htt reports\head.html
set linkfile=links_%time:~0,2%_%time:~3,2%_%time:~6,2%_%date:~4,2%_%date:~7,2%_%date:~10,4%.html
echo ^<H2^>Server/DB List^</H2^>^<HR^> > reports\%linkfile%
rem echo ^<UL^> > reports\reports\%linkfile%
type b01.htt > reports\body.html
echo ^<frame src="links_%time:~0,2%_%time:~3,2%_%time:~6,2%_%date:~4,2%_%date:~7,2%_%date:~10,4%.html" name="links" ^> >> reports\body.html
type b02.htt >> reports\body.html

for /f "tokens=1,2,3" %%a in (dblist.cfg) do (
	sqlplus11\sqlplus cis$$rtpa$$/cis$$rtpa$$@//%%a:%%b/%%c @rtpa no %linkfile%
)

REM echo ^</UL^> > reports\reports\%linkfile%
rem copy rpttpl01.htt reports\RTPA_REPORT_%time:~0,2%_%time:~3,2%_%time:~6,2%_%date:~4,2%_%date:~7,2%_%date:~10,4%.html
copy rpttpl01.htt reports\RTPA_MAIN.html