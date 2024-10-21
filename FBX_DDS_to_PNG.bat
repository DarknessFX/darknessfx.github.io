@ECHO OFF
@TITLE FBX DDS to FBX PNG
SETLOCAL EnableDelayedExpansion
CLS


REM === SETTINGS ==
SET output_dir=Converted
SET img_size=2048


REM === MAIN ==
CALL :LoadInternals
CALL :Banner
CALL :CheckTool Conv
(
  IF %ERRORLEVEL% EQU %Fail% ( CALL :AutoDownload Conv )
  IF %ERRORLEVEL% EQU %Fail% ( GOTO :END )
)
CALL :CheckTool Diag
(
  IF %ERRORLEVEL% EQU %Fail% ( CALL :AutoDownload Diag )
  IF %ERRORLEVEL% EQU %Fail% ( GOTO :END )
)
CALL :CheckTool2
(
  IF %ERRORLEVEL% EQU %Fail% ( CALL :AutoDownload2 )
  IF %ERRORLEVEL% EQU %Fail% ( GOTO :END )
)
CALL :Start
FOR /R "%CD%\Textures" %%F IN (*.dds) DO (
  CALL :GetFileInfo %%F
  CALL :Diag %%F
  CALL :Conv %%F
)
CALL :FBXConv
CALL :FBXFix
CALL :BannerOut
GOTO :END


REM === FUNC ==
:FBXConv
FOR %%F IN (*.fbx) DO (
  FbxFormatConverter.exe -q "%%F" > tmp.txt
  FIND "binary" tmp.txt >nul
  IF ERRORLEVEL 1 (
    ECHO Copying FBX ASCII : %%~nxF
    COPY %%F %CD%\%output_dir%\%%~nxF
  ) ELSE (
    ECHO Converting to FBX ASCII : %%~nxF
    FbxFormatConverter.exe -c "%%F" -o "%CD%\%output_dir%\%%~nxF" -ascii
  )
)
%return% 

:FBXFix
FOR /R "%CD%\%output_dir%" %%F IN (*.fbx) DO (
  CALL :ReplaceFBX %%F %CD%\%%~nF_Fixed.fbx
  TIMEOUT /T 1 >nul
  DEL "%%F"
  TIMEOUT /T 1 >nul
  MOVE %CD%\%%~nF_Fixed.fbx %%F
  TIMEOUT /T 1 >nul
)
%return% 

:Diag
texdiag.exe info "%1" >tmp.txt
SET index=0
FOR /F "delims== skip=4 tokens=2" %%A IN (tmp.txt) DO (
  SET /A index+=1
  SET value=%%A
  IF !index! EQU 1  ( SET diag_width=!value:~1!)
  IF !index! EQU 2  ( SET diag_height=!value:~1!)
  IF !index! EQU 3  ( SET diag_depth=!value:~1!)
  IF !index! EQU 4  ( SET diag_mipLevels=!value:~1!)
  IF !index! EQU 5  ( SET diag_arraySize=!value:~1!)
  IF !index! EQU 6  ( SET diag_format=!value:~1!)
  IF !index! EQU 7  ( SET diag_dimension=!value:~1!)
  IF !index! EQU 8  ( SET diag_alpha mode=!value:~1!)
  IF !index! EQU 9  ( SET diag_images=!value:~1!)
  IF !index! EQU 10 ( SET diag_pixelsize=!value:~1,-5!)
)
DEL tmp.txt
%return% 0

:Conv
ECHO Converting !filename!
texconv -nologo -timing -pow2 -w !diag_width! -h !diag_height! -m !diag_mipLevels! -f DXT1 -wicq 1.0 -wiclossless -wicmulti -o "%CD%\%output_dir%\Textures" -y -ft png -- "%1"
ECHO.
%return% 

:Start
ECHO Starting...
IF NOT EXIST %CD%\%output_dir% ( MKDIR %CD%\%output_dir% )
IF NOT EXIST %CD%\%output_dir%\Textures ( MKDIR %CD%\%output_dir%\Textures )
%return%

:ReplaceFBX
IF EXIST "%1" (
  ECHO Editing FBX, replacing .DDS with .PNG : %~n2
  SET a1=%~p1
  SET a1=!a1:^\=^\^\!
  SET a2=%~p2
  SET a2=!a2:^\=^\^\!
  POWERSHELL "(Get-Content '%1') -replace '.dds','.png' -replace '!a2!','!a1!' | Out-File -encoding ASCII '%2'"
)
%return%

:Banner
ECHO ===============================================================================
ECHO  .----------------.  .----------------.  .----------------. 
ECHO ^| .--------------. ^|^| .--------------. ^|^| .--------------. ^|
ECHO ^| ^|  ________    ^| ^|^| ^|  _________   ^| ^|^| ^|  ____  ____  ^| ^|
ECHO ^| ^| ^|_   ___ `.  ^| ^|^| ^| ^|_   ___  ^|  ^| ^|^| ^| ^|_  _^|^|_  _^| ^| ^|
ECHO ^| ^|   ^| ^|   `. \ ^| ^|^| ^|   ^| ^|_  \_^|  ^| ^|^| ^|   \ \  / /   ^| ^|
ECHO ^| ^|   ^| ^|    ^| ^| ^| ^|^| ^|   ^|  _^|      ^| ^|^| ^|    ^> ^`^' ^<    ^| ^|
ECHO ^| ^|  _^| ^|___.' / ^| ^|^| ^|  _^| ^|_       ^| ^|^| ^|  _/ /'`\ \_  ^| ^|
ECHO ^| ^| ^|________.'  ^| ^|^| ^| ^|_____^|      ^| ^|^| ^| ^|____^|^|____^| ^| ^|
ECHO ^| ^|              ^| ^|^| ^|              ^| ^|^| ^|              ^| ^|
ECHO ^| '--------------' ^|^| '--------------' ^|^| '--------------' ^|
ECHO  '----------------'  '----------------'  '----------------' 
ECHO.
ECHO       DarknessFX @ https://dfx.lv ^| Twitter: @DrkFX
ECHO.
ECHO ===============================================================================
ECHO.
ECHO Script to convert FBX with DDS textures to FBX PNG.
ECHO.
ECHO   ... because UnrealEngine is allergic to DDS ...
ECHO.
ECHO Using Microsoft DirectXTex TexConv.exe and TexDiag.exe.
ECHO Please, download both files before use this script :
ECHO.
ECHO TexConv from
ECHO %ColorBlueDarkFG%https://github.com/microsoft/DirectXTex/releases/download/sep2024/texconv.exe%ColorDefault%
ECHO.
ECHO TexDiag from
ECHO %ColorBlueDarkFG%https://github.com/microsoft/DirectXTex/releases/download/sep2024/texdiag.exe%ColorDefault%
ECHO.
ECHO Also using FbxFormatConverter.
ECHO Please, download it before use this script :
ECHO.
ECHO FbxFormatConverter from
ECHO %ColorBlueDarkFG%https://github.com/BobbyAnguelov/FbxFormatConverter/releases/download/v0.3/FbxFormatConverter.exe%ColorDefault%
ECHO.
%return%

:BannerOut
ECHO.
ECHO %ColorGreenDarkFG%Success!%ColorDefault% Everything worked.
ECHO   Your converted files location is :
ECHO     %CD%\%output_dir%
ECHO.
%return%

:AutoDownload
SET _result=%Fail%
SET /P answer=Do you want to try auto-download [y/N]? || Set answer=N
IF /I %answer% EQU Y (
  ECHO Downloading ...
  BITSADMIN /rawreturn /transfer /download "https://github.com/microsoft/DirectXTex/releases/download/sep2024/tex%1.exe" "%CD%\tex%1.exe"
  GOTO :RESTART
  SET _result=%Success%
)
%return% %_result%

:AutoDownload2
SET _result=%Fail%
SET /P answer=Do you want to try auto-download [y/N]? || Set answer=N
IF /I %answer% EQU Y (
  ECHO Downloading ...
  BITSADMIN /rawreturn /transfer /download "https://github.com/BobbyAnguelov/FbxFormatConverter/releases/download/v0.3/FbxFormatConverter.exe" "%CD%\FbxFormatConverter.exe"
  GOTO :RESTART
  SET _result=%Success%
)
%return% %_result%

:CheckTool
SET _result=
ECHO Checking Tex%1.exe ... 
tex%1.exe>nul
IF %ERRORLEVEL% EQU %Success% (
  ECHO        %ColorGreenDarkFG%Found!%ColorDefault%
  SET _result=%Success%
) ELSE (
  ECHO        %ColorRedDarkFG%Not found!%ColorDefault%
  ECHO.
  ECHO %ColorRedDarkFG%Error:%ColorDefault% Can't find Tex%1.exe, please download the tool.
  SET _result=%Fail%
)
%return% %_result%

:CheckTool2
SET _result=
ECHO Checking FbxFormatConverter.exe ... 
FbxFormatConverter.exe>nul
IF %ERRORLEVEL% EQU %Success% (
  ECHO        %ColorGreenDarkFG%Found!%ColorDefault%
  SET _result=%Success%
) ELSE (
  ECHO        %ColorRedDarkFG%Not found!%ColorDefault%
  ECHO.
  ECHO %ColorRedDarkFG%Error:%ColorDefault% Can't find FbxFormatConverter.exe, please download the tool.
  SET _result=%Fail%
)
%return% %_result%

:GetFileInfo
SET file=%1
SET filename=%~nx1
SET filepath=%~p1
SET filepath=!filepath:~1!
SET filepath=!filepath:~%CDlength%,-1!
Set filesubpath=!filepath!\!filename!
%return%

:LoadInternals
SET return=EXIT /B
SET Success=0
SET Fail=1
CALL :strlen %CD% CDlength

REM TexConv
SET width=%img_size%
SET height=%img_size%

REM TexDiag
SET diag_width=
SET diag_height=
SET diag_depth=
SET diag_mipLevels=
SET diag_arraySize=
SET diag_format=
SET diag_dimension=
SET diag_alpha mode=
SET diag_images=
SET diag_pixelsize=

FOR /F %%A IN ('ECHO PROMPT $E^| cmd') DO SET "ESC=%%A"
SET ColorDefault=%ESC%[0m
SET ColorBlackFG=%ESC%[30m
SET ColorBlackBG=%ESC%[40m
SET ColorRedDarkFG=%ESC%[31m
SET ColorRedDarkBG=%ESC%[41m
SET ColorGreenDarkFG=%ESC%[32m
SET ColorGreenDarkBG=%ESC%[42m
SET ColorBlueDarkFG=%ESC%[34m
SET ColorBlueDarkBG=%ESC%[44m
%return%

:strlen  StrVar  [RtnVar]
SETLOCAL EnableDelayedExpansion
SET "s=#!%~1!"
SET "len=0"
FOR %%N IN (4096 2048 1024 512 256 128 64 32 16 8 4 2 1) DO (
  IF "!s:~%%N,1!" NEQ "" (
    SET /a "len+=%%N"
    SET "s=!s:~%%N!"
  )
)
ENDLOCAL&IF "%~2" NEQ "" (SET %~2=%len%) ELSE ECHO %len%
%return%

REM === END ==
:RESTART
START "" "%~f0"
EXIT /B

:END
IF EXIST tmp.txt (
  DEL tmp.txt>nul
)
ECHO.
PAUSE
%return%