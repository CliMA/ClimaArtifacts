#!/bin/bash

GEOTIFF_DATA_DIR="soilgrids_geotiff"
mkdir -p "$GEOTIFF_DATA_DIR"
IGH="+proj=igh +lat_0=0 +lon_0=0 +datum=WGS84 +units=m +no_defs" # proj string for Homolosine projection
SG_URL="/vsicurl?max_retry=3&retry_delay=1&list_dir=no&url=https://files.isric.org/soilgrids/latest/data_aggregated/5000m"

for var in "bdod" "silt" "sand" "clay" "cfvo" "soc"
do
    for level in "0-5cm" "100-200cm" "15-30cm" "30-60cm" "5-15cm" "60-100cm"
    do
	gdal_translate     -projwin_srs "$IGH" -co "TILED=YES" -co "COMPRESS=DEFLATE" -co "PREDICTOR=2" -co "BIGTIFF=YES"     $SG_URL"/"$var"/"$var"_"$level"_mean_5000.tif"     $GEOTIFF_DATA_DIR"/tmp.tif"
    gdalwarp -overwrite -t_srs EPSG:4326  $GEOTIFF_DATA_DIR"/tmp.tif" $GEOTIFF_DATA_DIR"/"$var"_"$level"_mean_5000.tif"
    done
done
rm $GEOTIFF_DATA_DIR"/tmp.tif"

      
