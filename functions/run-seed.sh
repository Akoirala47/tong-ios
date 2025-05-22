#!/bin/bash

# Run the seed command and store the output
echo "Running seed command..."
npx ts-node tools/seed.ts --lang es --levels NL --can-do-index 0 > seed_output.log 2>&1

# Display the output
echo "Seed command completed. Output:"
cat seed_output.log 