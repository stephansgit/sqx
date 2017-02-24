all: /var/www/html/sqx.servebeer.com/vbt/vbt.html

clean: 
	rm -f data/SetupData.RData data/EOD-Data.RData

data/SetupData.RData: 03_ticker.R
	Rscript $<

data/EOD-Data.RData: 04_load_EOD.R data/SetupData.RData
	Rscript $<

VolBreakout.html: data/EOD-Data.RData
	Rscript -e "rmarkdown::render('/home/fibo/boerse/VolBreakout/VolBreakout.Rmd')"

/var/www/html/sqx.servebeer.com/vbt/vbt.html: VolBreakout.html
	mv $< $@
