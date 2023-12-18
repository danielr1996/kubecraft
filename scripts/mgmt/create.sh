echo ""
echo "###############"
echo "# mgmt/create #"
echo "###############"
echo ""
export CLUSTERNAME=$MGMTCLUSTER
export KUBECONFIG="$HOME/.kube/$BOOTSTRAPCLUSTER"
helm upgrade --install -n "$CLUSTERNAME" --create-namespace "$CLUSTERNAME" charts/kubecraft \
  --set clusterapi.infrastructure.hetzner.token="$HCLOUDTOKEN" \
  --set clusterapi.infrastructure.hetzner.region="$HCLOUDREGION" \
  --set clusterapi.bootstrap.kubeadm.containerdversion="$CONTAINERDVERSION" \
  --set clusterapi.bootstrap.kubeadm.kubernetesversion="$KUBERNETESVERSION" \
  --set clusterapi.controlplane.kubeadm.containerdversion="$CONTAINERDVERSION" \
  --set clusterapi.controlplane.kubeadm.kubernetesversion="$KUBERNETESVERSION" \
  --set clusterapi.controlplane.kubeadm.encryptionpassphrase="$ENCRYPTIONPASSPHRASE" \
  --set clusterapi.controlplane.kubeadm.replicas="1" \
  --set clusterapi.core.replicas="1" \
  --set clusterapi.core.version="$KUBERNETESVERSION"
echo "Waiting for ControlPlaneInitialized"
kubectl wait --for=condition=ControlPlaneInitialized cluster kubecraft-mgmt -n kubecraft-mgmt --timeout=10m
clusterctl get kubeconfig  -n "$CLUSTERNAME" "$CLUSTERNAME" > ~/.kube/"$CLUSTERNAME"
