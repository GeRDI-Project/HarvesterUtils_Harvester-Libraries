echo "Checking Code Formatting:"

# navigate to project root directory
projectRoot=$(git rev-parse --show-toplevel)
if [ "$projectRoot" != "" ]; then
  cd $projectRoot
fi

sourcePath="$projectRoot/src/*"
formattingStyle="$projectRoot/scripts/formatting/astyle-kr.ini"

# run AStyle without changing the files
result=$(astyle --options="$formattingStyle" --dry-run --recursive --formatted "$sourcePath")
returnCode=$?

# remove all text up until the name of the first unformatted file
newResult=${result#*Formatted  }

errorCount=0

while [ "$newResult" != "$result" ]
do
errorCount=$(($errorCount + 1))
result="$newResult"

# retrieve the name of the unformatted file
fileName=$(echo $result | sed -e "s/Formatted .*//gi")
 
# log the unformatted file
echo "Unformatted File: $fileName"

# remove all text up until the name of the next unformatted file
newResult=${result#*Formatted  }
done

if [ $errorCount -ne 0 ]; then
  echo "\\nFound $errorCount unformatted files! Please use the ArtisticStyle formatter before committing your code!\\n(see https://wiki.gerdi-project.de/display/GeRDI/%5BWIP%5D+How+to+Format+Code)"
  exit 1
elif [ $returnCode -ne 0 ]; then
  echo "Astyle returned an error. Please make sure that AStyle is installed!"
  exit 1
else
  echo "All files are properly formatted!"
  exit 0
fi