@echo off

set INT=%USERPROFILE%\loc\int
set PLOT=%INT%\plot.pl\plot.pl
REM set PATH=%PATH%;%INT%\mingw\msys\1.0\bin
set PATH=%PATH%;%INT%\cygwin\cygwin64\bin
set PATH=%PATH%;%INT%\gnuplot\gnuplot\bin

perl.exe %PLOT% %1

