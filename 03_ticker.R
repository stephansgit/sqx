#############################
# Liest die Ticker-Daten ein
# merged 28.02.2017
#########################

##############
# HBT
##############
symbols_yahoo <- c( "DJIA", "^GDAXI", "^FCHI", "^SSMI", "^IBEX", "^SSEC", "^MXX", "^N225", "^AORD", "^ATX", "^GSPTSE", "^HSI", "^BVSP", "^MERV")


##############
# VBT
##############
args <- commandArgs(trailingOnly = TRUE)

source("01_functions.R")

read_ticker_data(path_from_upload=args[1], 
                 path_for_standard=args[2], 
                 output=args[3])
