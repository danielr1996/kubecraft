#!/bin/bash
source .env.example
source .env



# TODO dont install if name already exists
# TODO: randomly generate bootstrap cluster name
echo ""
echo "####################"
echo "# bootstrap/create #"
echo "####################"
echo ""
export KUBECONFIG="$HOME/.kube/$BOOTSTRAPCLUSTER"
cat <<EOF | kind create cluster --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: "$BOOTSTRAPCLUSTER"
nodes:
  - role: control-plane
    image: kindest/node:$KIND_VERSION
  - role: worker
    image: kindest/node:$KIND_VERSION
EOF

echo ""
echo "##################"
echo "# bootstrap/init #"
echo "##################"
echo ""
export KUBECONFIG="$HOME/.kube/$BOOTSTRAPCLUSTER"
clusterctl init \
  --infrastructure hetzner:"$PROVIDER_INFRASTRUCTURE_HETZNER_VERSION" \
  --addon helm:"$PROVIDER_ADDON_HELM_VERSION" \
  --core cluster-api:"$PROVIDER_CORE_VERSION" \
  --bootstrap kubeadm:"$PROVIDER_CORE_VERSION" \
  --control-plane kubeadm:"$PROVIDER_CORE_VERSION" \

kubectl wait --timeout=10m --for=condition=available deployment -n caph-system caph-controller-manager
kubectl wait --timeout=10m --for=condition=available deployment -n caaph-system caaph-controller-manager
kubectl wait --timeout=10m --for=condition=available deployment -n capi-kubeadm-bootstrap-system capi-kubeadm-bootstrap-controller-manager
kubectl wait --timeout=10m --for=condition=available deployment -n capi-kubeadm-control-plane-system capi-kubeadm-control-plane-controller-manager
kubectl wait --timeout=10m --for=condition=available deployment -n capi-system capi-controller-manager

echo ""
echo "###############"
echo "# mgmt/create #"
echo "###############"
echo ""
export KUBECONFIG="$HOME/.kube/$BOOTSTRAPCLUSTER"
helm upgrade --install -n "$MGMTCLUSTER" --create-namespace "$MGMTCLUSTER" kubecraft \
  --set clusterapi.infrastructure.hetzner.token="$HCLOUDTOKEN" \
  --set clusterapi.infrastructure.hetzner.region="$HCLOUDREGION" \
  --set clusterapi.bootstrap.kubeadm.containerdversion="$CONTAINERDVERSION" \
  --set clusterapi.bootstrap.kubeadm.kubernetesversion="$KUBERNETESVERSION" \
  --set clusterapi.controlplane.kubeadm.containerdversion="$CONTAINERDVERSION" \
  --set clusterapi.controlplane.kubeadm.kubernetesversion="$KUBERNETESVERSION" \
  --set clusterapi.controlplane.kubeadm.encryptionpassphrase="$ENCRYPTIONPASSPHRASE" \
  --set clusterapi.core.version="$KUBERNETESVERSION" \
  --set clusterapi.addon.capiOperator.enabled="true" \
  --set clusterapi.addon.capiOperator.version="$CAPI_OPERATOR_VERSION" \
  --set clusterapi.addon.capiTenant.enabled="true" \
  --set clusterapi.addon.capiTenant.providers.core="$PROVIDER_CORE_VERSION" \
  --set clusterapi.addon.capiTenant.providers.infrastructure.hetzner="$PROVIDER_INFRASTRUCTURE_HETZNER_VERSION" \
  --set clusterapi.addon.capiTenant.providers.addon.helm="$PROVIDER_ADDON_HELM_VERSION"

echo "Waiting for ControlPlaneInitialized"
kubectl wait --for=condition=ControlPlaneInitialized cluster "$MGMTCLUSTER" -n "$MGMTCLUSTER" --timeout=10m
clusterctl get kubeconfig  -n "$MGMTCLUSTER" "$MGMTCLUSTER" > ~/.kube/"$MGMTCLUSTER"
echo "Controlplane is ready, kubeconfig has been saved to ~/.kube/$MGMTCLUSTER"

echo "Waiting for Capi Operator Helm Release to succeed"
kubectl wait --for=condition=HelmReleaseProxiesReady helmchartproxy capi-tenant -n "$MGMTCLUSTER" --timeout=10m

echo "Waiting for Cluster API Operator to be ready"
KUBECONFIG="$HOME/.kube/$MGMTCLUSTER" kubectl wait --timeout=10m --for=condition=available deployment -n capi-system capi-operator-cluster-api-operator

echo "Waiting for Providers to be ready"
KUBECONFIG="$HOME/.kube/$MGMTCLUSTER" kubectl wait --timeout=10m --for=condition=ready -n capi-system coreprovider cluster-api
KUBECONFIG="$HOME/.kube/$MGMTCLUSTER" kubectl wait --timeout=10m --for=condition=ready -n capi-system infrastructureprovider hetzner
KUBECONFIG="$HOME/.kube/$MGMTCLUSTER" kubectl wait --timeout=10m --for=condition=ready -n capi-system addonprovider helm
KUBECONFIG="$HOME/.kube/$MGMTCLUSTER" kubectl wait --timeout=10m --for=condition=ready -n capi-system controlplaneprovider kubeadm
KUBECONFIG="$HOME/.kube/$MGMTCLUSTER" kubectl wait --timeout=10m --for=condition=ready -n capi-system bootstrapprovider kubeadm

#echo ""
#echo "#############"
#echo "# mgmt/move #"
#echo "#############"
#echo ""
#export KUBECONFIG="$HOME/.kube/$BOOTSTRAPCLUSTER"
# TODO: use velero backup restore instead of clusterctl move to transfer cluster, because otherwise the moved manifests would conflict with previous backups
#clusterctl -n "$MGMTCLUSTER" move --to-kubeconfig="$HOME/.kube/$MGMTCLUSTER"
#
#echo ""
#echo "######################"
#echo "# bootstrap/teardown #"
#echo "######################"
#echo ""
#kind delete clusters $BOOTSTRAPCLUSTER


# TODO: install workload cluster

## TODO
#install velero and flux in management/workload/kubecraft cluster

#cat <<EOF > credentials
#[default]
#aws_access_key_id=$AWS_KEYID
#aws_secret_access_key=$AWS_KEYSECRET
#EOF
#
#KUBECONFIG=~/.kube/"$CLUSTER" velero install \
#    --provider aws \
#    --plugins velero/velero-plugin-for-aws:$VELEROAWSVERSION \
#    --bucket "$AWS_BUCKET" \
#    --secret-file credentials \
#    --use-volume-snapshots=false \
#    --backup-location-config region="$AWSREGION",s3Url="$AWSURL"
#rm credentials

#apiVersion: velero.io/v1
#kind: Schedule
#metadata:
#  name: {{ .Release.Name}}
#  namespace: velero
#spec:
#  schedule: '*/10 * * * *'
#  template:
#    includedNamespaces:
#      - {{ .Release.Namespace}}
#  useOwnerReferencesInBackup: false
