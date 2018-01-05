# Description:
# This script builds and runs a docker image using the Dockerfile from the current directory and a war-file from the target/ directory.
# The name of the image is derived from the war-file's pom.properties file, whereas the image version can be explicitly defined.
#
# Arguments:
# 1 - docker image name
#     If "", the name will be the war file name up until the first character that is neither a letter nor a -
#     If "<maven>", the name will be the artifactId defined in the pom.properties of the war-file.
#     If "<git>", the name will the name of the bitbucket repository.
#
# 2 - docker image tag
#     If "", the tag will be "latest".
#     If "<maven>", the tag will be the one defined in the pom.properties of the war-file.
#     If "<git>", the tag will be the current git tag.


# navigate to project root directory
projectRoot=$(git rev-parse --show-toplevel)
if [ "$projectRoot" != "" ]; then
  cd $projectRoot
fi

# build image
fullImageName=$(./scripts/docker-build.sh "$1" "$2" "")

# run image if it exists
if [ "$fullImageName" != "" ]; then 
  docker run -p 8080:8080 $fullImageName
fi