#!/bin/bash

set -ex

# get_remote_revision GITURL BRANCH
get_remote_revision() {
    local URL="$1"
    local BRANCH="$2"
    local REVISION
    REVISION=$(git ls-remote --tags --heads "${URL}" "refs/${BRANCH}" | cut -f 1)
    if [[ -z "$REVISION" ]]; then
        >&2 echo "Unable to get remote revision for ${URL} refs/${BRANCH}"
        exit 255
    fi
    echo "$REVISION"
}

VERSION=$1
URL="https://github.com/val-lang/val"

if echo "${VERSION}" | grep 'trunk'; then
   VERSION=trunk-$(date +%Y%m%d)
   BRANCH=main
   REVISION=$(get_remote_revision "${URL}" "heads/${BRANCH}")
else
   BRANCH=v${VERSION}
   REVISION=$(get_remote_revision "${URL}" "tags/${BRANCH}")
fi

FULLNAME=val-${VERSION}
OUTPUT=$2/${FULLNAME}.tar.xz

if [[ $2 =~ ^s3:// ]]; then
    S3OUTPUT=$2
else
    if [[ -d "${2}" ]]; then
        OUTPUT=$2/${FULLNAME}
    else
        OUTPUT=${2-$OUTPUT}
    fi
fi

DIR="${BRANCH}/val"
git clone --depth 1 -b "${BRANCH}" "${URL}" "${DIR}"

LAST_REVISION="${3}"

echo "ce-build-revision:${REVISION}"
echo "ce-build-output:${OUTPUT}"

if [[ "${REVISION}" == "${LAST_REVISION}" ]]; then
   echo "ce-build-status:SKIPPED"
   exit
fi

pushd "${DIR}"

swift --version && swift package resolve
.build/checkouts/Swifty-LLVM/Tools/make-pkgconfig.sh /usr/local/lib/pkgconfig/llvm.pc
export PKG_CONFIG_PATH=$PWD
swift build -c release

popd

tar -zcvf "${OUTPUT}" "${DIR}/.build/release/valc"

echo "ce-build-status:OK"
