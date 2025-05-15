# CMIP RMSEs

This artifacts contains the root mean square error (RMSE) in the seasonal climatology of
cloud radiative effect (computed by `rsutcs - rsut`) for different models in CMIP6 AMIP
experiments. The instructions to reproduce the RMSEs can be found in the section titled
"Computing RMSEs from CMIP Models".

The file produced is called `cre_rmse_amip_cre_amip_2010.csv` which contain the RMSE
averaged over one simulated year of 2010. The columns of the CSV file are the seasons `DJF`,
`MAM`, `JJA`, `SON`, and `ANN`. The rows are the models. All models available are used
except for `ICON-ESM-LR` whose native grid is unstructured and icosahedral.

# Computing RMSEs from CMIP Models

## Prerequisites
1. Python
2. Julia


# Steps to download CMIP model outputs

## Download CMIP model outputs

To download CMIP model outputs, we will use the python library (`esgf-download`)[https://github.com/ESGF/esgf-download].

TODO: Change rmses_thingy and move it to cmip_model_rmse

1. Change directory to `rmses_thingy` with `cd rmses_thingy`.

2. Create a python virtual environment using
```
python3 -m venv cmip_download
```

2. Activate the new virtual environment using
```
source cmip_download/bin/activate
```

3. Install the requirements with
```
pip install -r requirements.txt
```

TODO: Add link to esgpull documentation
4. To enable all the functionality of `esgpull`, use
```
esgpull self install cmip_download_esgpull
```

5. To download the files we need, we can run the command
```
esgpull add --distrib true --latest true --replica none --retracted false activity_id:CMIP experiment_id:amip frequency:mon mip_era:CMIP6 table_id:Amon variable_id:rsutcs,rsut variant_label:r1i1p1f1 \!data_node:esg-dn2.nsc.liu.se,esg-dn3.nsc.liu.se
```

Note that we exclude downloading data from `esg-dn2.nsc.liu.se` and `esg-dn3.nsc.liu.se` as
downloading from these nodes was not successful.

This adds a query. Then, we need track and update the query with the following commands.

```
esgpull track db2c58
esgpull update
```
Note that the query ID can be found with `esgpull show`.

6. To download the files, you can run `esgpull download --disable-ssl`. We use
`--disable-ssl`, because some data nodes have poor certificates that we need to disable
verification for. If everything goes well, all the files should be downloaded. If this is
not the case, read the section below to troubleshoot your issues.

# Troubleshooting

This section was written with version `0.7.3` for `esgpull` in mind. It could be the case
that there are other options to try for troubleshooting, which can be found in the
[documentation](https://esgf.github.io/esgf-download/) of `esgpull`.

## Not all the files are downloaded!

You can try `esgpull retry` and `esgpull download --disable-ssl`. This can happen when
the nodes are temporarily down. It may be worthwhile to try again at a later time.

Alternatively, the data nodes may be bad and they must be excluded as nodes to download
from. For more information, see this dicussion on GitHub:
https://github.com/ESGF/esgf-download/issues/61

1. Find the query ID using `esgpull show` and remove it using
`python esgpull_remove.py query_id`.

2. Identify the nodes that cannot be downloaded by inspecting the log file with the errors.
In particular, we are interested in the host names. For example, the host names could look
like this:

```
esg-dn2.nsc.liu.se
esg-dn3.nsc.liu.se
aims3.llnl.gov
esgf-data1.llnl.gov
cmip.bcc.cma.cn
esgf-data.ucar.edu
dist.nmlab.snu.ac.kr
dpesgf03.nccs.nasa.gov
esgf-data03.diasjp.net
cmip.dess.tsinghua.edu.cn
```

Note that the list above is not comprehensive.

3. Delete the current query with `esgpull remove QUERY_ID`. The query ID can be found by
`esgpull show`.

4. Then, add a query, but with the argument `\!data_node`. For example, this would be

```
esgpull add --distrib true --latest true --replica none --retracted false activity_id:CMIP experiment_id:amip frequency:mon mip_era:CMIP6 table_id:Amon variable_id:rsutcs,rsut variant_label:r1i1p1f1 \!data_node:esg-dn2.nsc.liu.se,esg-dn3.nsc.liu.se
```

5. Then, run

```
esgpull track QUERY_ID
esgpull update
esgpull download --disable-ssl
```

To find the query ID, you can use `esgpull show`.

You may need to do this multiple times, until all files are downloaded.

## For whatever reason, the `cmip_download.yaml` does not work anymore.

This could happen if the id of the query changed from the last time the command
was used, or the `cmip_download.yaml` was modified. To make a new one, run
```
esgpull add --distrib true --latest true --replica none --retracted false activity_id:CMIP experiment_id:amip frequency:mon mip_era:CMIP6 table_id:Amon variable_id:rsutcs,rsut variant_label:r1i1p1f1 \!data_node:esg-dn2.nsc.liu.se,esg-dn3.nsc.liu.se
esgpull show
```

Then, find the corresponding query and run the following command to generate a new yaml file.

```
esgpull show --yaml <QUERY ID>
```

## Compute RMSE with ClimaAnalysis

After the data is downloaded, we can compute the RMSEs of simulation data provided by the
CMIP models and observational data. The observational data will be the CERES radiation
data, which can be downloaded following the instructions in the directory `radiation_obs`.

To compute the RMSEs and save them in `cre_rmse_amip_cre_2010.csv`, you can run the
following command:

```
julia compute_rmse.jl <Directory to the CMIP model outputs> <File to observation data>
```

For example, the command could look like the following:

```
julia compute_rmse.jl cmip_download_esgpull/data CERES_EBAF_Ed4.2_Subset_200003-201910.nc
```

# Data Usage and Citation

CMIP6 model data is licensed under a Creative Commons Attribution 4.0 International License
(CC BY 4.0) or Creative Commons Zero 1.0 Universal (CC0 1.0) depending on the model. See
https://creativecommons.org/licenses/ for more information for both licenses. A list of the
corresponding license for each model is available at
https://wcrp-cmip.github.io/CMIP6_CVs/docs/CMIP6_source_id_licenses.html. Consult
https://pcmdi.llnl.gov/CMIP6/TermsOfUse for terms of use governing CMIP6 output, including
citation requirements and proper acknowledgment. Further information about this data,
including some limitations, can be found via the `further_info_url`. The data producers and
data providers make no warranty, either express or implied, including, but not limited to,
warranties of merchantability and fitness for a particular purpose. All liabilities arising
from the supply of the information (including any liability arising in negligence) are
excluded to the fullest extent permitted by law.
