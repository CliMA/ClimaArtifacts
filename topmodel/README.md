# Topographic Index Statistics for TOPMODEL Runoff
This artifact includes topographic index statistics derived from a high-resolution map of topographic index, found here:
Marthews, T.R., Dadson, S.J., Lehner, B., Abele, S., Gedney, N. (2015). High-resolution global topographic index values. NERC Environmental Information Data Centre. (Dataset). https://doi.org/10.5285/6b0c4358-2bf3-4924-aa8f-793d468b92bev

The raw data (high-resolution map) can be downloaded with this link: https://catalogue.ceh.ac.uk/download/6b0c4358-2bf3-4924-aa8f-793d468b92be?url=https%3A%2F%2Fcatalogue.ceh.ac.uk%2Fdatastore%2Feidchub%2F6b0c4358-2bf3-4924-aa8f-793d468b92be%2F6b0c4358-2bf3-4924-aa8f-793d468b92be.zip

but please note that you will be prompted to make an account with the UK Center for Ecology and Hydrology. The raw data is 12GB in size.

Citation for data:
Marthews, T.R., Dadson, S.J., Lehner, B., Abele, S., Gedney, N. (2015). High-resolution global topographic index values. NERC Environmental Information Data Centre. (Dataset). https://doi.org/10.5285/6b0c4358-2bf3-4924-aa8f-793d468b92be

The procedure for creating the map is described in the following:
 Marthews, T. R., Dadson, S. J., Lehner, B., Abele, S., and Gedney, N.: High-resolution global topographic index values for use in large-scale hydrological modelling, Hydrol. Earth Syst. Sci., 19, 91–104, https://doi.org/10.5194/hess-19-91-2015, 2015.

To create the data required by the TOPMODEL runoff scheme, we first download the data. Then, we run
`julia --project create_artifacts.jl nc_path`, where nc_path is the path to the downloaded data on your local machine.
This julia script partitions the Earth's surface into a grid of 1degree x 1degree areas. It computes
certain statistics of the topographic index using each point of the higher resolution map within each
1degree x  1 degree area. It therefore creates a
lower resolution (1degree x 1degree) map of each statistic. The final data product contains
data supplied by Natural Environment Research Council.

For more information on TOPMODEL, please see e.g.: Niu, Guo‐Yue, et al. "A simple TOPMODEL‐based runoff parameterization (SIMTOP) for use in global climate models." Journal of Geophysical Research: Atmospheres 110.D21 (2005).

License:
This resource is available under the Open Government Licence (OGL)

You must always use the following attribution statement to acknowledge the source of the information: "Contains data supplied by Natural Environment Research Council."

You must include any copyright notice identified in the metadata record for the Data on all copies of the Data, publications and reports, including but not limited to, use in presentations to any audience.

You will ensure that citation of any relevant key publications and Digital Object Identifiers identified in the metadata record for the Data are included in full in the reference list of any reports or publications that describe any research in which the Data have been used.

This product, High-resolution global topographic index values, has been created with use of data from the HydroSHEDS database which is © World Wildlife Fund, Inc. (2006-2013) and has been used herein under license. WWF has not evaluated the data as altered and incorporated within, High-resolution global topographic index values, and therefore gives no warranty regarding its accuracy, completeness, currency or suitability for any particular purpose. Portions of the HydroSHEDS database incorporate data which are the intellectual property rights of © USGS (2006-2008), NASA (2000-2005), ESRI (1992-1998), CIAT (2004-2006), UNEP-WCMC (1993), WWF (2004), Commonwealth of Australia (2007), and Her Royal Majesty and the British Crown and are used under license. The HydroSHEDS database and more information are available at http://www.hydrosheds.org.
