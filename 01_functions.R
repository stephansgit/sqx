#############################
# Beinhaltet Funktionen im Rahmen des HBT und VBT VB-Projekts
# merged 28.02.2017
#############################

library(xts)
library(quantmod)

#### Allgemeines ####
# Konvertiert xts-Objekt in einen data.frame
xts2df <- function(x) {
  tmp <- data.frame(Date=index(x), coredata(x))
  return(tmp)
}


#### VBT ####
read_ticker_data <- function(path_from_upload="/var/www/html/sqx.servebeer.com/vbt/upload/dateien/ticker.csv", path_for_standard="data/ticker.csv", output="data/SetupData.RData") {
  #lies die Default-Daten ein
  ticker <- read.csv(path_for_standard,header=TRUE) #lies das spreadsheet ein
  
  # versuche vom Upload Folder zu lesen
  try(
    ticker <- read.csv(path_from_upload, header=TRUE),
    silent=TRUE
  )
  
  # Kreiert einen Vektor aus den Tickersymbolen.
  de_stocks <- as.vector(unlist(ticker[,1]))
  
  save(list=ls(all=TRUE), file=output)
  
}

load_EoD_data <- function(daten = "data/SetupData.RData", output_eod="data/EOD-Data.RData") {
  load(daten)
  source("02_parameters.R")
  
  stocks <- new.env()
  
  # Loop 1: Find values as specified
  for (i in 1:length(de_stocks)) {
    try(
      getSymbols(de_stocks[i], from=StartDate_vbt, env=stocks, verbose = FALSE, warnings = FALSE)
    )
    Sys.sleep(1)
  }
  
  # Loop 2: Replace exchanges of values not find with Frankfurt
  de_stocks2 <- setdiff(de_stocks, ls(envir=stocks))
  de_stocks2 <- gsub("\\..*$", ".F", de_stocks2) # replace the Xetra-suffix with Frankfurt suffix
  for (i in 1:length(de_stocks2)) {
    try(
      getSymbols(de_stocks2[i], from=StartDate_vbt, env=stocks, verbose = FALSE, warnings = FALSE)
    )
    Sys.sleep(1)
  }
  message("Downloading done")
  
  # create lists of tickers requested and loaded; for comparison later
  stocks_requested <- sub("(.*?)\\..*", "\\1", de_stocks)
  stocks_loaded <- sub("(.*?)\\..*", "\\1", ls(envir=stocks))
  # Entferne die nicht mehr benötigten Vektoren mit Tickersymbolen
  rm(de_stocks)
  rm(de_stocks2)
  
  message("Tidying the data....")
  de_vol <- eapply(stocks, volUpDn) #volUpDn ist eine Eigendefinierte Funktion
  de_vol <- lapply(de_vol, VolUpDn_extract) #volUpDn_extract ist eine Eigendefinierte Funktion
  de_vol <- as.xts(do.call(merge, de_vol))
  # adjust column names are re-order columns
  colnames(de_vol) <- gsub("_VolUpDn","",colnames(de_vol))
  
  de_vol[de_vol==0] <- NA # replace 0 with NA
  
  # Load full names from Yahoo
  message("Loading full names...")
  fullnames <- getQuote(names(de_vol), what=yahooQF("Name"))
  fullnames <- data.frame(Ticker=rownames(fullnames), Name=fullnames$Name)
  
  
  # Speichert EOD-Daten
  message("Saving...")
  message("Output path is ", output_eod)
  save(stocks_requested, stocks_loaded, de_vol, stocks,fullnames, file=output_eod)
  
}

#function to calculate Volumen dependant on up or downmove of prices
volUpDn <- function(x) {
  x$VolUpDn <- Vo(x) * sign(ifelse(OpCl(x)!=0, Cl(x)-Op(x), 0.01))
  nm <- gsub(".Open", "", colnames(x)[1])
  colnames(x)[colnames(x)=="VolUpDn"] <- paste(nm, "VolUpDn", sep="_")
  x
}

# Extrahiert die VolUpDn-Spalte
VolUpDn_extract <- function(x) { #function to extract the newly created VolUpDn-colum
  tmp <- x[,grep("VolUpDn", colnames(x), ignore.case=TRUE)]
  tmp
  #stop("subscript out of bounds: no column name containing \"VolUpDn\"")
}


# säubert einen Quote von getQuote
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
  lubridate::hour(x$Trade.Time) <- ifelse(
    (lubridate::hour(x$Trade.Time)>=0 & lubridate::hour(x$Trade.Time)<9),
    lubridate::hour(x$Trade.Time) + 12,
    lubridate::hour(x$Trade.Time)
  )
  return(x)
}

# berechnet VB-Wert
vb_calc <- function(voldata, lookback) {
  tmp <- voldata / (rollapply(abs(voldata), width=lookback_vbt, FUN=mean, na.rm=T, align="right"))
  return(tmp)
}

# Berechnet welche Aktie Signal generiert hat
calc_signal <- function(vb_vector, trigger) {
  last <- t(tail(vb_vector,1))
  signals <- list(
    signal_up=rownames(last)[which(last>trigger)],
    signal_dn=rownames(last)[which(last<(0-trigger))])
}



#### HBT ####

# berechnet HBT Wert
hbt_calc <- function(indices, lookback_hbt, smoothper_hbt) {
  tmp <- indices / (rollapply(indices, width=lookback_hbt, FUN=mean, na.rm=T, align="right")) # calc the RSL
  tmp <- rollapply(tmp, width=smoothper_hbt, FUN=mean, na.rm=TRUE, align="right") # add a smoother
  return(tmp)
}
