#!/bin/bash
#
# Copyright © 2017 Robin Weiss (http://www.gerdi-project.de)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# This Script checks all source files that match the extensions defined in astyle-fileTypes.ini
# and prints a list of possibly unformatted files.

# abort if AStyle is not installed
isInstalled=$(command -v astyle)

if [ "$isInstalled" = "" ]; then
  echo "Cannot format: AStyle 3.11 is not installed!"
  exit 1
fi

echo "Checking Code Formatting:"

# navigate to project root directory
projectRoot=$(git rev-parse --show-toplevel)
if [ "$projectRoot" = "" ]; then
  projectRoot="."
else
  cd $projectRoot
fi

# read ini files
formattingStyle="$projectRoot/scripts/formatting/astyle-kr.ini"
includedFiles=$(cat "$projectRoot/scripts/formatting/astyle-includedFiles.ini")

# run AStyle without changing the files
CountAndPrintUnformattedFiles() {
  errorCount=0
  unformattedLog='
Unformatted Files:
'
  printf '%s\n' "$includedFiles" | ( while IFS= read -r fileType
  do 
    result=$(astyle "$projectRoot/src/*.$fileType" --options="$formattingStyle" --dry-run --recursive --formatted )
	
	# extract relevant lines
	result=$(echo $result | grep -oP 'main/.+?'$fileType)
	
	# generate log of unformatted files
	unformattedLog=$unformattedLog$result
	
	# count unformatted files
	if [ "$result" != "" ]; then
      errorCount=$(expr $errorCount + $(echo ''"$result"'' | wc -l))
	fi
  done
  
  if [ $errorCount -ne 0 ]; then
    echo ''"$unformattedLog"'' >&2
  fi
  echo $errorCount
  )
}

errorCount=$(CountAndPrintUnformattedFiles)
if [ $errorCount -ne 0 ]; then
  echo '
Found '"$errorCount"' unformatted file(s)! Please use the ArtisticStyle formatter before committing your code!
(see https://wiki.gerdi-project.de/display/GeRDI/%5BWIP%5D+How+to+Format+Code)'
  exit 1
else
  echo "All files are properly formatted!"
  exit 0
fi