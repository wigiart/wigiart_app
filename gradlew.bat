@echo off
setlocal
set DIR=%~dp0
if "%DIR%"=="" set DIR=.
set DIR=%DIR:~0,-1%
set GRADLE_HOME=%DIR%\gradle
set PATH=%GRADLE_HOME%\bin;%PATH%
java -jar "%DIR%\gradle-wrapper.jar" %*
endlocal
