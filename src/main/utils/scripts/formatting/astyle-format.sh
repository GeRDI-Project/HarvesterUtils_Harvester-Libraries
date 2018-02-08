#!/bin/bash

# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

# This Script formats all source files that match the extensions defined in astyle-fileTypes.ini

# abort if AStyle is not installed
isInstalled=$(command -v astyle)

if [ "$isInstalled" = "" ]; then
  echo "Cannot format: AStyle 3.11 is not installed!"
  exit 1
fi

echo "Formatting Code:"

# navigate to project root directory
projectRoot=$(git rev-parse --show-toplevel)
if [ "$projectRoot" != "" ]; then
  cd $projectRoot
fi

# read ini files
formattingStyle="$projectRoot/scripts/formatting/astyle-kr.ini"
includedFiles=$(cat "$projectRoot/scripts/formatting/astyle-includedFiles.ini")

# run AStyle for all included filetypes
printf '%s\n' "$includedFiles" | while IFS= read -r fileType
do 
  astyle "$projectRoot/src/*.$fileType" --options="$formattingStyle" --recursive --suffix=none --formatted
done