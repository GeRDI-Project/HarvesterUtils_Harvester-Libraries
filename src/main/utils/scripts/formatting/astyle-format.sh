echo "Formatting Code:"

# navigate to project root directory
projectRoot=$(git rev-parse --show-toplevel)
if [ "$projectRoot" != "" ]; then
  cd $projectRoot
fi

sourcePath="$projectRoot/src/*"
formattingStyle="$projectRoot/scripts/formatting/astyle-kr.ini"

# run AStyle without changing the files
astyle --options="$formattingStyle" --recursive --suffix=none --formatted "$sourcePath"
returnCode=$?

if [ $returnCode -ne 0 ]; then
  echo "Astyle returned an error. Please make sure that AStyle is installed!"
  exit 1
else
  exit 0
fi