# Arquitectura DTE - FacturaOn API

## Plan de Variantes

El sistema soportará **dos variantes** de generación de DTE:

### Variante A: Sistema Integrado (PRIORIDAD ACTUAL) ✅ EN DESARROLLO

- **Endpoint final:** `/api/v1/dte/generar`
- **Filosofía:** Mínimo input, máximo cálculo automático
- **Datos en BD:** empresas, productos, impuestos, CAF, certificados, clientes

#### Decisiones de Diseño:

| Concepto | Decisión | Razón |
|----------|----------|-------|
| **Emisor** | Se obtiene de BD con `empresa_id` | Los datos del emisor son fijos |
| **Receptor** | Se envía en JSON | Cambia cada factura |
| **Items** | Solo `producto_id` + `cantidad` | Nombre, precio, código se obtienen de BD |
| **Afecto/Exento** | Calculado desde `producto_impuestos` | Si no hay registros → exento |
| **Impuestos** | Tasas desde `impuesto_valores` vigente | Siempre usa la tasa actual |
| **Folios** | Asignados automáticamente del CAF | Desde `rango_folios` → `folios` |

#### Request Mínimo (Variante A):
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

### Variante B: API de Firma Pura (SIGUIENTE FASE) ⏳ PENDIENTE

- **Endpoint:** `/api/v1/dte/firmar`
- **Filosofía:** El cliente envía todo calculado, nosotros solo firmamos
- **Datos en BD:** Solo certificados y CAF
- **Uso típico:** Sistemas externos que ya tienen su propia lógica de facturación

#### Request Completo (Variante B):
```json
{
  "empresa_id": 101,
  "emisor": {
    "rut": "76.XXX.XXX-X",
    "razon_social": "Mi Empresa",
    "giro": "...",
    ...
  },
  "receptor": { ... },
  "items": [
    {
      "codigo": "SKU001",
      "glosa": "Producto X",
      "cantidad": 2,
      "precio_unitario": 10000,
      "afecto": true,
      "impuestos": [{ "codigo": "IVA", "tasa": 19 }]
    }
  ],
  "totales": {
    "neto": 100000,
    "iva": 19000,
    "total": 119000
  }
}
```

---

## Orden de Implementación

1. **Variante A** (en desarrollo activo)
2. **Variante B** (posterior, reutiliza Firmador y EnviadorSii)

---

## Estado de Fases - Variante A

| Fase | Descripción | Estado | Notas |
|------|-------------|--------|-------|
| 1 | Preparación del Entorno | ✅ | gems: nokogiri, prawn, matrix, rest-client |
| 2 | Paginación y Folios | ✅ | Services: ClasificadorItems, AsignadorFolios |
| 2.5 | Endpoint `preparar` | ✅ | Items desde BD con impuestos calculados |
| 3 | Generación de XML | ✅ | Service: GeneradorXml con Nokogiri |
| 3.5 | Endpoint Certificados | ✅ | CRUD certificados con Active Storage |
| 4 | Firma Digital | ✅ | Service: Firmador (TED + Documento + SetDTE) |
| 5 | Envío al SII | ⏳ | Service: EnviadorSii (token + upload) |
| 6 | Endpoint `/generar` | ⏳ | Orquesta todo el flujo completo |
| 7 | Config final | ⏳ | Variables de entorno, manejo de errores |

---

## Modelo de Datos Utilizado

### Obtención de datos del Emisor
```
Empresa
├── rut, razon_social, giro, direccion
├── telefono1
├── fecha_resolucion, numero_resolucion
└── acteco_empresas → actecos
```

### Obtención de datos de Productos
```
Producto
├── codigo (SKU)
├── nombre (usado como glosa en DTE)
├── precio_unitario
└── producto_impuestos → impuestos → impuesto_valores
                                      └── valor (tasa vigente)
```

### Lógica Afecto/Exento
```ruby
# En preparar_items del DteController
afecto = producto.producto_impuestos.any?

# Si tiene registros en producto_impuestos → AFECTO (suma IVA, etc.)
# Si NO tiene registros → EXENTO (sin impuestos)
```

### Asignación de Folios
```
TipoDocumento (codigo='33' para Factura)
    ↓
TipoHabilitado (vincula empresa con tipo de documento)
    ↓
RangoFolio (contiene archivo CAF en Active Storage)
    ↓
Folio (números individuales, disponible=true/false)
```

---

## Services Creados

```
app/services/dte/
├── clasificador_items.rb    ✅ Pagina items según área de PDF
├── asignador_folios.rb      ✅ Asigna folios disponibles del CAF
├── generador_xml.rb         ✅ Construye XML con Nokogiri
├── firmador.rb              ✅ Firma digital (TED + Documento + SetDTE)
└── enviador_sii.rb          ⏳ Comunicación con SII (pendiente)
```

### Patrón de Service Object
```ruby
# Todos siguen el mismo patrón:
module Dte
  class MiService
    def self.call(**params)
      new(**params).call
    end
    
    def initialize(**params)
      @params = params
    end
    
    def call
      # Lógica principal
      { success: true, data: resultado }
    end
  end
end
```

---

## Endpoints Actuales

### DTE (Generación)
| Método | Ruta | Descripción | Auth | Estado |
|--------|------|-------------|------|--------|
| POST | `/api/v1/dte/test_clasificacion` | Test paginación | No | ✅ |
| POST | `/api/v1/dte/test_folios` | Test asignación folios | No | ✅ |
| POST | `/api/v1/dte/preparar` | Retorna estructura JSON lista para XML | No | ✅ |
| POST | `/api/v1/dte/generar_xml` | Genera XML sin firmar | No | ✅ |
| POST | `/api/v1/dte/firmar_xml` | Genera XML y lo firma | No | ✅ |
| POST | `/api/v1/dte/generar` | DTE completo + envío SII (Variante A) | Sí | ⏳ |
| POST | `/api/v1/dte/firmar` | Solo firma (Variante B) | Sí | ⏳ |

### Certificados Digitales
| Método | Ruta | Descripción | Auth | Estado |
|--------|------|-------------|------|--------|
| POST | `/api/v1/certificados/crear` | Sube certificado digital | No | ✅ |
| GET | `/api/v1/certificados/listar` | Lista certificados | No | ✅ |
| POST | `/api/v1/certificados/verificar` | Verifica certificado | No | ✅ |
| DELETE | `/api/v1/certificados/eliminar` | Elimina certificado | No | ✅ |

### Rangos de Folios (CAF)
| Método | Ruta | Descripción | Auth | Estado |
|--------|------|-------------|------|--------|
| POST | `/api/v1/rango_folios/cargar` | Carga archivo CAF y crea folios | No | ✅ |
| GET | `/api/v1/rango_folios/listar` | Lista rangos de una empresa | No | ✅ |
| GET | `/api/v1/rango_folios/obtener` | Detalle de un rango | No | ✅ |
| DELETE | `/api/v1/rango_folios/eliminar` | Elimina rango y folios | No | ✅ |

---

## Configuración SII

Archivo: `config/initializers/sii.rb`

```ruby
Rails.application.config.sii.ambiente  # 'certificacion' o 'produccion'
Rails.application.config.sii.url_upload
Rails.application.config.sii.url_token
Rails.application.config.sii.url_seed
Rails.application.config.sii.timezone  # 'America/Santiago'
```

Variable de entorno: `SII_AMBIENTE` (default: `certificacion`)

---

## Documentación Relacionada

- [ALGORITMO_GENERAR_XML_33.md](./ALGORITMO_GENERAR_XML_33.md) - Algoritmo detallado de generación DTE

---

## Gestión de Archivos Temporales

El sistema incluye **limpieza automática** de archivos temporales generados durante el proceso DTE:

### Archivos Generados

| Archivo | Servicio | Propósito |
|---------|----------|-----------|
| `dte_*.pdf` | ClasificadorItems | Simulación de paginación |
| `dte_*.xml` | GeneradorXml | XML generado (pre-firma) |

### Mecanismo de Limpieza

1. **Inmediata**: Cada endpoint limpia sus archivos temporales al finalizar (vía `ensure`)
2. **Periódica**: Archivos con más de 60 minutos se eliminan automáticamente

```ruby
# Métodos en DteController
limpiar_archivos_temporales(archivos)       # Limpia archivos específicos
limpiar_archivos_temporales_antiguos(60)    # Limpia archivos > 60 min
```

---

## Próximos Pasos

1. ~~**Fase 4 - Firma Digital:**~~ ✅ COMPLETADA
   - ~~Crear `Dte::Firmador`~~
   - ~~Firmar TED con clave privada del CAF~~
   - ~~Firmar Documento con certificado de empresa~~
   - ~~Firmar SetDTE completo~~

2. **Fase 5 - Envío al SII:**
   - Crear `Dte::EnviadorSii`
   - Obtener token de autenticación
   - Construir request multipart
   - Enviar y procesar respuesta (trackid)

3. **Fase 6 - Endpoint Final `/generar`:**
   - Orquestar todo el proceso
   - Almacenar DTE en base de datos
   - Retornar PDF y estado final
