@echo off

set INT=%USERPROFILE%\loc\int
set PLOT=%INT%\plot.pl\plot.pl
set PATH=%PATH%;%INT%\mingw\msys\1.0\bin
set PATH=%PATH%;%INT%\gnuplot\gp465-win32\bin

perl.exe %PLOT% %1

