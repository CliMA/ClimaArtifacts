import Dates

"""
    contain_year(file::AbstractString, year::Dates.Date)

Return `true` if the file contain `year` and false otherwise.
"""
function contain_year(file::AbstractString, year::Dates.Date)
    year0_year1 = match(r"\d{6}-\d{6}", basename(file)).match
    year0 = Dates.Date(year0_year1[1:6], Dates.dateformat"yyyymm")
    year1 = Dates.Date(year0_year1[8:13], Dates.dateformat"yyyymm")
    return (year0 <= year) && (year <= year1)
end

"""
    model_name(file::AbstractString)

Return the model name or source id used to generate the data of the file.

The file name should follows the template:
`<variable_name>_<table_id>_<soure_id>_<experiment_id>_<member_id>_<grid_label>_<time_range>.nc`
"""
function find_model_name(file::AbstractString)
    return split(basename(file), "_")[3]
end
