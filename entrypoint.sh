#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# GitHub Actions output functions
echo_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

echo_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

echo_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

echo_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Set default values
PROJECT_PATH="${INPUT_PROJECT_PATH:-"."}"
MAKEFILE_TARGET="${INPUT_MAKEFILE_TARGET:-"all"}"
NORMINETTE_FLAGS="${INPUT_NORMINETTE_FLAGS:-""}"
STRICT_MODE="${INPUT_STRICT_MODE:-"true"}"
BUILD_ONLY="${INPUT_BUILD_ONLY:-"false"}"
NORMINETTE_ONLY="${INPUT_NORMINETTE_ONLY:-"false"}"

# Initialize status variables
NORMINETTE_STATUS="skipped"
BUILD_STATUS="skipped"
NORMINETTE_VIOLATIONS=0
EXIT_CODE=0

echo_info "42 Norminette & Build Check Action"
echo_info "Project path: $PROJECT_PATH"
echo_info "Makefile target: $MAKEFILE_TARGET"
echo_info "Strict mode: $STRICT_MODE"
echo_info "Build only: $BUILD_ONLY"
echo_info "Norminette only: $NORMINETTE_ONLY"

# Change to project directory
if [ "$PROJECT_PATH" = "." ]; then
    cd "$GITHUB_WORKSPACE"
else
    cd "$GITHUB_WORKSPACE/$PROJECT_PATH"
fi

# Function to run norminette
run_norminette() {
    echo_info "Running norminette check..."
    
    # Check if there are any C files to check
    if ! find . -name "*.c" -o -name "*.h" | grep -q .; then
        echo_warning "No C files found to check with norminette"
        NORMINETTE_STATUS="skipped"
        return 0
    fi
    
    # Create temporary file for norminette output
    NORMINETTE_OUTPUT=$(mktemp)
    
    # Run norminette and capture output
    if norminette $NORMINETTE_FLAGS . > "$NORMINETTE_OUTPUT" 2>&1; then
        echo_success "Norminette check passed!"
        NORMINETTE_STATUS="passed"
        cat "$NORMINETTE_OUTPUT"
    else
        echo_error "Norminette violations found:"
        cat "$NORMINETTE_OUTPUT"
        
        # Count violations (each violation typically has an "Error" line)
        NORMINETTE_VIOLATIONS=$(grep -c "Error" "$NORMINETTE_OUTPUT" || echo "0")
        echo_info "Total violations found: $NORMINETTE_VIOLATIONS"
        
        NORMINETTE_STATUS="failed"
        
        if [ "$STRICT_MODE" = "true" ]; then
            EXIT_CODE=1
        else
            echo_warning "Norminette violations found but strict mode is disabled"
        fi
    fi
    
    # Clean up
    rm -f "$NORMINETTE_OUTPUT"
}

# Function to run build
run_build() {
    echo_info "Running build check..."
    
    # Check if Makefile exists
    if [ ! -f "Makefile" ] && [ ! -f "makefile" ]; then
        echo_error "No Makefile found in project directory"
        BUILD_STATUS="failed"
        EXIT_CODE=1
        return 1
    fi
    
    # Clean before building
    echo_info "Cleaning previous build..."
    if make fclean >/dev/null 2>&1 || make clean >/dev/null 2>&1; then
        echo_info "Cleaned successfully"
    else
        echo_warning "Clean target not available or failed"
    fi
    
    # Build the project
    echo_info "Building with target: $MAKEFILE_TARGET"
    if make "$MAKEFILE_TARGET"; then
        echo_success "Build completed successfully!"
        BUILD_STATUS="passed"
        
        # Check if executable was created (common for 42 projects)
        if [ -f "$(basename $(pwd))" ] || ls *.a >/dev/null 2>&1 || find . -maxdepth 1 -type f -executable | grep -q .; then
            echo_success "Executable/library created successfully"
        fi
    else
        echo_error "Build failed!"
        BUILD_STATUS="failed"
        EXIT_CODE=1
    fi
}

# Main execution logic
if [ "$NORMINETTE_ONLY" = "true" ]; then
    echo_info "Running norminette check only..."
    run_norminette
elif [ "$BUILD_ONLY" = "true" ]; then
    echo_info "Running build check only..."
    run_build
else
    echo_info "Running both norminette and build checks..."
    run_norminette
    run_build
fi

# Set GitHub Actions outputs
if [ -n "$GITHUB_OUTPUT" ] && [ -w "$(dirname "$GITHUB_OUTPUT")" ]; then
    echo "norminette_status=$NORMINETTE_STATUS" >> $GITHUB_OUTPUT
    echo "build_status=$BUILD_STATUS" >> $GITHUB_OUTPUT
    echo "norminette_violations=$NORMINETTE_VIOLATIONS" >> $GITHUB_OUTPUT
else
    echo_warning "Cannot write to GITHUB_OUTPUT file, outputs will not be available"
    echo_info "norminette_status=$NORMINETTE_STATUS"
    echo_info "build_status=$BUILD_STATUS"
    echo_info "norminette_violations=$NORMINETTE_VIOLATIONS"
fi

# Summary
echo ""
echo_info "=== Summary ==="
echo_info "Norminette status: $NORMINETTE_STATUS"
echo_info "Build status: $BUILD_STATUS"
if [ "$NORMINETTE_VIOLATIONS" -gt 0 ]; then
    echo_info "Norminette violations: $NORMINETTE_VIOLATIONS"
fi

# Final result
if [ $EXIT_CODE -eq 0 ]; then
    echo_success "Action completed successfully!"
else
    echo_error "Action failed with exit code $EXIT_CODE"
fi

exit $EXIT_CODE
