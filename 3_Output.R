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
plot(Gauge1)

### Create timeseries chart
Time <- gvisAnnotationChart(data=data.frame(Date=index(rsl.all.zoo),Value=coredata(rsl.all.zoo)),
                              datevar="Date", numvar="Value", options=list(width=700, height=400))

plot(Time)

### Create Map
map.data <- melt(data=coredata(tail(rsl.zoo,1)), value.name="RSL")[,-1]

Geo=gvisGeoChart(map.data, locationvar="Var2", colorvar="RSL",
                 options=list(colorAxis="{values:[0.95,1.05],
                                 colors:[\'red', \'blue']}",
                              projection="kavrayskiy-vii"))
plot(Geo)


### Create interactive timeseries
myStateSettings <- '
  {"orderedByY":false,"dimensions":{"iconDimensions":["dim0"]},"iconKeySettings":[],"xAxisOption":"_TIME","uniColorForNonSelected":false,"yLambda":1,"showTrails":false,"xZoomedDataMin":1170720000000,"nonSelectedAlpha":0.3,"playDuration":15000,"sizeOption":"_UNISIZE","xZoomedIn":false,"xLambda":1,"colorOption":"_UNIQUE_COLOR","yZoomedIn":false,"xZoomedDataMax":1422403200000,"iconType":"LINE","orderedByX":false,"yAxisOption":"2","yZoomedDataMin":0,"duration":{"timeUnit":"D","multiplier":1},"yZoomedDataMax":1.3}
'
line.data <- melt(data=coredata(rsl.zoo), id=c("Date"), value.name="RSL")
line.data$Var1 <- as.Date(line.data$Var1)
Line2 <- gvisMotionChart(subset(line.data, Var1>as.Date("2014-01-01")), idvar="Var2", timevar="Var1",
                         options=list(state=myStateSettings, width=800, height=500))
plot(Line2)


