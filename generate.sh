#!/bin/bash

function fail()
{
    echo "${*}"
    exit 1
}

function checkErr()
{
    local exitCode=${1}
    local errMessage=${2}
    if [ ${exitCode} -ne 0 ] ; then
        fail "${errMessage}"
    fi
}

function rmDir()
{
    local theDir="${1}"
    # if the directory exists, remove the directory (trying to avoid error messages in scripts)
    [[ -d "${theDir}" ]] && rm -r "${theDir}"
}

function rmFile()
{
    local theFile="${1}"
    # if the file exists, remove the file (trying to avoid error messages in scripts)
    [[ -f "${theFile}" ]] && rm "${theFile}"
}

function setupNpmPackage()
{
    local npmCfgPath=""
    if [ "TEST${CUSTOM_CFG_PATH}" != "TEST" ]; then
        npmCfgPath="--userconfig \"${CUSTOM_CFG_PATH}\""
    fi

    echo "npm version ${VERSION}"
    npm version ${VERSION} --allow-same-version --no-git-tag-version
    checkErr $? "Failed to version"

    # echo "npm login: ${npmCfgPath}"
    # npm login ${npmCfgPath} --scope=@levelsbeyond --registry=https://levelsbeyond.jfrog.io/levelsbeyond/api/npm/npm-virtual
    # checkErr $? "Failed to login"

    echo "npm whoami"
    # npm whoami ${npmCfgPath}
    npm whoami
    checkErr $? "Failed to whoami"

    echo "npm install: ${npmCfgPath}"
    npm install --legacy-peer-deps ${npmCfgPath}
    checkErr $? "Failed to install library dependencies"
}

function buildNpmPackage()
{
    local npmCfgPath=""
    if [ "TEST${CUSTOM_CFG_PATH}" != "TEST" ]; then
        npmCfgPath="--userconfig \"${CUSTOM_CFG_PATH}\""
    fi
    # echo "npm run build: ${npmCfgPath}"
    # npm run ${npmCfgPath} build
    # checkErr $? "Failed to build"

    # echo "npm pack: ${npmCfgPath}"
    # npm pack ${npmCfgPath} 
    # checkErr $? "Failed to pack"

    echo "npm publish: ${npmCfgPath}"
    npm publish ${npmCfgPath} 
    checkErr $? "Failed to publish"
}

function buildTsSdk()
{
    echo "Generate sdk"
    rmDir "generated"
    setupNpmPackage
    buildNpmPackage
}

#CUSTOM_CFG_PATH="/tmp/.npmptg"
#CUSTOM_CFG_PATH="~/.npmrc"
# for npm publish, cannot (currently) publish a package with the same version (i.e., cannot overwrite an existing npm package version).
# therefore, append a generated date/time string to the version number to make it a unique version every time the script is run.
# allow pipeline to send flag to determine if version will have a generated unique string attached to version.
# this allows pass/fail to be tested by the same pipeline to exhibit what works/does not work.
echo "number of cmdline params: $#"
echo "first parameter: ${1-notprovided}"
if [ "${1}" == "true" ]; then
    echo "true"
    VERSION="4.0.2-"$(date "+%Y%m%d%H%M.%S")"-ptg"
else
    echo "false"
    VERSION="4.0.2-ptg"
fi

buildTsSdk
exit 0