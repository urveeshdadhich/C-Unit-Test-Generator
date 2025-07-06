#!/bin/bash
# Coverage report generation script

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
OUTPUT_DIR="coverage-html"
COVERAGE_FILE="coverage.info"
FILTERED_FILE="coverage.filtered.info"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --build-dir)
            BUILD_DIR="$2"
            shift 2
            ;;
        --output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  --build-dir DIR    Build directory (default: build)"
            echo "  --output-dir DIR   Output directory (default: coverage-html)"
            echo "  -h, --help         Show this help"
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Check if build directory exists
if [ ! -d "$BUILD_DIR" ]; then
    log_error "Build directory $BUILD_DIR does not exist"
    log_error "Please run build.sh first"
    exit 1
fi

cd "$BUILD_DIR"

# Check if coverage was enabled
if [ ! -f "CMakeCache.txt" ] || ! grep -q "ENABLE_COVERAGE:BOOL=ON" CMakeCache.txt; then
    log_warn "Coverage was not enabled during build"
    log_warn "Run: ./scripts/build.sh --enable-coverage"
    exit 1
fi

log_info "Generating coverage report..."

# Run tests to generate coverage data
log_info "Running tests to generate coverage data..."
ctest --output-on-failure

# Capture coverage data
log_info "Capturing coverage data..."
lcov --capture --directory . --output-file "$COVERAGE_FILE"

# Remove system files and external libraries
log_info "Filtering coverage data..."
lcov --remove "$COVERAGE_FILE" '/usr/*' '/opt/*' '*/tests/*' '*/build/*' --output-file "$FILTERED_FILE"

# Generate HTML report
log_info "Generating HTML report..."
genhtml "$FILTERED_FILE" --output-directory "$OUTPUT_DIR"

# Generate text summary
log_info "Generating text summary..."
lcov --summary "$FILTERED_FILE" > coverage.txt

# Display summary
log_info "Coverage Summary:"
cat coverage.txt

# Check coverage thresholds
LINE_COVERAGE=$(grep "lines" coverage.txt | grep -oE '[0-9]+\.[0-9]+%' | head -1)
FUNCTION_COVERAGE=$(grep "functions" coverage.txt | grep -oE '[0-9]+\.[0-9]+%' | head -1)
BRANCH_COVERAGE=$(grep "branches" coverage.txt | grep -oE '[0-9]+\.[0-9]+%' | head -1)

log_info "Coverage Results:"
log_info "  Lines: $LINE_COVERAGE"
log_info "  Functions: $FUNCTION_COVERAGE"
log_info "  Branches: $BRANCH_COVERAGE"

# Open HTML report in browser (optional)
if command -v xdg-open > /dev/null; then
    log_info "Opening HTML report in browser..."
    xdg-open "$OUTPUT_DIR/index.html" &
fi

log_info "Coverage report generated successfully!"
log_info "HTML report: $BUILD_DIR/$OUTPUT_DIR/index.html"
log_info "Text summary: $BUILD_DIR/coverage.txt"
