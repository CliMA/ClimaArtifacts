#!/usr/bin/env bash
set -euo pipefail

if [ $# -ne 1 ]; then
    echo "Please provide the path to the fluxnet2015 metadata file as an argument (ex: /path/to/FLX_AA-Flx_BIF_DD_20200501.xlsx)"
    exit 1
fi

metadata_path="$1"

# Infer parent fluxnet2015 directory
fluxnet_dir="$(dirname "$(dirname "$metadata_path")")"

# Example file name: FLX_AA-Flx_BIF_DD_20200501.xlsx
filename="$(basename "$metadata_path")"
temporal_code=$(echo "$filename" | awk -F'_' '{print $4}')

# Ensure xlsx2csv is installed
if ! command -v xlsx2csv >/dev/null 2>&1; then
    echo "xlsx2csv not found. Installing..."
    pip install --user xlsx2csv
    export PATH="$PATH:$(python -m site --user-base)/bin"
fi

# Convert to CSV in fluxnet2015 root directory
output_csv="$fluxnet_dir/metadata_${temporal_code}_full.csv"
echo "Converting $metadata_path -> $output_csv"
xlsx2csv "$metadata_path" "$output_csv"

echo "Full metadata CSV saved at: $output_csv"

# process the CSV 
processed_csv="$fluxnet_dir/metadata_${temporal_code}_clean.csv"
echo "Processing metadata to minimal CSV: $processed_csv"
python3 "$(dirname "$0")/process_metadata.py" "$output_csv" "$processed_csv"

echo "Processed metadata saved at: $processed_csv"
