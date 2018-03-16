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
SETLOCAL ENABLEDELAYEDEXPANSION

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
  SET projectRoot=!CD!
) ELSE (
  cd !projectRoot!
)

:: get path to the files that are to be formatted
SET "targetPath=%1"

IF "!targetPath!" == "" (
  SET "targetPath=!projectRoot!\src\*"
  
) ELSE (
  :: if path is the folder, get its absolute path
  IF EXIST "!targetPath!\^*" (
    pushd !targetPath!
	SET "targetPath=!CD!\*"
	popd
  ) ELSE (
    IF EXIST "%targetPath%" (
      SET "targetPath=!targetPath:"=!"
    ) ELSE (
      echo Could not format path %targetPath%^^! Please specify a valid file or a folder.
      ENDLOCAL
      ECHO ON
      EXIT /B 1
	)
  )
)

SET formattingStyle=%projectRoot%\scripts\formatting\astyle-kr.ini
SET includedFiles=%projectRoot%\scripts\formatting\astyle-includedFiles.ini

:: check if path ends with * to distinguish between folders and files
IF "%targetPath:~-1%" == "*" (
  :: format folder
  for /F "tokens=*" %%i in ('type "!includedFiles!"') do (
    astyle "!targetPath!.%%i" --suffix=none --recursive --formatted --options="!formattingStyle!"
  )
) ELSE (
  :: check if file has an allowed file extension
  SET isValidFile=false
  for %%i in ("!targetPath!") do (
    SET fileExtension=%%~xi
	for /f %%i in ('type "!includedFiles!"^|find "!fileExtension:~1!"') do (
      SET isValidFile=true
    )
  )
  :: format single file
  IF "!isValidFile!" == "true" (
    astyle "!targetPath!" --suffix=none --formatted --options="!formattingStyle!"
  ) ELSE (
    echo Could not format %targetPath% because ^'!fileExtension!^' is not a suitable file type for AStyle.
    ENDLOCAL
    ECHO ON
    EXIT /B 1
  )
)

echo Done^^!
ENDLOCAL
ECHO ON