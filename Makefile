all: /var/www/html/sqx.servebeer.com/vbt/vbt.html

clean: 
	rm -f data/SetupData.RData data/EOD-Data.RData VolBreakout.html

data/SetupData.RData: 03_ticker.R
	Rscript $<

data/EOD-Data.RData: 04_load_EOD.R data/SetupData.RData
	Rscript $<

VolBreakout.html: VolBreakout.Rmd data/EOD-Data.RData
	Rscript -e 'rmarkdown::render("$<")'

/var/www/html/sqx.servebeer.com/vbt/vbt.html: VolBreakout.html
	mv $< $@
