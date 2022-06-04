#############################
# Präpariert die daten
# 04.06.2022
##########################

args <- commandArgs(trailingOnly = TRUE)

source("01_functions.R")

prep_EoD_data(daten = args[1], output_eod = args[2])
