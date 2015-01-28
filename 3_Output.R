# Create the output



library(googleVis)

### Create the gauge
gauge.df <- as.data.frame(round(tail(rsl.all.zoo,1),4))
gauge.df$Type <- c("latest RSL all")
colnames(gauge.df) <- c("RSL_all", "Type")
Gauge1 <- gvisGauge(gauge.df, options=list(min=0.9, max=1.1, greenFrom=1.02,
                                           greenTo=1.1, yellowFrom=0.98, yellowTo=1.02,
                                           redFrom=0.9, redTo=.98, height=250))
print(Gauge1, tag="chart", file="Gauge.html")
