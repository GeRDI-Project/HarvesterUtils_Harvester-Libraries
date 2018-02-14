::!/bin/bash

:: Licensed to the Apache Software Foundation (ASF) under one
:: or more contributor license agreements.  See the NOTICE file
:: distributed with this work for additional information
:: regarding copyright ownership.  The ASF licenses this file
:: to you under the Apache License, Version 2.0 (the
:: "License"); you may not use this file except in compliance
:: with the License.  You may obtain a copy of the License at
::
::   http://www.apache.org/licenses/LICENSE-2.0
::
:: Unless required by applicable law or agreed to in writing,
:: software distributed under the License is distributed on an
:: "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
:: KIND, either express or implied.  See the License for the
:: specific language governing permissions and limitations
:: under the License.

:: This Script formats all source files that match the extensions defined in astyle-fileTypes.ini

@ECHO OFF
SETLOCAL ENABLEEXTENSIONS

WHERE /Q astyle
IF %ERRORLEVEL% NEQ 0 (
  echo Cannot format: AStyle 3.11 is not installed!
  ENDLOCAL
  ECHO ON
  EXIT /B 1
)

echo Formatting Code:

:: navigate to project root directory
for /f %%i in ('git rev-parse --show-toplevel') do SET projectRoot=%%i
IF NOT "%projectRoot%" == "" (
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
EXIT /B 0