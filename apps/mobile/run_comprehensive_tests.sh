#!/bin/bash

# AIc Mobile App - Comprehensive Test Runner
# This script runs all Patrol integration tests

echo "🚀 Starting AIc Mobile App Comprehensive Tests"
echo "================================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    print_error "pubspec.yaml not found. Please run this script from the mobile app directory."
    exit 1
fi

# Check if patrol is installed
if ! grep -q "patrol:" pubspec.yaml; then
    print_error "Patrol not found in pubspec.yaml. Please add patrol as a dev dependency."
    exit 1
fi

# Variables
DEVICE_ID=""
TEST_RESULTS_DIR="test_results"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--device)
            DEVICE_ID="-d $2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  -d, --device DEVICE_ID    Specify device ID for testing"
            echo "  -h, --help               Show this help message"
            exit 0
            ;;
        *)
            print_warning "Unknown option: $1"
            shift
            ;;
    esac
done

# Create results directory
mkdir -p "$TEST_RESULTS_DIR"

print_status "Installing dependencies..."
flutter pub get

if [ $? -ne 0 ]; then
    print_error "Failed to install dependencies"
    exit 1
fi

print_success "Dependencies installed successfully"

# Check if API server is running
print_status "Checking API server connection..."
if curl -s -f "http://localhost:3000/health" > /dev/null 2>&1; then
    print_success "API server is running on localhost:3000"
else
    print_warning "API server not detected on localhost:3000"
    print_warning "Some tests may fail without API server running"
    echo "To start API server: cd ../api && npm start"
fi

# List available devices
print_status "Available devices:"
flutter devices

# Test suite configuration
declare -A test_suites=(
    ["comprehensive"]="integration_test/app_comprehensive_test.dart"
    ["chat"]="integration_test/chat_feature_test.dart" 
    ["api"]="integration_test/api_integration_test.dart"
    ["ui"]="integration_test/ui_ux_test.dart"
)

# Run each test suite
total_tests=0
passed_tests=0
failed_tests=0

for suite_name in "${!test_suites[@]}"; do
    test_file="${test_suites[$suite_name]}"
    
    if [ ! -f "$test_file" ]; then
        print_warning "Test file not found: $test_file"
        continue
    fi
    
    print_status "Running $suite_name tests..."
    echo "----------------------------------------"
    
    # Run the test
    flutter test integration_test --reporter=expanded $DEVICE_ID "$test_file" 2>&1 | tee "$TEST_RESULTS_DIR/${suite_name}_${TIMESTAMP}.log"
    
    test_result=${PIPESTATUS[0]}
    total_tests=$((total_tests + 1))
    
    if [ $test_result -eq 0 ]; then
        print_success "$suite_name tests PASSED"
        passed_tests=$((passed_tests + 1))
    else
        print_error "$suite_name tests FAILED"
        failed_tests=$((failed_tests + 1))
    fi
    
    echo ""
done

# Unit tests
print_status "Running unit tests..."
flutter test test/ --reporter=expanded 2>&1 | tee "$TEST_RESULTS_DIR/unit_tests_${TIMESTAMP}.log"

unit_test_result=$?
total_tests=$((total_tests + 1))

if [ $unit_test_result -eq 0 ]; then
    print_success "Unit tests PASSED"
    passed_tests=$((passed_tests + 1))
else
    print_error "Unit tests FAILED"
    failed_tests=$((failed_tests + 1))
fi

# Generate summary report
echo ""
echo "================================================"
echo "🏁 TEST EXECUTION COMPLETE"
echo "================================================"
echo "Total test suites: $total_tests"
print_success "Passed: $passed_tests"
if [ $failed_tests -gt 0 ]; then
    print_error "Failed: $failed_tests"
else
    echo "Failed: $failed_tests"
fi
echo ""

# Coverage report (if available)
if command -v lcov &> /dev/null; then
    print_status "Generating coverage report..."
    flutter test --coverage
    genhtml coverage/lcov.info -o coverage/html
    print_success "Coverage report generated: coverage/html/index.html"
fi

# Final result
if [ $failed_tests -eq 0 ]; then
    print_success "🎉 ALL TESTS PASSED!"
    echo "Results saved in: $TEST_RESULTS_DIR/"
    exit 0
else
    print_error "❌ SOME TESTS FAILED"
    echo "Check detailed logs in: $TEST_RESULTS_DIR/"
    echo ""
    echo "Common troubleshooting steps:"
    echo "1. Ensure API server is running: cd ../api && npm start"
    echo "2. Check device connection: flutter devices"
    echo "3. Clear cache: flutter clean && flutter pub get"
    echo "4. Check individual test logs for specific errors"
    exit 1
fi