# PyCLES SCM LES reference data

Single-column model (SCM) intercomparison reference data from
[PyCLES](https://github.com/CliMA/pycles) large-eddy simulations
(code under GNU General Public License v3.0)
The following canonical test cases used in ClimaAtmos.jl are included:

| File | Case |
|---|---|
| `Bomex.nc` | BOMEX shallow-cumulus |
| `Soares.nc` | Soares dry convective boundary layer |
| `GABLS.nc` | GABLS stable boundary layer |
| `DYCOMS_RF01.nc` | DYCOMS RF01 stratocumulus (no drizzle) |
| `DYCOMS_RF02.nc` | DYCOMS RF02 stratocumulus (with drizzle) |
| `Rico.nc` | RICO trade-wind cumulus |
| `TRMM_LBA.nc` | TRMM LBA deep convection (new-format Stats export) |

## Recreating the artifact

```bash
cd /path/to/ClimaArtifacts
julia --project=pycles_scm_les_data pycles_scm_les_data/create_artifact.jl
```

You will be prompted to upload the generated `pycles_scm_les_data_artifact.tar.gz`
to Box (or another host) and paste the direct download URL.
Copy the resulting `OutputArtifacts.toml` content to
`post_processing/Artifacts.toml` in `ClimaAtmos.jl`.
