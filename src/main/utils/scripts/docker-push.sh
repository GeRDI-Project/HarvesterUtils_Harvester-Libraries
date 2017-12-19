# Description:
# This script builds a docker image using the Dockerfile from the current directory and a war-file from the target/ directory.
# The name of the image is derived from the war-file's pom.properties file, whereas the image version can be explicitly defined.
# After the image is built, it is pushed to a docker registry and subsequently removed from the local image list.
#
# Arguments:
#
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

image=$(./scripts/docker-getImageName.sh "$1" "$2" "$3")

if [ "$image" != "" ]; then 
  # build image
  echo "Building docker image $image"
  docker build -t $image .

  # push image
  echo "Pushing docker image $image"
  docker push $image
  
  # push 'latest' tag
  imageTag=${image##*:}
  if [ "$imageTag" != "latest" ]; then
    latestImage=${image%:*}:latest
    docker tag  $image $latestImage
    docker push $latestImage
  fi

  # remove image from local image list
  echo "Removing docker image from local docker image list"
  docker rmi $image
fi