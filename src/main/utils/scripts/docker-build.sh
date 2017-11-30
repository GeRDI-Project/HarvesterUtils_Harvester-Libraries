echo "Building docker image"

# go to the maven build directory
cd target

# set up variables
dockerFilePath="Dockerfile"
warSourceFile=$(ls *.war)

imageVersion=${warSourceFile#*_}
imageVersion=$(echo ${imageVersion%.*} | tr '[:upper:]' '[:lower:]')
imageName=$(echo ${warSourceFile%_*} | tr '[:upper:]' '[:lower:]')

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
docker build -t $imageName:$imageVersion .