#!/bin/bash

usage="Usage: $(basename "$0") [-r | --releaseTag]<GitHub Release Tag in simver format>"

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -r|--releaseTag) releaseTag="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; echo $usage; exit 1 ;;
    esac
    shift
done

if [[ -z "${releaseTag}" ]]; then
  echo "Not all requied parmiters passed!"; echo $usage; exit 1 ;
fi

version=$(echo $releaseTag | grep -Eo [0-9].[0-9].[0-9])
echo $version

if [[ -z "${version}" ]]; then
  echo "Tag string did not contain a proper version (x.y.z)"; exit 1 ;
fi

baseCodePath="https://raw.githubusercontent.com/thecloudtaylor/hubitat-honeywell/$releaseTag"
echo $baseCodePath

releaseJson=$(curl -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/thecloudtaylor/hubitat-honeywell/releases/tags/$releaseTag)
echo $releaseJson

releaseNote=$(jq .body <<<$releaseJson)
echo $releaseNote

if [[ -z "${releaseNote}" ]]; then
  echo "Release Notes Could Not Be Found - did the release have body text?"; exit 1 ;
fi

appPath="$baseCodePath/honeywellhomeapp.groovy"
thermDriverPath="$baseCodePath/honeywellhomedriver.groovy"
sensorDriverPath="$baseCodePath/honeywellremotesensordriver.groovy"

echo "Version: $version"
echo "AppPath: $appPath"
echo "ThermDriverPath: $thermDriverPath"
echo "SensorDriverPath: $sensorDriverPath"
echo "ReleaseNotes: $releaseNote"

./.github/workflows/tools/hpm manifest-modify-driver --id 390cc6e1-acbb-4af3-be52-7a68e4bcc580 --version=$version --location $thermDriverPath ../hubitat-packages/packages/honeywellManifest.json
./.github/workflows/tools/hpm manifest-modify-driver --id ebe84e87-e064-4029-9e5b-ad0cb7939230 --version=$version --location $sensorDriverPath ../hubitat-packages/packages/honeywellManifest.json
./.github/workflows/tools/hpm manifest-modify-app --id fe2bb542-854f-47b4-8d20-cde1ead99f2d --version=$version --location $appPath ../hubitat-packages/packages/honeywellManifest.json
./.github/workflows/tools/hpm manifest-modify --releasenotes="$relNotes" --version=$version ../hubitat-packages/packages/honeywellManifest.json

cat ../hubitat-packages/packages/honeywellManifest.json