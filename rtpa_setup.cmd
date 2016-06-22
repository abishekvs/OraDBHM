@echo off
for /f "tokens=1,2,3" %%a in (dblist.cfg) do (
	sqlplus11\sqlplus cis$$rtpa$$/cis$$rtpa$$@//%%a:%%b/%%c @rtpa_setup
)
