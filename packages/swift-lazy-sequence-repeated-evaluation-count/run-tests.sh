#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$(mktemp -d)"
trap 'rm -rf "$BUILD_DIR"' EXIT

echo "빌드 디렉토리: $BUILD_DIR"
echo "테스트 컴파일 중..."

swiftc -swift-version 6 -parse-as-library \
    "$SCRIPT_DIR/src/LazyEvaluationCounter.swift" \
    "$SCRIPT_DIR/tests/main.swift" \
    -o "$BUILD_DIR/test-runner"

echo "테스트 실행 중..."
echo ""

"$BUILD_DIR/test-runner"
