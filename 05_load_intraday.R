#############################
# Lädt die Intraday-Daten
# 26.07.2015
#############################

library(reshape2)
library(quantmod)
library(xts)

Sys.setenv(TZ="Europe/Berlin") # needs to be done in order to make sure, getSymbols works properly.

load(file="EOD-Data.RData")
loaded_symbols <- ls(envir=stocks)

#Get quotes from yahoo
quotes_raw <- getQuote(loaded_symbols)


quotes_all <- getQuote2clean(quotes_raw)
quotes_all$Date = as.Date(quotes_all$Trade.Time)
#unique(tmp$Date)
lasttradingday <- as.Date(getQuote("^GDAXI")$'Trade Time') # use DAX quote to asses last German trading day
quotes_tday <- subset(quotes_all, Date==as.Date(lasttradingday)) # delete all quotes not from TODAY
no_act_quotes <- setdiff(quotes_all$Ticker, quotes_tday$Ticker)


#merge den snapshot-frame mit der Zeitreihe
quotes_tday.c <- dcast(data = quotes_tday, Date ~ Ticker, value.var = 'Volume')
quotes_tday.c <- quotes_tday.c[which(is.Date(quotes_tday.c$Date)),,drop=FALSE] # Filter nur Daten heraus, bspw wg NAs
#tmp.zoo<-read.zoo(tmp.c)

#Convert the xts to data.frame for the merge to follow
de_vol.df <- xts2df(de_vol)
#Merge
de_vol_intraday <- merge(de_vol.df, quotes_tday.c, by=intersect(names(de_vol.df), names(quotes_tday.c)), all=TRUE)
## de_stocks[grep("^[0-9]", de_stocks)] ##
de_vol_intraday <- read.zoo(de_vol_intraday)

save(de_vol_intraday, file="Intraday-Data.RData")
# de_vol_intraday kann von der Hauptroutine nun genutzt werden

#-------------------------------------------
# Exportiere die Daten zum Debuggen
filename <- paste("intradayexport", as.numeric(Sys.time()),sep="_")
save(de_vol_intraday, quotes_tday, quotes_tday.c, file=filename)
#-------------------------------------------

# Darstellen von Charts:
# assign() and eval() sind vielleicht hilfreich.

