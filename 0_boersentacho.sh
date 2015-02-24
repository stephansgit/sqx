#!/bin/bash
Rscript 1_Import_Calc.R
Rscript -e  "library(rmarkdown); render('3_Output.Rmd')"
echo "Fertig"

