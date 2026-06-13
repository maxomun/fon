## Contexto últimos avances firma DTE

Fecha: 2026-03-04  
Rama: `feature/firma-digital-firmador-ted-documento-setdte`

### Objetivo general

- **Implementar la firma electrónica completa del EnvioDTE** usando `xmlsec1` como única fuente de `SignatureValue`, respetando el esquema `EnvioDTE_v10.xsd` y la normativa del SII.

### Estado actual (servicio `Dte::Firmador`)

- **Servicio principal**: `Dte::Firmador` recibe:
  - `xml_string`: XML del `EnvioDTE` generado previamente (ver `ALGORITMO_GENERAR_XML_33.md`).
  - `empresa_id`: para obtener el certificado vigente de la empresa (`empresa.certificado_vigente`).
  - `paginas`: arreglo con la metadata por documento (incluye `rango_folio_id` y `rsask` del CAF).
- **Flujo principal (`call`)**:
  - Parseo del XML con `Nokogiri` y fijar `encoding` a `ISO-8859-1`.
  - Obtención y validación del certificado vigente de la empresa.
  - Para cada documento:
    - Inserta el nodo `CAF` dentro del `DD` del `TED` usando `RangoFolio` y el archivo CAF adjunto (`insertar_caf`).
    - Firma el `TED` con la clave privada del CAF (`rsask`) usando `OpenSSL::PKey::RSA` + `SHA1`; el resultado se guarda en el nodo `FRMT` (`firmar_ted`).
    - Calcula `DigestValue` del nodo `<Documento>` canonicalizado y construye un template de `<Signature>` como hijo de `<DTE>` inmediatamente después de `<Documento>` (`firmar_documento` + `insertar_signature_como_hijo`).
  - Calcula el `DigestValue` de `<SetDTE>` canonicalizado y genera un `<Signature>` adicional para el SetDTE, insertado como hermano de `<SetDTE>` (`firmar_set_dte` + `insertar_signature_template_after`).
  - Convierte el XML a string (`ISO-8859-1`) e invoca `Dte::XmlSignerWithXmlsec` para:
    - Completar los `SignatureValue` usando `xmlsec1`.
    - Ejecutar `sign + verify` como paso obligatorio de validación.
- **Cálculo de digest**:
  - Se usa `OpenSSL::Digest::SHA1` y el resultado se codifica en Base64 sin saltos de línea (`calcular_digest`).
- **Manejo de errores y logging**:
  - Logs detallados en cada paso (inicio, obtención de certificado, inserción de CAF, firma de TED, inserción de templates de firma de DTE y SetDTE, invocación de `xmlsec1`).
  - Captura explícita de `Dte::XmlSecVerifyError` y errores genéricos, devolviendo `{ success: false, error: mensaje }` en caso de fallo.

### Puntos pendientes / próximos pasos (estimados)

- **Validación exhaustiva** del XML firmado contra:
  - Esquema XSD del SII.
  - Herramientas oficiales de validación (si aplica).
- **Pruebas de integración**:
  - Flujo completo desde generación de XML (`GeneradorXml`) hasta el servicio de envío al SII.
  - Casos con múltiples DTE en un mismo `SetDTE` y distintos rangos de folios.
- **Monitoreo y observabilidad**:
  - Revisar que los logs actuales del `Firmador` sean suficientes para debug en producción.
  - Evaluar métricas (tiempos de firma, cantidad de documentos por set, errores frecuentes).

### Referencias internas

- **Arquitectura y generación de XML**:
  - `docs/ARQUITECTURA_DTE.md`
  - `docs/ALGORITMO_GENERAR_XML_33.md`

