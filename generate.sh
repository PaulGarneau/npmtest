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
    # npm whoami
    # checkErr $? "Failed to whoami"

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

function setNpmConfigInfo()
{
    echo "set individual npm config info"
    echo "  allow-same-version value: "
    # attempted to allow the same name and version package to be published with the following config setting:
    npm config set allow-same-version=true
    # However, according to official npm docs page: https://docs.npmjs.com/cli/v11/commands/npm-publish
        # The publish will fail if the package name and version combination already exists in the specified registry.
}

function outputNpmConfigInfo()
{
    echo "show all npm config info"
    npm config list -l
    echo "show individual npm config info"
    echo "  globalconfig value: "$(npm config get globalconfig)
    echo "  userconfig value: "$(npm config get userconfig)
    echo "  registry value: "$(npm config get registry)
    echo "  node-version value: "$(npm config get node-version)
    echo "  package-lock value: "$(npm config get package-lock)
    echo "  dry-run value: "$(npm config get dry-run)
    echo "  auth-type value: "$(npm config get auth-type)
    echo "  always-auth value: "$(npm config get always-auth)
    echo "  allow-same-version value: "$(npm config get allow-same-version)
}

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

CUSTOM_CFG_PATH=
if [ "TEST${2}" != "TEST" ]; then
    echo "custom cfg path provided"
    # copy config to npm project dir
    pwd
    # if the following copy of the npmrc file is skipped...
        # npm whoami returns the following:
            # npm ERR! code ENEEDAUTH
            # npm ERR! need auth This command requires you to be logged in.
            # npm ERR! need auth You need to authorize this machine using `npm adduser`
        # the solution is NOT to attempt the command "npm adduser"...
        # but instead to copy the .npmrc file to the npm project directory!!!
        # npm publish returns the following:
            # npm ERR! code E404
            # npm ERR! 404 Not Found - PUT https://registry.npmjs.org/@ptg%2fnpmtest - Not found
            # npm ERR! 404 
            # npm ERR! 404  '@ptg/npmtest@4.0.2-202501091046.52-ptg' is not in the npm registry.
        # interpreting the return reveals that the levelsbeyond registry is not defined (since the npmrc is not in place)...
        # and the publish attempted to publish the package to the public npm registry, which failed (thankfully)
    # when the .npmrc file is in the npm project directory, everything works as desired.
    # therefore, copy the .npmrc file to the npm project directory
    cp "${2}" .
    ls -la .
fi

setNpmConfigInfo
outputNpmConfigInfo
buildTsSdk
exit 0