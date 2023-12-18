export CLUSTERNAME=$BOOTSTRAPCLUSTER
export KUBECONFIG="$HOME/.kube/$CLUSTERNAME"
# TODO dont install if name already exists
# TODO: randomly generate bootstrap cluster name
echo ""
echo "####################"
echo "# bootstrap/create #"
echo "####################"
echo ""
cat <<EOF | kind create cluster --kubeconfig "$KUBECONFIG" --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: "$CLUSTERNAME"
nodes:
  - role: control-plane
    image: kindest/node:$KIND_VERSION
  - role: worker
    image: kindest/node:$KIND_VERSION
EOF
