#!/bin/bash

ISTIO_VERSION=1.0.5

oc login -u system:admin

oc delete project istio-system

# shut down previous labs if needed
oc get -n coolstore-dev dc/coolstore >& /dev/null && oc scale --replicas=0 dc/coolstore dc/coolstore-postgresql -n coolstore-dev ; \
oc get -n coolstore-prod dc/coolstore-prod >& /dev/null && oc scale --replicas=0 dc/coolstore-prod dc/coolstore-postgresql dc/jenkins -n coolstore-prod ; \
oc get -n inventory dc/inventory >& /dev/null && oc scale --replicas=0 dc/inventory dc/inventory-database -n inventory ; \
oc get -n catalog dc/catalog >& /dev/null && oc scale --replicas=0 dc/catalog dc/catalog-database -n catalog ; \
oc get -n cart dc/cart >& /dev/null && oc scale --replicas=0 dc/cart -n cart

curl -L https://github.com/istio/istio/releases/download/${ISTIO_VERSION}/istio-${ISTIO_VERSION}-linux.tar.gz | tar xz

cd istio-${ISTIO_VERSION}
export ISTIO_HOME=`pwd`
export PATH=$ISTIO_HOME/bin:$PATH

oc new-project istio-system

oc adm policy add-scc-to-user anyuid -z istio-egressgateway-service-account -n istio-system
oc adm policy add-scc-to-user anyuid -z istio-galley-service-account -n istio-system
oc adm policy add-scc-to-user anyuid -z istio-citadel-service-account -n istio-system
oc adm policy add-scc-to-user anyuid -z istio-ingressgateway-service-account -n istio-system
oc adm policy add-scc-to-user anyuid -z istio-cleanup-old-ca-service-account -n istio-system
oc adm policy add-scc-to-user anyuid -z istio-mixer-post-install-account -n istio-system
oc adm policy add-scc-to-user anyuid -z istio-mixer-service-account -n istio-system
oc adm policy add-scc-to-user anyuid -z istio-pilot-service-account -n istio-system
oc adm policy add-scc-to-user anyuid -z istio-sidecar-injector-service-account -n istio-system

oc apply -f install/kubernetes/helm/istio/templates/crds.yaml

curl https://raw.githubusercontent.com/danieloh30/cloud-native-workshop-v2-labs-solutions/master/istio-demo.yaml -o istio-demo.yaml

oc apply -f istio-demo.yaml

oc expose svc istio-ingressgateway
oc expose svc grafana
oc expose svc servicegraph
oc expose svc prometheus
oc expose svc tracing
oc expose svc jaeger-query

export JAEGER_URL="http://jaeger-query-istio-system.apps.seoul-7b68.openshiftworkshop.com "; \
export GRAFANA_URL="http://grafana-istio-system.apps.seoul-7b68.openshiftworkshop.com"; \
export VERSION_LABEL="v0.9.0"

curl https://raw.githubusercontent.com/kiali/kiali/${VERSION_LABEL}/deploy/openshift/kiali-configmap.yaml | \
  VERSION_LABEL=${VERSION_LABEL} \
  JAEGER_URL=${JAEGER_URL}  \
  GRAFANA_URL=${GRAFANA_URL} envsubst | oc create -n istio-system -f -

curl https://raw.githubusercontent.com/kiali/kiali/${VERSION_LABEL}/deploy/openshift/kiali-secrets.yaml | \
VERSION_LABEL=${VERSION_LABEL} envsubst | oc create -n istio-system -f -

curl https://raw.githubusercontent.com/kiali/kiali/${VERSION_LABEL}/deploy/openshift/kiali.yaml | \
  VERSION_LABEL=${VERSION_LABEL}  \
  IMAGE_NAME=kiali/kiali \
  IMAGE_VERSION=${VERSION_LABEL}  \
  NAMESPACE=istio-system  \
  VERBOSE_MODE=4  \
  IMAGE_PULL_POLICY_TOKEN="imagePullPolicy: Always" envsubst | oc create -n istio-system -f -

oc adm policy add-cluster-role-to-user admin system:serviceaccount:istio-system:kiali-service-account -z default

(oc get route kiali -n istio-system -o json|sed 's/80/443/')|oc apply -n istio-system -f -

oc new-project istio-sample-user1

oc adm policy add-scc-to-user privileged -z default -n istio-sample-user1

istioctl kube-inject -f samples/bookinfo/platform/kube/bookinfo.yaml | oc apply -f -