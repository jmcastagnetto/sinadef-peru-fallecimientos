#! /bin/bash -x

wget https://cloud.minsa.gob.pe/s/nqF2irNbFomCLaa/download -O datos/fallecidos_sinadef.csv

# revisar si el archivo a cambiado
sha1sum --status -c sha1sum-orig.txt

if [ $? -eq 0 ]
then
	echo "Datos no han cambiado"
	rm datos/fallecidos_sinadef.csv
else
	echo "Datos originales han cambiado... "
	now=`date -I`
	sha1sum datos/fallecidos_sinadef.csv > sha1sum-orig.txt
	iconv -f ISO_8859-1  -t UTF8 datos/fallecidos_sinadef.csv | tr -d '\000' > datos/fallecidos_sinadef-utf8.csv
	gzip -9f datos/fallecidos*csv
	Rscript 01-procesar-datos.R
	Rscript build-readme.R
	git commit -a -m "Actualizado el $now"
	HOME=/home/jesus git push origin main
fi
