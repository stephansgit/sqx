#############################
# Beinhaltet Funktionen im Rahmen des Börsentacho-Projekts
# 20.08.2015
#############################

# Konvertiert xts-Objekt in einen data.frame
xts2df <- function(x) {
  tmp <- data.frame(Date=index(x), coredata(x))
  return(tmp)
}

# berechnet VB-Wert
hbt_calc <- function(indices, lookback, smoothper) {
  tmp <- indices / (rollapply(indices, width=lookback, FUN=mean, na.rm=T, align="right")) # calc the RSL
  tmp <- rollapply(tmp, width=smoothper, FUN=mean, na.rm=TRUE, align="right") # add a smoother
  return(tmp)
}
