# Description:
# This script builds a docker image using the Dockerfile from the current directory and a war-file from the target/ directory.
# The name of the image is derived from the war-file's pom.properties file, whereas the image version can be explicitly defined.
# After the image is built, it is pushed to a docker registry and subsequently removed from the local image list.
#
# Arguments:
#
# 1 - docker image version
#     If empty, the version will be "latest".
#     If "<maven>", the version will be the one defined in the pom.properties of the war-file.
#
# 2 - docker registry URL
#     If "<gerdi>", the URL will be "docker-registry.gerdi.research.lrz.de:5043".

image=$(./scripts/docker-getImageName.sh "$1" "$2")

if [ "$image" = "" ]; then 
  echo "Could not find a war-file in the target/ directory! Make sure you are in a valid Maven project root directory, and that a war-file has been built!"

else
  # build image
  echo "Building docker image $image"
  docker build -t $image .

  # push image
  echo "Pushing docker image $image"
  docker push $image

  # remove image from local image list
  echo "Removing docker image from local docker image list"
  docker rmi $image
fi