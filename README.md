# C++ Unit Test Generator with LLM Integration

🚀 **Automated C++ unit test generation for Drogon web applications using LLaMA 3.1**

This project provides a complete solution for generating, refining, and managing unit tests for C++ Drogon applications using Large Language Models (LLMs). It's specifically designed to work with the [orgChartApi](https://github.com/keploy/orgChartApi) project.

## 🎯 Features

- **LLM-Powered Test Generation**: Uses LLaMA 3.1 via Ollama to generate comprehensive unit tests
- **Intelligent Test Refinement**: Automatically improves test quality, removes duplicates, and adds edge cases
- **Build Error Resolution**: Automatically fixes common compilation issues
- **Coverage Analysis**: Integrated with lcov/gcov for detailed coverage reporting
- **Docker Integration**: Containerized PostgreSQL for testing database operations
- **CMake Integration**: Seamless integration with existing CMake projects

## 📋 Prerequisites

- **Arch Linux** (this setup is optimized for Arch)
- **Ollama** installed and running
- **LLaMA 3.1 model** downloaded via Ollama
- **Docker** and **Docker Compose**

## 🚀 Quick Start

### 1. Clone the orgChartApi Repository

```bash
git clone https://github.com/keploy/orgChartApi.git
cd orgChartApi
```

### 2. Copy This Project

```bash
# Copy the entire cpp-unit-test-generator folder into the orgChartApi directory
cp -r /path/to/cpp-unit-test-generator .
cd cpp-unit-test-generator
```

### 3. Run Setup Script

```bash
# Make setup script executable and run it
chmod +x setup.sh
./setup.sh
```

This will:
- Install all required dependencies (Drogon, GoogleTest, lcov, etc.)
- Start PostgreSQL container
- Verify Ollama and LLaMA 3.1 are working
- Create necessary directories and configuration files

### 4. Generate Tests

```bash
# Generate tests for controllers
python test_generator.py ../controllers --test-dir tests

# Generate tests for models
python test_generator.py ../models --test-dir tests

# Generate tests for plugins
python test_generator.py ../plugins --test-dir tests
```

### 5. Build and Run Tests

```bash
# Build with coverage enabled
./scripts/build.sh

# Generate coverage report
./scripts/coverage.sh
```

### 6. View Results

- **Test files**: `tests/*.cc`
- **Coverage report**: `build/coverage-html/index.html`
- **Coverage summary**: `build/coverage.txt`

## 📁 Project Structure

```
cpp-unit-test-generator/
├── test_generator.py           # Main automation script
├── generate_tests.yaml         # LLM test generation config
├── refine_tests.yaml          # Test refinement config
├── build_error_resolution.yaml # Build error fixing config
├── setup.sh                   # Environment setup script
├── docker-compose.yml         # PostgreSQL container config
├── requirements.txt           # Python dependencies
├── README.md                  # This file
├── .gitignore                 # Git ignore rules
├── tests/
│   ├── CMakeLists.txt        # Test build configuration
│   └── db/
│       └── seed.sql          # Test database schema and data
└── scripts/
    ├── build.sh              # Build automation
    ├── coverage.sh           # Coverage report generation
    └── clean.sh              # Cleanup script
```

## 🔧 Configuration

### LLM Settings

Edit the YAML configuration files to customize LLM behavior:

- **`generate_tests.yaml`**: Controls initial test generation
- **`refine_tests.yaml`**: Controls test refinement and quality improvements
- **`build_error_resolution.yaml`**: Controls build error fixing

### Database Configuration

The PostgreSQL container is configured in `docker-compose.yml`:
- **Host**: localhost
- **Port**: 5433
- **Database**: orgchart
- **User**: orgchart_user
- **Password**: orgchart_pass

### Build Configuration

Modify `tests/CMakeLists.txt` to adjust:
- GoogleTest version
- Compiler flags
- Coverage settings
- Library dependencies

## 🛠️ Advanced Usage

### Custom Test Generation

```bash
# Generate tests for specific files
python test_generator.py ../controllers/PersonsController.cc --test-dir tests

# Skip build step
python test_generator.py ../models --test-dir tests --skip-build

# Skip coverage analysis
python test_generator.py ../plugins --test-dir tests --skip-coverage
```

### Manual Build Commands

```bash
# Build in release mode
./scripts/build.sh --release

# Build without coverage
./scripts/build.sh --no-coverage

# Build with custom parallel jobs
./scripts/build.sh --jobs 8
```

### Coverage Analysis

```bash
# Generate coverage with custom output directory
./scripts/coverage.sh --output-dir my-coverage-report

# View coverage summary
cat build/coverage.txt
```

### Cleanup

```bash
# Clean build artifacts but keep tests
./scripts/clean.sh --keep-tests

# Clean everything
./scripts/clean.sh --all
```

## 📊 Example Generated Test

```cpp
#include <gtest/gtest.h>
#include <drogon/drogon.h>
#include "PersonsController.h"

class PersonsControllerTest : public ::testing::Test {
protected:
    void SetUp() override {
        // Initialize test database connection
        app().loadConfigFile("test_config.json");
    }

    void TearDown() override {
        // Clean up test data
    }

    api::v1::PersonsController controller_;
};

TEST_F(PersonsControllerTest, GetPerson_ValidId_Returns200) {
    // Arrange
    auto req = HttpRequest::newHttpRequest();
    req->setPath("/api/v1/persons/1");
    req->setMethod(Get);

    // Act
    auto resp = controller_.getPerson(req, 1);

    // Assert
    EXPECT_EQ(resp->statusCode(), k200OK);
    EXPECT_TRUE(resp->getJsonObject() != nullptr);
    EXPECT_EQ(resp->getJsonObject()->get("id", 0).asInt(), 1);
}

TEST_F(PersonsControllerTest, GetPerson_InvalidId_Returns404) {
    // Arrange
    auto req = HttpRequest::newHttpRequest();
    req->setPath("/api/v1/persons/999");
    req->setMethod(Get);

    // Act
    auto resp = controller_.getPerson(req, 999);

    // Assert
    EXPECT_EQ(resp->statusCode(), k404NotFound);
}
```

## 🎯 Test Coverage Goals

The generator aims for:
- **Line Coverage**: ≥80%
- **Function Coverage**: ≥85%
- **Branch Coverage**: ≥60%

## 🔍 Troubleshooting

### Ollama Issues

```bash
# Check if Ollama is running
curl http://localhost:11434/api/tags

# Restart Ollama
systemctl --user restart ollama

# Check LLaMA model
ollama list
```

### Database Issues

```bash
# Check PostgreSQL container
docker ps | grep postgres

# Restart database
docker-compose restart postgres

# Check database connection
docker exec -it orgchart_postgres psql -U orgchart_user -d orgchart
```

### Build Issues

```bash
# Clean and rebuild
./scripts/clean.sh --all
./scripts/build.sh

# Check CMake configuration
cmake -B build -S .. -DENABLE_COVERAGE=ON --debug-output
```

### Coverage Issues

```bash
# Ensure coverage was enabled during build
grep "ENABLE_COVERAGE:BOOL=ON" build/CMakeCache.txt

# Manually run coverage commands
cd build
ctest
lcov --capture --directory . --output-file coverage.info
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

## 📜 License

This project is licensed under the MIT License. See the LICENSE file for details.

## 🙏 Acknowledgments

- [Drogon Framework](https://github.com/drogonframework/drogon) for the excellent C++ web framework
- [Ollama](https://ollama.com/) for making LLM deployment simple
- [Meta](https://ai.meta.com/) for the LLaMA models
- [Google Test](https://github.com/google/googletest) for the testing framework

## 📞 Support

If you encounter any issues or have questions:

1. Check the troubleshooting section above
2. Review the log files in the build directory
3. Ensure all prerequisites are installed correctly
4. Verify that Ollama and LLaMA 3.1 are working properly

## 🎓 Academic Use

This project was created for educational purposes to demonstrate:
- LLM integration in software development workflows
- Automated test generation techniques
- CI/CD pipeline automation
- Modern C++ testing practices

Perfect for computer science students learning about:
- Software testing methodologies
- AI-assisted development
- Build automation
- Code coverage analysis

---

**Happy Testing!** 🧪✨
# C-Unit-Test-Generator
# C-Unit-Test-Generator
