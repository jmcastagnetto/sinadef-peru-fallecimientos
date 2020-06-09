#! /bin/bash -x

wget https://cloud.minsa.gob.pe/s/nqF2irNbFomCLaa/download -O datos/fallecidos_sinadef.csv
iconv -f ISO_8859-1  -t UTF8 datos/fallecidos_sinadef.csv > datos/fallecidos_sinadef-utf8.csv
gzip -9f datos/fallecidos*csv
