#!/usr/bin/env python3
import csv
import sys
import os
import re
from collections import defaultdict

def process_metadata(input_csv, output_csv):
    os.makedirs(os.path.dirname(output_csv), exist_ok=True)

    key_map = {
        "LOCATION_LAT": "latitude",
        "LOCATION_LONG": "longitude",
        "UTC_OFFSET": "utc_offset",
        "HEIGHTC": "canopy_height_raw"
    }

    # Regex for SWC & TS variable detection
    swc_pattern = re.compile(r"^SWC_F_MDS_\d+$")
    ts_pattern = re.compile(r"^TS_F_MDS_\d+$")

    sites = defaultdict(lambda: {
        "latitude": None,
        "longitude": None,
        "utc_offset": None,
        "canopy_height_values": [],
        "atmospheric_sensor_heights": set(),
        "swc_depths": set(),
        "ts_depths": set()
    })

    with open(input_csv, newline='') as f:
        rows = list(csv.reader(f))

    i = 0
    while i < len(rows):
        row = rows[i]
        site_id, key, value = row[0], row[3], row[4]

        # Handle direct key mappings
        if key in key_map:
            if key == "HEIGHTC":
                try:
                    sites[site_id]["canopy_height_values"].append(float(value))
                except ValueError:
                    pass
            else:
                target_key = key_map[key]
                try:
                    sites[site_id][target_key] = float(value)
                except ValueError:
                    sites[site_id][target_key] = value

        # Atmospheric sensor heights (CO2_F_MDS -> next row)
        if value == "CO2_F_MDS" and i + 1 < len(rows):
            try:
                sites[site_id]["atmospheric_sensor_heights"].add(float(rows[i + 1][4]))
            except ValueError:
                pass

        # Soil water content depths
        if swc_pattern.match(value) and i + 1 < len(rows):
            try:
                sites[site_id]["swc_depths"].add(float(rows[i + 1][4]))
            except ValueError:
                pass

        # Soil temperature depths
        if ts_pattern.match(value) and i + 1 < len(rows):
            try:
                sites[site_id]["ts_depths"].add(float(rows[i + 1][4]))
            except ValueError:
                pass

        i += 1

    # Post-process results
    for site_id, data in sites.items():
        # Canopy height average
        if data["canopy_height_values"]:
            data["canopy_height"] = sum(data["canopy_height_values"]) / len(data["canopy_height_values"])
        else:
            data["canopy_height"] = None

        # Convert sets to sorted lists
        data["atmospheric_sensor_heights"] = sorted(data["atmospheric_sensor_heights"])
        data["swc_depths"] = sorted(data["swc_depths"]) if data["swc_depths"] else ["NaN"]
        data["ts_depths"] = sorted(data["ts_depths"]) if data["ts_depths"] else ["NaN"]

    # Write minimal CSV
    with open(output_csv, "w", newline='') as f:
        writer = csv.writer(f)
        writer.writerow([
            "site_id","latitude","longitude","utc_offset",
            "canopy_height","atmospheric_sensor_heights","swc_depths","ts_depths"
        ])
        for site_id, data in sites.items():
            writer.writerow([
                site_id,
                data["latitude"],
                data["longitude"],
                data["utc_offset"],
                data["canopy_height"],
                ";".join(map(str, data["atmospheric_sensor_heights"])),
                ";".join(map(str, data["swc_depths"])),
                ";".join(map(str, data["ts_depths"]))
            ])

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: process_fluxnet_metadata.py input_csv output_csv")
        sys.exit(1)
    process_metadata(sys.argv[1], sys.argv[2])
