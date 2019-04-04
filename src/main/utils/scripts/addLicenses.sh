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


# treat unset variables as an error when substituting
set -u


#########################
#  FUNCTION DEFINITIONS #
#########################

# Retrieves the owner defined in the pom.xml.
# If no owner is specified, all developers are returned
# in a comma separated string.
#
# Arguments:
#  1 - the content of the pom.xml of which the owner is to be retrieved  
#
GetOwner() {
  local pomContent="$1"

  # retrieve owner tag value
  local owner
  owner=$(echo "$pomContent" | grep -oP "(?<=<owner>)[^<]+")

  # retrieve developers if no owner was specified
  if [ -z "$owner" ]; then
    local developers
    developers=${pomContent#*<developers>}
    developers=${developers%%</developers>*}
	
    owner=$(echo "$developers" \
	        | grep -oP "(?<=<name>)[^<]+" \
            | tr '\n' ',')
    owner=$(echo "${owner::-1}" | sed -e 's~,~, ~g')
  fi
  
  echo "$owner"
}


# Checks if the pom.xml has a defined inception year.
#
# Arguments:
#  1 - the content of the pom.xml to be checked
#
HasInceptionYear() {
  local pomContent="$1"
  echo "$pomContent" | grep -q "<inceptionYear>"
}


# Adds an inceptionYear-tag with a the first commit year to the pom.xml.
#
# Arguments:
#  1 - the content of the pom.xml to which the year is added
#
AddInceptionYear() {
  local pomContent="$1"
  
  echo "No <inceptionYear> tag was found, adding the date of the first commit as inception year." >&2
  
  # look for first commit of the pom.xml)
  local year=$( git log --format=%ad --date=format:%Y pom.xml | tail -1 )
  
  # abort if there is no commit date
  if [ -z "$year" ]; then
    echo "Cannot set license headers, because the inception year could not be retrieved!" >&2
    exit 1
  fi  
  
  # retrieve a tag after which the insertion year should be added
  local insertionTag
  if [ -n $(echo "$pomContent" | grep -o "</description>") ]; then
    insertionTag="description"
  else
    insertionTag="modelVersion"
  fi
  
  # retrieve whitespace that comes before the opening tag
  whitespace=$(echo "$pomContent" | grep -oP "\s+(?=<$insertionTag>)")
  
  # write content to temporary pom.xml
  newPom=$(mktemp)
  echo "${pomContent%</$insertionTag>*}</$insertionTag>" > $newPom
  echo "$whitespace<inceptionYear>$year</inceptionYear>${pomContent#*</$insertionTag>}" >> $newPom
  
  # replace pom.xml
  mv -f $newPom pom.xml
}


# The main function that is called when this script is executed
#
# Arguments: - 
#
Main() {
  # check if pom.xml exists
  if [ ! -f "pom.xml" ]; then
    echo "Cannot set license headers, because no pom.xml exists!" >&2
    exit 1
  fi
  
  # read pom.xml
  local pomContent=$(cat pom.xml)
  
  # retrieve owner or developers
  local owner=$(GetOwner "$pomContent")
  if [ -z "$owner" ]; then
    echo "Cannot set license headers, because no owners are specified!" >&2
    exit 1
  fi

  # check if inception year is present in the pom
  if ! $(HasInceptionYear "$pomContent"); then
    AddInceptionYear "$pomContent"
  fi
  
  # generate headers
  echo "Adding license headers for owner(s) '$owner'" >&2
  mvn license:format -DaddHeadersInternal -Downer="$owner" >&2 
}


###########################
#  BEGINNING OF EXECUTION #
###########################

Main "$@"
