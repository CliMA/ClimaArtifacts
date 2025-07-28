"""
This script generates the unit test data for the P-model using the R package `rpmodel`. 
It saves the inputs and expected outputs to csv files. These files are then used to validate
the P-model implementation in ClimaLand. To run this file, first install the `rpmodel` package 
in R by typing install.packages('rpmodel') in the R terminal. Then, to run this script, do
Rscript pmodel_test.r in the terminal. 

Citation:
Stocker, B. D., Wang, H., Smith, N. G., Harrison, S. P., Keenan, T. F., Sandoval, D., 
Davis, T., and Prentice, I. C.: P-model v1.0: an optimality-based light use efficiency
model for simulating ecosystem gross primary production, Geosci. Model Dev., 13, 
1545–1581, https://doi.org/10.5194/gmd-13-1545-2020, 2020.
"""

library(rpmodel)

testcases <- list(
    "default_wang17" = list( 
        tc             = 20,
        vpd            = 1000,
        co2            = 400,
        fapar          = 1, 
        ppfd           = 300,
        patm           = 101325,
        kphio          = 0.049977, # this is constant
        beta           = 146,
        c4             = FALSE,
        method_jmaxlim = "wang17",
        do_ftemp_kphio = FALSE,
        do_soilmstress = FALSE,
        verbose        = FALSE
    ), 
    "temp_dependent_phi" = list(
        tc             = 20,
        vpd            = 1000,
        co2            = 400,
        fapar          = 1, 
        ppfd           = 300,
        patm           = 101325,
        kphio          = 0.081785, # this is the constant FACTOR for temp-dependent phi
        beta           = 146,
        c4             = FALSE,
        method_jmaxlim = "wang17",
        do_ftemp_kphio = TRUE,
        do_soilmstress = FALSE,
        verbose        = FALSE
    ), 
    "soil_moisture_stress" = list(
        tc             = 20,
        vpd            = 1000,
        co2            = 400,
        fapar          = 1, 
        ppfd           = 300,
        patm           = 101325,
        kphio          = 0.049977, # this is constant
        beta           = 146,
        c4             = FALSE,
        soilm          = 0.1, 
        method_jmaxlim = "wang17",
        do_ftemp_kphio = FALSE,
        do_soilmstress = TRUE,
        verbose        = FALSE
    ),
    "temp_dep_phi_and_soil_moisture" = list(
        tc             = 30,
        vpd            = 1000,
        co2            = 400,
        fapar          = 1, 
        ppfd           = 300,
        patm           = 101325,
        kphio          = 0.081785, # this is the constant FACTOR for temp-dependent phi
        beta           = 146,
        c4             = FALSE,
        soilm          = 0.1, 
        method_jmaxlim = "wang17",
        do_ftemp_kphio = TRUE,
        do_soilmstress = TRUE,
        verbose        = FALSE
    )
)


if (!dir.exists("testcases")) {
    dir.create("testcases")
}

# Initialize lists to store all results
all_inputs <- list()
all_outputs <- list()
testcase_names <- c()

for (name in names(testcases)) {
    print(sprintf("Running testcase: %s", name))
    inputs <- testcases[[name]]    
    outputs <- do.call(rpmodel, inputs)
    
    # Store results
    all_inputs[[name]] <- inputs
    all_outputs[[name]] <- outputs
    testcase_names <- c(testcase_names, name)
}

# Get all unique parameter names across all test cases
all_param_names <- unique(unlist(lapply(all_inputs, names)))

# Create a standardized inputs data frame
inputs_list <- list()
for (i in seq_along(testcase_names)) {
    name <- testcase_names[i]
    inputs <- all_inputs[[name]]
    
    # Create a row with all parameters, filling missing ones with NA
    row_data <- list(testcase = name)
    for (param in all_param_names) {
        if (param %in% names(inputs)) {
            val <- inputs[[param]]
            # Convert logical values to integers for better compatibility
            if (is.logical(val)) {
                row_data[[param]] <- as.integer(val)
            } else {
                row_data[[param]] <- val
            }
        } else {
            row_data[[param]] <- NA
        }
    }
    inputs_list[[i]] <- row_data
}

# Convert to data frame
inputs_df <- do.call(rbind, lapply(inputs_list, data.frame, stringsAsFactors = FALSE))

# Convert outputs to data frame
outputs_df <- data.frame(
    testcase = testcase_names,
    do.call(rbind, lapply(all_outputs, function(x) {
        data.frame(x, stringsAsFactors = FALSE)
    })),
    stringsAsFactors = FALSE
)

# Write inputs to CSV file
write.csv(inputs_df, "testcases/inputs.csv", row.names = FALSE)

# Write outputs to CSV file  
write.csv(outputs_df, "testcases/outputs.csv", row.names = FALSE)

# Write combined data to CSV file
combined_df <- merge(inputs_df, outputs_df, by = "testcase")
write.csv(combined_df, "testcases/combined.csv", row.names = FALSE)

print("Data written to CSV files:")
print("- testcases/inputs.csv (input parameters)")
print("- testcases/outputs.csv (output results)")
print("- testcases/combined.csv (inputs and outputs combined)")
