#############################
# Beinhaltet Parameter im Rahmen des VBT und HBT -Projekts
# merged 28.02.2017
#############################

# Startdatum für Historie VBT
StartDate_vbt <- as.Date("2015-01-01")
StartDate_hbt <- as.Date("2007-01-01")

#### Symbole für HBT Indizes
symbols_yahoo <- c( "DJI", "^GDAXI", "^FCHI", "^SSMI", "^IBEX", "^SSEC", "^MXX", "^N225", "^AORD", "^ATX", "^GSPTSE", "^HSI", "^BVSP", "^MERV")


# Parameter für Berechnungen
lookback_vbt <- 40
lookback_hbt <- 27
trigger_vbt <- 3
smoothper_hbt <- 10


