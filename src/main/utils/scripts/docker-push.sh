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
# After the image is built, it is pushed to a docker registry and subsequently removed from the local image list.
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


if [ "$3" = "" ]; then
  echo "You need to specify three arguments: dockerImageName, dockerImageTag, dockerRegistryURL"
  exit 1
fi

# navigate to project root directory
projectRoot=$(git rev-parse --show-toplevel)
if [ "$projectRoot" != "" ]; then
  cd $projectRoot
fi

# build image
scriptPath=$(dirname "${BASH_SOURCE[0]}")
fullImageName=$($scriptPath/docker-build.sh "$1" "$2" "$3")

if [ "$fullImageName" != "" ]; then 
  # push image
  echo "Pushing docker image $fullImageName" >&2
  docker push $fullImageName
  
  # push 'latest' tag
  imageTag=${fullImageName##*:}
  if [ "$imageTag" != "latest" ]; then
    latestImage=${fullImageName%:*}:latest
    docker tag  $fullImageName $latestImage
    docker push $latestImage
  fi

  # remove image from local image list
  echo "Removing docker image from local docker image list" >&2
  docker rmi $fullImageName
fi