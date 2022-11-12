cls
:: $c000 compile for crunching
:: Crunched to store as 0801 PRG

@echo off

set filename=user
set toolPath="D:\MyData\Geek Stuff\Projects\Commodore 64\Software\PC Utils-SW"

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



echo ***Start...
%clean% %cleanArgs% %buildPath%\*.*

echo ***Compile...
%compilerPath%\%compiler% %compilerArgs% %buildPath%\%build% %sourcePath%\%source%

echo ***Crunch...
%cruncherPath%\%cruncher% %cruncherArgs% %buildPath%\%build% %buildPath%\%build%

echo ***Emulate...
rem @echo on
%emulatorPath%\%emulator% %emulatorArgs% %buildPath%\%build%
pause
