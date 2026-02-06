#!/bin/bash

# PlantUML Diagram Generator for UVM Router Project
# Usage: ./generate_diagrams.sh [puml_file]
#        If no file specified, generates all .puml files

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLANTUML_JAR="${SCRIPT_DIR}/plantuml.jar"
PUML_DIR="${SCRIPT_DIR}/PlantUML_scripts"

# Check if PlantUML JAR exists
if [ ! -f "${PLANTUML_JAR}" ]; then
    echo "Error: plantuml.jar not found in ${SCRIPT_DIR}"
    echo "Download from: https://plantuml.com/download"
    exit 1
fi

# Function to generate diagram
generate_diagram() {
    local puml_file="$1"
    echo "Generating diagram for: ${puml_file}"
    java -jar "${PLANTUML_JAR}" "${puml_file}"
    
    if [ $? -eq 0 ]; then
        echo "✓ Successfully generated: ${puml_file%.puml}.png"
    else
        echo "✗ Failed to generate diagram from ${puml_file}"
    fi
}

# Main logic
if [ $# -eq 0 ]; then
    # No arguments - generate all .puml files
    echo "Generating all diagrams in ${PUML_DIR}..."
    
    if [ ! -d "${PUML_DIR}" ]; then
        echo "Error: PlantUML scripts directory not found: ${PUML_DIR}"
        exit 1
    fi
    
    puml_count=$(find "${PUML_DIR}" -name "*.puml" | wc -l)
    
    if [ ${puml_count} -eq 0 ]; then
        echo "No .puml files found in ${PUML_DIR}"
        echo "Note: Found a file named 'diagram' without .puml extension"
        echo "Rename it to diagram.puml and try again"
        exit 0
    fi
    
    for puml_file in "${PUML_DIR}"/*.puml; do
        if [ -f "${puml_file}" ]; then
            generate_diagram "${puml_file}"
        fi
    done
else
    # Generate specific file
    puml_file="$1"
    
    if [ ! -f "${puml_file}" ]; then
        echo "Error: File not found: ${puml_file}"
        exit 1
    fi
    
    generate_diagram "${puml_file}"
fi

echo ""
echo "Done! Check the output directory for generated PNG files."
