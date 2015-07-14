# Script for merging end-of-day data and intraday data
# Aufwand: 4hr
#load("~/Dropbox/Privates/Skripte_ab_072014/Boerse/VolBreakout/intraday.RData")
library(lubridate)
library(xts)
library(quantmod)

#Sys.setenv(TZ="Europe/Berlin") # needs to be done in order to make sure, getSymbols works properly.

# lies Daten ein. Mache es mit einer "try"-Schleife
# getQuote(xxx, what=yahooQF("Volume"))
loaded_symbols <- ls(envir=stocks)

tmp.qte <- getQuote(loaded_symbols)
# stelle sicher, dass NAs usw richtig sind.

getQuote2clean <- function(x) {
  x <- transform(x, Last=as.numeric(Last),
                      Change=as.numeric(Change),
                     Open=as.numeric(Open),
                    High=as.numeric(High),
                      Low=as.numeric(Low),
                     Volume=as.numeric(Volume))
  x$Volume <- x$Volume * sign(ifelse((x$Open- x$Last)!=0, x$Last - x$Open, 0.01))
  x$Ticker <- row.names(x)
  #x$Tradetime <- x$Trade.Time
  hour(x$Trade.Time) <- ifelse(
                            (hour(x$Trade.Time)>=0 & hour(x$Trade.Time)<9),
                            hour(x$Trade.Time) + 12,
                            hour(x$Trade.Time)
                            )
  return(x)
  }

tmp.1 <- getQuote2clean(tmp.qte)
tmp.1$Date = as.Date(tmp.1$Trade.Time)
#unique(tmp$Date)
lasttradingday <- as.Date(getQuote("^GDAXI")$'Trade Time') # use DAX quote to asses last German trading day
tmp <- subset(tmp.1, Date==as.Date(lasttradingday)) # delete all quotes not from TODAY
no_act_quotes <- setdiff(tmp.1$Ticker, tmp$Ticker)


#merge den snapshot-frame mit der Zeitreihe
library(reshape2)
tmp.c <- dcast(data = tmp, Date ~ Ticker, value.var = 'Volume')
tmp.c <- tmp.c[which(is.Date(tmp.c$Date)),,drop=FALSE] # Filter nur Daten heraus, bspw wg NAs
#tmp.zoo<-read.zoo(tmp.c)
#Convert the xts to data.frame for the merge to follow
de_vol.df <- xts2df(de_vol)

#Merge
x <- merge(de_vol.df, tmp.c, by=intersect(names(de_vol.df), names(tmp.c)), all=TRUE)
## de_stocks[grep("^[0-9]", de_stocks)] ##
x <- read.zoo(x)

filename<-paste("intradayexport", as.numeric(Sys.time()),sep="_")
save(x, tmp, tmp.c, file=filename)

# "x" kann nun also weiter in das normale Skript überführt werden. Das einzige, was noch zu tun ist, sind die Tocker, die mit einer Zahl starten, zu säubern.
# UND: Wie kann ich die Charts darstellen?
#subset(tmp, Ticker==info[1])

#get(info[1], envir=stocks)
#stocks$info[1]
# assign() and eval() sind vielleicht hilfreich.

