#!/bin/bash
echo "-----------------------"
echo "Start des Skripts"
echo "-----------------------"
Rscript /home/fibo/scripts/Boersentacho/1_Import_Calc.R
echo "----------------------------------------"
echo "Import fertig, starte Out-Generierung"
echo "----------------------------------------"
Rscript -e  "library(rmarkdown); render('/home/fibo/scripts/Boersentacho/3_Output.Rmd')"
sudo mv /home/fibo/scripts/Boersentacho/3_Output.html /var/www/html/hbt.html
echo "--------------"
echo "Fertig"
echo "--------------"


