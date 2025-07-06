#!/usr/bin/env python3
"""
LLM-Driven C++ Unit Test Generator for Drogon Applications
Generates Google Test unit tests using LLaMA 3 via Ollama
"""

import os
import sys
import json
import yaml
import subprocess
import requests
import re
import shutil
import argparse
from pathlib import Path
from typing import List, Dict, Optional, Tuple

class TestGenerator:
    def __init__(self, config_dir: str = "."):
        self.config_dir = Path(config_dir)
        self.ollama_url = "http://localhost:11434/api/generate"
        self.model = "llama3.1"
        self.load_configs()

    def load_configs(self):
        """Load YAML configuration files"""
        try:
            with open(self.config_dir / "generate_tests.yaml", 'r') as f:
                self.generate_config = yaml.safe_load(f)
            with open(self.config_dir / "refine_tests.yaml", 'r') as f:
                self.refine_config = yaml.safe_load(f)
            with open(self.config_dir / "build_error_resolution.yaml", 'r') as f:
                self.build_error_config = yaml.safe_load(f)
        except FileNotFoundError as e:
            print(f"Error: Config file not found: {e}")
            sys.exit(1)

    def call_llm(self, prompt: str, system_prompt: str = "", max_tokens: int = 4000) -> str:
        """Make API call to local Ollama instance"""
        full_prompt = f"{system_prompt}\n\n{prompt}" if system_prompt else prompt

        data = {
            "model": self.model,
            "prompt": full_prompt,
            "stream": False,
            "options": {
                "temperature": 0.3,
                "top_p": 0.9,
                "max_tokens": max_tokens
            }
        }

        try:
            response = requests.post(self.ollama_url, json=data, timeout=120)
            response.raise_for_status()
            return response.json()["response"]
        except requests.exceptions.RequestException as e:
            print(f"Error calling LLM: {e}")
            return ""

    def analyze_source_file(self, file_path: str) -> Dict:
        """Analyze C++ source file and extract metadata"""
        with open(file_path, 'r') as f:
            content = f.read()

        # Extract class names, function names, includes
        classes = re.findall(r'class\s+(\w+)\s*[:{]', content)
        functions = re.findall(r'\w+\s+(\w+)\s*\([^)]*\)\s*[{;]', content)
        includes = re.findall(r'#include\s*[<"](.*?)[>"]', content)

        file_type = "unknown"
        if "Controller" in file_path:
            file_type = "controller"
        elif "models" in file_path:
            file_type = "model"
        elif "plugins" in file_path:
            file_type = "plugin"

        return {
            "path": file_path,
            "content": content,
            "classes": classes,
            "functions": functions,
            "includes": includes,
            "type": file_type
        }

    def generate_tests(self, source_files: List[str], test_dir: str) -> List[str]:
        """Generate initial unit tests for source files"""
        generated_files = []

        for file_path in source_files:
            print(f"🔍 Analyzing {file_path}...")
            file_info = self.analyze_source_file(file_path)

            # Get generation rules for this file type
            rules = self.generate_config.get("rules", {}).get(file_info["type"], {})
            if not rules:
                print(f"⚠️  No rules found for file type: {file_info['type']}")
                continue

            # Build prompt
            prompt_template = rules.get("prompt_template", "")
            system_prompt = self.generate_config.get("system_prompt", "")

            prompt = prompt_template.format(
                source_code=file_info["content"],
                file_name=os.path.basename(file_path),
                classes=", ".join(file_info["classes"]),
                functions=", ".join(file_info["functions"][:10])  # Limit to first 10
            )

            print(f"🤖 Generating tests for {file_path}...")
            test_code = self.call_llm(prompt, system_prompt)

            if test_code:
                # Save generated test
                test_file_name = f"{Path(file_path).stem}Test.cc"
                test_file_path = os.path.join(test_dir, test_file_name)

                with open(test_file_path, 'w') as f:
                    f.write(test_code)

                generated_files.append(test_file_path)
                print(f"✅ Generated {test_file_path}")
            else:
                print(f"❌ Failed to generate tests for {file_path}")

        return generated_files

    def refine_tests(self, test_files: List[str]) -> List[str]:
        """Refine generated tests using LLM"""
        refined_files = []

        for test_file in test_files:
            print(f"🔧 Refining {test_file}...")

            with open(test_file, 'r') as f:
                test_content = f.read()

            # Build refinement prompt
            prompt_template = self.refine_config.get("prompt_template", "")
            system_prompt = self.refine_config.get("system_prompt", "")

            prompt = prompt_template.format(
                test_code=test_content,
                file_name=os.path.basename(test_file)
            )

            refined_code = self.call_llm(prompt, system_prompt)

            if refined_code:
                # Backup original
                backup_file = test_file + ".backup"
                shutil.copy2(test_file, backup_file)

                # Save refined version
                with open(test_file, 'w') as f:
                    f.write(refined_code)

                refined_files.append(test_file)
                print(f"✅ Refined {test_file}")
            else:
                print(f"❌ Failed to refine {test_file}")

        return refined_files

    def build_tests(self, test_dir: str, build_dir: str = "build") -> bool:
        """Build the project with tests"""
        print(f"🔨 Building tests in {build_dir}...")

        # Create build directory
        os.makedirs(build_dir, exist_ok=True)

        # Configure with CMake
        cmake_cmd = [
            "cmake", "..", 
            "-DENABLE_COVERAGE=ON",
            "-DBUILD_TESTING=ON",
            "-DCMAKE_BUILD_TYPE=Debug"
        ]

        result = subprocess.run(cmake_cmd, cwd=build_dir, capture_output=True, text=True)

        if result.returncode != 0:
            print(f"❌ CMake configuration failed:\n{result.stderr}")
            return False

        # Build
        build_cmd = ["cmake", "--build", ".", "--parallel"]
        result = subprocess.run(build_cmd, cwd=build_dir, capture_output=True, text=True)

        if result.returncode != 0:
            print(f"❌ Build failed:\n{result.stderr}")
            # Try to fix build errors
            if self.fix_build_errors(result.stderr, test_dir):
                print("🔧 Applied fixes, retrying build...")
                return self.build_tests(test_dir, build_dir)
            return False

        print("✅ Build successful!")
        return True

    def fix_build_errors(self, error_output: str, test_dir: str) -> bool:
        """Attempt to fix build errors using LLM"""
        print("🔧 Attempting to fix build errors...")

        # Extract error information
        error_lines = error_output.split('\n')
        error_context = "\n".join(error_lines[-50:])  # Last 50 lines

        # Build fix prompt
        prompt_template = self.build_error_config.get("prompt_template", "")
        system_prompt = self.build_error_config.get("system_prompt", "")

        prompt = prompt_template.format(
            error_output=error_context,
            test_directory=test_dir
        )

        fix_suggestion = self.call_llm(prompt, system_prompt)

        if fix_suggestion:
            print(f"🤖 LLM suggests:\n{fix_suggestion}")
            # Apply common fixes (this is a simplified version)
            self.apply_common_fixes(test_dir, fix_suggestion)
            return True

        return False

    def apply_common_fixes(self, test_dir: str, fix_suggestion: str):
        """Apply common build fixes to test files"""
        # This is a simplified version - in reality, you'd parse the fix_suggestion
        # and apply specific changes to files

        test_files = Path(test_dir).glob("*.cc")

        for test_file in test_files:
            with open(test_file, 'r') as f:
                content = f.read()

            # Common fixes
            if "#include <gtest/gtest.h>" not in content:
                content = "#include <gtest/gtest.h>\n" + content

            if "#include <drogon/drogon.h>" not in content:
                content = "#include <drogon/drogon.h>\n" + content

            with open(test_file, 'w') as f:
                f.write(content)

    def run_tests(self, build_dir: str = "build") -> bool:
        """Run the generated tests"""
        print("🧪 Running tests...")

        result = subprocess.run(
            ["ctest", "--output-on-failure", "--parallel"], 
            cwd=build_dir, 
            capture_output=True, 
            text=True
        )

        if result.returncode == 0:
            print("✅ All tests passed!")
            return True
        else:
            print(f"❌ Some tests failed:\n{result.stdout}")
            return False

    def generate_coverage_report(self, build_dir: str = "build"):
        """Generate coverage report using lcov"""
        print("📊 Generating coverage report...")

        commands = [
            ["lcov", "--capture", "--directory", ".", "--output-file", "coverage.info"],
            ["lcov", "--remove", "coverage.info", "/usr/*", "--output-file", "coverage.filtered.info"],
            ["genhtml", "coverage.filtered.info", "--output-directory", "coverage-html"]
        ]

        for cmd in commands:
            result = subprocess.run(cmd, cwd=build_dir, capture_output=True, text=True)
            if result.returncode != 0:
                print(f"⚠️  Coverage command failed: {' '.join(cmd)}")

        # Generate text summary
        result = subprocess.run(
            ["lcov", "--summary", "coverage.filtered.info"], 
            cwd=build_dir, 
            capture_output=True, 
            text=True
        )

        if result.returncode == 0:
            with open(os.path.join(build_dir, "coverage.txt"), 'w') as f:
                f.write(result.stdout)
            print("✅ Coverage report generated!")
            print(result.stdout)

def main():
    parser = argparse.ArgumentParser(description="Generate C++ unit tests using LLM")
    parser.add_argument("source_path", help="Path to source files or directory")
    parser.add_argument("--test-dir", default="tests", help="Directory to save generated tests")
    parser.add_argument("--build-dir", default="build", help="Build directory")
    parser.add_argument("--skip-build", action="store_true", help="Skip building tests")
    parser.add_argument("--skip-coverage", action="store_true", help="Skip coverage analysis")

    args = parser.parse_args()

    # Initialize generator
    generator = TestGenerator()

    # Find source files
    source_files = []
    if os.path.isfile(args.source_path):
        source_files = [args.source_path]
    elif os.path.isdir(args.source_path):
        for ext in ['*.cc', '*.cpp', '*.cxx']:
            source_files.extend(Path(args.source_path).rglob(ext))
        source_files = [str(f) for f in source_files]

    if not source_files:
        print("❌ No source files found!")
        sys.exit(1)

    print(f"📁 Found {len(source_files)} source files")

    # Create test directory
    os.makedirs(args.test_dir, exist_ok=True)

    # Generate tests
    generated_files = generator.generate_tests(source_files, args.test_dir)

    if not generated_files:
        print("❌ No tests generated!")
        sys.exit(1)

    # Refine tests
    refined_files = generator.refine_tests(generated_files)

    if not args.skip_build:
        # Build tests
        if generator.build_tests(args.test_dir, args.build_dir):
            # Run tests
            if generator.run_tests(args.build_dir) and not args.skip_coverage:
                # Generate coverage
                generator.generate_coverage_report(args.build_dir)

    print("\n🎉 Test generation complete!")
    print(f"Generated {len(generated_files)} test files in {args.test_dir}/")
    print(f"Build artifacts in {args.build_dir}/")

if __name__ == "__main__":
    main()
