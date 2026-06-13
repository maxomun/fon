# Explicación Algorítmica: Generación DTE (Factura Electrónica Tipo 33)

Este documento describe el algoritmo para generar el XML de una **Factura Electrónica (Tipo 33)** según el formato requerido por el SII de Chile.

---

## Decisiones de Arquitectura

### Variante Implementada: Sistema Integrado (Variante A)

Los datos se obtienen de la base de datos, minimizando el JSON de entrada:

| Dato | Origen | Observación |
|------|--------|-------------|
| **Emisor** | BD (`Empresa.find(empresa_id)`) | Datos fijos de la empresa |
| **Receptor** | JSON de entrada | Cliente, cambia cada factura |
| **Items** | BD (`Producto.find(producto_id)`) | Solo se envía `producto_id` y `cantidad` |
| **Impuestos** | BD (`producto_impuestos` + `impuesto_valores`) | Calculados automáticamente |
| **Folios** | BD (`rango_folios` + `folios`) | Asignados del CAF |
| **Certificados** | BD (`certificados`) | Para firma digital |

### Request Mínimo (Variante A):
```json
{
  "empresa_id": 101,
  "tipo_documento": 33,
  "receptor": {
    "rut": "12.345.678-9",
    "razon_social": "Cliente SpA",
    "giro": "Servicios",
    "direccion": "Av. Principal 123"
  },
  "items": [
    { "producto_id": 445, "cantidad": 2 },
    { "producto_id": 444, "cantidad": 1 }
  ]
}
```

---

## ALGORITMO GENERAL

### ENTRADA:
```
params = {
  empresa_id:     ID de la empresa emisora (se busca en BD)
  tipo_documento: 33 (Factura Electrónica)
  receptor:       { rut, razon_social, giro, direccion, email }
  items:          [ { producto_id, cantidad }, ... ]
}
```

### SALIDA:
```
{
  xml:            String del XML generado
  archivo:        Ruta al archivo XML
  folios_usados:  Array de folios asignados
}
```

---

## FASE 1: Validación y Obtención de Datos ✅ IMPLEMENTADO

**Service:** Controller `DteController#generar_xml`

```
1. VALIDAR parámetros de entrada:
   - empresa_id es requerido
   - tipo_documento es requerido
   - receptor es requerido (rut, razon_social, giro, direccion)
   - items es requerido y no vacío
   - cada item debe tener producto_id y cantidad

2. OBTENER empresa emisora desde BD:
   empresa ← Empresa.find(empresa_id)
   SI empresa NO existe:
      LANZAR ERROR "Empresa no encontrada"

3. PREPARAR items desde BD:
   PARA CADA item EN params[:items]:
      producto ← Producto.find(item[:producto_id])
      
      // Obtener datos del producto
      codigo         ← producto.codigo
      glosa          ← producto.nombre
      precio_unitario ← producto.precio_unitario
      
      // Determinar si es afecto según producto_impuestos
      afecto ← producto.producto_impuestos.any?
      
      // Obtener impuestos con tasas vigentes
      impuestos ← producto.impuestos.map { |i| 
        { codigo: i.abreviacion, tasa: i.valor_vigente }
      }
      
      // Calcular neto
      subtotal ← cantidad * precio_unitario
      descuento_monto ← calcular_descuento()
      neto ← subtotal - descuento_monto
```

---

## FASE 2: Paginación y Asignación de Folios ✅ IMPLEMENTADO

**Services:** `Dte::ClasificadorItems`, `Dte::AsignadorFolios`

```
4. CLASIFICAR ITEMS EN PÁGINAS:
   resultado ← Dte::ClasificadorItems.call(
     items: items_preparados,
     archivo: "/tmp/calculo.pdf"
   )
   
   // Usa Prawn para simular el render y determinar cuántos items caben
   // Parámetros: y_ini=500, alto=380, ancho=300
   // Retorna:
   //   items[]   → cada item con su página asignada
   //   paginas[] → [{ pagina: 1, folio: -1 }, ...]

5. ASIGNAR FOLIOS DESDE CAF:
   resultado ← Dte::AsignadorFolios.call(
     paginas: paginas,
     empresa_id: empresa.id,
     tipo_documento: 33
   )
   
   // Flujo interno:
   //   TipoDocumento.find_by(codigo: '33')
   //   TipoHabilitado.find_by(empresa_id, tipo_documento_id)
   //   RangoFolio.where(tipo_habilitado_id).order('fa ASC')
   //   Folio.where(disponible: true).order('numero ASC')
   //
   // Actualiza cada página con:
   //   paginas[i].folio       → número de folio asignado
   //   paginas[i].archivo_caf → ruta al archivo CAF (Active Storage)
```

---

## FASE 3: Generación del XML ✅ IMPLEMENTADO

**Service:** `Dte::GeneradorXml`

```
6. CONSTRUIR ESTRUCTURA DTE:
   estructura = {
     emisor: {
       rut: empresa.rut,
       razon_social: empresa.razon_social,
       giro: empresa.giro,
       direccion: empresa.direccion,
       telefono: empresa.telefono1,
       fecha_resolucion: empresa.fecha_resolucion,
       numero_resolucion: empresa.numero_resolucion
     },
     receptor: { ... },  // desde params
     documento: {
       tipo_dte: 33,
       fecha_emision: "YYYY-MM-DD",
       timestamp: "YYYY-MM-DDTHH:MM:SS"
     },
     paginas: [
       {
         numero: 1,
         folio: 123,
         archivo_caf: "/path/to/caf.xml",
         items: [...],
         totales: {
           neto_afecto: X,
           neto_exento: Y,
           tasa_iva: 19,
           iva: Z,
           total: X + Y + Z
         }
       }
     ]
   }

7. GENERAR XML CON NOKOGIRI:
   resultado ← Dte::GeneradorXml.call(
     emisor: estructura[:emisor],
     receptor: estructura[:receptor],
     documento: estructura[:documento],
     paginas: estructura[:paginas],
     rut_envia: empresa.rut,
     actecos: empresa.actecos.map { |a| { codigo: a.codigo } }
   )
```

### Estructura XML Generada:

```xml
<EnvioDTE xmlns="http://www.sii.cl/SiiDte" version="1.0">
  <SetDTE ID="SetDoc">
    <Caratula version="1.0">
      <RutEmisor>76.XXX.XXX-X</RutEmisor>
      <RutEnvia>12.345.678-9</RutEnvia>
      <RutReceptor>98.765.432-1</RutReceptor>
      <FchResol>2020-01-15</FchResol>
      <NroResol>80</NroResol>
      <TmstFirmaEnv>2026-02-01T12:00:00</TmstFirmaEnv>
      <SubTotDTE>
        <TpoDTE>33</TpoDTE>
        <NroDTE>1</NroDTE>
      </SubTotDTE>
    </Caratula>
    
    <DTE version="1.0">
      <Documento ID="F0000000123T33">
        <Encabezado>
          <IdDoc>
            <TipoDTE>33</TipoDTE>
            <Folio>123</Folio>
            <FchEmis>2026-02-01</FchEmis>
          </IdDoc>
          <Emisor>...</Emisor>
          <Receptor>...</Receptor>
          <Totales>
            <MntNeto>100000</MntNeto>
            <TasaIVA>19</TasaIVA>
            <IVA>19000</IVA>
            <MntTotal>119000</MntTotal>
          </Totales>
        </Encabezado>
        <Detalle>...</Detalle>
        <TED version="1.0">
          <DD>
            <RE>76.XXX.XXX-X</RE>
            <TD>33</TD>
            <F>123</F>
            <FE>2026-02-01</FE>
            <RR>98.765.432-1</RR>
            <RSR>Cliente SpA</RSR>
            <MNT>119000</MNT>
            <IT1>Primer producto</IT1>
            <TSTED>2026-02-01T12:00:00</TSTED>
          </DD>
          <FRMT algoritmo="SHA1withRSA"/>
        </TED>
        <TmstFirma>2026-02-01T12:00:00</TmstFirma>
      </Documento>
    </DTE>
  </SetDTE>
</EnvioDTE>
```

---

## FASE 4: Firma Digital ⏳ PENDIENTE

**Service:** `Dte::Firmador` (por crear)

```
8. INSERTAR CAF EN TED:
   PARA CADA página EN pgs[]:
      LEER archivo CAF
      INSERTAR nodo <CAF> antes de <TSTED>

9. FIRMAR TIMBRE (TED):
   PARA CADA documento:
      // Extraer clave privada del CAF
      RSASK ← extraer_rsask(archivo_caf)
      
      // Firmar DD con SHA1withRSA
      DD_canonicalizado ← canonicalizar(nodo_DD)
      firma_timbre ← firmar_rsa_sha1(DD_canonicalizado, RSASK)
      
      // Insertar firma en FRMT
      nodo_FRMT.content ← Base64.encode(firma_timbre)

10. FIRMAR CADA DOCUMENTO:
    PARA CADA documento:
       // Calcular DigestValue
       documento_canonicalizado ← canonicalizar(nodo_Documento)
       digest ← SHA1(documento_canonicalizado)
       DigestValue ← Base64.encode(digest)
       
       // Firmar SignedInfo con certificado de la empresa
       SignedInfo_canonicalizado ← canonicalizar(nodo_SignedInfo)
       SignatureValue ← firmar_certificado(SignedInfo_canonicalizado)
       
       // Insertar datos del certificado
       Modulus, Exponent, X509Certificate ← extraer_certificado()

11. FIRMAR SetDTE:
    // Mismo proceso que paso 10, pero para el SetDTE completo
```

---

## FASE 5: Envío al SII ⏳ PENDIENTE

**Service:** `Dte::EnviadorSii` (por crear)

```
12. OBTENER TOKEN DE AUTENTICACIÓN:
    seed ← obtener_seed(url_seed)
    token ← obtener_token(seed, certificado)

13. CONSTRUIR REQUEST MULTIPART:
    secuencia ← construir_multipart(
      rutSender,
      dvSender,
      rutCompany,
      dvCompany,
      archivo_xml
    )

14. ENVIAR A SII:
    response ← POST(url_upload, secuencia, headers_con_token)
    
    // Parsear respuesta
    status ← response.xpath("//STATUS")
    
    CASE status:
      0 → trackid = response.xpath("//TRACKID") // Éxito
      1 → "Sender no tiene permiso"
      2 → "Error en tamaño del archivo"
      5 → "No está autenticado"
      6 → "Empresa no autorizada"
      7 → "Esquema Inválido"
      8 → "Firma del Documento"
      9 → "Sistema Bloqueado"
```

---

## Services Implementados

```
app/services/dte/
├── clasificador_items.rb    ✅ Pagina items con Prawn
├── asignador_folios.rb      ✅ Asigna folios del CAF
├── generador_xml.rb         ✅ Genera XML con Nokogiri
├── firmador.rb              ⏳ Firma digital (pendiente)
└── enviador_sii.rb          ⏳ Envío HTTP al SII (pendiente)
```

---

## Endpoints Disponibles

| Endpoint | Descripción | Estado |
|----------|-------------|--------|
| `POST /api/v1/dte/test_clasificacion` | Test de paginación | ✅ |
| `POST /api/v1/dte/test_folios` | Test asignación folios | ✅ |
| `POST /api/v1/dte/preparar` | Retorna estructura JSON | ✅ |
| `POST /api/v1/dte/generar_xml` | Retorna XML sin firmar | ✅ |
| `POST /api/v1/dte/generar` | DTE completo firmado | ⏳ |

---

## Modelo de Datos Utilizado

### Para obtener datos del Emisor:
```
Empresa
├── rut
├── razon_social
├── giro
├── direccion
├── telefono1
├── fecha_resolucion
├── numero_resolucion
└── acteco_empresas → actecos (códigos actividad económica)
```

### Para obtener datos de Items:
```
Producto
├── codigo
├── nombre (usado como glosa)
├── precio_unitario
└── producto_impuestos → impuestos
                         └── impuesto_valores (tasa vigente)
```

### Para determinar Afecto/Exento:
```
SI producto.producto_impuestos.any?
   → AFECTO (tiene impuestos asociados)
   → Calcular IVA y otros impuestos
SINO
   → EXENTO (no tiene impuestos)
   → No calcular impuestos
```

### Para asignar Folios:
```
TipoDocumento (codigo='33')
    ↓
TipoHabilitado (empresa_id + tipo_documento_id)
    ↓
RangoFolio (tiene archivo CAF en Active Storage)
    ↓
Folio (numero, disponible=true)
```

---

## Notas sobre Paginación

Por cada página se genera un DTE con su propio folio. Si una venta tiene muchos items que no caben en una página PDF, se divide en múltiples DTEs.

### Área de Paginación (simulada con Prawn):

```
    Página A4
    ┌────────────────────────────┐
    │   (encabezado)             │
    │                            │
    │   ┌──────────────────┐     │  ← y_ini = 500
    │   │                  │     │
    │   │  ÁREA DE ITEMS   │     │  altura = 380
    │   │  (ancho = 300)   │     │
    │   │                  │     │
    │   └──────────────────┘     │  ← y_lim = 120
    │                            │
    │   (pie de página)          │
    └────────────────────────────┘
```
