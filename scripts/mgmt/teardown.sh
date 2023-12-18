export KUBECONFIG="$HOME/.kube/$MGMTCLUSTER"
kubectl delete cluster "$MGMTCLUSTER" -n "$MGMTCLUSTER"