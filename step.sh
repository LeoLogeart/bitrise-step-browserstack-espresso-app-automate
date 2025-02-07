#!/bin/bash
set -ex
echo "uploading app apk to browserstack"
upload_app_response="$(curl -u $browserstack_username:$browserstack_access_key -X POST https://api-cloud.browserstack.com/app-automate/upload -F file=@$app_apk_path)"
app_url=$(echo "$upload_app_response" | jq .app_url)

echo "uploading test apk to browserstack"
upload_test_response="$(curl -u $browserstack_username:$browserstack_access_key -X POST https://api-cloud.browserstack.com/app-automate/espresso/test-suite -F file=@$test_apk_path)"
test_url=$(echo "$upload_test_response" | jq .test_url)

echo "starting automated tests"
jsonParamString='{devices: $devices, app: $app_url, testSuite: $test_url'
# Adds parameters when not empty
addParam()
{
    KEY=$1
    VALUE=$2
    if [[ ! -z $VALUE ]]
    then
        jsonParamString+=", $KEY: \$$KEY"
    fi
}
addParam "package" "$browserstack_package"
addParam "video" "$browserstack_video"
addParam "class" "$browserstack_class"
addParam "annotation" "$browserstack_annotation"
addParam "size" "$browserstack_size"
addParam "logs" "$browserstack_device_logs"
addParam "video" "$browserstack_video"
addParam "loc" "$browserstack_local"
addParam "locId" "$browserstack_local_identifier"
addParam "gpsLocation" "$browserstack_gps_location"
addParam "language" "$browserstack_language"
addParam "locale" "$browserstack_locale"
addParam "callback" "$callback_url"
jsonParamString+='}'

json=$( jq -n \
                --argjson app_url $app_url \
                --argjson test_url $test_url \
                --argjson devices ["$browserstack_device_list"] \
                --argjson package ["$browserstack_package"] \
                --argjson class ["$browserstack_class"] \
                --argjson annotation ["$browserstack_annotation"] \
                --arg size "$browserstack_size" \
                --arg logs "$browserstack_device_logs" \
                --arg video "$browserstack_video" \
                --arg loc "$browserstack_local" \
                --arg locId "$browserstack_local_identifier" \
                --arg gpsLocation "$browserstack_gps_location" \
                --arg language "$browserstack_language" \
                --arg locale "$browserstack_locale" \
                --arg callback "$callback_url" \
                "$jsonParamString")
run_test_response="$(curl -X POST https://api-cloud.browserstack.com/app-automate/espresso/build -d \ "$json" -H "Content-Type: application/json" -u "$browserstack_username:$browserstack_access_key")"
build_id=$(echo "$run_test_response" | jq .build_id | envman add --key BROWSERSTACK_BUILD_ID)

echo "build id: $build_id"
