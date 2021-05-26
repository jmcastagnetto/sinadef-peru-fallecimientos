#! /bin/bash -x

# intentar usar el tamaño para decidir si hay cambio o no
prev_size=`cat sinadef-size.txt`
curr_size=`curl --silent --insecure --head https://cloud.minsa.gob.pe/s/nqF2irNbFomCLaa/download | grep -Fi content-length | cut -d ' ' -f2`
# --insecure para evitar errores con los certificados del MINSA que han ocurrido ocasionalmente

#wget https://cloud.minsa.gob.pe/s/nqF2irNbFomCLaa/download -O datos/fallecidos_sinadef.csv

# revisar si el archivo a cambiado
#sha1sum --status -c sha1sum-orig.txt

#if [ $? -eq 0 ]
if [ $prev_size == $curr_size ]
then
	echo "Datos no han cambiado"
	#rm datos/fallecidos_sinadef.csv
else
	echo "Datos originales han cambiado... "
	echo $curr_size > sinadef-size.txt
    curl --insecure --parallel https://cloud.minsa.gob.pe/s/nqF2irNbFomCLaa/download --output datos/fallecidos_sinadef.csv
	now=`date -I`
	sha1sum datos/fallecidos_sinadef.csv > sha1sum-orig.txt
	iconv -f ISO_8859-1  -t UTF8 datos/fallecidos_sinadef.csv | tr -d '\000' > datos/fallecidos_sinadef-utf8.csv
	gzip -9f datos/fallecidos*csv
	Rscript 01-procesar-datos.R
	Rscript build-readme.R
	git commit -a -m "Actualizado el $now"
	HOME=/home/jesus git push origin main
fi
