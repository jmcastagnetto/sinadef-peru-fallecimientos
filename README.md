[![DOI](https://zenodo.org/badge/270383647.svg)](https://zenodo.org/badge/latestdoi/270383647)

**Última actualización**: 2020-06-16 21:46:39 UTC

Fallecimientos en Perú (SINADEF)
================================

Análisis usando los datos de

[“Información de Fallecidos del Sistema Informático Nacional de
Defunciones - SINADEF - \[Ministerio de
Salud\]”](https://www.datosabiertos.gob.pe/dataset/informaci%C3%B3n-de-fallecidos-del-sistema-inform%C3%A1tico-nacional-de-defunciones-sinadef-ministerio)

Notas
-----

-   **2020-06-08**:
    -   Hoy el formato de fecha a cambiado de “DD/MM/YYYY” a
        “YYYY-MM-DD”
    -   Los CSV ahora se guardarán comprimidos para no llegar a los
        límites de github
-   **2020-06-16**:
    -   Con la adición de campos de causas, estoy calculando campos que
        marcan si las causas contienen la expresión regular:
        `"(CORONAVIRUS|COVID|SARS COV|SARS-COV)"` se encuentra presente,
        y marcar como posible registro de fallecimiento debido a
        COVID-19.

Gráfico de fallecimientos por día desde marzo 2020
--------------------------------------------------

De los registros del SINADEF, se han empleado los 6 campos que contienen
posibles causas del deceso, y se empleó la expresión regular
`(CORONAVIRUS|COVID|SARS COV|SARS-COV)` para encontrar aquellas causas
que pudieran ser por COVID-19. Luego, se marcaron los registros con al
menos un campo que correspondía a la expresión regular mencioanada.

![Fallecimientos por día desde Marzo del
2020](plots/fallecimientos-por-dia.png)

![Fallecimientos acumulados desde Marzo del
2020](plots/fallecimientos-acumulados.png)
