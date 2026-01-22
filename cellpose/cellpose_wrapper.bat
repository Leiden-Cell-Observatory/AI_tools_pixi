@echo off
SET CELLPOSE_ENV=D:\Code\AI_tools_pixi\cellpose\.pixi\envs\default
SET PATH=%CELLPOSE_ENV%\Library\bin;%CELLPOSE_ENV%\Scripts;%CELLPOSE_ENV%;%PATH%
SET CONDA_PREFIX=%CELLPOSE_ENV%

REM Call python.exe with all arguments
"%CELLPOSE_ENV%\python.exe" %*