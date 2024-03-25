# ClimaArtifacts

Pre-processing pipelines for the input data used by the CliMA project.

Each folder (except for `ClimaArtifactsHelper.jl`) contains everything that is
needed to produce an artifact for CliMA:
- A readme to describe the details,
- `Project.toml` and a `Manifest.toml` files that describe the version of packages required,
- A `create_artifact.jl` Julia script to do the per-processing, optionally
  retrieving the data and creating an `Artifact.toml` entry.

To use, `cd` into the desired folder and run `julia --project
create_artifact.jl`.

The `ClimaArtifactsHelper.jl` contains shared functions used across the various
artifacts.

## Artifacts available

- Aerosol data for the year 2005 (monthly means averaged over the years 2000-2009) 
