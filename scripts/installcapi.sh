export KUBECONFIG="$HOME/.kube/$1"

echo ""
echo "#########################"
echo "# $1/installcapi #"
echo "#########################"
echo ""

helm repo add capi-operator https://kubernetes-sigs.github.io/cluster-api-operator
helm repo update
# TODO: Maybe wait can be ommited, theoretically wait should not be necessary, because CRDs should be enough to install
# the providers
helm upgrade \
  cluster-api-operator capi-operator/cluster-api-operator \
  --install \
  --version=$CAPI_OPERATOR_VERSION \
   -n capi-operator-system \
   --create-namespace \
  --wait \
  --timeout=10m \
  --set cert-manager.enabled=true
helm upgrade \
   kubecraft-bootstrap charts/kubecraft-bootstrap \
  --install \
   -n capi-operator-system \
   --create-namespace \
  --set core.version=$PROVIDER_CORE_VERSION \
  --set infrastructure.hetzner.version=$PROVIDER_INFRASTRUCTURE_HETZNER_VERSION \
  --set addon.helm.version=$PROVIDER_ADDON_HELM_VERSIONÏ
helm repo remove capi-operator
echo "Waiting for Providers"
kubectl wait --timeout=10m --for=condition=ready -n capi-system coreprovider cluster-api
kubectl wait --timeout=10m --for=condition=ready -n capi-system infrastructureprovider hetzner
kubectl wait --timeout=10m --for=condition=ready -n capi-system addonprovider helm
kubectl wait --timeout=10m --for=condition=ready -n capi-system controlplaneprovider kubeadm
kubectl wait --timeout=10m --for=condition=ready -n capi-system bootstrapprovider kubeadm
