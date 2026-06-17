#!/bin/bash
set -euo pipefail

# --- Config ---
IMAGE_NAME="installer-sandbox"
CONTAINER_NAME="installer-test"
TIMEOUT="${EXECUTION_TIMEOUT:-1800}"   # default 30 minutes, override with TIMEOUT=600 ./test.sh

# --- Paths ---
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"   # test/ folder
SRC_DIR="$SCRIPT_DIR/../src"

if [ ! -d "$SRC_DIR" ]; then
  echo "[FAIL] src/ directory not found at $SRC_DIR"
  exit 1
fi

echo "[INFO] Building sandbox image..."
docker build -t "$IMAGE_NAME" -f "$SCRIPT_DIR/Dockerfile.test" "$SCRIPT_DIR/.."

# --- Run container ---
echo "[INFO] Starting sandbox container..."
docker run --name "$CONTAINER_NAME" -d "$IMAGE_NAME" tail -f /dev/null

# --- Execute install.sh ---
echo "[INFO] Running src/install.sh inside container (timeout=$TIMEOUT seconds)..."
if ! docker exec "$CONTAINER_NAME" timeout "$TIMEOUT" bash /root/src/install.sh; then
  echo "[FAIL] install.sh exited with error or timeout"
  docker logs "$CONTAINER_NAME" > "$SCRIPT_DIR/install.log"
  echo "[INFO] Logs saved to $SCRIPT_DIR/install.log"
  docker rm -f "$CONTAINER_NAME"
  exit 1
fi

# --- Verification step ---
echo "[INFO] Verifying installation..."
docker exec "$CONTAINER_NAME" bash -c 'command -v docker && echo "✅ docker installed" || echo "❌ docker missing"'

# --- Execute uninstall.sh ---
echo "[INFO] Running src/uninstall.sh inside container (timeout=$TIMEOUT seconds)..."
if ! docker exec "$CONTAINER_NAME" timeout "$TIMEOUT" bash /root/src/uninstall.sh; then
  echo "[FAIL] uninstall.sh exited with error or timeout"
  docker logs "$CONTAINER_NAME" > "$SCRIPT_DIR/uninstall.log"
  echo "[INFO] Logs saved to $SCRIPT_DIR/uninstall.log"
  docker rm -f "$CONTAINER_NAME"
  exit 1
fi

# --- Post-uninstall verification ---
echo "[INFO] Verifying uninstall..."
docker exec "$CONTAINER_NAME" bash -c 'command -v docker && echo "❌ docker still present" || echo "✅ docker removed"'

# --- Cleanup ---
echo "[INFO] Stopping and removing container..."
docker rm -f "$CONTAINER_NAME"
rm "$SCRIPT_DIR/Dockerfile.test"

echo "[DONE] Test completed in isolated Docker sandbox."
