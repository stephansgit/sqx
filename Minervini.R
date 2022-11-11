#TTR::SMA(quantmod::Cl(stocks$HEN3.DE), n = c(10)) %>% length()

#eapply(stocks, FUN=function(x){TTR::SMA(zoo::na.approx(quantmod::Cl(x)))})

stocks_cl <- eapply(stocks, FUN=quantmod::Cl)
stocks_cl <- lapply(stocks_cl, FUN=function(x) x["2021-10::"])
stocks_cl <- lapply(stocks_cl, FUN=zoo::na.approx)
which(sapply(stocks_cl, FUN=function(x) {colSums(is.na(x))}, simplify=TRUE)!=0)

which(lapply(stocks_cl, length)==0)
# subset stocks_cl with only valid stocks
stocks_cl <- stocks_cl[!lapply(stocks_cl, length)==0]

lapply(stocks_cl, FUN=function(x){TTR::SMA(x)})
which(lapply(stocks_cl, length) <200)
stocks_cl$SCE.DE
tail(stocks$SCE.DE)


#--------------------------
library(xts)
library(magrittr)
load("data/EOD-Data.RData")
stocks_cl <- eapply(stocks, FUN=quantmod::Cl)
stocks_cl <- lapply(stocks_cl, FUN=function(x) x["2021-10::"])
stocks_cl <- lapply(stocks_cl, setNames, "Close") # set all colnames to "Close"



stocks_nas(stocks_cl) %>% print(n=Inf)



stocks_cleaned <- clean_data_for_technical_indicators(stocks_cl)

message(paste(c("Deleted Stocks due to little history: ", stocks_cleaned$deleted_stocks), collapse="; "))

sma_200 <- lapply(stocks_cleaned$stocks, FUN=function(x){TTR::SMA(quantmod::Cl(x), n = 200)})
sma_150 <- lapply(stocks_cleaned$stocks, FUN=function(x){TTR::SMA(quantmod::Cl(x), n = 150)})
sma_50 <- lapply(stocks_cleaned$stocks, FUN=function(x){TTR::SMA(quantmod::Cl(x), n = 50)})
min_200 <- lapply(stocks_cleaned$stocks, FUN=function(x){rollapply(x, width=200, FUN=min, na.rm=TRUE)})
max_200 <- lapply(stocks_cleaned$stocks, FUN=function(x){rollapply(x, width=200, FUN=max, na.rm=TRUE)})
sma_up <- NA

minervini <- Map(xts::merge.xts, stocks_cleaned$stocks, sma_200, sma_150, sma_50, min_200, max_200, sma_up)
columnames <- c("Close", "SMA_200", "SMA_150", "SMA_50", "Minimum_200", "Maximum_200", "SMA_200_up")
minervini <- lapply(minervini, setNames, columnames)

#minervini$HEN3.DE$Close > minervini$HEN3.DE$SMA_200 & minervini$HEN3.DE$Close > minervini$HEN3.DE$SMA_150


min_1 <- lapply(minervini, minervini_1)
min_2 <- lapply(minervini, minervini_2)
min_4 <- lapply(minervini, minervini_4)

crits <- Map(xts::merge.xts, min_1, min_2, min_4)
columnames <- c("Krit_1", "Krit_2", "Krit_4") 
crits <- lapply(crits, setNames, columnames)
#minervini <- Map(xts::merge.xts, minervini, crits) sollte vllt nicht mergen, denn dann habe ich eine standalon 'crits' Liste und kann schön die hits summieren...



crits_sum <- lapply(crits, xts_rowsums)

data.frame(Count=sort(sapply(crits_sum, FUN=tail, n=1), decreasing = TRUE))




TODO: Die anderen Kriterien implementieren


# Was ich brauche:
- Funktion, die stocks bereinigt: 
    - Extrahiere Close, 
    - approximiere NA values (! Beschreibe was passiert)
    - lösche alle leeren
    - lösche alle mit nicht genug Historie
    - schreibe raus, welche gelöscht wurden (und warum)
- Funktion die Minervini berechnet