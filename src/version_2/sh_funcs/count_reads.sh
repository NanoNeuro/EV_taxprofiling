#!/bin/bash

count_reads_fastq() {
  local file="$1"

  if [[ "$file" == *.gz ]]; then
    # Use zcat for gzipped files
    total_lines=$(zcat "$file" | wc -l)
  else
    # Use cat for uncompressed files
    total_lines=$(cat "$file" | wc -l)
  fi

  # Each read spans 4 lines, so divide by 4
  echo $((total_lines / 4))
}

# Call the function with the file path as argument
count_reads_fastq "$1"