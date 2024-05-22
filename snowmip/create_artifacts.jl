#Menard, Cecile; Essery, Richard (2019): ESM-SnowMIP meteorological and evaluation datasets at ten reference sites (in situ and bias corrected reanalysis data) [dataset]. PANGAEA, https://doi.org/10.1594/PANGAEA.897575, Supplement to: Menard, Cecile; Essery, Richard; Barr, Alan; Bartlett, Paul; Derry, Jeff; Dumont, Marie; Fierz, Charles; Kim, Hyungjun; Kontu, Anna; Lejeune, Yves; Marks, Danny; Niwano, Masashi; Raleigh, Mark; Wang, Libo; Wever, Nander (2019): Meteorological and evaluation datasets for snow modelling at 10 reference sites: description of in situ and bias-corrected reanalysis data. Earth System Science Data, 11(2), 865-880, https://doi.org/10.5194/essd-11-865-2019
using ClimaArtifactsHelper
using Downloads
using Base
using DelimitedFiles

outputdir = "snowmip"
if isdir(outputdir)
    @warn "$outputdir already exists. Content will end up in the artifact and may be overwritten."
    @warn "Abort this calculation, unless you know what you are doing."
else
    mkdir(outputdir)
end

file_url = "https://hs.pangaea.de/Projects/ESM-SnowMIP/ESM-SnowMIP_all.zip"
file_path = "ESM-SnowMIP_all.zip"
if !isfile(file_path)
    @info "$file_path not found, downloading it (might take a while)"
    file = Downloads.download(file_url)
    Base.mv(file, file_path)
    mycommand = `unzip $file_path -d $outputdir`
    run(mycommand)
end

# Create a metadata file in the same directory
site_name = ["name", "cdp", "oas", "obs", "ojp", "rme", "sap", "snb", "sod", "swa", "wfj"]
site_lat = ["lat", 45.29,  54.05, 54.650000, 54.530000 , 43.186000, 43.060000,37.906890, 26.590000, 37.906910,46.826700]
site_lon = ["lon", 5.7669,-106.3333,-105.200000,-116.783000,-116.783000, 141.328600,-107.726280, 26.590000,-107.711320, 9.807]
site_elev = ["elevation", 1325, 601, 629, 579, 2043, 17, 3714, 179, 3371, 2536]
site_class = ["class", "alpine", "boreal", "boreal", "boreal", "alpine", "maritime", "alpine", "artic", "alpine", "alpine"]
site_data = hcat(site_name, site_lat, site_lon, site_elev, site_class)

open(joinpath(outputdir, "site_metadata.txt"), "w") do io
    writedlm(io, site_data)
end

@info "Data file generated!"
create_artifact_guided(outputdir; artifact_name = basename(@__DIR__))
