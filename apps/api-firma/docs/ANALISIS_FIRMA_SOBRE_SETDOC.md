# Análisis: firma del sobre (SetDoc) vacía

## Resumen del problema

En el XML EnvioDTE generado:

- **Firma del DTE** (`Reference URI="#F0000000001T33"`): `SignatureValue`, `Modulus`, `Exponent`, `X509Certificate` **sí vienen poblados**.
- **Firma del sobre** (`Reference URI="#SetDoc"`): los mismos nodos aparecen **vacíos**.

El sistema está generando el nodo `<Signature>` del SetDTE pero xmlsec1 no está rellenando sus valores.

---

## Causa raíz

### 1. Resolución del atributo ID para SetDTE

`xmlsec1` resuelve las referencias `URI="#xxx"` buscando elementos cuyo **atributo ID** esté declarado como tal. Esa declaración se hace con:

```text
--id-attr[:attr-name] [namespace-uri:]node-name
```

En el código actual se usa:

- `--id-attr:ID Documento`
- `--id-attr:ID SetDTE`

**Sin indicar el namespace del elemento.** En el XML, `<Documento>` y `<SetDTE>` están en el namespace del SII: `http://www.sii.cl/SiiDte`. Si no se indica ese namespace en `--id-attr`, xmlsec1 puede:

- Resolver bien el primer elemento que encuentra (p. ej. un `Documento` con ese ID), y
- **No** considerar el atributo `ID` de `<SetDTE ID="SetDoc">` como ID válido para la referencia `#SetDoc`, por estar el elemento en otro namespace.

Resultado: la primera firma (del DTE) se calcula y se rellenan `SignatureValue` y `KeyInfo`; la segunda (del sobre) no se procesa correctamente y queda con placeholders vacíos.

### 2. Falta de validación post-firma

Aunque `xmlsec1 --verify` pase, no se comprueba en Ruby que **todas** las `<Signature>` tengan:

- `SignatureValue` no vacío
- `KeyInfo` (p. ej. `X509Certificate`, `Modulus`, `Exponent`) rellenado

Si por cualquier motivo xmlsec1 deja una firma a medias, el flujo actual devuelve ese XML como válido.

### 3. No fallar ante firmas incompletas

Si alguna firma queda vacía, el proceso debería **abortar con error explícito** y no devolver nunca un EnvioDTE con firmas incompletas. Hoy no hay esa garantía.

---

## Correcciones aplicadas

1. **XmlSignerWithXmlsec**
   - Pasar el namespace SII en `--id-attr` para que tanto `Documento` como `SetDTE` sean reconocidos al resolver `#F000...` y `#SetDoc`:
     - `--id-attr:ID http://www.sii.cl/SiiDte:Documento`
     - `--id-attr:ID http://www.sii.cl/SiiDte:SetDTE`
   - Tras `--sign` y `--verify`, validar en Ruby que **ninguna** `<Signature>` tenga `SignatureValue` o `X509Certificate` vacíos; si alguna está vacía, lanzar excepción clara (no devolver XML).

2. **Firmador**
   - Tras recibir el XML firmado de `XmlSignerWithXmlsec`, opcionalmente comprobar de nuevo que no haya firmas vacías (doble capa de seguridad).
   - Si alguna firma está vacía o el firmado falla: **no** devolver `success: true`; devolver `success: false` con mensaje explícito o lanzar excepción según el contrato del servicio.
   - Asegurar que **nunca** se genere XML final con firmas vacías o incompletas; en ese caso el proceso debe fallar de forma explícita.

Con esto se corrige la causa raíz (reconocimiento del ID de SetDTE por xmlsec1) y se cumplen los requisitos de no entregar XML con firmas vacías y de fallar de forma clara si el firmado del sobre (o cualquier firma) no se completa.

---

## Entregables (código)

- **`app/services/dte/xml_signer_with_xmlsec.rb`**: `--id-attr:ID` con namespace (`http://www.sii.cl/SiiDte:Documento` y `...:SetDTE`), método `validar_firmas_no_vacias!(xml_string)` y excepción `Dte::XmlSecFirmaIncompletaError`.
- **`app/services/dte/firmador.rb`**: rescue explícito de `XmlSecFirmaIncompletaError`; nunca se devuelve `success: true` si alguna firma quedó vacía.
