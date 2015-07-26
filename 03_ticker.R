#############################
# Liest die Ticker-Daten ein
# 26.07.2015
#########################

#DOWNLOADING GOOGLE SPREADSHEET
ticker <- read.csv("ticker.csv",header=TRUE) #lies das spreadsheet ein

# versucht die Tabelle über GoogleSpreadsheet ein
pass <- read.table(file="pass", header=FALSE, stringsAsFactors = FALSE)[[1]]
try({
  sheets.con = getGoogleDocsConnection(getGoogleAuth("stephan.raspberry@gmail.com", pass, service = "wise"))
  a = getDocs(sheets.con)
  ts = getWorksheets(a$`20150425_Ticker`, sheets.con)
  ticker <- sheetAsMatrix(ts$ticker_werner, header = TRUE, as.data.frame = TRUE, trim = TRUE)
})

# Kreiert einen Vektor aus den Tickersymbolen.
de_stocks <- as.vector(unlist(ticker[,1]))
