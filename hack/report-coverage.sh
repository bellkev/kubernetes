#!/bin/bash

# Copyright 2014 Google Inc. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -o errexit
set -o nounset


combineCoverage() {
  {
    # The combined coverage profile needs to start with a line indicating which
    # coverage mode was used (set, count, or atomic). This line is included in
    # each of the coverage profiles generated when running 'go test -cover', but
    # we strip these lines out when combining so that there's only one.
    echo "mode: ${KUBE_COVERMODE}"

    # Include all coverage reach data in the combined profile, but exclude the
    # 'mode' lines, as there should be only one.
    for x in `find "${COVER_REPORT_DIR}" -name "${COVER_PROFILE}"`; do
      cat $x | grep -h -v "^mode:" || true
    done
  } >"${COMBINED_COVER_PROFILE}"

  go tool cover -html="${COMBINED_COVER_PROFILE}" -o="${COMBINED_HTML_FILE}"
  kube::log::status "Combined coverage report: ${COMBINED_HTML_FILE}"
}

reportCoverageToCoveralls() {
  if [[ -x "${KUBE_GOVERALLS_BIN}" ]]; then
    # goveralls only looks at $TRAVIS_JOB_ID
    TRAVIS_JOB_ID=${CIRCLE_BUILD_NUM}
    ${KUBE_GOVERALLS_BIN} -coverprofile=${COMBINED_COVER_PROFILE} \
        -service=circleci -repotoken=${COVERALLS_REPO_TOKEN} || true
  fi
}


# Only combine and report coverage for the last api version run
# NOTE: Make sure that the same version has run to completion on all CI nodes

COVER_REPORT_DIR="$(cat $COVER_REPORT_DIR_LOC)"
COMBINED_COVER_PROFILE="${COVER_REPORT_DIR}/combined-coverage.out"
COMBINED_HTML_FILE=${CIRCLE_ARTIFACTS}/combined-coverage.html
KUBE_COVERMODE=${KUBE_COVERMODE:-atomic}
KUBE_ROOT=$(dirname "${BASH_SOURCE}")/..
source "${KUBE_ROOT}/hack/lib/init.sh"

if [[ $CIRCLE_NODE_INDEX==0 ]]; then
  for ((i=1; i<$GO_TEST_PARALLELISM; i++)); do
    rsync -avz --ignore-existing node$i:$COVER_REPORT_DIR/ $COVER_REPORT_DIR/
  done
  combineCoverage
  reportCoverageToCoveralls
fi
