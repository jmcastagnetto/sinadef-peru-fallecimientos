#! /bin/bash -x

# intentar usar el tamaño para decidir si hay cambio o no
prev_size=`cat sinadef-size.txt`
data_url="https://cloud.minsa.gob.pe/s/g9KdDRtek42X3pg/download"
curr_size=`curl --silent --insecure --head $data_url | grep -Fi content-length | cut -d ' ' -f2`
# --insecure para evitar errores con los certificados del MINSA que han ocurrido ocasionalmente

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
    curl --silent --insecure $data_url --output datos/fallecidos_sinadef.7z
	now=`date -I`
	#sha1sum datos/fallecidos_sinadef.csv > sha1sum-orig.txt
	(Rscript 01-procesar-datos.R && Rscript build-readme.R) && (xz -T 3 -9e -f datos/fallecidos*csv; git commit -a -m "Actualizado el $now"; HOME=/home/jesus git push origin main)
fi
