#!/bin/bash
# Clean script for C++ Unit Test Generator

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Default values
BUILD_DIR="build"
KEEP_TESTS="false"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --build-dir)
            BUILD_DIR="$2"
            shift 2
            ;;
        --keep-tests)
            KEEP_TESTS="true"
            shift
            ;;
        --all)
            KEEP_TESTS="false"
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  --build-dir DIR    Build directory (default: build)"
            echo "  --keep-tests       Keep generated test files"
            echo "  --all              Clean everything including tests"
            echo "  -h, --help         Show this help"
            exit 0
            ;;
        *)
            log_warn "Unknown option: $1"
            shift
            ;;
    esac
done

log_info "Cleaning project..."

# Remove build directory
if [ -d "$BUILD_DIR" ]; then
    log_info "Removing build directory: $BUILD_DIR"
    rm -rf "$BUILD_DIR"
fi

# Remove coverage files
log_info "Removing coverage files..."
rm -f coverage.info coverage.filtered.info coverage.txt
rm -rf coverage-html

# Remove backup files
log_info "Removing backup files..."
find . -name "*.backup" -delete
find . -name "*.orig" -delete

# Remove log files
log_info "Removing log files..."
find . -name "*.log" -delete

# Remove CMake cache files
log_info "Removing CMake cache files..."
find . -name "CMakeCache.txt" -delete
find . -name "CMakeFiles" -type d -exec rm -rf {} + 2>/dev/null || true

# Remove generated test files (optional)
if [ "$KEEP_TESTS" = "false" ]; then
    log_info "Removing generated test files..."
    find tests -name "*Test.cc" -delete 2>/dev/null || true
    find tests -name "*_test.cc" -delete 2>/dev/null || true
fi

# Remove Python cache
log_info "Removing Python cache..."
find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
find . -name "*.pyc" -delete 2>/dev/null || true

# Remove editor temporary files
log_info "Removing editor temporary files..."
find . -name "*~" -delete 2>/dev/null || true
find . -name "*.swp" -delete 2>/dev/null || true
find . -name "*.swo" -delete 2>/dev/null || true

log_info "Clean completed successfully!"
