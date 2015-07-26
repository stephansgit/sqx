#############################
# Beinhaltet Funktionen im Rahmen des VB-Projekts
# 26.07.2015
#############################

# Konvertiert xts-Objekt in einen data.frame
xts2df <- function(x) {
  tmp <- data.frame(Date=index(x), coredata(x))
  return(tmp)
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
  hour(x$Trade.Time) <- ifelse(
    (hour(x$Trade.Time)>=0 & hour(x$Trade.Time)<9),
    hour(x$Trade.Time) + 12,
    hour(x$Trade.Time)
  )
  return(x)
}

# berechnet VB-Wert
vb_calc <- function(voldata, lookback) {
  tmp <- voldata / (rollapply(abs(voldata), width=lookback, FUN=mean, na.rm=T, align="right"))
  return(tmp)
}

# Berechnet welche Aktie Signal generiert hat
calc_signal <- function(vb_vector, trigger) {
  last <- t(tail(vb_vector,1))
  signals <- list(
    signal_up=rownames(last)[which(last>trigger)],
    signal_dn=rownames(last)[which(last<(0-trigger))])
}



