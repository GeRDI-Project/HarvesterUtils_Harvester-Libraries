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
# This script builds a docker image using the Dockerfile from the current directory and a war-file from the target/ directory.
# The name of the image is derived from the war-file's pom.properties file, whereas the image version can be explicitly defined.
#
# Returns: 
# The full name of the built image
#
# Arguments:
# 1 - docker image name
#     If empty, the name will be the war file name up until the first character that is neither a letter nor a -
#     If "<maven>", the name will be the artifactId defined in the pom.properties of the war-file.
#     If "<git>", the name will the name of the bitbucket repository.
#
# 2 - docker image tag
#     If empty, the tag will be "latest".
#     If "<maven>", the tag will be the one defined in the pom.properties of the war-file.
#     If "<git>", the tag will be the current git tag.
#
# 3 - docker registry URL
#     If "<gerdi>", the URL will be "docker-registry.gerdi.research.lrz.de:5043".


projectRoot=$(git rev-parse --show-toplevel)
if [ "$projectRoot" = "" ]; then
  projectRoot="."
fi

# make sure a war-file exists
echo "Looking for war-file in target/ directory" >&2
warFile=$(ls $projectRoot/target/*.war)

if [ "$warFile" = "" ]; then 
  echo "Looking for war-file in current directory" >&2
  warFile=$(ls $projectRoot/*.war)
fi

if [ ! -e $warFile ]; then 
  echo "Could not find war-file!" >&2
  exit 1
fi

# pre-define version and image name
imageName="$1"
imageTag="$2"

# retrieve image name and tag from maven
if [ "$1" = "<maven>" ] || [ "$2" = "<maven>" ]; then
  mavenMetadata=$(unzip -p $warFile META-INF/maven/**/pom.properties)

  if [ "$mavenMetadata" != "" ]; then
    echo "Reading pom.properties from war file" >&2
	
    # get image name from artifact ID
	if [ "$1" = "<maven>" ] ; then
      imageName=${mavenMetadata#*artifactId=}
      imageName=${imageName%%[^-0-9.A-Za-z]*}
	fi
	
	# get image tag from maven version
	if [ "$2" = "<maven>" ] ; then
      imageTag=${mavenMetadata#*version=}
      imageTag=${imageTag%%[^-0-9.A-Za-z]*}
	fi
  else
    echo "Could not read pom.properties from war file" >&2
  fi
fi

# retrieve image name and tag from git
if [ "$1" = "<git>" ]; then
  gitConfig=$(cat .git/config)

	# get image name from the remote origin URL of the git config file
  if [ "$gitConfig" != "" ]; then
    echo "Reading .git/config" >&2
    imageName=${gitConfig#*\[remote \"origin\"\]}
    imageName=${imageName#*url = }
    imageName=${imageName%.git*}
    imageName=${imageName##*/}
  else
    echo "Could not read .git/config" >&2
  fi
fi

# retrieve image version from the current tag
if [ "$2" = "<git>" ]; then
  imageTag=$(git tag -l --points-at HEAD)
  
  if [ "$imageTag" != "" ]; then
    echo "Reading commit tag" >&2
  else
    echo "There is no commit tag" >&2
  fi
fi

# add a slash at the end of the docker registry URL, if it's not already there
dockerRegistryUrl=$3
if [ "$dockerRegistryUrl" = "<gerdi>" ]; then
  dockerRegistryUrl="docker-registry.gerdi.research.lrz.de:5043/"
elif [ "$dockerRegistryUrl" != "" ] && [ "${dockerRegistryUrl#*/}" != "" ]; then
  dockerRegistryUrl=$dockerRegistryUrl/
fi

# fallback image version is 'latest'
if [ "$imageTag" = "" ]; then
  imageTag="latest"
fi

# fallback image name is the war file name up until the first character that is neither a letter nor a -
if [ "$imageName" = "" ]; then
  imageName=${warFile##*/}
  imageName=${imageName%%[^-A-Za-z]*}
fi

# remove "-Harvester...", or "Harvester..." suffix from image name
imageName=${imageName%-Harvester*}
imageName=${imageName%Harvester*}

# prepend "harvest/"
imageName="harvest/$imageName"

# convert image name and tag to lower case
imageName=$(echo $imageName | tr '[:upper:]' '[:lower:]')
imageTag=$(echo $imageTag | tr '[:upper:]' '[:lower:]')
fullImageName="$dockerRegistryUrl$imageName:$imageTag"

# change war file access rights to allow jetty to use it
warAccessRights=$(stat -c "%a" $warFile)
chmod o+rw $warFile

# build image
echo "Building docker image $fullImageName" >&2
dockerBuildLog=$(docker build -t $fullImageName .)
echo "$dockerBuildLog" >&2

# restore old war file access rights
chmod $warAccessRights $warFile

echo $fullImageName