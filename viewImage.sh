#!/bin/bash

# Check if at least one argument (image file) is provided
if [ "$#" -eq 0 ]; then
  echo "Usage: $0 image1 [image2 ...]"
  exit 1
fi

# Start all display processes in background
pids=()
for img in "$@"; do
  display -resize 10% "$img" &
  pids+=($!)
done

# Wait for user input to kill all display processes
read -p "Press ENTER to close all images..."

# Kill all display processes
for pid in "${pids[@]}"; do
  kill "$pid" 2>/dev/null
done
