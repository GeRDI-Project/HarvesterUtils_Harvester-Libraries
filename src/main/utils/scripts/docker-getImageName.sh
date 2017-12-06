# Arguments:
#
# 1 - docker image version
#     If empty, the version will be "latest".
#     If "<maven>", the version will be the one defined in the pom.properties of the war-file.
#
# 2 - docker registry URL
#     If "<gerdi>", the URL will be "docker-registry.gerdi.research.lrz.de:5043".


# make sure a war-file exists
warFile=$(ls target/*.war)
if [ -e $warFile ]; then 
  # extract maven metadata from war-file
  mavenMetadata=$(unzip -p target/*.war META-INF/maven/**/pom.properties)

  mavenVersion=${mavenMetadata#*version=}
  mavenVersion=${mavenVersion%%[^-0-9.A-Za-z]*}

  mavenArtifact=${mavenMetadata#*artifactId=}
  mavenArtifact=${mavenArtifact%%[^-0-9.A-Za-z]*}

  # define image version
  imageVersion=$1
  if [ "$imageVersion" = "" ]; then
    imageVersion="latest"
  elif [ "$imageVersion" = "<maven>" ]; then
    imageVersion=$(echo $mavenVersion | tr '[:upper:]' '[:lower:]')
  fi

  # add a slash at the end of the docker registry URL, if it's not already there
  dockerRegistryUrl=$2
  if [ "$dockerRegistryUrl" = "<gerdi>" ]; then
    dockerRegistryUrl="docker-registry.gerdi.research.lrz.de:5043/"
  elif [ "$dockerRegistryUrl" != "" ] && [ "${dockerRegistryUrl#*/}" != "" ]; then
    dockerRegistryUrl=$dockerRegistryUrl/
  fi

  imageName=$(echo "$mavenArtifact" | tr '[:upper:]' '[:lower:]')
  echo $dockerRegistryUrl$imageName:$imageVersion
else
  echo ""
fi