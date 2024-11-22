# Lehmann et al. 2008 Fig. 8 Evaporation Dataset
## Overview
This artifact contains one dataset: a .csv containing data corresponding
to the experiment displayed in figure 8 of Lehmann et al. 2008.

This experiment involves measuring the evaporation rate of water from
columns of varying heights, all containing coarse sand.
The dataset contains timeseries of the evaporation rate [mm/day]
throughout the duration of the experiment for each column height tested
(150mm, 250mm, and 350mm).
The experiment was run for 13 days, and the data is hourly starting 30 minutes
into the simulation.
For column heights of 150mm and 250mm, the last datapoint provided is at time
12 days 23 hours. For column height 350mm, the last datapoint is at time
12 days 18 hours. Additional details of the experimental setup are provided
in the paper.

This data is used by ClimaLand.jl as a quantitative comparison for
model-calculated evaporation.

## Dataset acquisition
This dataset was generously provided by the authors of the paper cited below
via email. It is hosted and distributed alongside the CliMA project with their consent.
Since this dataset was directly sent to CliMA developers by the authors, we
do not have a script to recreate the dataset, and it must be downloaded from
where it is hosted.

## Full citation:
Peter Lehmann, Shmuel Assouline, and Dani Or. "Characteristic lengths affecting
evaporative drying of porous media." Physical Review E 77.5 (2008): 056309
