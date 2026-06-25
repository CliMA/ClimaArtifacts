# pycles_scm_les_data/create_artifact.jl
#
# Creates a Julia artifact containing the 7 PyCLES single-column LES reference
# NetCDF files used for SCM intercomparison plots in ClimaAtmos.jl.
#
# Usage (from the ClimaArtifacts root):
#   julia --project=pycles_scm_les_data pycles_scm_les_data/create_artifact.jl
#
# The script downloads all files from Caltech Box, bundles them into one
# artifact directory, and calls create_artifact_guided. You will be prompted
# to upload the generated tarball to Box (or another host), paste the direct
# download URL, and press ENTER.  The resulting OutputArtifacts.toml entry
# should then be copied to post_processing/Artifacts.toml in ClimaAtmos.jl.

using Downloads
using ClimaArtifactsHelper

# Each entry: (canonical filename inside the artifact, Box direct-download URL)
# Files are named to match the case_name used by edmf_scm_intercomparison.jl
# from PR https://github.com/CliMA/ClimaAtmos.jl/pull/4610.
# The script looks for <artifact_dir>/<case_name>.nc.
# See PyCLES readme on how to run the model: https://github.com/CliMA/pycles/blob/master/docs/source/running.rst
const FILES = [
    ("Bomex.nc",       "https://caltech.box.com/shared/static/jci8l11qetlioab4cxf5myr1r492prk6.nc"),
    ("Soares.nc",      "https://caltech.box.com/shared/static/pzuu6ii99by2s356ij69v5cb615200jq.nc"),
    ("GABLS.nc",       "https://caltech.box.com/shared/static/zraeiftuzlgmykzhppqwrym2upqsiwyb.nc"),
    ("DYCOMS_RF01.nc", "https://caltech.box.com/shared/static/toyvhbwmow3nz5bfa145m5fmcb2qbfuz.nc"),
    ("DYCOMS_RF02.nc", "https://caltech.box.com/shared/static/dgie1774uw5ot8mmrmp46nauhb3ervgp.nc"),
    ("Rico.nc",        "https://caltech.box.com/shared/static/johlutwhohvr66wn38cdo7a6rluvz708.nc"),
    ("TRMM_LBA.nc",    "https://caltech.box.com/shared/static/67uaebore3fc00k2hh82t520u4dtuvwz.nc"),
]

const OUTPUT_DIR = "pycles_scm_les_data_artifact"

if isdir(OUTPUT_DIR)
    @warn "$OUTPUT_DIR already exists. Existing files will be skipped; delete the folder to re-download."
else
    mkdir(OUTPUT_DIR)
end

for (filename, url) in FILES
    dest = joinpath(OUTPUT_DIR, filename)
    if isfile(dest)
        @info "$filename already present ($(round(filesize(dest)/1024^2, digits=1)) MB), skipping download"
    else
        @info "Downloading $filename …"
        tmp = Downloads.download(url; progress = download_rate_callback())
        Base.mv(tmp, dest)
        println()  # newline after progress output
        @info "Saved $filename ($(round(filesize(dest)/1024^2, digits=1)) MB)"
    end
end

@info "All 7 PyCLES reference files ready in $OUTPUT_DIR"
@info "Creating artifact (you will be prompted to upload the tarball) …"
create_artifact_guided(OUTPUT_DIR; artifact_name = "pycles_scm_les_data")
