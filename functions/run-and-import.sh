#!/bin/bash

# Run the seed for Spanish
echo "Seeding Spanish content for all ACTFL levels..."

# Set language code
LANG="es"

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
  echo "Installing dependencies..."
  npm install
fi

# Import existing content
echo "Importing all existing Spanish content to the app..."
npx ts-node tools/import.ts --lang="$LANG"

echo "Content has been imported to the iOS app!"
echo "The JSON content file is located at ../tong-ios/Content/${LANG}Content.json"
echo "To use this content, access it via ESContentLoader in the app." 