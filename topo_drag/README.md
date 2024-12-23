# `topo_drag.res.nc`

`topo_drag.res.nc` contains the matrix tensor `T`, as well as `hmax` and `hmin` as defined
in [(Garner, 2005)](https://doi.org/10.1175/JAS3496.1). All relevent information about the
topology, including amplitude, variance, orientation, and anisotropy, is contained in `T`.

## Dimensions

- `bnds`: has length of 2 and indicates lower and upper bounds
- `Time`: this is a singleton dimension
- `lat`: has length of 180
- `lon` has length of 288

## Variables

- `lat` (`lat`): latitude defined in degrees N
- `lon` (`lon`): longitude defined in degrees E
- `lat_bnds` (`bnds` x `lat`): the lower and upper bounds represented by each `lat`
- `lon_bnds` (`bnds` x `lon`): the lower and upper bounds represented by each `lon`
- `t11` (`lon` x `lat` x `time`)
- `t12` (`lon` x `lat` x `time`)
- `t21` (`lon` x `lat` x `time`)
- `t22` (`lon` x `lat` x `time`)
- `hmin` (`lon` x `lat` x `time`)
- `hmax` (`lon` x `lat` x `time`)

## Data Citation

<https://doi.org/10.22033/ESGF/CMIP6.1401>
