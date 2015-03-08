# Import and data cleansing

### Load packages and set options

options(scipen = 0, digits = 5) # set options to avoid scientific notation
Sys.setenv(TZ="America/Chicago") # needs to be done in order to make sure, getSymbols works properly.


library(googleVis)
library(ggplot2)
library(quantmod)
library(reshape2)
library(scales)
library(gridExtra)


### Import
getSymbols(c( "DJIA", "^GDAXI", "^FTSE", "^FCHI", "^SSMI", "^IBEX", "^SSEC", "^STI", "^MXX", "^N225", "^AORD", "RTS.RS", "^ATX", "FTSEMIB.MI", "^GSPTSE", "^HSI", "^BVSP", "^MERV"), warnings=FALSE)

indices.zoo <- merge(Ad(DJIA), Ad(AORD), Ad(ATX), Ad(BVSP), Ad(FCHI), Ad(FTSE), Ad(FTSEMIB.MI), Ad(GDAXI), Ad(GSPTSE), Ad(HSI), Ad(IBEX), Ad(MERV), Ad(MXX), Ad(N225), Ad(RTS.RS), Ad(SSEC), Ad(SSMI), Ad(STI))
colnames(indices.zoo) <- c("USA", "Australia", "Austria", "Brasil", "France", "UK", "Italy", "Germany", "Canada", "HongKong", "Spain", "Argentina", "Mexico", "Japan", "Russia", "China", "Switzerland", "Singapore")      
tail(indices.zoo)

Sys.setenv(TZ="CET") # sets system time back to Europe; important for the deletion that follows
indices.zoo <- window(indices.zoo, end=Sys.Date()-1) # delete current day, because it will contain NAs.

rm(list=setdiff(ls(), "indices.zoo")) # remove all raw data, just keep indices.zoo

### Check missing data
#   check.df <- data.frame(is.na(data.frame(coredata(indices.zoo))))
#   check.df$Date <- index(indices.zoo)
#   check.m <- melt(check.df, id.vars="Date", variable.name="Country", value.name="Missing_Quote")
#   ggplot(data=subset(check.m)) + geom_tile(aes(x=Date, y=Country, fill=Missing_Quote)) + theme_minimal()

### treat NAs
indices.zoo <- na.approx(zoo(indices.zoo), na.rm=TRUE) # interpolation happens for NAs
indices.zoo <- na.locf(indices.zoo) # any remaining NAs are being replaced by simple "roll forward"


### calculate RSL
#RSL=Close/MovingAverage
mean.zoo <- rollapply(indices.zoo, width=27, FUN=mean, na.rm=T, align="right")
rsl.zoo <- indices.zoo / mean.zoo
rsl.gd.zoo <- rollapply(rsl.zoo, width=10, FUN=mean, na.rm=T, align="right") # we add a 10-day SMA
rsl.all.zoo <- zoo(rowMeans(rsl.gd.zoo), order.by=as.Date(index(rsl.gd.zoo)))
#plot(tail(rsl.all.zoo, 40), type="b")


### Save data
save(indices.zoo, rsl.gd.zoo, rsl.all.zoo, file="/home/fibo/scripts/Boersentacho/Indices_Data.RData")

