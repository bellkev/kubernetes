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

set -u

PARALLEL_GO_TEST=${PARALLEL_GO_TEST:-n}

if [[ $PARALLEL_GO_TEST == "y" ]]; then
  KUBE_RACE="-race" \
  KUBE_COVER="y" \
  KUBE_TIMEOUT="-timeout 300s" \
  KUBE_COVERPROCS=2 \
  PATH=$GOPATH/bin:$PATH \
  ./hack/test-go.sh -- -p=2
else
  PATH="$GOPATH/bin:./third_party/etcd:$PATH" ./hack/test-cmd.sh
  cmd_result=$?
  echo "test-cmd exited with code ${cmd_result}"
  PATH="$GOPATH/bin:./third_party/etcd:$PATH" ./hack/test-integration.sh
  integration_result=$?
  echo "test-integration exited with code ${integration_result}"
  if [[ ${cmd_result} -ne 0 || ${integration_result} -ne 0 ]]; then exit 1; fi
fi
