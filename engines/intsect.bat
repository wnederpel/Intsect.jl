@echo off
set "INTSECT_ROOT=%~1"
if "%INTSECT_ROOT%"=="" (
	echo Usage: intsect.bat ^<folder^>
	echo Example: intsect.bat engines\intsect-first-build
	exit /b 1
)

set "INTSECT_EXE=%INTSECT_ROOT%\bin\intsect.exe"
if not exist "%INTSECT_EXE%" (
	echo Error: "%INTSECT_EXE%" not found.
	exit /b 1
)

shift
"%INTSECT_EXE%" %*
