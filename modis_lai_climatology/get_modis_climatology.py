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


def get_modis_climatology(input_dir: str, output_path: str):
    """
    Compute monthly climatology from yearly MODIS LAI files.
    
    Parameters
    ----------
    input_dir : str
        Directory containing Yuan_et_al_YYYY_1x1.nc files
    output_path : str
        Path to write the output climatology file
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
    
    # Concatenate along new year dimension
    combined = xr.concat(datasets, dim="year")
    combined = combined.assign_coords(year=years)
    
    # Compute climatology by averaging over years
    climatology = combined.mean(dim="year")
    
    # Rename month back to time with proper CF-compliant datetime coordinates
    climatology = climatology.rename({"month": "time"})
    
    # Use UNIFORM 30-day spacing (like original files) for PeriodicCalendar compatibility
    # Store as integer seconds since 1970-01-01 to match original format exactly
    # Reference: 2000-01-01 00:00:00 UTC = 946684800 seconds since 1970-01-01
    epoch_2000 = 946684800
    seconds_per_day = 86400
    # 30-day uniform spacing, starting at day 0
    time_seconds = np.array([epoch_2000 + i * 30 * seconds_per_day for i in range(12)], dtype=np.int32)
    climatology["time"] = ("time", time_seconds)
    climatology["time"].attrs = {
        "units": "seconds since 1970-01-01",
        "standard_name": "time",
        "calendar": "proleptic_gregorian",
    }
    
    # Add metadata
    climatology.attrs["title"] = "MODIS LAI Monthly Climatology"
    climatology.attrs["source"] = f"Averaged from Yuan et al. data ({min(years)}-{max(years)})"
    climatology.attrs["history"] = f"Created by get_modis_climatology.py"
    
    # Write output with explicit encoding to ensure integer time
    encoding = {
        "time": {"dtype": "int32"},
        "lai": {"dtype": "float32"},
    }
    climatology.to_netcdf(output_path, encoding=encoding)
    print(f"\nWrote climatology to {output_path}")
    print(f"  Years averaged: {min(years)}-{max(years)} ({len(years)} years)")
    
    # Plot all months
    month_names = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                   "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    
    fig, axes = plt.subplots(3, 4, figsize=(16, 10))
    axes = axes.flatten()
    
    lai = climatology["lai"]
    vmin, vmax = float(lai.min()), float(lai.max())
    
    for i, ax in enumerate(axes):
        data = lai.isel(time=i)
        im = ax.pcolormesh(climatology["lon"], climatology["lat"], data,
                          cmap="YlGn", vmin=vmin, vmax=vmax)
        ax.set_title(month_names[i])
        ax.set_aspect("equal")
        ax.set_xlim(-180, 180)
        ax.set_ylim(-90, 90)
    
    fig.suptitle(f"MODIS LAI Monthly Climatology ({min(years)}-{max(years)})", fontsize=14)
    fig.colorbar(im, ax=axes, label="LAI (m² m⁻²)", shrink=0.6)
    plt.tight_layout()
    
    # Save plot beside the netcdf
    plot_path = output_path.replace(".nc", ".png")
    fig.savefig(plot_path, dpi=150, bbox_inches="tight")
    print(f"Saved plot to {plot_path}")
    plt.close(fig)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Compute monthly climatology from yearly MODIS LAI files"
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
    get_modis_climatology(args.input_dir, args.output)
