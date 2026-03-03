@echo off
setlocal

set "INTSECT_ROOT=%~1"
if "%INTSECT_ROOT%"=="" (
    echo Usage: intsect.bat ^<folder^> 1>&2
    exit /b 1
)

set "INTSECT_EXE=%INTSECT_ROOT%\bin\intsect.exe"
if not exist "%INTSECT_EXE%" (
    echo Error: "%INTSECT_EXE%" not found. 1>&2
    exit /b 1
)

rem Add engine bin dir to PATH so DLLs are found
set "PATH=%INTSECT_ROOT%\bin;%PATH%"

shift
rem Run exe as the last command; stdin/stdout are inherited from the parent pipe.
"%INTSECT_EXE%" %*
