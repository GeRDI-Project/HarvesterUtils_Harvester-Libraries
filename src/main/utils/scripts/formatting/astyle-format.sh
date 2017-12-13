echo "Formatting Code"

# navigate to project root directory
projectRoot=$(git rev-parse --show-toplevel)
if [ "$projectRoot" != "" ]; then
  cd $projectRoot
fi

sourcePath="$projectRoot/src/*"
formattingStyle="$projectRoot/scripts/formatting/astyle-kr.ini"

# run AStyle without changing the files
astyle --options="$formattingStyle" --recursive --suffix=none --formatted "$sourcePath"