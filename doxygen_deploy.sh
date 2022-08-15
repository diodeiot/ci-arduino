#!/bin/bash

###################################################################
# Creates doxygen documentation and deploys to gh-pages brunch.
#
# Author: Diode IoT Inc. <info@diodeiot.com>
# Maintainer: Kadir Sevil <kadir.sevil@diodeiot.com>
#
# Copyright (c) 2021-2022 Diode Iot Inc. All rights reserved.
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
###################################################################

###################################################################
# This script will generate Doxygen documentation and push the documentation to
# the gh-pages branch of a repository.
# Before this script is used there should already be a gh-pages branch in the
# repository.
#
# Required global variables:
# - GITHUB_TOKEN: Secure token to the github repository.
#
# Optional global variables:
#  - DOC_LANG: Language of doxygen documentation. (Default: English)
#    en: English
#    tr: Turkish
#
#  - PRETTY_NAME: Name of documentation. (Default: "Diode IoT [Repository name after last '_' character]")
###################################################################

set -e

echo "Setting up the script..."

#set documentation name
D_NAME=${PRETTY_NAME:-"Diode IoT ${GITHUB_REPOSITORY##*[/_]}"}
echo "Documentation name: \"${D_NAME}\""

#set documentation language
if [ -z "${DOC_LANG}" ] || [ ${DOC_LANG} == 'en' ]; then
    D_LANG='English'
elif [ ${DOC_LANG} == 'tr' ]; then
    D_LANG='Turkish'
else
    echo "Wrong documentation language: \"${DOC_LANG}\"!" >&2
    exit 1
fi
echo "Documentation language: \"${D_LANG}\""

export CI_DOXYGEN_DIR=${GITHUB_WORKSPACE}/workspace/ci/doxygen
export CI_DOXYFILE=${CI_DOXYGEN_DIR}/Doxyfile

cd workspace
mkdir code_docs
cd code_docs

# The default version of doxygen is too old so we will use a modern version.
wget -q http://github.diodeiot.com/assets/doxygen-1.9.4.linux.bin.tar.gz
tar -xf doxygen-1.9.4.linux.bin.tar.gz
mv doxygen-1.9.4/bin/doxygen .
chmod +x doxygen

# Get the current gh-pages branch.
git clone -b gh-pages https://github.com/${GITHUB_REPOSITORY}.git
export REPO_NAME=${GITHUB_REPOSITORY#*/}
cd ${REPO_NAME}

# Configure git.
git config --global push.default simple
git config user.name "Doxygen CI"
git config user.email "ci-arduino@invalid"

# Remove everything currently in the gh-pages branch.
# GitHub is smart enough to know which files have changed and which files have
# stayed the same and will only update the changed files. So the gh-pages branch
# can be safely cleaned, and it is sure that everything pushed later is the new
# documentation.
# If there's no index.html (forwarding stub) grab our default one
shopt -s extglob
if [ ! -f index.html ]; then
    rm -rf *
else
    # Don't fail if there's no files in the directory, just keep going!
    rm -r -- !(index.html) || true
fi

# Need to create a .nojekyll file to allow filenames starting with an underscore
# to be seen on the gh-pages site. Therefore creating an empty .nojekyll file.
# Presumably this is only needed when the SHORT_NAMES option in Doxygen is set
# to NO, which it is by default. So creating the file just in case.
echo "" > .nojekyll

cp ${CI_DOXYGEN_DIR}/doxygen_index.html index.html
cp ${CI_DOXYGEN_DIR}/doxygen_404.html '404.html'
#cp ${CI_DOXYGEN_DIR}/logo.png logo.png

# Set required Doxyfile fields.
sed -i "s;^EXCLUDE_PATTERNS.*;EXCLUDE_PATTERNS = workspace;" ${CI_DOXYFILE}
sed -i "s;^PROJECT_NAME.*;PROJECT_NAME = \"${D_NAME}\";" ${CI_DOXYFILE}
sed -i "s;^OUTPUT_LANGUAGE.*;OUTPUT_LANGUAGE = ${D_LANG};" ${CI_DOXYFILE}
sed -i "s;^HTML_OUTPUT.*;HTML_OUTPUT = workspace/code_docs/${REPO_NAME}/html;" ${CI_DOXYFILE}
sed -i "s;^PROJECT_LOGO.*;PROJECT_LOGO = ${CI_DOXYGEN_DIR}/icon.png;" ${CI_DOXYFILE}
sed -i "s;^HTML_HEADER.*;HTML_HEADER = ${CI_DOXYGEN_DIR}/header.html;" ${CI_DOXYFILE}
sed -i "s;^HTML_EXTRA_STYLESHEET.*;HTML_EXTRA_STYLESHEET = ${CI_DOXYGEN_DIR}/doxygen-awesome.css;" ${CI_DOXYFILE}
sed -i "s;^HTML_EXTRA_FILES.*;HTML_EXTRA_FILES = ${CI_DOXYGEN_DIR}/doxygen-awesome-darkmode-toggle.js;" ${CI_DOXYFILE}

# Generate the Doxygen documentation
echo "Generating Doxygen code documentation..."
cd ${GITHUB_WORKSPACE}
${GITHUB_WORKSPACE}/workspace/code_docs/doxygen $CI_DOXYFILE

# If we're a pull request, don't push docs to github!
if [ "$GITHUB_EVENT_NAME" == "pull_request" ]; then
    echo "This is a pull request, documentation did not updated"
    exit 0
else
    echo "This is a commit, uploading documentation..."
fi

# Upload the documentation to the gh-pages branch of the repository.
cd workspace/code_docs/${REPO_NAME}
if [ "$GITHUB_REF_NAME" == 'master' ]; then
    echo "Uploading documentation to the gh-pages branch..."
    echo "Adding all files"
    
    git add --all
    if [ -n "$(git status --porcelain)" ]; then
      echo "Changes to commit"
    else
      echo "No changes to commit"
      exit 0
    fi
    
    echo "Git committing"
    git commit \
    -m "Deploy docs to GitHub Pages from commit ${GITHUB_SHA:0:10}" \
    -m "Commit: ${GITHUB_SHA}"$'\n'"GitHub Actions run: ${GITHUB_RUN_ID}"
    
    # Force push to the remote gh-pages branch.
    # The output is redirected to /dev/null to hide any sensitive credential data that might otherwise be exposed.
    echo "Git pushing"
    git remote set-url origin https://${GITHUB_ACTOR}:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY} &> /dev/null
    git push --force &> /dev/null
else
    echo "Not the main branch, not pushing documentation"
fi
echo "Completed successfully"
