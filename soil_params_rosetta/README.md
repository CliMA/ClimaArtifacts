# Soil parameters for hydrology from ROSETTA
This artifact repackages data from Montzka, C et al. (2017): A global data set of soil hydraulic properties and sub-grid variability of soil water retention and hydraulic conductivity curves. Earth System Science Data, 9(2), 529-543, https://doi.org/10.5194/essd-9-529-2017.

The raw data can be downloaded at this link:
https://doi.pangaea.de/10.1594/PANGAEA.870605


The raw data includes the saturated hydraulic conductivity $K_{sat}$, the porosity $\nu$,
residual water content $\theta_{res}$, and van Genuchten parameters $\log (\alpha)$ and $n$ at seven
depths and at 0.25deg x 0.25deg resolution.
The `create_artifacts.jl` script
- combines the data at different depths into a single file
- applies data transformations (e.g. unit conversions)

License: Creative Commons Attribution 4.0 International