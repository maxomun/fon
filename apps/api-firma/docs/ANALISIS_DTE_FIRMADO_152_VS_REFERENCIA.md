# Análisis: dte_firmado_152 vs F60T33-ejemplo (firma SetDTE)

## Archivos comparados

| Archivo | Descripción |
|---------|-------------|
| `tmp/dte_firmado_152_20260307_144520.xml` | XML generado por nuestra app; **firma del sobre vacía** |
| `tmp/F60T33-ejemplo.xml` | Referencia SII; **firma del sobre correctamente poblada** |

---

## Estructura esperada de la firma del SetDTE (referencia F60T33)

La segunda `<Signature>` (firma del sobre) va **inmediatamente después de `</SetDTE>`**, como hermano de `SetDTE`, dentro de `EnvioDTE`:

```xml
</SetDTE><Signature xmlns="http://www.w3.org/2000/09/xmldsig#">
  <SignedInfo>
    <CanonicalizationMethod Algorithm="..."/>
    <SignatureMethod Algorithm="...rsa-sha1"/>
    <Reference URI="#SetDoc">
      <Transforms>...</Transforms>
      <DigestMethod Algorithm="...sha1"/>
      <DigestValue>4OTWXyRl5fw3htjTyZXQtYEsC3E=</DigestValue>
    </Reference>
  </SignedInfo>
  <SignatureValue>sBnr8Yq14vVAcrN/pKLD/BrqUFczKMW3y1t3JOrdsxhhq6IxvS13SgyMXbIN/...</SignatureValue>
  <KeyInfo>
    <KeyValue>
      <RSAKeyValue>
        <Modulus>tNEknkb1kHiD1OOAWlLKkcH/UP5UGa6V6MYso++JB+vYMg2OXFROAF7G8BNFFPQx...</Modulus>
        <Exponent>AQAB</Exponent>
      </RSAKeyValue>
    </KeyValue>
    <X509Data>
      <X509Certificate>MIIEgjCCA+ugAwIBAgIEAQAApzANBgkqhkiG9w0BAQUFADCBtTELMAkGA1UEBhMC...</X509Certificate>
    </X509Data>
  </KeyInfo>
</Signature>
```

En la referencia, **todos** estos nodos tienen contenido:
- `SignatureValue`: valor Base64 de la firma.
- `Modulus` y `Exponent`: clave pública RSA.
- `X509Certificate`: certificado en Base64.

---

## Qué tiene el generado (dte_firmado_152)

- **Estructura**: correcta. La segunda `Signature` está después de `</SetDTE>`, con `Reference URI="#SetDoc"` y `DigestValue` presente (`DPJGBtqvzerW3lA8zfc9Hl2Sge4=`).
- **Firma del DTE** (primera `Signature`, `URI="#F0000000001T33"`): **completa** — `SignatureValue`, `Modulus`, `Exponent`, `X509Certificate` llenos.
- **Firma del SetDTE** (segunda `Signature`, `URI="#SetDoc"`): **vacía**:
  - `<SignatureValue/>` sin contenido.
  - `<Modulus/>` y `<Exponent/>` vacíos.
  - `<X509Certificate/>` vacío.

Es decir: el template de la firma del sobre se inserta bien y el digest del SetDTE se calcula, pero **xmlsec1 no rellena** esa segunda firma (no calcula `SignatureValue` ni rellena `KeyInfo`).

---

## Conclusión

- La **posición y forma** de la firma del SetDTE en nuestro XML coinciden con la referencia.
- Lo que falta en el generado es **solo el contenido** que debe poner xmlsec1 en la segunda `Signature`: `SignatureValue`, `Modulus`, `Exponent`, `X509Certificate`.
- Eso apunta a que xmlsec1 **no está resolviendo** la referencia `#SetDoc` (no asocia el atributo `ID="SetDoc"` del elemento `<SetDTE>` con la referencia), por eso no firma ese bloque y deja los placeholders vacíos.

En el código ya se aplicó:
- Uso de `--id-attr:ID` con namespace para `Documento` y `SetDTE` (`http://www.sii.cl/SiiDte:Documento` y `http://www.sii.cl/SiiDte:SetDTE`).
- Validación `validar_firmas_no_vacias!` para no entregar XML si alguna firma queda vacía.

Si tras volver a generar el EnvioDTE la firma del SetDTE sigue vacía, conviene:
1. Probar xmlsec1 a mano con el mismo XML y los mismos `--id-attr` para ver stderr/stdout.
2. Probar un DTD que declare los atributos ID de `Documento` y `SetDTE` y pasar `--dtd-file` a xmlsec1 (método recomendado en la documentación).
