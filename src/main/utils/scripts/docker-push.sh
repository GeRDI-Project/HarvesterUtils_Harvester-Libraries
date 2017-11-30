echo "Building docker image"

# go to the maven build directory
cd target

# set up variables
dockerRegistryUrl="docker-registry.gerdi.research.lrz.de:5043"
dockerFilePath="Dockerfile"
warSourceFile=$(ls *.war)

imageVersion=${warSourceFile#*_}
imageVersion=$(echo ${imageVersion%.*} | tr '[:upper:]' '[:lower:]')
imageName=$(echo ${warSourceFile%_*} | tr '[:upper:]' '[:lower:]')
image=$dockerRegistryUrl/$imageName:$imageVersion

warTargetFile="\$JETTY_BASE/webapps/${imageName%-harvesterservice*}.war"

# remove old docker file
rm -f $dockerFilePath

# assemble docker file
echo "# GeRDI Harvester Image:" >> $dockerFilePath
echo "# $imageName:$imageVersion" >> $dockerFilePath
echo >> $dockerFilePath
echo >> $dockerFilePath
echo "FROM jetty:9.4.7-alpine" >> $dockerFilePath
echo >> $dockerFilePath
echo "COPY $warSourceFile $warTargetFile" >> $dockerFilePath
echo >> $dockerFilePath
echo "EXPOSE 8080" >> $dockerFilePath

# build image
docker build -t $image .

# push image
echo "Pushing docker image to $dockerRegistryUrl"
docker push $image

# remove image from local image list
docker rmi $image