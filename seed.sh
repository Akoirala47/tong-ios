#!/bin/bash

# Set environment variables from .env file if it exists
if [ -f .env ]; then
  export $(cat .env | grep -v '^#' | xargs)
fi

# Ensure GEMINI_API_KEY is set
if [ -z "$GEMINI_API_KEY" ]; then
  export GEMINI_API_KEY="AIzaSyAXXaMHGOgDzyf4iUNs-5xG5ZysuvfiFR4"
  echo "Using default Gemini API key"
fi

# Default values
LANG="es"
LEVELS="NL"
CAN_DO_INDEX=0
IMPORT_TO_APP=true

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --lang)
      LANG="$2"
      shift 2
      ;;
    --levels)
      LEVELS="$2"
      shift 2
      ;;
    --can-do-index)
      CAN_DO_INDEX="$2"
      shift 2
      ;;
    --no-import)
      IMPORT_TO_APP=false
      shift
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

echo "Seeding content for language: $LANG with levels: $LEVELS"

# Change to the functions directory
cd functions

# Install dependencies if node_modules doesn't exist
if [ ! -d "node_modules" ]; then
  echo "Installing dependencies..."
  npm install
fi

# Run the seed command
npx ts-node tools/seed.ts --lang "$LANG" --levels "$LEVELS" --can-do-index "$CAN_DO_INDEX"
SEED_EXIT_CODE=$?

if [ $SEED_EXIT_CODE -ne 0 ]; then
  echo "Error: Seeding process failed with exit code $SEED_EXIT_CODE"
  exit $SEED_EXIT_CODE
fi

# Import the content to the app
if [ "$IMPORT_TO_APP" = true ]; then
  echo "Importing content to iOS app..."
  npx ts-node tools/import.ts --lang="$LANG"
  
  echo "Content has been imported to the iOS app!"
  echo "The JSON content file is located at tong-ios/Content/${LANG}Content.json"
  echo "To use this content, access it via ESContentLoader in the app."
else
  echo "Content import skipped (--no-import flag used)"
fi

echo "Seeding complete!" 