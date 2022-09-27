TTR::SMA(quantmod::Cl(stocks$HEN3.DE), n = c(10)) %>% length()

eapply(stocks, FUN=function(x){TTR::SMA(na.approx(quantmod::Cl(x)))})

stocks_cl <- eapply(stocks, FUN=quantmod::Cl)
stocks_cl <- lapply(stocks_cl, FUN=function(x) x["2022::"])
stocks_cl <- lapply(stocks_cl, FUN=zoo::na.approx)
which(sapply(stocks_cl, FUN=function(x) {colSums(is.na(x))}, simplify=TRUE)!=0)

which(lapply(stocks_cl, length)==0)
# subset stocks_cl with only valid stocks
stocks_cl <- stocks_cl[!lapply(stocks_cl, length)==0]

lapply(stocks_cl, FUN=function(x){TTR::SMA(x)})
which(lapply(stocks_cl, length) <160)
stocks_cl$SCE.DE
tail(stocks$SCE.DE)


stocks_cl <- eapply(stocks, FUN=quantmod::Cl)
stocks_cl <- lapply(x, setNames, "Close") # set all colnames to "Close"

clean_data_for_technical_indicators <- function(x) {
  stopifnot(is.list(x)) # should be a list!
  aa <- sapply(x, FUN=function(y) {colSums(is.na(y))}, simplify = FALSE)
  dplyr::bind_rows(aa, .id="Aktie") # gibt DF mit Anzahl der NAs. Disen sollte ich filtern und präsentieren
  
  stocks_w_na <- which(sapply(stocks_cl, FUN=function(x) {colSums(is.na(x))}, simplify=FALSE)!=0) # Welche stocks haben NA und wie viele?
  lapply(x, FUN=zoo::na.approx)
  }

# Was ich brauche:
- Funktion, die stocks bereinigt: 
    - Extrahiere Close, 
    - approximiere NA values (! Beschreibe was passiert)
    - lösche alle leeren
    - lösche alle mit nicht genug Historie
    - schreibe raus, welche gelöscht wurden (und warum)
- Funktion die Minervini berechnet