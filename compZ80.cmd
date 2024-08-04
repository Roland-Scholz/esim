@echo off
set Z80TOOLS=C:\github\FABIAN
PATH=%PATH%;%Z80TOOLS%\tools;%Z80TOOLS%\tools\z88dk\bin;%Z80TOOLS%\tools\cpmimage\Debug

set CPM=C:\atarigit\CPM\RunCPM-master\Release
set ASM=z80asm
rem set ASM=z80asm.exe
rem set ASM=tniasm.exe

call :compile z80 0000
if not %ERRORLEVEL%==0 goto error

call :compile test A000
if not %ERRORLEVEL%==0 goto error

call :compile test1 A200
if not %ERRORLEVEL%==0 goto error

rem move ..\src\*.o ..\release
rem move ..\src\*.hex ..\release
rem move ..\src\*.lis ..\release
rem move ..\src\*.com ..\release

pause


rem ----------------------------------------------
:compile
rem	pushd ..\src
	echo *** compile %1
	%ASM% -mz80 %3 -b -l -o%1.com %1 
	if not %ERRORLEVEL%==0 goto ende

	bin2hex %1.com %1.hex -o %2
rem	popd
	goto ende
rem ----------------------------------------------

:error
	pause
:ende


