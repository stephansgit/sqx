#############################
# Lädt die Intraday-Daten
# 26.07.2015
#############################

library(reshape2)
library(quantmod)
library(xts)
library(lubridate)

Sys.setenv(TZ="Europe/Berlin") # needs to be done in order to make sure, getSymbols works properly.

load(file="data/EOD-Data.RData")
source("01_functions.R")
loaded_symbols <- ls(envir=stocks)

#Get quotes from yahoo
quotes_raw_1 <- getQuote_json(loaded_symbols[1:100])
quotes_raw_2 <- getQuote_json(loaded_symbols[101:200])
quotes_raw_3 <- getQuote_json(loaded_symbols[201:300])
quotes_raw_4 <- getQuote_json(loaded_symbols[301:400])
quotes_raw_5 <- getQuote_json(loaded_symbols[401:500])
quotes_raw_6 <- getQuote_json(loaded_symbols[501:length(loaded_symbols)])
quotes_raw <- rbind(quotes_raw_1, quotes_raw_2, quotes_raw_3, quotes_raw_4, quotes_raw_5, quotes_raw_6)

#quotes_all <- getQuote2clean(quotes_raw)
quotes_all <- quotes_raw
quotes_all$Date = as.Date(quotes_all$Trade.Time)
#unique(tmp$Date)
lasttradingday <- as.Date(getQuote_DAX_json("^GDAXI")$Trade.Time) # use DAX quote to asses last German trading day
quotes_tday <- subset(quotes_all, Date==as.Date(lasttradingday)) # delete all quotes not from TODAY
no_act_quotes <- setdiff(quotes_all$Ticker, quotes_tday$Ticker)


#merge den snapshot-frame mit der Zeitreihe
quotes_tday.c <- dcast(data = quotes_tday, Date ~ Ticker, value.var = 'Volume')
quotes_tday.c <- quotes_tday.c[which(is.Date(quotes_tday.c$Date)),,drop=FALSE] # Filter nur Daten heraus, bspw wg NAs
#tmp.zoo<-read.zoo(tmp.c)

#Convert the xts to data.frame for the merge to follow
    #and first we need to check for duplicate entries in the index
    doubleindex <- which(duplicated(index(de_vol)))
    if (length(doubleindex)) {
      message(paste("Doppelte Eintraeg im Index:", length(doubleindex)))
      #is.na(de_vol[doubleindex, ])
      de_vol <- de_vol[ -doubleindex, ] # entferne die doppelten Einträge - ACHTUNG, das ist Holzammer, weil wir nicht prüfen, ob die NA sind oder so.
      message("Doppele Eintraege entfernt")
    } else {
      message("Keine doppelten Eintraege")
    } 

de_vol.df <- xts2df(de_vol)
#Merge
de_vol_intraday <- merge(de_vol.df, quotes_tday.c, by=intersect(names(de_vol.df), names(quotes_tday.c)), all=TRUE)
# wenn das am WE läuft, dann findet er die Zeitstempel für den Freitag 2-mal und wirft deswegen ein Warning: Fix hier:
de_vol_intraday <- read.zoo(de_vol_intraday)
if(wday(Sys.Date())==1 | wday(Sys.Date())==7) {
  de_vol_intraday <- de_vol_intraday[-dim(de_vol_intraday)[1],]  
}

save(de_vol_intraday, quotes_tday, no_act_quotes, file="data/Intraday-Data.RData")
# de_vol_intraday kann von der Hauptroutine nun genutzt werden

#-------------------------------------------
# Exportiere die Daten zum Debuggen
filename <- paste("data/intradayexport", as.numeric(Sys.time()),sep="_")
#save(de_vol_intraday, quotes_tday, quotes_tday.c, file=filename)
#-------------------------------------------

# Darstellen von Charts:
# assign() and eval() sind vielleicht hilfreich.

