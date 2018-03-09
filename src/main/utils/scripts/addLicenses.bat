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


:: Description:
:: This script extracts the owner property and inception year from the pom.xml and
:: creates headers in source files using this info. If the inception year property
:: is missing from the pom.xml, the last modified date of the pom.xml is retrieved
:: and added to the pom.xml.
:: if no owner property was specified, the developer names are used instead.
::
:: Arguments: none

@ECHO OFF
SETLOCAL ENABLEEXTENSIONS
SETLOCAL ENABLEDELAYEDEXPANSION

SET pomPath=pom.xml
IF NOT EXIST "%pomPath%" (
  echo Cannot set license headers, because no pom.xml exists^^!
  ENDLOCAL
  ECHO ON
  EXIT /B 1
)

:: retrieve owner tag value
for /f "tokens=1,2,3 delims=><" %%a in ('type !pomPath!^|find "<owner>"') do (
  SET owner=%%c
)

:: retrieve developer names if no owner was specified
IF "%owner%" == "" (
  :: retrieve line number of <developer> tag
  for /f "tokens=1,2,3 delims=[]" %%a in ('type !pomPath!^|find /N "<developers>"') do (
    SET /a developersOpeningLine=%%a
  )
  
  IF NOT "!developersOpeningLine!" == "" (
    :: retrieve line number of </developer> tag
    for /f "tokens=1,2,3 delims=[]" %%a in ('type !pomPath!^|find /N "</developers>"') do (
      SET /a developersClosingLine=%%a
    )

	:: concatenate developer names
    for /f "tokens=1,2,3,4 delims=[]<>" %%a in ('type !pomPath!^|find /N "<name>"') do (
      SET /a lineNumber=%%a
	  SET devName=%%d
	
	  IF !lineNumber! GTR !developersOpeningLine! (
	    IF !lineNumber! LSS !developersClosingLine! (
          IF "!owner!" == "" (
            SET owner=!devName!
          ) ELSE (
            SET owner=!owner!, !devName!
          )
        )
      )
    )
  )
)

:: abort if no owner was found
IF "%owner%" == "" (
  echo Cannot set license headers, because no owners are specified^^!
  ENDLOCAL
  ECHO ON
  EXIT /B 1
)

:: retrieve inception year
for /f "tokens=1,2,3 delims=><" %%a in ('type !pomPath!^|find "<inceptionYear>"') do (
  SET inceptionYear=%%c
)

IF "%inceptionYear%" == "" (
  echo No ^<inceptionYear^> tag was found, using the date of the first commit of the pom.xml
  
  :: get file creation date
  CALL :getFileCreationDate "!pomPath!" "inceptionYear"
  
  echo Adding ^<inceptionYear^> tag to pom.xml
  
  :: try to add year after descriptionTag
  SET insertionTag=modelVersion
  for /f "delims=" %%a in ('type !pomPath!^|find "</description>"') do (
    SET insertionTag=description
  )
  
  :: retrieve whitespace that comes before the opening tag
  for /f "tokens=1,2 delims=<" %%a in ('type !pomPath!^|find "</%%insertionTag%%>"') do (
    SET whitespace=%%a
  )
  
  :: create temporary pom.xml
  copy /y NUL tempPom.xml >NUL
  
  :: write content to temporary pom.xml
  for /f "tokens=* delims=" %%a in (!pomPath!) do (
	:: disable delayed expansion for treating special characters
    SETLOCAL DISABLEDELAYEDEXPANSION
	rem copy line to temporary file
	echo.%%a>> tempPom.xml
    ENDLOCAL
	
	:: remove double quotes from line, because they will break the subsequent text replacement
	SET line=%%a
	SET line=!line:"=!
	
	:: remove the insertion closing tag from the line, if it exists
	CALL SET "lineWithoutInsertTag=%%line:^</!insertionTag!^>=%%"
	
	:: check if the current line has the insertion closing tag
	IF NOT "!lineWithoutInsertTag!" == "!line!" (
	  echo.!whitespace!^<inceptionYear^>!inceptionYear!^</inceptionYear^>>> tempPom.xml
	)
  )
  :: replace pom.xml
  xcopy tempPom.xml /y /u /a !pomPath!
  del tempPom.xml
)

:: generate headers
echo Adding license headers for owner(s) ^'%owner%^' and year ^'%inceptionYear%^'
mvn generate-resources -DaddHeaders "-Downer=%owner%"

:: exit script
ENDLOCAL
ECHO ON
EXIT /B 0


:: retrieves the date at which a file was created
:getFileCreationDate
SET fileName=%~1
SET varName=%~2
for /f "tokens=1-6 delims= " %%a in ('git log --format^=%%aD -- "%fileName%"') do (
    CALL SET "%%varName%%=%%d"
  )
EXIT /B 0