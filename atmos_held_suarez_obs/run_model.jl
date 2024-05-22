import YAML, ClimaAtmos as CA
config_dict = YAML.load_file(joinpath(@__DIR__, "model_config.yml"))
config = CA.AtmosConfig(config_dict)
simulation = CA.get_simulation(config)
CA.solve_atmos!(simulation)
