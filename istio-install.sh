#!/bin/bash

oc login -u system:admin

oc delete project istio-system

curl -L https://github.com/istio/istio/releases/download/1.1.1/istio-1.1.1-linux.tar.gz | tar xz

cd istio-1.1.1
export ISTIO_HOME=`pwd`
export PATH=$ISTIO_HOME/bin:$PATH

oc new-project istio-system

oc adm policy add-scc-to-user anyuid -z istio-egressgateway-service-account -n istio-system
c adm policy add-scc-to-user anyuid -z istio-galley-service-account -n istio-system
oc adm policy add-scc-to-user anyuid -z istio-citadel-service-account -n istio-system
oc adm policy add-scc-to-user anyuid -z istio-ingressgateway-service-account -n istio-system
oc adm policy add-scc-to-user anyuid -z istio-cleanup-old-ca-service-account -n istio-system
oc adm policy add-scc-to-user anyuid -z istio-mixer-post-install-account -n istio-system
oc adm policy add-scc-to-user anyuid -z istio-mixer-service-account -n istio-system
oc adm policy add-scc-to-user anyuid -z istio-pilot-service-account -n istio-system
oc adm policy add-scc-to-user anyuid -z istio-sidecar-injector-service-account -n istio-system

oc apply -f install/kubernetes/helm/istio-init/files/crd-11.yaml
oc apply -f install/kubernetes/istio-demo.yaml

oc expose svc istio-ingressgateway
oc expose svc grafana
oc expose svc prometheus
oc expose svc tracing
oc expose service kiali --path=/kiali
oc adm policy add-cluster-role-to-user admin system:serviceaccount:istio-system:kiali-service-account -z default
