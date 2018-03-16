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

# This Script formats all source files that match the extensions defined in astyle-fileTypes.ini

# Description:
# This Script formats all source files that match the extensions defined in astyle-fileTypes.ini
# using the astyle-kr.ini to determine how the files should be formatted.
# Can format single files or a directory.
#
# Arguments: 
#  1 - the file or directory that is to be formatted. If empty, the src/ folder will be chosen.


# abort if AStyle is not installed
command -v astyle || {
  echo "Cannot format: AStyle 3.11 is not installed!"
  exit 1
}

echo "Formatting Code:"

# navigate to project root directory
projectRoot=$(git rev-parse --show-toplevel)
if [ "$projectRoot" = "" ]; then
  projectRoot="."
else
  cd $projectRoot
fi

# get path to the files that are to be formatted
# preferably, use the firest argument, otherwise the project source folder
targetPath=$(realpath "${1:-$projectRoot/src}")

isFormattingDirectory=
[ -d "$targetPath" ] && isFormattingDirectory=true
[ -f "$targetPath" ] && isFormattingDirectory=false
if [ -z $isFormattingDirectory ]; then 
    echo "Could not format path $targetPath! Please specify a valid file or a folder." >&2
    exit 1
fi

# read ini files
formattingStyle="$projectRoot/scripts/formatting/astyle-kr.ini"
includedFiles="$projectRoot/scripts/formatting/astyle-includedFiles.ini"

if $isFormattingDirectory; then
  # format folder
  xargs -a "$includedFiles" -I {} \
    astyle --options="$formattingStyle" --recursive --suffix=none --formatted "$targetPath/*.{}"
else
  # format single file
  validFileExtension=$(grep "${targetPath##*.}" "$includedFiles")
  if [ "$validFileExtension" != "" ]; then
    astyle "$targetPath" --options="$formattingStyle" --suffix=none --formatted
  else
    echo "Could not format $targetPath because '${targetPath##*.}' is not a suitable file type for AStyle." >&2
    exit 1
  fi
fi
echo "Done!" >&2