#############################
# Lädt eod-Daten von yahoo.
# 26.07.2015
##########################

args <- commandArgs(trailingOnly = TRUE)

source("01_functions.R")

load_EoD_data(daten = args[1], output_eod = "data/EOD-Data_raw.RData")
prep_EoD_data(daten = "data/EOD-Data_raw.RData", output_eod = args[2])
