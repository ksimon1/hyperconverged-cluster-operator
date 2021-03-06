#!/bin/bash -e
#
# This file is part of the KubeVirt project
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
#
# Copyright 2019 Red Hat, Inc.
#
# Usage:
# export KUBEVIRT_PROVIDER=okd-4.1
# make cluster-up
# make upgrade-test
#
# Deploys the HCO cluster using the latest version in the git repo.
# This latest version deploys the hco-operator using the :latest tag 
# on quay.io.
#
# A new version, named 100.0.0, is then created. A new hco-operator
# image is created based off of the code in the current checkout.  
# A CSV and registry image is created for this version. The CSV
# uses the new hco-operator image in the hco deployment.
#
# Both the hco-operator image and new registry image is pushed
# to the local registry.
#
# The hco-catalogsource pod is then patched to use the new registry
# image.
#
# The subscription is checked to verify that it progresses
# to the new version. 
# 
# The hyperconverged-cluster deployment's image is also checked
# to verify that it is updated to the new operator image from 
# the local registry.
source hack/common.sh

if [ -n "${KUBEVIRT_PROVIDER}" ]; then
  # okd-* provider, STDCI
  REGISTRY_IMAGE="registry:5000/kubevirt/hco-registry"
  REGISTRY_IMAGE_UPGRADE="registry:5000/kubevirt/hco-registry-upgrade"
  REGISTRY_IMAGE_URL_PREFIX="registry:5000/kubevirt"
  CMD="./cluster-up/kubectl.sh"
  HCO_CATALOG_NAMESPACE="openshift-operator-lifecycle-manager"
  echo "Running on STDCI ${KUBEVIRT_PROVIDER}"
else
  # Prow OpenShift CI
  # IMAGE_FORMAT=registry.svc.ci.openshift.org/ci-op-b1qw1nxw/stable:hyperconverged-cluster-operator
  HCO_OPERATOR_IMAGE=`eval echo ${IMAGE_FORMAT}`
  CI_IMAGE_URL_PREFIX=$(echo $HCO_OPERATOR_IMAGE | cut -d ":" -f 1)
  echo "CI_IMAGE_URL_PREFIX: $CI_IMAGE_URL_PREFIX"
  REGISTRY_IMAGE="${CI_IMAGE_URL_PREFIX}:hco-registry"
  REGISTRY_IMAGE_UPGRADE="${CI_IMAGE_URL_PREFIX}:hco-registry-upgrade"
  REGISTRY_IMAGE_URL_PREFIX=$CI_IMAGE_URL_PREFIX
  HCO_CATALOG_NAMESPACE="openshift-marketplace"
  CMD="oc"
  echo "Running on OpenShift CI"
fi

function cleanup() {
    rv=$?
    if [ "x$rv" != "x0" ]; then
        echo "Error during upgrade: exit status: $rv"
        make dump-state
        echo "*** Upgrade test failed ***"
    fi
    exit $rv
}

trap "cleanup" INT TERM EXIT

echo "--"
echo "-- Upgrade Step 1/6: clean cluster"
echo "--"

make cluster-clean
"${CMD}" delete -f ./deploy/hco.cr.yaml -n kubevirt-hyperconverged | true
"${CMD}" delete subscription hco-subscription-example -n kubevirt-hyperconverged | true
"${CMD}" delete catalogsource hco-catalogsource-example -n ${HCO_CATALOG_NAMESPACE} | true
"${CMD}" delete operatorgroup hco-operatorgroup -n kubevirt-hyperconverged | true



${CMD} wait deployment packageserver --for condition=Available -n openshift-operator-lifecycle-manager --timeout="1200s"
${CMD} wait deployment catalog-operator --for condition=Available -n openshift-operator-lifecycle-manager --timeout="1200s"

if [ -n "${KUBEVIRT_PROVIDER}" ]; then
  echo "--"
  echo "-- Upgrade Step 2/6: build images for STDCI"
  echo "--"
  ./hack/upgrade-test-build-images.sh
else
  echo "--"
  echo "-- Upgrade Step 2/6: Openshift CI detected."
  echo "-- Image build skipped. Images are built through Prow."
  echo "--"
fi

echo "--"
echo "-- Upgrade Step 3/6: create catalogsource and subscription to install HCO"
echo "--"

${CMD} create ns kubevirt-hyperconverged | true
${CMD} get pods -n kubevirt-hyperconverged 

cat <<EOF | ${CMD} create -f -
apiVersion: operators.coreos.com/v1alpha2
kind: OperatorGroup
metadata:
  name: hco-operatorgroup
  namespace: kubevirt-hyperconverged
EOF

# TODO: The catalog source image here should point to the latest version in quay.io
# once that is published.
cat <<EOF | ${CMD} create -f -
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: hco-catalogsource-example
  namespace: ${HCO_CATALOG_NAMESPACE}
spec:
  sourceType: grpc
  image: ${REGISTRY_IMAGE}
  displayName: KubeVirt HyperConverged
  publisher: Red Hat
EOF

sleep 15

HCO_CATALOGSOURCE_POD=`${CMD} get pods -n ${HCO_CATALOG_NAMESPACE} | grep hco-catalogsource | head -1 | awk '{ print $1 }'`
${CMD} wait pod $HCO_CATALOGSOURCE_POD --for condition=Ready -n ${HCO_CATALOG_NAMESPACE} --timeout="120s"

CATALOG_OPERATOR_POD=`${CMD} get pods -n openshift-operator-lifecycle-manager | grep catalog-operator | head -1 | awk '{ print $1 }'`
${CMD} wait pod $CATALOG_OPERATOR_POD --for condition=Ready -n openshift-operator-lifecycle-manager --timeout="120s"

PACKAGESERVER_POD=`${CMD} get pods -n openshift-operator-lifecycle-manager | grep packageserver | head -1 | awk '{ print $1 }'`
${CMD} wait pod $PACKAGESERVER_POD --for condition=Ready -n openshift-operator-lifecycle-manager --timeout="120s"

# Creating a subscription immediately after the catalog
# source is ready can cause delays. Sometimes the catalog-operator
# isn't ready to create the install plan. As a temporary workaround
# we wait for 15 seconds here. 
sleep 15

LATEST_VERSION=$(ls -d ./deploy/olm-catalog/kubevirt-hyperconverged/*/ | sort -r | head -1 | cut -d '/' -f 5);

cat <<EOF | ${CMD} create -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: hco-subscription-example
  namespace: kubevirt-hyperconverged
spec:
  channel: ${LATEST_VERSION}
  name: kubevirt-hyperconverged
  source: hco-catalogsource-example
  sourceNamespace: ${HCO_CATALOG_NAMESPACE}
EOF

# Allow time for the install plan to be created a for the
# hco-operator to be created. Otherwise kubectl wait will report EOF.
./hack/retry.sh 20 30 "${CMD} get subscription -n kubevirt-hyperconverged | grep -v EOF"
./hack/retry.sh 20 30 "${CMD} get pods -n kubevirt-hyperconverged | grep hco-operator"

HCO_OPERATOR_POD=`${CMD} get pods -n kubevirt-hyperconverged | grep hco-operator | head -1 | awk '{ print $1 }'`
${CMD} wait pod $HCO_OPERATOR_POD --for condition=Ready -n kubevirt-hyperconverged --timeout="600s"

HCO_NAMESPACE="kubevirt-hyperconverged"
HCO_KIND="hyperconvergeds"
HCO_RESOURCE_NAME="hyperconverged-cluster"

${CMD} create -f ./deploy/hco.cr.yaml -n kubevirt-hyperconverged

HCO_OPERATOR_POD=`${CMD} get pods -n kubevirt-hyperconverged | grep hco-operator | head -1 | awk '{ print $1 }'`
${CMD} wait pod $HCO_OPERATOR_POD --for condition=Ready -n kubevirt-hyperconverged --timeout="600s"

${CMD} get subscription -n kubevirt-hyperconverged -o yaml
${CMD} get pods -n kubevirt-hyperconverged 

echo "----- Images before upgrade"
${CMD} get deployments -n kubevirt-hyperconverged -o yaml | grep image | grep -v imagePullPolicy
${CMD} get pod $HCO_CATALOGSOURCE_POD -n ${HCO_CATALOG_NAMESPACE} -o yaml | grep image | grep -v imagePullPolicy

echo "--"
echo "-- Upgrade Step 4/6: patch existing catalog source with new registry image"
echo "-- and wait for hco-catalogsource pod to be in Ready state"
echo "--"

# Patch the HCO catalogsource image to the upgrade version
${CMD} patch catalogsource hco-catalogsource-example -n ${HCO_CATALOG_NAMESPACE} -p "{\"spec\": {\"image\": \"${REGISTRY_IMAGE_UPGRADE}\"}}"  --type merge
sleep 5
./hack/retry.sh 20 30 "${CMD} get pods -n ${HCO_CATALOG_NAMESPACE} | grep hco-catalogsource | grep -v Terminating"
HCO_CATALOGSOURCE_POD=`${CMD} get pods -n ${HCO_CATALOG_NAMESPACE} | grep hco-catalogsource | grep -v Terminating | head -1 | awk '{ print $1 }'`
${CMD} wait pod $HCO_CATALOGSOURCE_POD --for condition=Ready -n ${HCO_CATALOG_NAMESPACE} --timeout="120s"

sleep 15
CATALOG_OPERATOR_POD=`${CMD} get pods -n openshift-operator-lifecycle-manager | grep catalog-operator | head -1 | awk '{ print $1 }'`
${CMD} wait pod $CATALOG_OPERATOR_POD --for condition=Ready -n openshift-operator-lifecycle-manager --timeout="120s"

# Verify the subscription has changed to the new version
#  currentCSV: kubevirt-hyperconverged-operator.v100.0.0
#  installedCSV: kubevirt-hyperconverged-operator.v100.0.0
echo "--"
echo "-- Upgrade Step 5/6: verify the subscription's currentCSV and installedCSV have moved to the new version"
echo "--"


sleep 10
HCO_OPERATOR_POD=`${CMD} get pods -n kubevirt-hyperconverged | grep hco-operator | head -1 | awk '{ print $1 }'`
${CMD} wait pod $HCO_OPERATOR_POD --for condition=Ready -n kubevirt-hyperconverged --timeout="600s"
./hack/retry.sh 30 60 "${CMD} get subscriptions -n kubevirt-hyperconverged -o yaml | grep currentCSV | grep v100.0.0"
./hack/retry.sh 2 30 "${CMD} get subscriptions -n kubevirt-hyperconverged -o yaml | grep installedCSV | grep v100.0.0"

echo "--"
echo "-- Upgrade Step 6/6: verify the hyperconverged-cluster deployment is using the new image"
echo "--"

./hack/retry.sh 6 30 "${CMD} get deployments -n kubevirt-hyperconverged -o yaml | grep image | grep hyperconverged-cluster | grep ${REGISTRY_IMAGE_URL_PREFIX}"

echo "----- Images after upgrade"
${CMD} get deployments -n kubevirt-hyperconverged -o yaml | grep image | grep -v imagePullPolicy
${CMD} get pod $HCO_CATALOGSOURCE_POD -n ${HCO_CATALOG_NAMESPACE} -o yaml | grep image | grep -v imagePullPolicy
