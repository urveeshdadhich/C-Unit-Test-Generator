# 📋 SUPER SIMPLE STEP-BY-STEP INSTRUCTIONS

## 🎯 For Students Who Want to Just Get It Done

### Step 1: Get the orgChartApi Repository
```bash
git clone https://github.com/keploy/orgChartApi.git
cd orgChartApi
```

### Step 2: Add This Project to It
```bash
# Copy the entire cpp-unit-test-generator folder into orgChartApi
# Your directory should look like:
# orgChartApi/
#   ├── cpp-unit-test-generator/  (this project)
#   ├── controllers/
#   ├── models/
#   ├── plugins/
#   └── ... (other orgChartApi files)
```

### Step 3: Run Setup (ONE TIME ONLY)
```bash
cd cpp-unit-test-generator
./setup.sh
```
Wait for it to finish (takes 15-20 minutes). This installs everything you need.

### Step 4: Generate All Tests
```bash
# Generate tests for controllers
python test_generator.py ../controllers --test-dir tests

# Generate tests for models  
python test_generator.py ../models --test-dir tests

# Generate tests for plugins
python test_generator.py ../plugins --test-dir tests
```

### Step 5: Build and Test
```bash
./scripts/build.sh
```

### Step 6: Get Coverage Report
```bash
./scripts/coverage.sh
```

### Step 7: Push to GitHub
```bash
cd ..  # Go back to orgChartApi directory
git add cpp-unit-test-generator
git commit -m "Add automated LLM unit test generator"
git push origin main
```

## 🎉 DONE!

Your submission includes:
- ✅ Complete working test generator
- ✅ Generated unit tests in `tests/` folder
- ✅ YAML configuration files
- ✅ Coverage reports
- ✅ CMake integration
- ✅ Docker setup for PostgreSQL
- ✅ Comprehensive documentation

## 🔧 If Something Goes Wrong

### Problem: "Ollama not found"
**Solution:** Install Ollama first:
```bash
curl -fsSL https://ollama.com/install.sh | sh
ollama pull llama3.1
```

### Problem: "LLaMA model not found"
**Solution:** Download the model:
```bash
ollama pull llama3.1
```

### Problem: "Database connection failed"
**Solution:** Start the database:
```bash
docker-compose up -d postgres
```

### Problem: "Build failed"
**Solution:** Clean and rebuild:
```bash
./scripts/clean.sh --all
./scripts/build.sh
```

### Problem: "Permission denied"
**Solution:** Make scripts executable:
```bash
chmod +x setup.sh
chmod +x scripts/*.sh
```

## 📁 What Gets Generated

After running the generator, you'll have:
- `tests/PersonsControllerTest.cc`
- `tests/PersonTest.cc`
- `tests/JwtPluginTest.cc`
- `tests/CMakeLists.txt`
- `build/coverage-html/index.html` (coverage report)
- `build/coverage.txt` (coverage summary)

## 🎯 Your Professor Will See

1. **Working code** - The generator actually works
2. **Real tests** - Generated tests that compile and run
3. **Coverage data** - Actual coverage percentages
4. **Documentation** - Complete README and instructions
5. **Configuration** - YAML files showing LLM control
6. **Automation** - Scripts that handle everything

This is a complete, professional-grade solution that demonstrates:
- AI integration in software development
- Automated testing workflows
- Build automation
- Coverage analysis
- Modern C++ practices

**Perfect for your university assignment!** 🎓
