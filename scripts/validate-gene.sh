#!/bin/bash
# validate-gene.sh - Validate gene definitions and check genome integrity

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

echo "=== Gene Validation Script ==="
echo "Project: $PROJECT_ROOT"
echo ""

# Check gene directories
GENES_DIR="$PROJECT_ROOT/godot/genes"
ERRORS=0

validate_behavior() {
    local gene_file="$1"
    local gene_name=$(basename "$gene_file" .gd)
    
    # Check for required methods
    if ! grep -q "func get_display_name()" "$gene_file"; then
        echo "ERROR: $gene_name missing get_display_name()"
        ((ERRORS++))
    fi
    
    if ! grep -q "func get_gene_id()" "$gene_file"; then
        echo "ERROR: $gene_name missing get_gene_id()"
        ((ERRORS++))
    fi
    
    if ! grep -q "func _evaluate" "$gene_file"; then
        echo "ERROR: $gene_name missing _evaluate()"
        ((ERRORS++))
    fi
    
    echo "OK: Behavior gene $gene_name"
}

validate_effect() {
    local gene_file="$1"
    local gene_name=$(basename "$gene_file" .gd)
    
    # Check for required methods
    if ! grep -q "func get_display_name()" "$gene_file"; then
        echo "ERROR: $gene_name missing get_display_name()"
        ((ERRORS++))
    fi
    
    if ! grep -q "func get_gene_id()" "$gene_file"; then
        echo "ERROR: $gene_name missing get_gene_id()"
        ((ERRORS++))
    fi
    
    if ! grep -q "func apply" "$gene_file"; then
        echo "ERROR: $gene_name missing apply()"
        ((ERRORS++))
    fi
    
    echo "OK: Effect gene $gene_name"
}

# Validate behaviors
echo "--- Validating Behavior Genes ---"
if [ -d "$GENES_DIR/behaviors" ]; then
    for gene in "$GENES_DIR/behaviors"/*.gd; do
        if [ -f "$gene" ]; then
            validate_behavior "$gene" || true
        fi
    done
else
    echo "WARNING: behaviors directory not found"
fi

echo ""
echo "--- Validating Effect Genes ---"
if [ -d "$GENES_DIR/effects" ]; then
    for gene in "$GENES_DIR/effects"/*.gd; do
        if [ -f "$gene" ]; then
            validate_effect "$gene" || true
        fi
    done
else
    echo "WARNING: effects directory not found"
fi

echo ""
echo "--- Checking GenomeRegistry Registration ---"
if [ -f "$GENES_DIR/GenomeRegistry.gd" ]; then
    echo "OK: GenomeRegistry exists"
else
    echo "ERROR: GenomeRegistry.gd not found"
    ((ERRORS++))
fi

echo ""
echo "--- Validation Summary ---"
if [ $ERRORS -eq 0 ]; then
    echo "All genes validated successfully!"
    exit 0
else
    echo "Found $ERRORS validation errors"
    exit 1
fi
