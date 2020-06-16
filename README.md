# Fallecimientos en Perú (SINADEF)

Análisis usando los datos de 

["Información de Fallecidos del Sistema Informático Nacional de Defunciones - SINADEF - [Ministerio de Salud]"](https://www.datosabiertos.gob.pe/dataset/informaci%C3%B3n-de-fallecidos-del-sistema-inform%C3%A1tico-nacional-de-defunciones-sinadef-ministerio)

## Notas

- **2020-06-08**:
  - Hoy el formato de fecha a cambiado de "DD/MM/YYYY" a "YYYY-MM-DD"
  - Los CSV ahora se guardarán comprimidos para no llegar a los límites de github

- **2020-06-16**:
  - Con la adición de campos de causas, estoy calculando campos que marcan si las causas contienen la expresión regular: `"(CORONAVIRUS|COVID|SARS COV|SARS-COV)"` se encuentra presente, y marcar como posible registro de fallecimiento debido a COVID-19.
