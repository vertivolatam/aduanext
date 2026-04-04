#!/bin/bash
# Compile hacienda.proto → Dart gRPC stubs + TypeScript stubs
# Usage: ./scripts/compile-proto.sh

set -euo pipefail

PROTO_DIR="libs/proto"
PROTO_FILE="$PROTO_DIR/hacienda.proto"
DART_OUT="apps/server/lib/src/generated"
TS_OUT="apps/hacienda-sidecar/src/generated"

# Ensure output directories exist
mkdir -p "$DART_OUT" "$TS_OUT"

echo "Compiling $PROTO_FILE..."

# Dart gRPC stubs
export PATH="$PATH:$HOME/.pub-cache/bin"
protoc \
  --dart_out=grpc:"$DART_OUT" \
  --proto_path="$PROTO_DIR" \
  "$PROTO_FILE"
echo "  Dart stubs → $DART_OUT/ ($(ls "$DART_OUT"/*.dart | wc -l) files)"

# TypeScript stubs (ts-proto with grpc-js services)
TS_PROTO_PLUGIN="$(npm root -g)/ts-proto/protoc-gen-ts_proto"
if [ ! -f "$TS_PROTO_PLUGIN" ]; then
  echo "  Installing ts-proto globally..."
  npm install -g ts-proto
fi

protoc \
  --plugin=protoc-gen-ts_proto="$TS_PROTO_PLUGIN" \
  --ts_proto_out="$TS_OUT" \
  --ts_proto_opt=outputServices=grpc-js,esModuleInterop=true \
  --proto_path="$PROTO_DIR" \
  "$PROTO_FILE"
echo "  TypeScript stubs → $TS_OUT/ ($(ls "$TS_OUT"/*.ts | wc -l) files)"

echo "Done."
