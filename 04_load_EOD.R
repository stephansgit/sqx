#############################
# Lädt eod-Daten von yahoo.
# 26.07.2015
##########################

args <- commandArgs(trailingOnly = TRUE)

source("01_functions.R")

load_EoD_data(daten = args[1], output_eod = args[2])
