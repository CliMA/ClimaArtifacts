#!/usr/bin/env python3
"""
Combine yearly MODIS LAI files into a single monthly climatology.
Each input file has 12 months of data; this script averages across years for each month.
"""

import argparse
import glob
import os
import xarray as xr
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt


def get_max_lai_modis(input_dir: str, output_path: str):
    """
    Compute max LAI per pixel from yearly MODIS LAI files.
    
    Parameters
    ----------
    input_dir : str
        Directory containing Yuan_et_al_YYYY_1x1.nc files
    output_path : str
        Path to write the output file
    """
    # Find all yearly files
    pattern = os.path.join(input_dir, "Yuan_et_al_*_1x1.nc")
    files = sorted(glob.glob(pattern))
    
    if not files:
        raise FileNotFoundError(f"No files found matching {pattern}")
    
    print(f"Found {len(files)} yearly files")
    
    # Load all datasets
    datasets = []
    years = []
    for f in files:
        # Extract year from filename
        basename = os.path.basename(f)
        year = int(basename.split("_")[3])
        years.append(year)
        
        ds = xr.open_dataset(f)
        # Rename time to month (each file has 12 months)
        ds = ds.rename({"time": "month"})
        ds = ds.assign_coords(month=np.arange(1, 13))
        datasets.append(ds)
        print(f"  Loaded {basename}")
    
    # Concatenate along month dimension
    combined = xr.concat(datasets, dim="month")
    # Compute max LAI by taking max over months
    maxlai = combined.max(dim="month")
    # Add metadata
    maxlai.attrs["title"] = "MODIS Max LAI"
    maxlai.attrs["source"] = f"Computed from Yuan et al. data ({min(years)}-{max(years)})"
    maxlai.attrs["history"] = f"Created by get_max_modis_lai.py"
    
    # Write output with explicit encoding to ensure integer time
    encoding = {
        "lai": {"dtype": "float32"},
    }
    maxlai.to_netcdf(output_path, encoding=encoding)
    print(f"\nWrote maxLAI to {output_path}")
    print(f"  Years averaged: {min(years)}-{max(years)} ({len(years)} years)")
    fig, ax = plt.subplots(1, 1, figsize=(16, 10))
    
    lai = maxlai["lai"]
    vmin, vmax = float(lai.min()), float(lai.max())
    im = ax.pcolormesh(maxlai["lon"], maxlai["lat"], lai, cmap="YlGn", vmin=vmin, vmax=vmax)
    ax.set_aspect("equal")
    ax.set_xlim(-180, 180)
    ax.set_ylim(-90, 90)
    
    fig.suptitle(f"MODIS Max LAI ({min(years)}-{max(years)})", fontsize=14)
    fig.colorbar(im, ax, label="LAI (m² m⁻²)", shrink=0.6)
    
    # Save plot beside the netcdf
    plot_path = output_path.replace(".nc", ".png")
    fig.savefig(plot_path, dpi=150, bbox_inches="tight")
    print(f"Saved plot to {plot_path}")
    plt.close(fig)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Compute max LAI from yearly MODIS LAI files"
    )
    parser.add_argument(
        "--input-dir",
        required=True,
        help="Directory containing Yuan_et_al_YYYY_1x1.nc files (from modis_lai artifact)",
    )
    parser.add_argument(
        "--output",
        required=True,
        help="Output file path",
    )
    
    args = parser.parse_args()
    get_max_lai_modis(args.input_dir, args.output)
