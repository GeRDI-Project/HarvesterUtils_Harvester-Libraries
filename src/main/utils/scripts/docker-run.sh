# Description:
# This script builds and runs a docker image using the Dockerfile from the current directory and a war-file from the target/ directory.
# The name of the image is derived from the war-file's pom.properties file, whereas the image version can be explicitly defined.
#
# Arguments:
#
# 1 - docker image version
#     If empty, the version will be "latest".
#     If "<maven>", the version will be the one defined in the pom.properties of the war-file.


image=$(./scripts/docker-getImageName.sh "$1" "")

if [ "$image" = "" ]; then 
  echo "Could not find a war-file in the target/ directory! Make sure you are in a valid Maven project root directory, and that a war-file has been built!"

else
  # build image
  echo "Building docker image $image"
  docker build -t $image .
  
  # run image
  docker run -p 8080:8080 $image
fi