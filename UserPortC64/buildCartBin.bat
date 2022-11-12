cls
:: $8000 compile for Lower ROM
:: No crunching
:: Compiled/Saved as BIN w/ no header ("plain" format) for ROM image
:: cartconv to convert/copy to .crt file for emulation

@echo off

set filename=user
set toolPath="D:\MyData\Geek Stuff\Projects\Commodore 64\Software\PC Utils-SW"

setlocal EnableDelayedExpansion
SET clean=del
SET cleanArgs=/F /Q 
SET buildPath=build
rem SET build=%filename%.prg
SET build=%filename%.bin
SET sourcePath=source
SET source=%filename%.asm

SET compilerPath=%toolPath%\C64-devkit\compiler\win32
SET compiler=acme.exe
SET compilerReport=buildreport
SET compilerSymbols=symbols
rem SET compilerArgs=-r %buildPath%\%compilerReport% --vicelabels %buildPath%\%compilerSymbols% --msvc --color --format cbm -v3 --outfile
SET compilerArgs=-r %buildPath%\%compilerReport% --vicelabels %buildPath%\%compilerSymbols% --msvc --color --format plain -v3 --outfile

rem SET cruncherPath=%toolPath%\C64-devkit\cruncher\win32
rem SET cruncher=pucrunch.exe
rem SET cruncherArgs=-x$c000 -c64 -g55 -fshort
rem rem SET cruncherArgs=-x$0801 -c64 -g55 -fshort

SET cartconvPath=%toolPath%\Emulation\GTK3VICE-3.6.1-win64\bin
SET cartconv=cartconv.exe
SET cartconvFilename=%filename%.crt
SET cartconvArgs=-v -t normal -i %buildPath%\%build% -o %buildPath%\%cartconvFilename%

SET emulatorPath=%toolPath%\Emulation\GTK3VICE-3.6.1-win64\bin
SET emulator=x64sc.exe
SET emulatorArgs=-autostart


echo ***Start...
@echo on
%clean% %cleanArgs% %buildPath%\*.*

echo ***Compile...
%compilerPath%\%compiler% %compilerArgs% %buildPath%\%build% %sourcePath%\%source%

rem echo ***Crunch...
rem %cruncherPath%\%cruncher% %cruncherArgs% %buildPath%\%build% %buildPath%\%build%

echo ***CartConvert...
%cartconvPath%\%cartconv% %cartconvArgs%

echo ***Emulate...
%emulatorPath%\%emulator% %emulatorArgs% %buildPath%\%cartconvFilename%

pause
