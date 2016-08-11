@echo off

set INT=%USERPROFILE%\loc\int
set PLOT=%INT%\plot.pl\plot.pl
REM set PATH=%PATH%;%INT%\mingw\msys\1.0\bin
set PATH=%PATH%;%INT%\cygwin\cygwin64\bin
set PATH=%INT%\gnuplot\gnuplot\bin;%PATH%

REM perl.exe %PLOT% %1
start %INT%\cygwin\cygwin64\bin\run.exe /usr/bin/perl.exe %PLOT% %1

