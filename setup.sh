#!/bin/bash
# Setup script for C++ Unit Test Generator on Arch Linux

set -e

echo "🚀 Setting up C++ Unit Test Generator environment..."
echo "📍 Detected OS: Arch Linux"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   log_error "This script should not be run as root"
   exit 1
fi

# Update system
log_info "Updating system packages..."
sudo pacman -Syu --noconfirm

# Install required packages
log_info "Installing required packages..."
sudo pacman -S --noconfirm \
    base-devel \
    cmake \
    ninja \
    git \
    curl \
    wget \
    docker \
    docker-compose \
    python \
    python-pip \
    python-virtualenv \
    postgresql \
    postgresql-libs \
    lcov \
    gcovr \
    jsoncpp \
    uuid \
    zlib \
    openssl \
    sqlite

# Install AUR helper (yay) if not present
if ! command -v yay &> /dev/null; then
    log_info "Installing yay (AUR helper)..."
    cd /tmp
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd - > /dev/null
fi

# Install Drogon from AUR
log_info "Installing Drogon framework from AUR..."
yay -S --noconfirm drogon

# Setup Docker
log_info "Setting up Docker..."
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker $USER

# Install Python dependencies
log_info "Installing Python dependencies..."
pip install --user requests pyyaml

# Verify Ollama installation
log_info "Checking Ollama installation..."
if ! command -v ollama &> /dev/null; then
    log_error "Ollama not found! Please install it first:"
    log_error "curl -fsSL https://ollama.com/install.sh | sh"
    exit 1
fi

# Check if LLaMA model is available
log_info "Checking LLaMA 3.1 model availability..."
if ! ollama list | grep -q "llama3.1"; then
    log_warn "LLaMA 3.1 model not found. Downloading..."
    ollama pull llama3.1:latest
fi

# Start Ollama service
log_info "Starting Ollama service..."
systemctl --user enable ollama
systemctl --user start ollama

# Test Ollama connection
log_info "Testing Ollama connection..."
if ! curl -s http://localhost:11434/api/tags >/dev/null; then
    log_error "Ollama is not responding. Please check the installation."
    exit 1
fi

# Setup PostgreSQL container
log_info "Setting up PostgreSQL database..."
docker-compose up -d postgres

# Wait for PostgreSQL to be ready
log_info "Waiting for PostgreSQL to be ready..."
sleep 10

# Test database connection
log_info "Testing database connection..."
if ! docker exec orgchart_postgres pg_isready -U orgchart_user -d orgchart >/dev/null 2>&1; then
    log_warn "Database not ready yet, waiting..."
    sleep 10
fi

# Create tests directory structure
log_info "Creating test directory structure..."
mkdir -p tests/db
mkdir -p scripts

# Make scripts executable
chmod +x scripts/*.sh 2>/dev/null || true

# Create .env file for database connection
log_info "Creating environment configuration..."
cat > .env << EOF
# Database Configuration
DB_HOST=localhost
DB_PORT=5433
DB_NAME=orgchart
DB_USER=orgchart_user
DB_PASSWORD=orgchart_pass

# Ollama Configuration
OLLAMA_URL=http://localhost:11434
OLLAMA_MODEL=llama3.1
EOF

log_info "✅ Setup complete!"
echo
echo "🎉 Environment is ready!"
echo "📋 Next steps:"
echo "   1. Clone the orgChartApi repository"
echo "   2. Copy this cpp-unit-test-generator folder into the repo"
echo "   3. Run: python test_generator.py controllers --test-dir tests"
echo "   4. Run: python test_generator.py models --test-dir tests"
echo "   5. Run: python test_generator.py plugins --test-dir tests"
echo
echo "🔧 Services running:"
echo "   - Ollama: http://localhost:11434"
echo "   - PostgreSQL: localhost:5433"
echo "   - pgAdmin: http://localhost:5050 (admin@orgchart.com / admin123)"
echo
echo "⚠️  Note: You may need to logout and login again for Docker group changes to take effect"
