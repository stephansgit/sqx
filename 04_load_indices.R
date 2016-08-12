#############################
# Beinhaltet Laderoutine für die Daten
# 20.08.2015
#########################

### Load packages and set options

options(scipen = 0, digits = 5) # set options to avoid scientific notation
options("getSymbols.warning4.0"=FALSE)
Sys.setenv(TZ="America/Chicago") # needs to be done in order to make sure, getSymbols works properly.
suppressPackageStartupMessages(library(googleVis))

library(googleVis)
library(ggplot2)
library(quantmod)
library(reshape2)
library(lubridate)

# Source die Parameter und die Funktionen später NOCH EINMAL, nach dem "rm"
source("01_functions.R")
source("02_parameters.R")
source("03_ticker.R")


### Import data from yahoo
length(symbols_yahoo)

#### Download Symbols in a list ####
# see: http://stackoverflow.com/questions/24377590/getsymbols-downloading-data-for-multiple-symbols-and-calculate-returns
stocks.sample <- lapply(symbols_yahoo, function(i) {
 try(getSymbols(i, from=StartDate, auto.assign=FALSE))
 }
 )
###==> das geht fast (download in Liste mit error handling). Jetzt noch sicherstellen, dass die anderen Indices gehen
# names(stocks.sample) <- symbols # give reasonable names to the list

try(getSymbols(symbols_yahoo[4:12], warnings=FALSE))

indices.zoo <- try(merge(Ad(DJIA), Ad(AORD), Ad(ATX), Ad(BVSP), Ad(FCHI), Ad(FTSE),  Ad(GDAXI), Ad(GSPTSE), Ad(HSI), Ad(IBEX), Ad(MERV), Ad(MXX), Ad(N225), Ad(SSEC), Ad(SSMI), Ad(STI)))
colnames(indices.zoo) <- c("USA", "Australia", "Austria", "Brasil", "France", "United Kingdom",  "Germany", "Canada", "HongKong", "Spain", "Argentina", "Mexico", "Japan", "China", "Switzerland", "Singapore")      
tail(indices.zoo)


getSymbols("^GSPC") #load S&P 500 data.
snp <- Ad(GSPC)

Sys.setenv(TZ="CET") # sets system time back to Europe; important for the deletion that follows

#--Download Russian data----------------------------
library(Quandl)
RTSI <- Quandl("YAHOO/INDEX_RTS_RS", type="xts", end_date='2016-06-30') # wieso auch immer hat Quandl die Daten danach unveraendert
library(RCurl)
URL <- "http://moex.com/iss/history/engines/stock/markets/index/securities/RTSI.csv?iss.only=history&iss.json=extended&callback=JSON_CALLBACK&from=2015-01-01&till=2016-12-31&lang=en&limit=100&start=0&sort_order=TRADEDATE&sort_order_desc=desc"
x <- getURL(URL)
#download.file(URL, destfile="rtsi.csv")
rtsi <- read.csv(textConnection(x), header=TRUE, skip=2, sep=";")
rtsi <- rtsi[,c("TRADEDATE", "CLOSE")] # drop irrelevant columns
rtsi$TRADEDATE <- ymd(rtsi$TRADEDATE) #convert to POSIXct
rtsi$TRADEDATE <- as.Date(rtsi$TRADEDATE) # convert to as.Date
ind <- data.frame(Date=index(RTSI),RTSI = Ad(RTSI)) # create new, temporary dataframe for Russia only
ind.m <- merge(x=ind, y=rtsi, by.x="Date", by.y="TRADEDATE", all=TRUE) # merge the Yahoo and the RTS data
ind.m <- as.xts(ind.m[,-1], order.by = ind.m$Date)

ind.m$Adjusted.Close[is.na(ind.m$Adjusted.Close)] <- ind.m$CLOSE[is.na(ind.m$Adjusted.Close)] # replace the NA data from quandl with data from RTS
indices.zoo$Russia <- ind.m$Adjusted.Close[paste0(start(indices.zoo),'::')] # add the new Russia data to the bigger data frame 
#--------


#---Download Italian data
#mib <- Quandl("YAHOO/INDEX_FTSEMIB_MI", type="xts", start=start(indices.zoo))
# or: https://www.quandl.com/api/v1/datasets/YAHOO/INDEX_FTSEMIB_MI.csv
# QUANDL seems instable, therefore we firts query Quandl. If that throws an error, we query yahoo.

italiandata <- new.env()

MIBfromQuandl <- function() {
  download.file("http://www.quandl.com/api/v1/datasets/YAHOO/INDEX_FTSEMIB_MI.csv", "MIB.csv", method="curl")
  mib <- read.csv("MIB.csv")
  mib$Date <- ymd(mib$Date)
  mib <- zoo(mib, order.by = mib$Date)[,-1]
  mib <- as.quantmod.OHLC(mib, col.names=c("Open", "High", "Low", "Close", "Volume", "Adjusted.Close")) 
  mib.zoo <-  Ad(mib)
}

MIBfromYahoo <- function() {
  getSymbols("FTSEMIB.MI", env = italiandata)
  mib.zoo <<-Ad(italiandata$FTSEMIB.MI)
  names(mib.zoo) <<- "Italy"
  print("Loading from Yahoo succesfull")
}


# tryCatch(MIBfromQuandl(),
#   error=function(e) MIBfromYahoo()) 
try(MIBfromYahoo())
 
indices.zoo <- merge(indices.zoo, mib.zoo)
#------------

# FTSE Data from Quandl of CONTINUOUS FUTURE
liffe_z2 <- Quandl("CHRIS/LIFFE_Z2")
liffe_z2.xts <- as.xts(liffe_z2$Settle, order.by = liffe_z2$Date)
indices.zoo <- merge(indices.zoo, liffe_z2.xts)


indices.zoo <- window(indices.zoo, start=StartDate, end=Sys.Date()-1) # delete current day, because it will contain NAs.

rm(list=setdiff(ls(), c("indices.zoo", "snp"))) # remove all raw data, just keep indices.zoo and the S&P Data

save(indices.zoo, file="data/indices_raw.RData")
### Check missing data
#   check.df <- data.frame(is.na(data.frame(coredata(indices.zoo))))
#   check.df$Date <- index(indices.zoo)
#   check.m <- melt(check.df, id.vars="Date", variable.name="Country", value.name="Missing_Quote")
#   ggplot(data=subset(check.m)) + geom_tile(aes(x=Date, y=Country, fill=Missing_Quote)) + theme_minimal()

### treat NAs
indices.zoo <- na.approx(zoo(indices.zoo), na.rm=TRUE) # interpolation happens for NAs
indices.zoo <- na.locf(indices.zoo) # any remaining NAs are being replaced by simple "roll forward"

source("01_functions.R")
source("02_parameters.R")

### calculate HBT
hbt <- hbt_calc(indices.zoo, lookback, smoothper)
hbt_world <- zoo(rowMeans(hbt), order.by=as.Date(index(hbt)))

### Save data
save(indices.zoo, hbt, hbt_world, snp, file="data/Indices_Data.RData")

