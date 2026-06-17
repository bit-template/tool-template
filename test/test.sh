#!/bin/bash
set -euo pipefail

# --- Config ---
IMAGE_NAME="installer-sandbox"
CONTAINER_NAME="installer-test"
TIMEOUT="${EXECUTION_TIMEOUT:-1800}"   # default 30 minutes, override with EXECUTION_TIMEOUT

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

# --- Results tracking ---
RESULT_INSTALL="PASS"
RESULT_UNINSTALL="PASS"
LOG_INSTALL="$SCRIPT_DIR/install.log"
LOG_UNINSTALL="$SCRIPT_DIR/uninstall.log"

# --- Execute install.sh ---
echo "[INFO] Running src/install.sh inside container (timeout=$TIMEOUT seconds)..."
if ! docker exec "$CONTAINER_NAME" timeout "$TIMEOUT" bash /root/src/install.sh; then
  RESULT_INSTALL="FAIL"
  docker logs "$CONTAINER_NAME" > "$LOG_INSTALL"
  echo "[INFO] Logs saved to $LOG_INSTALL"
fi

# --- Verification step ---
echo "[INFO] Verifying installation..."
docker exec "$CONTAINER_NAME" bash -c 'command -v docker && echo "✅ docker installed" || echo "❌ docker missing"'

# --- Execute uninstall.sh ---
echo "[INFO] Running src/uninstall.sh inside container (timeout=$TIMEOUT seconds)..."
if ! docker exec "$CONTAINER_NAME" timeout "$TIMEOUT" bash /root/src/uninstall.sh; then
  RESULT_UNINSTALL="FAIL"
  docker logs "$CONTAINER_NAME" > "$LOG_UNINSTALL"
  echo "[INFO] Logs saved to $LOG_UNINSTALL"
fi

# --- Post-uninstall verification ---
echo "[INFO] Verifying uninstall..."
docker exec "$CONTAINER_NAME" bash -c 'command -v docker && echo "❌ docker still present" || echo "✅ docker removed"'

# --- Cleanup ---
echo "[INFO] Stopping and removing container..."
docker rm -f "$CONTAINER_NAME"
rm "$SCRIPT_DIR/Dockerfile.test"

# --- Summary Report ---
echo
echo "=== Summary Report ==="
printf "%-15s %-10s %-30s\n" "Step" "Result" "Log File"
printf "%-15s %-10s %-30s\n" "install.sh" "$RESULT_INSTALL" "$LOG_INSTALL"
printf "%-15s %-10s %-30s\n" "uninstall.sh" "$RESULT_UNINSTALL" "$LOG_UNINSTALL"
echo "======================"
echo "[DONE] Test completed in isolated Docker sandbox."
