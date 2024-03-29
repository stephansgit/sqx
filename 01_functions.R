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

load_EoD_data <- function(daten = "data/SetupData.RData", output_eod="data/EOD-Data_raw.RData") {
  load(daten)
  source("02_parameters.R")
  
  stocks <- new.env()
  
  # Loop 1: Find values as specified
  for (i in 1:length(de_stocks)) {
    message(paste("Trying to load "), de_stocks[i])
    try(
      getSymbols(de_stocks[i], from=StartDate_vbt, env=stocks, verbose = FALSE, warnings = FALSE)
    )
    Sys.sleep(1)
  }
  
  # Loop 2: Replace exchanges of values not find with Frankfurt
  de_stocks2 <- setdiff(de_stocks, ls(envir=stocks))
  de_stocks2 <- gsub("\\..*$", ".F", de_stocks2) # replace the Xetra-suffix with Frankfurt suffix
  for (i in 1:length(de_stocks2)) {
    message(paste("Now on FRA: Trying to load "), de_stocks2[i])
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
  # mache einen Debug Save
  save(stocks_requested, stocks_loaded, stocks, file=output_eod)
}

prep_EoD_data <- function(daten = "data/EOD-Data_raw.RData", output_eod="data/EOD-Data.RData") {
  #message(paste("Raw data to load:",daten))
  load(daten)
  #message(paste("Content of data file:",ls()))

  #check for nonnumerics and clean
  check_clean_nonnumerics(stocks) #see below, it's a defined function
  
  message("Tidying the data....")
  de_vol <- eapply(stocks, volUpDn) #volUpDn ist eine Eigendefinierte Funktion
  de_vol <- lapply(de_vol, VolUpDn_extract) #volUpDn_extract ist eine Eigendefinierte Funktion
  de_vol <- as.xts(do.call(merge, de_vol))
  # adjust column names are re-order columns
  colnames(de_vol) <- gsub("_VolUpDn","",colnames(de_vol))
  
  de_vol[de_vol==0] <- NA # replace 0 with NA
  
  # Wir ersetzen die Symbole mit einem X aus make.names mit dem richtigen Symbol. Ziemlich kompliziert; das geht einfcher...
  which_symbols_has_added_x <- setdiff(stocks_loaded, make.names(stocks_loaded)) # shows where make.names did kick in
  which_tickers_are_those <- grep(paste(which_symbols_has_added_x,collapse="|"), names(de_vol), value = TRUE)
  names(de_vol)[grep(paste(which_symbols_has_added_x,collapse="|"), names(de_vol), value = FALSE)] <- sapply(strsplit(which_tickers_are_those, "X"), '[[', 2)
  
  # debug point - save
  save(stocks_requested, stocks_loaded, de_vol, stocks, file=output_eod)
  message("erfolgreicher debug save")

  # Load full names from Yahoo
  message("Loading full names...")                                               
  fullnames <- load_full_names(names(de_vol)) # this is a function defined below, that trries to call from Yahoo, but if it fails, it loads locally
  
  # Speichert EOD-Daten
  message("Saving...")
  message("Output path is ", output_eod)
  save(stocks_requested, stocks_loaded, de_vol, stocks,fullnames, file=output_eod)
  
}

# function to load full names
load_full_names <- function(x) {
  
  fullnames <- tryCatch(
    {
      fn <- getQuote(x, what=yahooQF(c("Symbol", "Name", "Volume", "Last Trade (Price Only)", "Bid", "Previous Close"))) #NOTE: Bid must be called, othersie fails
      fn <- data.frame(Ticker=rownames(fn), Name=fn$Name)
      return(fn)
    },
    error = function(cond) {
      message("Cannot read full names from Yahoo")
      message("Here's the original error message:")
      message(cond)
      message("\nattempting to load locally...")
      
      ## I manually saved a mapping table to mapping_table.RData, which I load now...
      load("name_mapping.RData")
      message("Full names loaded locally.")
      return(name_mapping)
    },
    finally = message("Full name loaded, one way or another...")
    )
}

#function to check for non-numeric data in the download, and eventually delete those
check_clean_nonnumerics <- function(x) {
  #check for non.numeric data
  stocks.l <- eapply(x, "[") # convert environment to list
  message("-------------------------------------------------------------")
  message('the following stocks come over as non-numeric - pls check!')
  message(paste('Diese: ',which(!sapply(stocks.l, is.numeric))))
  message("-------------------------------------------------------------")
  name_of_nonnumeric <- names(which(!sapply(stocks.l, is.numeric)))
  rm(list=c(name_of_nonnumeric)) #when calling this fct, the envir=stocks ist uebergeben
  message("I have deleted the following stocks from the list:")
  message(name_of_nonnumeric)
}

#function to calculate Volumen dependant on up or downmove of prices
volUpDn <- function(x) {
        tryCatch(
          {
            x$VolUpDn <- Vo(x) * sign(ifelse(OpCl(x)!=0, Cl(x)-Op(x), 0.01))
            nm <- gsub(".Open", "", colnames(x)[1])
            colnames(x)[colnames(x)=="VolUpDn"] <- paste(nm, "VolUpDn", sep="_")
            #return(x)
          },
          error = function(cond) {
            message("Extracting VolUpDn from data failed")
            message("Here's the original error message:")
            cond$message <- paste0(cond$message, ": ", names(x)[1]) #sows name of column 1 of the object
            stop(cond)
          }
  )
  return(x)
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


#### Minervini #####
stocks_nas <- function(x) { #function counts the NAs and shows them in table, descending
  stopifnot(is.list(x)) # should be a list!
  aa <- sapply(x, FUN=function(y) {colSums(is.na(y))}, simplify = FALSE)
  nas <- dplyr::bind_rows(aa, .id="Aktie") # gibt DF mit Anzahl der NAs. Disen sollte ich filtern und präsentieren
  nas %>% dplyr::filter(Close!=0) %>% dplyr::arrange(., desc(Close))
}


clean_data_for_technical_indicators <- function(x, obs=200) { #function interpolates missing values 'sledgehammer' and deletes values with less than x observations
  message("Interpolating linearly missing values")
  stocks_approx <- lapply(x, FUN=zoo::na.approx)
  stocks_enough_history <- stocks_approx[!(lapply(stocks_approx, length) < obs)]
  names_of_stocks_with_too_little_history <- names(which(lapply(stocks_approx, length) < obs))
  message(paste(c("Deleted Stocks due to little history: ", names_of_stocks_with_too_little_history), collapse="; "))
  return(list(stocks=stocks_enough_history, deleted_stocks=names_of_stocks_with_too_little_history))
}


minervini_1 <- function(x) {
  x$Close > x$SMA_200 & x$Close > x$SMA_150
}

minervini_2 <- function(x) {
  x$SMA_150 > x$SMA_200
}

minervini_3 <- function(x) {
  x$SMA_200 > lag.xts(x$SMA_200, k=20)
}

minervini_4 <- function(x) {
  x$SMA_50 > x$SMA_200 & x$SMA_50 > x$SMA_150
}

minervini_5 <- function(x) {
  x$Close > x$SMA_50 
}

minervini_6 <- function(x) {
  x$Close > x$Minimum_250 * 1.3
}

minervini_7 <- function(x) {
  x$Close > x$Maximum_250 * 0.75
}



xts_rowsums <- function(x) { # see https://stackoverflow.com/questions/44222272/preserve-xts-index-when-using-rowsums-on-xts
  library(xts)  
  res <- .xts(x = rowSums(x), .index(x))
  return(res)
}

calculate_age_of_signal <- function(x) {
  cdf <- coredata(x$signal)
  comp <- cbind(TRUE, t(cdf[-nrow(x$signal), ] < cdf[-1,"signal"])) #https://stackoverflow.com/questions/16573131/last-occurrence-of-value-change
  comp[is.na(comp)] <- FALSE
  #message(comp)
  timediff <- tail(index(x),1) - index(x[max.col(comp, "last"),])
  
  return(as.numeric(timediff))
  
}
