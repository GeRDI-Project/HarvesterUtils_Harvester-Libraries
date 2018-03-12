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

:: This Script formats all source files that match the extensions defined in astyle-fileTypes.ini

@ECHO OFF
SETLOCAL ENABLEEXTENSIONS

WHERE /Q astyle
IF %ERRORLEVEL% NEQ 0 (
  echo Cannot format: AStyle 3.11 is not installed^^!
  ENDLOCAL
  ECHO ON
  EXIT /B 1
)

echo Formatting Code:

:: navigate to project root directory
for /f %%i in ('git rev-parse --show-toplevel') do SET projectRoot=%%i
IF "%projectRoot%" == "" (
  SET projectRoot=%CD%
) ELSE (
  cd %projectRoot%
)

SET formattingStyle=%projectRoot%/scripts/formatting/astyle-kr.ini
SET includedFiles=%projectRoot%/scripts/formatting/astyle-includedFiles.ini

:: format all files
for /F "tokens=*" %%i in (%includedFiles%) do (
  astyle "%projectRoot%/src/*.%%i" --suffix=none --recursive --formatted --options="%formattingStyle%"
)

ENDLOCAL
ECHO ON