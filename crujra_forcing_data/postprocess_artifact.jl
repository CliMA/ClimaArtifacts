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
        defDim(ds, "valid_time", length(mfds["valid_time"]))
        defDim(ds, "latitude", length(mfds["latitude"]))
        defDim(ds, "longitude", length(mfds["longitude"]))
        
        # Copy coordinate variables
        defVar(ds, "valid_time", mfds["valid_time"][:], ("valid_time",))
        ds["valid_time"].attrib["units"] = "seconds since 1901-01-01 00:00:00"
        ds["valid_time"].attrib["long_name"] = "time"
        ds["valid_time"].attrib["standard_name"] = "time"
        ds["valid_time"].attrib["calendar"] = "noleap"
        
        # Reverse latitude dimension so that elements are in increasing order
        lat_reversed = reverse(Float32.(mfds["latitude"][:]))
        defVar(ds, "latitude", lat_reversed, ("latitude",))
        ds["latitude"].attrib["units"] = "degrees_north"
        ds["latitude"].attrib["long_name"] = "latitude"
        ds["latitude"].attrib["standard_name"] = "latitude"
        
        defVar(ds, "longitude", Float32.(mfds["longitude"][:]), ("longitude",))
        ds["longitude"].attrib["units"] = "degrees_east"
        ds["longitude"].attrib["long_name"] = "longitude"
        ds["longitude"].attrib["standard_name"] = "longitude"
        
        # Copy data variables (reverse latitude dimension to match coordinate order)
        for var_name in var_names
            if haskey(mfds, var_name)
                # Reverse the latitude dimension (dims = 2)
                # Handle missing values by replacing with NaN
                raw_data = mfds[var_name][:, :, :]
                data = replace(raw_data, missing => NaN32)
                data = reverse(Float32.(data), dims=2)
                defVar(ds, var_name, data, ("valid_time", "latitude", "longitude"))
                
                # Copy important attributes
                if haskey(mfds[var_name].attrib, "units")
                    ds[var_name].attrib["units"] = mfds[var_name].attrib["units"]
                end
                if haskey(mfds[var_name].attrib, "long_name")
                    ds[var_name].attrib["long_name"] = mfds[var_name].attrib["long_name"]
                end
                if haskey(mfds[var_name].attrib, "standard_name")
                    ds[var_name].attrib["standard_name"] = mfds[var_name].attrib["standard_name"]
                end
                ds[var_name].attrib["_FillValue"] = NaN32
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
