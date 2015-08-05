#############################
# Lädt eod-Daten von yahoo.
# 26.07.2015
##########################



stocks <- new.env()

# Loop 1: Find values as specified
for (i in 1:length(de_stocks)) {
  try(
    getSymbols(de_stocks[i], from=StartDate, env=stocks, verbose = FALSE, warnings = FALSE)
  )
  Sys.sleep(1)
}

# Loop 2: Replace exchanges of values not find with Frankfurt
de_stocks2 <- setdiff(de_stocks, ls(envir=stocks))
de_stocks2 <- gsub("\\..*$", ".F", de_stocks2) # replace the Xetra-suffix with Frankfurt suffix
for (i in 1:length(de_stocks2)) {
  try(
    getSymbols(de_stocks2[i], from=StartDate, env=stocks, verbose = FALSE, warnings = FALSE)
  )
  Sys.sleep(1)
}


# create lists of tickers requested and loaded; for comparison later
stocks_requested <- sub("(.*?)\\..*", "\\1", de_stocks)
stocks_loaded <- sub("(.*?)\\..*", "\\1", ls(envir=stocks))
# Entferne die nicht mehr benötigten Vektoren mit Tickersymbolen
rm(de_stocks)
rm(de_stocks2)

de_vol <- eapply(stocks, volUpDn) #volUpDn ist eine Eigendefinierte Funktion
de_vol <- lapply(de_vol, VolUpDn_extract) #volUpDn_extract ist eine Eigendefinierte Funktion
de_vol <- as.xts(do.call(merge, de_vol))
# adjust column names are re-order columns
colnames(de_vol) <- gsub("_VolUpDn","",colnames(de_vol))

de_vol[de_vol==0] <- NA # replace 0 with NA

# Speichert EOD-Daten
save(stocks_requested, stocks_loaded, de_vol, stocks, file="data/EOD-Data.RData")
