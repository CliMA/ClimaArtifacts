#!/bin/bash

# Define the source and destination directories specific to your local machine
SRC_DIR="soilgrids_geotiff"
DEST_DIR="soilgrids_nc"

# Create the destination directory if it doesn't exist
mkdir -p "$DEST_DIR"

# Loop over all GeoTIFF files in the source directory
for file in "$SRC_DIR"/*.tif; do
  # Extract the base name of the file (without extension)
  base_name=$(basename "$file" .tif)
  
  # Define the output NetCDF file name
  output_file="$DEST_DIR/${base_name}.nc"
  
  # Convert the GeoTIFF file to NetCDF format
  gdal_translate -ot Int16 -of netCDF "$file" "$output_file"
  
  echo "Converted $file to $output_file"
done

echo "All files have been converted."
