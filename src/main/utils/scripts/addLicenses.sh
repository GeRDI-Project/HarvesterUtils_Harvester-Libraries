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

# Description:
# This script extracts the owner property and inception year from the pom.xml and
# creates headers in source files using this info. If the inception year property
# is missing from the pom.xml, the last modified date of the pom.xml is retrieved
# and added to the pom.xml.
# If no owner property was specified, the developer names are used instead.
#
# Arguments: none

set -u

if [ ! -f "pom.xml" ]; then
  echo "Cannot set license headers, because no pom.xml exists!" >&2
  exit 1
fi

owner=""
inceptionYear=""

# read pom.xml
pomContent=$(cat pom.xml)

# retrieve owner tag value
owner=$(echo "$pomContent" | grep -oP "(?<=<owner>)[^<]+")

# retrieve developers if no owner was specified
if [ "$owner" = "" ]; then
  developers=${pomContent#*<developers>}
  developers=${developers%%</developers>*}
  developers=$(echo "$developers" | grep -oP "(?<=<name>)[^<]+")
  
  owner=$(printf '%s\n' "$developers" | (while IFS= read -r devName
  do
    if [ "$owner" = "" ]; then
	  owner="$devName"
	else
	  owner="$owner, $devName"
	fi
  done
  
  echo "$owner" ))
fi

# abort if no owner was found
if [ "$owner" = "" ]; then
  echo "Cannot set license headers, because no owners are specified!" >&2
  exit 1
fi

# retrieve inception year
inceptionYear=$(echo "$pomContent" | grep -oP "(?<=<inceptionYear>)[^<]+")

if [ "$inceptionYear" = "" ]; then
  echo "No <inceptionYear> tag was found, using the date of the first commit of the pom.xml" >&2
  commitDates=$(git log --format=%aD -- "pom.xml")
  inceptionYear=$(echo "${commitDates##*$'\n'}" | grep -oP "(?<=\s)\d\d\d\d")
  
  echo "Adding <inceptionYear> tag to pom.xml" >&2
  
  # try to add year after descriptionTag
  if [ "$(echo "$pomContent" | grep -o "</description>")" != "" ]; then
    insertionTag="description"
  else
    insertionTag="modelVersion"
  fi
  
  # retrieve whitespace that comes before the opening tag
  whitespace=$(echo "$pomContent" | grep -oP "\s+(?=<$insertionTag>)")
  
  # write content to temporary pom.xml
  newPom=$(mktemp)
  echo "${pomContent%</$insertionTag>*}</$insertionTag>" > $newPom
  echo "$whitespace<inceptionYear>$inceptionYear</inceptionYear>${pomContent#*</$insertionTag>}" >> $newPom
  
  # replace pom.xml
  mv -f $newPom pom.xml
fi

# generate headers
echo "Adding $inceptionYear Headers for owner(s): $owner" >&2
mvn generate-resources -DaddHeaders -Downer="$owner"