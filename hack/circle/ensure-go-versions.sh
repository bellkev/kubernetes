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

set -exu

DLROOT=https://storage.googleapis.com/golang

for VERSION in $@; do
    GOROOT=$HOME/custom-go-versions/go$VERSION
    if [[ ! -d  $GOROOT ]]; then
	TEMP=/tmp/go$VERSION.tar.gz
	wget $DLROOT/go$VERSION.linux-amd64.tar.gz -O $TEMP
	mkdir -p $GOROOT
	tar -xzf $TEMP -C $GOROOT --strip-components=1
    fi
done
