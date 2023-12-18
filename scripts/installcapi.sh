export KUBECONFIG="$HOME/.kube/$1"

echo ""
echo "#########################"
echo "# $1/installcapi #"
echo "#########################"
echo ""

helm repo add capi-operator https://kubernetes-sigs.github.io/cluster-api-operator
helm repo update
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
  --set clusterapi.ghtoken=$CLUSTERAPI_GH_TOKEN \
  --set core.version=$PROVIDER_CORE_VERSION \
  --set infrastructure.hetzner.version=$PROVIDER_INFRASTRUCTURE_HETZNER_VERSION \
  --set addon.helm.version=$PROVIDER_ADDON_HELM_VERSION
helm repo remove capi-operator
echo "Waiting for Providers"
kubectl wait --timeout=10m --for=condition=ready coreprovider cluster-api -n capi-system
kubectl wait --timeout=10m --for=condition=ready infrastructureprovider hetzner -n caph-system
kubectl wait --timeout=10m --for=condition=ready addonprovider helm -n caaph-system
kubectl wait --timeout=10m --for=condition=ready controlplaneprovider kubeadm -n capi-kubeadm-control-plane-system
kubectl wait --timeout=10m --for=condition=ready bootstrapprovider kubeadm -n capi-kubeadm-bootstrap-system
