Necesitamos implementar correctamente descuentos y recargos en la emisión de DTE Chile SII.

Contexto:
En un DTE existen descuentos/recargos por línea y descuentos/recargos globales. 
Los descuentos/recargos globales NO deben “esconderse” modificando artificialmente los precios de los productos; 
deben reflejarse en el XML dentro de la sección <DscRcgGlobal> cuando correspondan.

Documentación SII:
Usar como referencia el Formato DTE SII, sección “Descuentos y Recargos Globales”. El XML usa los tags:
- <DscRcgGlobal>
- <NroLinDR>
- <TpoMov>
- <GlosaDR>
- <TpoValor>
- <ValorDR>
- <IndExeDR>

Reglas principales:

1) Descuento o recargo por línea
Si el descuento afecta a un producto/servicio específico, debe registrarse en el detalle del ítem.

Ejemplo conceptual:
Detalle:
- precio unitario
- cantidad
- descuento %
- descuento monto
- monto item final

El total de la línea ya debe salir descontado.

2) Descuento o recargo global
Si el descuento afecta al documento completo, debe agregarse como entrada XML:

<DscRcgGlobal>
  <NroLinDR>1</NroLinDR>
  <TpoMov>D</TpoMov>
  <GlosaDR>Descuento comercial</GlosaDR>
  <TpoValor>%</TpoValor>
  <ValorDR>10</ValorDR>
</DscRcgGlobal>

Campos:
- NroLinDR: número correlativo del descuento/recargo, de 1 a 20.
- TpoMov: D = Descuento, R = Recargo.
- GlosaDR: descripción del movimiento.
- TpoValor: % o $.
- ValorDR: valor del porcentaje o monto.
- IndExeDR:
  - vacío / omitido: aplica a montos afectos.
  - 1: aplica a montos exentos o no afectos a IVA.
  - 2: aplica a montos no facturables.

3) Muy importante: afectos, exentos/no afectos y no facturables
Un descuento global NO debe mezclarse en una sola línea si afecta tipos de monto distintos.

Si el descuento afecta:
- solo afectos: una línea <DscRcgGlobal> sin <IndExeDR>.
- solo exentos/no afectos: una línea con <IndExeDR>1</IndExeDR>.
- solo no facturables: una línea con <IndExeDR>2</IndExeDR>.
- afectos + exentos/no afectos + no facturables: deben generarse líneas separadas, una por cada tipo de monto.

Ejemplo:
Documento con:
- neto afecto: 100.000
- exento/no afecto: 50.000
- no facturable: 10.000

Si hay descuento global de 10% sobre todo, NO generar una sola línea de 10%.
Generar tres líneas:
1) descuento 10% afecto
2) descuento 10% exento/no afecto con IndExeDR=1
3) descuento 10% no facturable con IndExeDR=2

4) Impacto en totales
El motor de cálculo debe recalcular:
- MntNeto
- MntExe
- IVA
- MntTotal
- otros montos si existen

Regla:
- Descuento afecto modifica la base imponible y por lo tanto cambia el IVA.
- Descuento exento/no afecto modifica MntExe, pero no cambia IVA.
- Descuento no facturable modifica el monto no facturable, pero no debe afectar IVA.
- Recargo afecto aumenta base imponible y aumenta IVA.
- Recargo exento/no afecto aumenta MntExe y no afecta IVA.

5) Modelo de datos sugerido

Tabla o estructura: documento_descuentos_recargos_globales

Campos:
- id
- documento_id
- nro_linea
- tipo_movimiento: D/R
- glosa
- tipo_valor: PORCENTAJE/MONTO
- valor
- aplica_sobre:
  - AFECTO
  - EXENTO_NO_AFECTO
  - NO_FACTURABLE
- monto_calculado
- orden

No usar un simple campo “descuento_global” en documento, porque no alcanza para representar correctamente las reglas SII.

6) Algoritmo de cálculo sugerido

Paso 1:
Calcular todas las líneas de detalle:
- monto bruto línea
- descuento línea
- recargo línea
- monto final línea
- clasificar línea como afecta, exenta/no afecta o no facturable

Paso 2:
Sumar bases:
- subtotal_afecto
- subtotal_exento
- subtotal_no_facturable

Paso 3:
Aplicar descuentos/recargos globales por ámbito:
- movimientos AFECTO sobre subtotal_afecto
- movimientos EXENTO_NO_AFECTO sobre subtotal_exento
- movimientos NO_FACTURABLE sobre subtotal_no_facturable

Paso 4:
Recalcular:
- neto_afecto_final
- exento_final
- no_facturable_final
- IVA = neto_afecto_final * tasa IVA
- total = neto_afecto_final + IVA + exento_final + no_facturable_final + otros impuestos/recargos si existen

Paso 5:
Generar XML:
- Detalle[]
- DscRcgGlobal[] si existen descuentos/recargos globales
- Totales consistentes con los movimientos globales

7) Validaciones obligatorias

Validar:
- máximo 20 líneas de DscRcgGlobal.
- NroLinDR correlativo.
- TpoMov solo D o R.
- TpoValor solo % o $.
- ValorDR mayor que 0.
- Si aplica_sobre = EXENTO_NO_AFECTO, XML debe incluir <IndExeDR>1</IndExeDR>.
- Si aplica_sobre = NO_FACTURABLE, XML debe incluir <IndExeDR>2</IndExeDR>.
- Si aplica_sobre = AFECTO, no incluir IndExeDR.
- No permitir descuento mayor que la base correspondiente.
- Los totales del encabezado deben cuadrar con detalle + descuentos/recargos globales.

8) Ejemplo XML con descuento afecto y exento

<DscRcgGlobal>
  <NroLinDR>1</NroLinDR>
  <TpoMov>D</TpoMov>
  <GlosaDR>Descuento sobre productos afectos</GlosaDR>
  <TpoValor>%</TpoValor>
  <ValorDR>10</ValorDR>
</DscRcgGlobal>

<DscRcgGlobal>
  <NroLinDR>2</NroLinDR>
  <TpoMov>D</TpoMov>
  <GlosaDR>Descuento sobre productos exentos</GlosaDR>
  <TpoValor>%</TpoValor>
  <ValorDR>10</ValorDR>
  <IndExeDR>1</IndExeDR>
</DscRcgGlobal>

9) Criterio de implementación
El sistema debe guardar explícitamente los descuentos/recargos globales, calcularlos por tipo de monto y serializarlos en el XML DTE. No basta con ajustar el total final. Si existe descuento/recargo global, debe existir su representación correspondiente en <DscRcgGlobal>.
