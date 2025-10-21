using Dates

"""
    postprocess_artifact(mfds::NCDataset, fileout::String)

Postprocess CRUJRAv2.5 forcing data by stitching monthly files together into annual files.

# Arguments
- `mfds`: Multi-file NCDataset containing monthly data
- `fileout`: Output file path for the annual file

# Post-processing steps:
- Stitch 12 monthly files into a single annual file
- Reverse latitude dimension so latitudes are in increasing order (for ClimaLand compatibility)
- Preserve variable attributes (units, long_name, standard_name, _FillValue)
- Convert data variables to Float32 (time remains Int64)
- Update global attributes with processing history and metadata
- Ensure CF-1.8 compliance
"""
function postprocess_artifact(mfds, fileout::String)
    # Variables to copy
    var_names = ["t2m", "sp", "d2m", "msdwlwrf", "msdwswrf", "msdrswrf", 
                 "mtpr", "msr", "rainrate", "wind"]
    
    # Create output dataset
    NCDataset(fileout, "c") do ds
        # Define dimensions
        defDim(ds, "time", length(mfds["valid_time"]))
        defDim(ds, "lon", length(mfds["longitude"]))
        defDim(ds, "lat", length(mfds["latitude"]))
        
        # Create coordinate variables
        time_var = defVar(ds, "time", Int64, ("time",))
        time_var[:] = mfds["valid_time"][:]
        time_var.attrib["units"] = "seconds since 1901-01-01 00:00:00"
        time_var.attrib["long_name"] = "time"
        time_var.attrib["standard_name"] = "time"
        time_var.attrib["calendar"] = "noleap"
        
        # Reverse latitude dimension so elements are in increasing order
        lat_reversed = reverse(Float32.(mfds["latitude"][:]))
        lat_var = defVar(ds, "lat", Float32, ("lat",))
        lat_var[:] = lat_reversed
        lat_var.attrib["units"] = "degrees_north"
        lat_var.attrib["long_name"] = "latitude"
        lat_var.attrib["standard_name"] = "latitude"
        
        lon_var = defVar(ds, "lon", Float32, ("lon",))
        lon_var[:] = Float32.(mfds["longitude"][:])
        lon_var.attrib["units"] = "degrees_east"
        lon_var.attrib["long_name"] = "longitude"
        lon_var.attrib["standard_name"] = "longitude"
        
        # Copy data variables (reverse latitude dimension to match coordinate order)
        for var_name in var_names
            if haskey(mfds, var_name)
                # Define variable
                data_var = defVar(ds, var_name, Float32, ("lon", "lat", "time"))
                
                # Copy attributes
                if haskey(mfds[var_name].attrib, "units")
                    data_var.attrib["units"] = mfds[var_name].attrib["units"]
                end
                if haskey(mfds[var_name].attrib, "long_name")
                    data_var.attrib["long_name"] = mfds[var_name].attrib["long_name"]
                end
                if haskey(mfds[var_name].attrib, "standard_name")
                    data_var.attrib["standard_name"] = mfds[var_name].attrib["standard_name"]
                end
                data_var.attrib["_FillValue"] = NaN32
                
                # Read and process data
                # NCDatasets automatically reorders to match dimnames
                # For these variables, dimnames = ("longitude", "latitude", "valid_time")
                # So raw_data is already (lon, lat, time) = (720, 360, 1460)
                raw_data = mfds[var_name][:, :, :]  # Already (lon, lat, time)
                
                # Replace missing with NaN and convert to Float32
                data_clean = Float32.(replace(raw_data, missing => NaN32))
                
                # Reverse latitude dimension (from 89.75→-89.75 to -89.75→89.75)
                # Lat is dimension 2
                data_var[:, :, :] = reverse(data_clean, dims=2)
            else
                @warn "Variable $var_name not found in source dataset"
            end
        end
        
        # Add global attributes
        ds.attrib["title"] = "CRUJRAv2.5 Forcing Data for ClimaLand"
        ds.attrib["institution"] = "Climatic Research Unit, University of East Anglia; Japan Meteorological Agency"
        ds.attrib["source"] = "CRUJRAv2.5 reformat"
        ds.attrib["grid_resolution"] = "0.5x0.5 degree (lat x lon)"
        ds.attrib["grid_size"] = "latitude=360, longitude=720"
        ds.attrib["history"] = "$(now()): Processed for ClimaArtifacts - monthly files stitched into annual file"
        ds.attrib["references"] = "Harris et al. (2020), Kobayashi et al. (2015), Weedon et al. (2014)"
        ds.attrib["Conventions"] = "CF-1.8"
        ds.attrib["comment"] = "6-hourly meteorological forcing data combining CRU TS and JRA-55 reanalysis"
    end
end
