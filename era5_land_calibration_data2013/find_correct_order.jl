"""
    find_correct_order(fnames)

Takes in `fnames`, a list of file names of .nc files, and find the correct order
to stitch the datasets together as one dataset along the time dimension.
"""
function find_correct_order(fnames)
    first_days = []
    for fname in fnames
        nc = NCDataset(fname)
        first_day = first(nc["valid_time"])
        push!(first_days, first_day)
    end
    indices_to_sort = sortperm(first_days)
    return fnames[indices_to_sort]
end
