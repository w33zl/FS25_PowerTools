@echo off

fsbuild bump inc
fsbuild install --tag mp

set "xx=FS25_PowerTools\.build\FS25_PowerTools.zip"
Set "REMOTE_MODS_FOLDER=\\fsmp\Farming Simulator 2025 Mods"

if exist "%REMOTE_MODS_FOLDER%" (
    xcopy /y /f /v /s "%xx%" "%REMOTE_MODS_FOLDER%"
) else (
    echo %REMOTE_MODS_FOLDER% does not exist
)
