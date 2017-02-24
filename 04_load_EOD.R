#############################
# Lädt eod-Daten von yahoo.
# 26.07.2015
##########################

source("01_functions.R")

load_EoD_data(daten = "data/SetupData.RData", output="data/EOD-Data.RData")
