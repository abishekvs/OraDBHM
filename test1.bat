echo %1\%2_%date:~4,2%_%date:~7,2%_%date:~10,4%
echo %1\%2_%date:~4,2%_%date:~7,2%_%date:~10,4%\arch
echo %1\%2_%date:~4,2%_%date:~7,2%_%date:~10,4%\control

echo ^<H2^>Server/DB List^</H2^>^<HR^> > links_%time:~0,2%_%time:~3,2%_%time:~6,2%_%date:~4,2%_%date:~7,2%_%date:~10,4%.html
type b01.htt > reports\body.html
echo ^<frame src="links_%time:~0,2%_%time:~3,2%_%time:~6,2%_%date:~4,2%_%date:~7,2%_%date:~10,4%.html" name="links" ^> >> body.html
type b02.htt >> reports\body.html

