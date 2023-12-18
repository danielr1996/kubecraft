export KUBECONFIG=~/.kube/kubecraft-bootstrap
export CLUSTERNAME=kubecraft-bootstrap
export CAPI_OPERATOR_VERSION=v0.7.0
export KIND_VERSION=v1.29.0 #@sha256:eaa1450915475849a73a9227b8f201df25e55e268e5d619312131292e324d570
export CLUSTERAPI_GH_TOKEN=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

cat <<EOF | kind create cluster --kubeconfig $KUBECONFIG --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: "$CLUSTERNAME"
nodes:
  - role: control-plane
    image: kindest/node:$KIND_VERSION
  - role: worker
    image: kindest/node:$KIND_VERSION
EOF
helm repo add capi-operator https://kubernetes-sigs.github.io/cluster-api-operator
helm repo update
helm upgrade --install cluster-api-operator capi-operator/cluster-api-operator --version=$CAPI_OPERATOR_VERSION --set cert-manager.enabled=true
helm upgrade --install kubecraft-bootstrap charts/kubecraft-bootstrap -n capi-operator-system --create-namespace --wait --set clusterapi.ghtoken=$CLUSTERAPI_GH_TOKEN
helm repo remove capi-operator