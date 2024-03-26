# Aerosol data, monthly means, average from 2000 to 2009

This artifact repackages data coming from [CMIP5 recommended data](https://tntcat.iiasa.ac.at/RcpDb/dsd?Action=htmlpage&page=download) and
contains mass concentration for a variety of aerosols.

The input file is defined in hybrid pressure coordinates, as specified in the
[CF
conventions](https://cfconventions.org/Data/cf-conventions/cf-conventions-1.11/cf-conventions.html#_atmosphere_hybrid_sigma_pressure_coordinate).
We convert this into altitude over mean-sea level.

First, we compute the pressure coordinates $P = P_0 a(k) + P_S b(k)$. In the
file, this is $P_S$ = `PS`, b = `hymb`, $P_0$ = `P0`, a = `hyam`. Next, we assume an
hydrostatic profile and convert pressure to altitude over the mean sea level using $P = P^*
exp(-z / H)$ with scale height $H$. We assume $P^* = 1e5$ (Pa) and $H = 7000$
(m). Now, we select our target z, from 10m to 60km, and resample the aerosol
file to that target z. We use "copy" boundary conditions for those points that
are outside the range of definition. The values of these points should not
matter too much for runs with topography (because they are below the surface).
$P_S$ is a function of time, and we preserve that in interpolating to z. We also
shift the dates by 15 days so that the data is defined approximately in the
middle of the month as opposed to its last day.

The output is a NetCDF file that contains concentrations for a set of aerosols defined on a lon-lat-z-time grid.
