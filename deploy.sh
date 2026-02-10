#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

CONFIG_FILE=$1

# Basic check if config exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Config file $CONFIG_FILE not found!"
    exit 1
fi

FEATURE_NAME=$(yq '.name' "$CONFIG_FILE")
# IMAGE_TAG=$(yq '.name' "$CONFIG_FILE")
IMAGE_TAG="dev90011"
GAMESERVER_IMAGE=$(yq '.gameserver.image' "$CONFIG_FILE")
BASE_DOMAIN=$(yq '.domainname' "$CONFIG_FILE")

echo "--- 🚀 Deploying Feature: $FEATURE_NAME ---"

# 1. Namespace setup
echo "Checking Namespace..."
kubectl create ns "$FEATURE_NAME" --dry-run=client -o yaml | kubectl apply -f -

# 2. Inject Namespace into Lua script template
echo "Generating Lua modules..."
sed "s/{{NAMESPACE}}/$FEATURE_NAME/g" ./infra-base/nakama-modules/allocator.lua.template > ./infra-base/nakama-modules/allocator-$FEATURE_NAME.lua

# 3. Build & Push custom Nakama image
# In deploy.sh
echo "Building Nakama Image..."
docker build -t "surendar/nakama:$IMAGE_TAG" -f ./infra-base/nakama-modules/Dockerfile .
# Use '|| true' if you want to skip push if not logged in (e.g. local minikube only)
docker push "surendar/nakama:$IMAGE_TAG" || echo "Warning: Push failed, using local image."

if command -v minikube &> /dev/null; then
    echo "Loading image into Minikube..."
    minikube image load "surendar/nakama:$IMAGE_TAG"
fi

# 4. Deploy Infrastructure via Helm
# --wait: waits for pods to be Ready
# --timeout: prevents hanging forever if something is wrong
echo "Installing CockroachDB..."
helm upgrade --install cockroachdb ./infra-base/helm-templates/nucleus \
 -f ./infra-base/helm-overrides/cockroachdb/custom-values.yaml \
 -n "$FEATURE_NAME" --wait --timeout 5m

echo "Installing Nakama..."
echo "Using Nakama image: surendar/nakama:$IMAGE_TAG"
# Force every path where dev4 might be hiding
helm upgrade --install nakama ./infra-base/helm-templates/nucleus  \
  -n "$FEATURE_NAME" \
  -f ./infra-base/helm-overrides/nakama/custom-values.yaml \
  --set workload.enabled=true \
  --set workload.kind="Deployment" \
  --set image.repository="surendar/nakama" \
  --set image.tag="$IMAGE_TAG" \
  --set "initContainers[0].image=surendar/nakama:$IMAGE_TAG" \
  --set image.pullPolicy=IfNotPresent \
  --set ingress.host="$FEATURE_NAME.$BASE_DOMAIN" \
  --wait --timeout 5m

echo "Installing Prometheus..."
helm upgrade --install prometheus ./infra-base/helm-templates/nucleus \
 -f ./infra-base/helm-overrides/prometheus/custom-values.yaml \
 -n "$FEATURE_NAME" --wait --timeout 5m

# 5. Generate and Deploy Agones Fleet
echo "Deploying Agones Fleet..."
./generate-fleet.sh "$CONFIG_FILE" > fleet-tmp.yaml
kubectl apply -n default -f fleet-tmp.yaml

echo "--- ✅ Deployment of $FEATURE_NAME Successful ---"
echo "Access Nakama at: http://$FEATURE_NAME.$BASE_DOMAIN"

# --- 6. Port Forwarding ---
echo "--- 🔌 Opening Nakama Tunnels for $FEATURE_NAME ---"

# Kill any existing port-forwards on these ports to avoid 'address already in use' errors
lsof -ti:7350,7349,7351 | xargs kill -9 2>/dev/null || true

# Port forward Services in the background
# 7350: API (HTTP/WS)
# 7349: gRPC
# 7351: Console (Handy for browser check)
kubectl port-forward -n "$FEATURE_NAME" svc/nakama-nucleus 7350:7350 > /dev/null 2>&1 &
kubectl port-forward -n "$FEATURE_NAME" svc/nakama-nucleus 7349:7349 > /dev/null 2>&1 &
kubectl port-forward -n "$FEATURE_NAME" svc/nakama-nucleus 7351:7351 > /dev/null 2>&1 &

echo "✅ Tunnels established:"
echo "   - Nakama API: http://127.0.0.1:7350"
echo "   - Nakama gRPC: 127.0.0.1:7349"
echo "   - Nakama Console: http://127.0.0.1:7351"
echo ""
echo "Keep this terminal open to maintain the connection."
# Optional: Wait for the user to press Ctrl+C to stop the tunnels
wait