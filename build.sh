#!/bin/sh

set -o errexit
set -o errtrace
set -o pipefail

PROJECT="Form.xcodeproj"
SCHEME="Form"

IOS_SDK="${IOS_SDK:-"iphonesimulator13.0"}"
IOS_DESTINATION_PHONE="${IOS_DESTINATION_PHONE:-"OS=13.0,name=iPhone Xs"}"

usage() {
cat << EOF
Usage: sh $0 command
  [Building]

  iOS           	Build iOS framework
  examples			Build examples
  clean         	Clean up all un-neccesary files

  [Testing]

  test-iOS      	Run tests on iOS host
  test-native		Run tests using `swift test`

  [Release]
  bump <version>	Bumps podspec and xcodeproject to specified version
EOF
}

COMMAND="$1"

case "$COMMAND" in
  "clean")
    find . -type d -name build -exec rm -r "{}" +\;
    exit 0;
  ;;

   "iOS" | "ios")
   carthage update Flow --cache-builds
    xcodebuild clean \
    -project $PROJECT \
    -scheme "${SCHEME}" \
    -sdk "${IOS_SDK}" \
    -destination "${IOS_DESTINATION_PHONE}" \
    -configuration Debug ONLY_ACTIVE_ARCH=YES \
    CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO \
    build | xcpretty -c
    exit 0;
  ;;

  "examples" | "")
    pod repo update
    for example in examples/*/; do
      echo "Building $example."
      pod install --project-directory=$example
      xcodebuild \
          -workspace "${example}Example.xcworkspace" \
          -scheme Example \
          -sdk "${IOS_SDK}" \
          -destination "${IOS_DESTINATION_PHONE}" \
          build | xcpretty -c
    done
    exit 0
  ;;

   "test-iOS" | "test-ios")
   carthage update Flow --cache-builds
    xcodebuild clean \
    -project $PROJECT \
    -scheme "${SCHEME}" \
    -sdk "${IOS_SDK}" \
    -destination "${IOS_DESTINATION_PHONE}" \
    -configuration Debug \
    ONLY_ACTIVE_ARCH=YES \
    CODE_SIGNING_REQUIRED=NO \
    ENABLE_TESTABILITY=YES \
    build test | xcpretty -c
    exit 0;
  ;;

  "test-native")
  	swift package clean
    swift build
    swift test
    exit 0;
  ;;

  "bump")
  VERSION="$2"

	if [ -z $VERSION ]
    then
      echo "Version parameter is not set. \nExample: sh build.sh bump 1.3.0"
      exit 0;
	 fi

   fastlane run version_bump_podspec version_number:$VERSION
   fastlane run increment_version_number version_number:$VERSION

	exit 0;
  ;;
esac

usage
