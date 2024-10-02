# ETOPO Downloader 
using Downloads
using Glob
import ClimaAtmos as CA
import ClimaCore as CC
import ClimaParams as C
import ClimaCore.Utilities as CCU
import ClimaComms as ClimaComms
import ClimaParams as CP
import ClimaCore.Quadratures
using ClimaUtilities: SpaceVaryingInputs
using NCDatasets
using Interpolations
using Statistics:mean 

"""
    run_download(target_dir; elev_type="surface")
The ETOPO2022 dataset is available in a series of 284 panels, 
each with 3600x3600 npoints (Total npts = 3680640000).

Data Product: https://www.ncei.noaa.gov/products/etopo-global-relief-model
Panel boundaries are identified by file-names with 
`N<X>E<Y>` or `S<X>W<Y>` strings in filenames designating lat,lon extents. 

Surface elevation maps are available with representations of either 
bedrock ('bed') or ice-surface ('surface'). Here we use Julia download 
to get the appropriate source panels.
"""
function run_download(target_dir=mktempdir(); elev_type="surface")
    @assert elev_type == "surface" || "bed"
    prefix = "ETOPO_2022_v1_15s_"
    suffix = "_"*elev_type*".nc"
    id1 = ["N", "S"]
    id2 = ["E", "W"]
    lat = 0:15:90
    lon = 0:15:180
    attempts = 0 
    failed_downloads = 0
    for ii in id1
        for latid in lat
            for jj in id2
                for lonid in lon
                    (jj == "S" && latid == 0) && continue
                    filename=prefix*ii*lpad(string(latid), 2, '0')*jj*lpad(string(lonid), 3, '0')*suffix
                    try 
                        attempts += 1
                        url_loc = "https://www.ngdc.noaa.gov/thredds/fileServer/global/ETOPO2022/15s/15s_surface_elev_netcdf/"
                        Downloads.download(url_loc*filename, target_dir*filename)
                    catch 
                        failed_downloads += 1
                        @warn "No $(filename) file found."
                    end
                end
            end
        end
    end
    # We expect 288 files!
    filelist =  glob("*.nc", target_dir);
    if length(filelist != 288)
        @warn "Some panels were not downloaded successfully. Please verify host data access"
    end
    return filelist
end

function SpaceVaryingInputs.SpaceVaryingInput(
    data_x::NC,
    data_y::NC,
    data_z::NC,
    space::S,
    target_field::F, 
) where {S <: CC.Spaces.SpectralElementSpace2D, 
         NC <: NCDatasets.CommonDataModel.CFVariable, 
         F <: CC.Fields.Field}
    # convert to appropriate device type
    device = ClimaComms.device(space)
    AT = ClimaComms.array_type(device)
    data_x = AT(data_x)
    data_y = AT(data_y) 
    data_z = AT(data_z)
    xvalues = CC.Fields.coordinate_field(space).long
    yvalues = CC.Fields.coordinate_field(space).lat
    xmin, xmax = extrema(data_x)
    ymin, ymax = extrema(data_y)
    Δx = diff(data_x)[1]
    Δy = diff(data_y)[1]
    regrid_field = linear_interpolation(
           (data_x, data_y),
           data_z,
           extrapolation_bc = (Interpolations.Flat(), Interpolations.Flat()),
    )
    # Do nothing if the horizontal spectral space coordinates lie 
    # outside the extents of a given source panel.
    target_field .= ifelse.(check_extents.(xmin .- Δx,xmax .+ Δx,xvalues,
                                           ymin .- Δy,ymax .+ Δy,yvalues), 
                                           regrid_field.(xvalues, yvalues), 
                                           target_field) 
    return target_field
end


"""
    check_extents(xmin,xmax,x, ymin,ymax,y)
Check that specified variables x and y lie within some bounds 
xmin, xmax (for x) and ymin,ymax (for y). We use this to verify that the 
curently considered coordinates are within the limits of a specific 
topography (ETOPO2022) source panel.
"""
function check_extents(xmin,xmax,x,ymin,ymax,y)
    (xmin <= x <= xmax && ymin <= y <= ymax) ? true : false
end

"""
    land_elevation(elevation_map)
Set all oceans to zero elevation, preserve elevation profiles on 
land (note that Death Valley and similar low-lying regions need
to be treated separately!)
"""
function land_elevation(elevation_map)
    ifelse.(elevation_map .< Float32(0), Float32(0), elevation_map)
end

"""
    ocean_bed(elevation_map)
Mask out land and return the ocean surface profile.
"""
function ocean_bed(elevation_map)
    ifelse.(elevation_map .> Float32(0), Float32(0), elevation_map)
end

"""
    filter_oceans(elevation_map)
Return binary map with 1 (ocean), 0 (otherwise)
"""
function filter_oceans(elevation_map)
    ifelse.(elevation_map .< Float32(0), Float32(1), Float32(0))
end

"""
    filter_land(elevation_map)
Return binary map with 1 (land), 0 (otherwise)
"""
function filter_land(elevation_map)
    ifelse.(elevation_map .< Float32(0), Float32(0), Float32(1))
end

"""
    filter_sea_ice(elevation_map)
Return binary map with 1 (sea-ice), 0 (otherwise)
"""
function filter_sea_ice(elevation_map)
    @error "Mask data currently unavailable"
end

"""
    filter_inland_lakes(elevation_map)
Return binary map with 1 (inland lakes), 0 (otherwise)
"""
function filter_inland_lakes(elevation_map)
    @error "Mask data currently unavailable"
end

## Explicitly defines the object that replicates InterpolationRegridder
"""
    generate_elevation_map_itp_regrid(; h_elem=32)
Given a kwarg number of elements per cubed-sphere face (by default 32),
generate the horizontal space using ClimaCore, and regrid, using the 
InterpolationRegridder, the source dataset onto the target horizontal space.

Estimated `@time` to generate field (serial itp): 
@time generate_elevation_map_itp_regrid(;h_elem=<>)

h = 8 : 57 seconds
h = 16 : 112 seconds.
h = 512 : 1308 seconds. 

In normal usage, users can generate a single high-resolution representation 
of the Earth's topography and regrid to coarser meshes as necessary using 
ClimaCore's built-in regridders. 

e.g. 15 arc-second elevation data is available in 288 panels, each 
with 3600 × 3600 grids, equivalent to ≈15 degree patches in `lon-lat`
coordinates. 

The output from `generate_elevation_map_itp_regrid()` can then 
be passed as an argument to `ClimaCore.Hypsography.diffuse_surface_elevation!`
to apply smoothing on the `SpectralElement2D` grid using `ClimaCore.Operators`.
Writes data to HDF5 output

"""
function generate_elevation_map_itp_regrid(filelist; h_elem=32)
   FT = Float32
   param_dict = CP.create_toml_dict(FT)
   params = CP.get_parameter_values(param_dict, ["planet_radius"])
   cubed_sphere_mesh = CA.cubed_sphere_mesh(; radius=params.planet_radius, h_elem)
   quad = Quadratures.GLL{4}()
   comms_ctx = ClimaComms.SingletonCommsContext()
   h_space = CA.make_horizontal_space(cubed_sphere_mesh, quad, comms_ctx, true)
   @assert h_space isa CC.Spaces.SpectralElementSpace2D
   coords = CC.Fields.coordinate_field(h_space)
   target_field = CC.Fields.zeros(h_space)
   for file in filelist 
       NCDataset(file) do data
           source_lat = data["lat"]
           source_lon = data["lon"]
           source_elev = data["z"]
           target_field .= SpaceVaryingInputs.SpaceVaryingInput(source_lon, 
                                                               source_lat, 
                                                               source_elev, 
                                                               h_space, 
                                                               target_field)
       end
   end
    
   return target_field
end

function create_artifacts(; h_elem=256)
end
