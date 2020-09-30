# MIT License
#
# Copyright (c) 2020 Suchith J N
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# Script which uses `kind-up.sh` to bring up N Kubernetes clusters locally
# It assumes a lot of defaults that are fine in most of the cases.

set -x

if [[ -z ${NUM_CLUSTERS} ]]; then
    export NUM_CLUSTERS=2
fi

export KIND_CLUSTER_CONFIG="${KIND_CLUSTER_CONFIG:$GOPATH/src/istio.io/istio/prow/config/trustworthy-jwt.yaml}" 
export METALLB_SETUP_REQUIRED="${METALLB_SETUP_REQUIRED:1}"

CLUSTER_PREFIX="${CLUSTER_PREFIX:-istio}"

for i in $(seq 1 $NUM_CLUSTERS); do
    export KIND_CLUSTER_NAME="${CLUSTER_PREFIX}-${i}"

    if [[ "${METALLB_SETUP_REQUIRED}" == 1 ]]; then
      export METALLB_START_IP="172.18.25${i}.1"
      export METALLB_END_IP="172.18.25${i}.250"
    else
      echo "metallb setup is disabled"
    fi

    $GOPATH/src/istio.io/dev-scripts/kind-up.sh
done

kubectl config get-contexts -o name