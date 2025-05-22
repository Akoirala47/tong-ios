#!/bin/bash

# Define the language and levels
LANG="es"
LEVELS=("NL" "NM" "NH" "IL" "IM" "IH" "AL" "AM" "AH" "S")

echo "=== Starting Spanish Language Pack Generation ==="

# Generate content for each level and can-do statement
for LEVEL in "${LEVELS[@]}"; do
  echo ""
  echo "=== Generating content for $LEVEL level ==="
  
  # Get the number of can-do statements for this level
  CAN_DO_COUNT=$(npx ts-node -e "
    const fs = require('fs');
    const path = require('path');
    const canDoPath = path.join(process.cwd(), '..', 'prompts', 'actfl_can_do.json');
    const canDos = JSON.parse(fs.readFileSync(canDoPath, 'utf8'));
    console.log(canDos['$LEVEL'].length);
  ")
  
  echo "Found $CAN_DO_COUNT can-do statements for $LEVEL level"
  
  # Generate content for each can-do statement
  for CAN_DO_INDEX in $(seq 0 $((CAN_DO_COUNT-1))); do
    echo ""
    echo "=== Generating content for can-do index $CAN_DO_INDEX ==="
    
    # Run the seed command
    npx ts-node tools/seed.ts --lang $LANG --levels $LEVEL --can-do-index $CAN_DO_INDEX
    
    # Check if the command succeeded
    if [ $? -ne 0 ]; then
      echo "Error generating content for $LEVEL level, can-do index $CAN_DO_INDEX"
      echo "Continuing with next can-do statement..."
    else
      echo "Successfully generated content for $LEVEL level, can-do index $CAN_DO_INDEX"
    fi
    
    # Add a delay to avoid rate limiting
    echo "Waiting 10 seconds before next generation..."
    sleep 10
  done
done

echo ""
echo "=== All content generated. Importing to iOS app... ==="

# Generate Swift model from all generated content
npx ts-node tools/import.ts --lang=$LANG

echo ""
echo "=== Spanish Language Pack Generation Complete ===" 