#!/bin/bash
# Build script for C++ Unit Test Generator

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Default values
BUILD_DIR="build"
BUILD_TYPE="Debug"
ENABLE_COVERAGE="ON"
ENABLE_TESTING="ON"
PARALLEL_JOBS=$(nproc)

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --build-dir)
            BUILD_DIR="$2"
            shift 2
            ;;
        --release)
            BUILD_TYPE="Release"
            shift
            ;;
        --no-coverage)
            ENABLE_COVERAGE="OFF"
            shift
            ;;
        --no-tests)
            ENABLE_TESTING="OFF"
            shift
            ;;
        --jobs)
            PARALLEL_JOBS="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  --build-dir DIR    Build directory (default: build)"
            echo "  --release          Build in release mode"
            echo "  --no-coverage      Disable coverage"
            echo "  --no-tests         Disable testing"
            echo "  --jobs N           Number of parallel jobs"
            echo "  -h, --help         Show this help"
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

log_info "Building project with:"
log_info "  Build directory: $BUILD_DIR"
log_info "  Build type: $BUILD_TYPE"
log_info "  Coverage: $ENABLE_COVERAGE"
log_info "  Testing: $ENABLE_TESTING"
log_info "  Parallel jobs: $PARALLEL_JOBS"

# Create build directory
mkdir -p "$BUILD_DIR"

# Configure with CMake
log_info "Configuring project with CMake..."
cmake -B "$BUILD_DIR" -S . \
    -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
    -DENABLE_COVERAGE="$ENABLE_COVERAGE" \
    -DBUILD_TESTING="$ENABLE_TESTING" \
    -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

# Build
log_info "Building project..."
cmake --build "$BUILD_DIR" --parallel "$PARALLEL_JOBS"

# Run tests if enabled
if [ "$ENABLE_TESTING" = "ON" ]; then
    log_info "Running tests..."
    cd "$BUILD_DIR"
    ctest --output-on-failure --parallel "$PARALLEL_JOBS"
    cd ..
fi

log_info "Build completed successfully!"
