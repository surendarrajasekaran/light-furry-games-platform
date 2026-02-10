#!/bin/bash
CONFIG=$1

# Extract values using yq
FEATURE_NAME=$(yq '.name' "$CONFIG")
REPLICAS=$(yq '.gameserver.replicas' "$CONFIG")
GS_IMAGE=$(yq '.gameserver.image' "$CONFIG")
# CPU=$(yq '.gameserver.cpu' "$CONFIG")
# MEMORY=$(yq '.gameserver.memory' "$CONFIG")

# Generate the YAML using a Here-Doc
cat <<EOF
apiVersion: agones.dev/v1
kind: Fleet
metadata:
  name: fleet-${FEATURE_NAME}
spec:
  replicas: ${REPLICAS}
  scheduling: Packed
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 25%
      maxUnavailable: 25%
  template:
    metadata:
      labels:
        feature: ${FEATURE_NAME}
        agones.dev/fleet: fleet-${FEATURE_NAME}
    spec:
      ports:
        - name: default
          portPolicy: Dynamic
          containerPort: 26000
      health:
        initialDelaySeconds: 30
        periodSeconds: 60
      sdkServer:
        logLevel: Info
      template:
        spec:
          containers:
            - name: game-server
              image: ${GS_IMAGE}
EOF