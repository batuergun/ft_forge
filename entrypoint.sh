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
WITH_MINILIBX="${INPUT_WITH_MINILIBX:-"auto"}"

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
echo_info "With minilibx: $WITH_MINILIBX"

# Change to project directory
if [ "$PROJECT_PATH" = "." ]; then
    cd "$GITHUB_WORKSPACE"
else
    cd "$GITHUB_WORKSPACE/$PROJECT_PATH"
fi

# Function to detect project type
detect_project_type() {
    # Check for minishell project indicators
    if [ -f "minishell.h" ] || [ -f "includes/minishell.h" ] || [ -f "inc/minishell.h" ] || \
       grep -q "minishell" Makefile 2>/dev/null || grep -q "minishell" makefile 2>/dev/null || \
       [ "$(basename $(pwd))" = "minishell" ] || [ "$(basename $(pwd))" = "Minishell" ]; then
        echo "minishell"
        return 0
    fi
    echo "unknown"
}

# Function to run norminette
run_norminette() {
    echo_info "Running norminette check..."
    
    # Check if there are any C files to check
    if ! find . -name "*.c" -o -name "*.h" | grep -q .; then
        echo_warning "No C files found to check with norminette"
        NORMINETTE_STATUS="skipped"
        return 0
    fi
    
    # Detect project type
    PROJECT_TYPE=$(detect_project_type)
    if [ "$PROJECT_TYPE" = "minishell" ]; then
        echo_info "Minishell project detected - will ignore GLOBAL_VAR_DETECTED warnings"
    fi
    
    # Create temporary file for norminette output
    NORMINETTE_OUTPUT=$(mktemp)
    NORMINETTE_FILTERED=$(mktemp)
    
    # Run norminette and capture output
    # Create a list of files to check, excluding minilibx directories
    FILES_TO_CHECK=$(find . -name "*.c" -o -name "*.h" | grep -v -E "(minilibx|mlx)" | tr '\n' ' ')
    
    if [ -n "$FILES_TO_CHECK" ]; then
        norminette $NORMINETTE_FLAGS $FILES_TO_CHECK > "$NORMINETTE_OUTPUT" 2>&1 || true
        
        # Filter output based on project type
        if [ "$PROJECT_TYPE" = "minishell" ]; then
            # Filter out GLOBAL_VAR_DETECTED notices for minishell projects
            # Remove the notice lines and the preceding context
            grep -v "GLOBAL_VAR_DETECTED" "$NORMINETTE_OUTPUT" > "$NORMINETTE_FILTERED" || cp "$NORMINETTE_OUTPUT" "$NORMINETTE_FILTERED"
        else
            cp "$NORMINETTE_OUTPUT" "$NORMINETTE_FILTERED"
        fi
        
        # Check if there are any remaining violations
        if grep -q "Error" "$NORMINETTE_FILTERED"; then
            echo_error "Norminette violations found:"
            cat "$NORMINETTE_FILTERED"
            
            # Count violations (each violation typically has an "Error" line)
            NORMINETTE_VIOLATIONS=$(grep -c "Error" "$NORMINETTE_FILTERED" || echo "0")
            
            # If we filtered anything for minishell, inform the user
            if [ "$PROJECT_TYPE" = "minishell" ]; then
                ORIGINAL_VIOLATIONS=$(grep -c "Error" "$NORMINETTE_OUTPUT" || echo "0")
                FILTERED_COUNT=$((ORIGINAL_VIOLATIONS - NORMINETTE_VIOLATIONS))
                if [ $FILTERED_COUNT -gt 0 ]; then
                    echo_info "Filtered $FILTERED_COUNT GLOBAL_VAR_DETECTED warning(s) for minishell project"
                fi
            fi
            
            echo_info "Total violations found: $NORMINETTE_VIOLATIONS"
            
            NORMINETTE_STATUS="failed"
            
            if [ "$STRICT_MODE" = "true" ]; then
                EXIT_CODE=1
            else
                echo_warning "Norminette violations found but strict mode is disabled"
            fi
        else
            echo_success "Norminette check passed!"
            NORMINETTE_STATUS="passed"
            
            # Show filtered output if there were any global var warnings that got filtered
            if [ "$PROJECT_TYPE" = "minishell" ]; then
                ORIGINAL_VIOLATIONS=$(grep -c "Error" "$NORMINETTE_OUTPUT" || echo "0")
                if [ $ORIGINAL_VIOLATIONS -gt 0 ]; then
                    echo_info "All violations were GLOBAL_VAR_DETECTED warnings (filtered for minishell)"
                fi
            fi
            cat "$NORMINETTE_FILTERED"
        fi
    else
        echo_warning "No C files found to check with norminette (excluding minilibx)"
        NORMINETTE_STATUS="skipped"
    fi
    
    # Clean up
    rm -f "$NORMINETTE_OUTPUT" "$NORMINETTE_FILTERED"
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
    
    # Auto-detect minilibx usage if set to auto
    if [ "$WITH_MINILIBX" = "auto" ]; then
        echo_info "Auto-detecting minilibx usage..."
        
        # Check for minilibx directories
        MINILIBX_DIRS_FOUND=""
        for dir in minilibx minilibx-linux minilibx-macos lib/minilibx lib/minilibx-linux lib/minilibx-macos mlx lib/mlx; do
            if [ -d "$dir" ]; then
                MINILIBX_DIRS_FOUND="$MINILIBX_DIRS_FOUND $dir"
            fi
        done
        
        # Check for minilibx includes in C files
        MINILIBX_INCLUDES_FOUND=""
        # Search for mlx patterns
        C_FILES=$(find . -name "*.c" -o -name "*.h" | grep -v -E "/minilibx|/mlx")
        if [ -n "$C_FILES" ]; then
            FOUND_FILES=$(echo "$C_FILES" | xargs grep -l "mlx\.h\|mlx_" 2>/dev/null || true)
            if [ -n "$FOUND_FILES" ]; then
                MINILIBX_INCLUDES_FOUND="yes"
                echo_info "  - MLX includes found in: $(echo $FOUND_FILES | tr '\n' ' ')"
            fi
        fi
        
        # Check Makefile for minilibx references
        MAKEFILE_MLX_FOUND=""
        if [ -f "Makefile" ] || [ -f "makefile" ]; then
            if grep -q -E "(mlx|minilibx)" Makefile 2>/dev/null || grep -q -E "(mlx|minilibx)" makefile 2>/dev/null; then
                MAKEFILE_MLX_FOUND="yes"
            fi
        fi
        
        # Auto-enable if minilibx detected
        if [ -n "$MINILIBX_DIRS_FOUND" ] || [ -n "$MINILIBX_INCLUDES_FOUND" ] || [ -n "$MAKEFILE_MLX_FOUND" ]; then
            echo_info "MinilibX detected! Auto-enabling graphics support..."
            if [ -n "$MINILIBX_DIRS_FOUND" ]; then
                echo_info "  - Found directories:$MINILIBX_DIRS_FOUND"
            fi
            if [ -n "$MINILIBX_INCLUDES_FOUND" ]; then
                echo_info "  - Found mlx includes in source files"
            fi
            if [ -n "$MAKEFILE_MLX_FOUND" ]; then
                echo_info "  - Found mlx references in Makefile"
            fi
            WITH_MINILIBX="true"
        else
            echo_info "No minilibx usage detected - using lightweight build"
            WITH_MINILIBX="false"
        fi
    elif [ "$WITH_MINILIBX" = "true" ]; then
        echo_info "MinilibX explicitly enabled"
    elif [ "$WITH_MINILIBX" = "false" ]; then
        echo_info "MinilibX explicitly disabled"
    fi
    
    # Set up minilibx environment if enabled (auto or manual)
    if [ "$WITH_MINILIBX" = "true" ]; then
        echo_info "Setting up minilibx environment..."
        
        # Install X11 dependencies on-demand
        echo_info "Installing X11 dependencies..."
        apt-get update -qq > /dev/null 2>&1
        apt-get install -y -qq \
            xorg-dev \
            libxext-dev \
            libbsd-dev \
            libx11-dev \
            libxrandr-dev \
            libxss-dev \
            libglu1-mesa-dev \
            freeglut3-dev \
            mesa-common-dev \
            xvfb \
            > /dev/null 2>&1
        
        # Set up virtual display
        echo_info "Starting virtual display..."
        export DISPLAY=:99
        Xvfb :99 -screen 0 1024x768x24 > /dev/null 2>&1 &
        XVFB_PID=$!
        sleep 2  # Give Xvfb time to start
        echo_info "MinilibX environment ready (Display: $DISPLAY, PID: $XVFB_PID)"
    else
        # Skip minilibx directories if not enabled
        MINILIBX_BACKUP=""
        echo_info "MinilibX not enabled - excluding from build..."
        for dir in minilibx minilibx-linux minilibx-macos lib/minilibx lib/minilibx-linux lib/minilibx-macos mlx lib/mlx; do
            if [ -d "$dir" ]; then
                mv "$dir" "${dir}.disabled" 2>/dev/null || true
                MINILIBX_BACKUP="$MINILIBX_BACKUP $dir"
            fi
        done
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
    
    # Restore minilibx directories if they were disabled
    if [ "$WITH_MINILIBX" = "false" ] && [ -n "$MINILIBX_BACKUP" ]; then
        echo_info "Restoring minilibx directories..."
        for dir in $MINILIBX_BACKUP; do
            if [ -d "${dir}.disabled" ]; then
                mv "${dir}.disabled" "$dir" 2>/dev/null || true
            fi
        done
    fi
    
    # Clean up virtual display
    if [ "$WITH_MINILIBX" = "true" ] && [ -n "$XVFB_PID" ]; then
        echo_info "Cleaning up virtual display..."
        kill $XVFB_PID 2>/dev/null || true
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
