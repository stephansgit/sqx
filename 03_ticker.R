#############################
# Liest die Ticker-Daten ein
# 26.07.2015
#########################

source("01_functions.R")

read_ticker_data(path_from_upload="/var/www/html/sqx.servebeer.com/vbt/upload/dateien/ticker.csv", 
                 path_for_standard="data/ticker.csv", 
                 output="data/SetupData.RData")
