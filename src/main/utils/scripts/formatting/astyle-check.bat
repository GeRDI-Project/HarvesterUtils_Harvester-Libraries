@REM
@REM Copyright © 2017 Robin Weiss (http://www.gerdi-project.de)
@REM
@REM Licensed under the Apache License, Version 2.0 (the "License");
@REM you may not use this file except in compliance with the License.
@REM You may obtain a copy of the License at
@REM
@REM     http://www.apache.org/licenses/LICENSE-2.0
@REM
@REM Unless required by applicable law or agreed to in writing, software
@REM distributed under the License is distributed on an "AS IS" BASIS,
@REM WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
@REM See the License for the specific language governing permissions and
@REM limitations under the License.
@REM

:: This Script checks all source files that match the extensions defined in astyle-fileTypes.ini
:: and prints a list of possibly unformatted files.

@ECHO OFF
SETLOCAL ENABLEEXTENSIONS
SETLOCAL ENABLEDELAYEDEXPANSION


:: check if astyle exists
WHERE /Q astyle
IF %ERRORLEVEL% NEQ 0 (
  echo Cannot format: AStyle 3.11 is not installed^^!
  ENDLOCAL
  ECHO ON
  EXIT /B 1
)

echo Checking Code Formatting:

:: navigate to project root directory
for /f %%i in ('git rev-parse --show-toplevel') do SET projectRoot=%%i
IF "%projectRoot%" == "" (
  SET projectRoot=%CD%
) ELSE (
  cd %projectRoot%
)

SET formattingStyle=%projectRoot%/scripts/formatting/astyle-kr.ini
SET includedFiles=%projectRoot%/scripts/formatting/astyle-includedFiles.ini

:: run AStyle without changing the files
SET unformattedCount=0
for /f "tokens=*" %%f in (%includedFiles%) do (
  for /f "delims=" %%l in ('astyle "%projectRoot%/src/*.%%f" --dry-run --recursive --formatted --options^="%formattingStyle%"') do (
	CALL :isFormatted %%l
    CALL SET /A "unformattedCount=%%unformattedCount%%+%%ERRORLEVEL%%"
  
    CALL :logUnformattedFileName %%l
  )
)

IF "%unformattedCount%" NEQ "0" (
  echo. 
  echo Unformatted Files: %unformattedLog:#=&echo %
  echo.
  echo Found %unformattedCount% unformatted file^(s^)^^! Please use the ArtisticStyle formatter before committing your code^^!
  echo ^(see https://wiki.gerdi-project.de/display/GeRDI/%%5BWIP%%5D+How+to+Format+Code^)
  
  ENDLOCAL
  ECHO ON
  EXIT /B 1
  
) ELSE (
  echo.
  echo All files are properly formatted^^!
  
  ENDLOCAL
  ECHO ON
  EXIT /B 0
)
:: returns 1 if the file is not properly formatted, else 0
:isFormatted
SET temp=%*
IF "%temp:   main\=%" == "%temp%" (
  EXIT /B 0
) ELSE (
  EXIT /B 1
)

:: writes the name of the unformatted file (if it exists) to the %unformattedLog% variable
:logUnformattedFileName
SET temp=%*
IF NOT "%temp:   main\=%" == "%temp%" (
  SET temp=!temp:   =#!
  for /f "tokens=1,2 delims=#" %%m in ('echo !temp!') do (
    CALL SET "unformattedLog=%%unformattedLog%%#%%n"
  )
)
EXIT /B 0