# Read elevation file
elv_filename <- "~/Downloads/halfdeg.elv"
codos::grim2nc(elv_filename, "elv")
codos:::plot_map(elevations, lat, lon)
