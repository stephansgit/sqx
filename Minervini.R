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
