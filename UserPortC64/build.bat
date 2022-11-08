set filename=user
set toolPath="D:\MyData\Geek Stuff\Projects\Commodore 64\Software\PC Utils-SW"


@echo off
setlocal EnableDelayedExpansion
SET clean=del
SET cleanArgs=/F /Q 
SET buildPath=build
SET build=%filename%.prg
SET sourcePath=source
SET source=%filename%.asm

SET compilerPath=%toolPath%\C64-devkit\compiler\win32
SET compiler=acme.exe
SET compilerReport=buildreport
SET compilerSymbols=symbols
SET compilerArgs=-r %buildPath%\%compilerReport% --vicelabels %buildPath%\%compilerSymbols% --msvc --color --format cbm -v3 --outfile

SET cruncherPath=%toolPath%\C64-devkit\cruncher\win32
SET cruncher=pucrunch.exe
SET cruncherArgs=-x$c000 -c64 -g55 -fshort
rem SET cruncherArgs=-x$0801 -c64 -g55 -fshort

SET emulatorPath=%toolPath%\Emulation\GTK3VICE-3.6.1-win64\bin
SET emulator=x64sc.exe
SET emulatorArgs=-autostart

rem SET genosinePath=%toolPath%\C64-devkit\genosine\win32
rem SET genosine=genosine.exe
rem SET tablesPath=tables
rem SET table1=sin1.dat
rem SET table1Args=256 63 81 0 720 80 3 0
rem SET table2=sin2.dat
rem SET table2Args=256 0 255 0 180 20 3 1
rem SET table3=sin3.dat
rem SET table3Args=256 80 255 0 360 60 2 1
rem SET table4=sin4.dat
rem SET table4Args=256 90 255 0 720 80 1 0


echo ***Start...
%clean% %cleanArgs% %buildPath%\*.*

rem echo ***Tables...
rem %clean% %cleanArgs% %tablesPath%\*.*
rem %genosinePath%\%genosine% %table1Args% > %tablesPath%\%table1%
rem %genosinePath%\%genosine% %table2Args% > %tablesPath%\%table2%
rem %genosinePath%\%genosine% %table3Args% > %tablesPath%\%table3%
rem %genosinePath%\%genosine% %table4Args% > %tablesPath%\%table4%

echo ***Compile...
%compilerPath%\%compiler% %compilerArgs% %buildPath%\%build% %sourcePath%\%source%

echo ***Crunch...
%cruncherPath%\%cruncher% %cruncherArgs% %buildPath%\%build% %buildPath%\%build%

echo ***Emulate...
rem @echo on
%emulatorPath%\%emulator% %emulatorArgs% %buildPath%\%build%
pause
