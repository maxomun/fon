# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2026_02_01_000002) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "_backup_empresa_personas_autorizadas", id: false, force: :cascade do |t|
    t.integer "id"
    t.integer "empresa_id"
    t.integer "persona_autorizada_id"
    t.datetime "fecha_creacion", precision: nil
  end

  create_table "_backup_personas", id: false, force: :cascade do |t|
    t.integer "id"
    t.string "uid", limit: 100
    t.integer "user_id"
    t.string "nombres", limit: 250
    t.string "apellido_paterno", limit: 250
    t.string "apellido_materno", limit: 250
    t.datetime "timestamp", precision: nil
  end

  create_table "_backup_user_roles", id: false, force: :cascade do |t|
    t.integer "id"
    t.integer "rol_id"
    t.integer "user_id"
    t.datetime "timestamp", precision: nil
  end

  create_table "_backup_users", id: false, force: :cascade do |t|
    t.integer "id"
    t.string "password_digest", limit: 200
    t.string "lenguaje", limit: 10
    t.integer "estado"
    t.boolean "visible"
    t.string "email", limit: 200
    t.integer "pais_id"
    t.datetime "timestamp", precision: nil
    t.integer "empresa_id"
    t.string "username", limit: 50
  end

  create_table "acteco_empresas", id: :serial, comment: "Código de actividad económica del emisor relevante para el DTE.", force: :cascade do |t|
    t.integer "empresa_id", null: false
    t.integer "acteco_id", null: false

    t.unique_constraint ["acteco_id", "empresa_id"], name: "uq_acteco_empresa"
  end

  create_table "actecos", id: { type: :integer, comment: "llave incremental", default: nil }, comment: "CÓDIGOS DE ACTIVIDAD ECONÓMICA", force: :cascade do |t|
    t.string "codigo", limit: 6, null: false, comment: "Entero maximo de 6 de largo"
    t.string "nombre", limit: 100, null: false, comment: "Nombre o descripcion del acteco."
    t.boolean "afecto_iva", null: false
    t.integer "categoria_tributaria", null: false
    t.integer "grupo_acteco_id", null: false, comment: "llave foranea a grupo acteco."
    t.boolean "disponible_internet", null: false
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", precision: nil, null: false
    t.string "service_name", limit: 255
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "audit_events", comment: "Registro append-only de acciones críticas para auditoría.", force: :cascade do |t|
    t.string "accion", limit: 100, null: false, comment: "Código de acción, ej. auth.login_exitoso"
    t.string "categoria", limit: 50, null: false, comment: "Dominio: auth, usuarios, personas, empresa, certificados, folios, dte, catalogo"
    t.string "resultado", limit: 20, null: false, comment: "success | failure"
    t.integer "actor_user_id"
    t.string "actor_email", limit: 200
    t.string "actor_nombre", limit: 300
    t.boolean "actor_acceso_global"
    t.integer "empresa_id", comment: "Scope tenant; NULL para eventos de plataforma"
    t.string "recurso_tipo", limit: 100
    t.string "recurso_id", limit: 100
    t.string "recurso_label", limit: 300
    t.jsonb "cambios", default: {}, null: false, comment: "Diff JSON de campos relevantes (sin secretos)"
    t.jsonb "metadata", default: {}, null: false, comment: "Contexto adicional no sensible"
    t.string "codigo_error", limit: 100
    t.string "mensaje", limit: 500
    t.string "ip", limit: 45
    t.string "user_agent", limit: 500
    t.string "request_id", limit: 100
    t.datetime "created_at", precision: nil, default: -> { "now()" }, null: false
    t.index ["accion", "created_at"], name: "idx_audit_events_accion_created_at", order: { created_at: :desc }
    t.index ["actor_user_id", "created_at"], name: "idx_audit_events_actor_created_at", order: { created_at: :desc }, where: "(actor_user_id IS NOT NULL)"
    t.index ["created_at"], name: "idx_audit_events_created_at", order: :desc
    t.index ["empresa_id", "created_at"], name: "idx_audit_events_empresa_created_at", order: { created_at: :desc }, where: "(empresa_id IS NOT NULL)"
    t.index ["recurso_tipo", "recurso_id"], name: "idx_audit_events_recurso"
    t.check_constraint "resultado::text = ANY (ARRAY['success'::character varying, 'failure'::character varying]::text[])", name: "chk_audit_events_resultado"
  end

  create_table "certificados", id: :serial, force: :cascade do |t|
    t.datetime "fecha_adjuncion", precision: nil
    t.boolean "vigente", null: false
    t.datetime "fecha_caducacion", precision: nil
    t.string "responsable", limit: 100
    t.string "frase_clave", limit: 1000
    t.integer "persona_autorizada_id", null: false, comment: "Persona autorizada duena del certificado digital."
    t.index ["persona_autorizada_id", "vigente", "fecha_adjuncion"], name: "idx_certificados_vigente_persona", order: { fecha_adjuncion: :desc }
    t.index ["persona_autorizada_id"], name: "idx_certificados_persona_autorizada"
  end

  create_table "clientes", id: { type: :integer, comment: "llave primaria", default: nil }, force: :cascade do |t|
    t.string "rut", limit: 20
    t.string "razon_social", limit: 250, null: false
    t.string "giro", limit: 250, null: false
    t.string "direccion", limit: 250, null: false
    t.string "fonos", limit: 100, null: false
    t.string "codigo_postal", limit: 100
    t.string "email", limit: 100, null: false
    t.decimal "descuento", precision: 10, scale: 2
    t.integer "empresa_id", null: false

    t.unique_constraint ["empresa_id", "rut"], name: "uq_clientes_rut_empresa"
  end

  create_table "dte_envios", force: :cascade do |t|
    t.integer "empresa_id", null: false
    t.integer "usuario_id", null: false
    t.datetime "created_at", precision: nil, default: -> { "now()" }, null: false
    t.index ["empresa_id", "created_at"], name: "idx_dte_envios_empresa_created", order: { created_at: :desc }
  end

  create_table "documento_emitidos", id: :integer, default: nil, comment: "Documentos DTE, apunta a un documento en el sistema origen.", force: :cascade do |t|
    t.integer "empresa_id", null: false, comment: "Codigo intenro de la empresa que emitio el documento (facturaon soporta asi multiples empresas)"
    t.integer "folio", null: false, comment: "Numero de folio del DTE"
    t.boolean "dte", null: false, comment: "Indica que el documento es emitido electronicamente, se agrega este campo para soportar migracion de datos de la empresa cuando no era emisor electronico."
    t.boolean "manual", null: false, comment: "Indica un origen manual del documento ( se agrega para soportar migraciones de cuando la empresa no era emisor electronico )"
    t.integer "tipo_habilitado_id", null: false, comment: "El tipo de documento es un tipo de documento habilitado para la empresa (en caso de DTEs no todos los documentos son habilitados siempre)"
    t.string "rut_emisor", limit: 20, null: false, comment: "RUT de la empresa que emite el documento"
    t.string "razon_social_emisor", limit: 250, null: false, comment: "Razon social de la empresa que emite el documento"
    t.string "giro_emisor", limit: 250, null: false, comment: "Giro de la empresa que emite el documento"
    t.string "direccion_emisor", limit: 250, null: false, comment: "Direccion de la empresa que emite el documento"
    t.string "rut_receptor", limit: 20, null: false, comment: "RUT de la empresa que recepciona el documento"
    t.string "razon_social_receptor", limit: 250, null: false, comment: "Razon social de la empresa que recepciona el documento"
    t.string "giro_receptor", limit: 250, null: false, comment: "Giro de la empresa que recepciona el documento"
    t.string "direccion_receptor", limit: 250, null: false, comment: "Direccion de la empresa que recepciona el documento"
    t.string "descripcion", limit: 100, comment: "Glosa libre que permite ingreso de alguna explicacion o nota del documento."
    t.string "ruta_imagen", limit: 250, comment: "...atributo en analisis: teniendo el xml siempre se debería poder generar la imagen."
    t.integer "cliente_id", comment: "Para las emisiones autonomas es el fk a clientes."
    t.integer "usuario_id", null: false, comment: "Que usuario genera el DTE."
    t.boolean "ingreso_integrado", null: false, comment: "Indica si el origen proviene de un sistema externo integrado al facturaon."
    t.boolean "ingreso_autonomo", null: false, comment: "Indica si el documento se origina en el propio facturador."
    t.integer "referencia_id", null: false, comment: "PAra el caso de funcionamiento de facturaon integrado a otro sistema, relaciona el DTe al documento origen (el del sistema origen)."
    t.integer "asociado_id", comment: "Indica que el documento hace refencia a otro DTE (ejemplo: caso nota credito de factura)"
    t.integer "dte_envio_id", comment: "Envío DTE (XML firmado en Active Storage) al que pertenece este folio."

    t.index ["dte_envio_id"], name: "idx_documento_emitidos_dte_envio"
    t.unique_constraint ["ruta_imagen"], name: "uq_ruta_imagen"
  end

  create_table "documento_recibidos", id: :integer, default: nil, force: :cascade do |t|
    t.integer "tipo_documento_id", null: false
    t.integer "folio", null: false, comment: "Numero de folio del documento del proveedor, puede provenir de un DTE o de un documento manual."
    t.string "rut_emisor", limit: 20
    t.string "razon_social_emisor", limit: 250, null: false
    t.string "giro_emisor", limit: 250, null: false
    t.string "direccion", limit: 250, null: false
    t.integer "proveedor_id", null: false
    t.integer "empresa_id", null: false
    t.integer "user_id", comment: "En casos donde hay ingreso manual de una factura"

    t.unique_constraint ["proveedor_id", "tipo_documento_id", "folio"], name: "uq_documento_recibido"
  end

  create_table "empresa_personas_autorizadas", id: :serial, comment: "Relacion N:M entre empresas y personas autorizadas para firmar.", force: :cascade do |t|
    t.integer "empresa_id", null: false
    t.integer "persona_autorizada_id", null: false
    t.datetime "fecha_creacion", precision: nil, default: -> { "now()" }, null: false
    t.boolean "es_administrador_empresa", default: false, null: false, comment: "Indica si la persona autorizada puede administrar datos de esta empresa."
    t.index ["empresa_id"], name: "idx_empresa_personas_autorizadas_empresa"
    t.index ["persona_autorizada_id"], name: "idx_empresa_personas_autorizadas_persona"
    t.unique_constraint ["empresa_id", "persona_autorizada_id"], name: "uq_empresa_persona_autorizada"
  end

  create_table "empresas", id: :serial, comment: "El que usa el sistema para emitir DTEs, tiene sus clientes, sus documentos, proveedores,etc.", force: :cascade do |t|
    t.string "rut", limit: 20, null: false
    t.string "razon_social", limit: 250, null: false
    t.string "giro", limit: 250, null: false
    t.string "direccion", limit: 250, null: false
    t.string "archivo_logo", limit: 200, comment: "Nombre del archivo de logo."
    t.string "resolucion_timbre", limit: 250, null: false, comment: "Texto de numero de resolucion del SII para el timbre electronico (Ej: Resolucion 99 del 2015)"
    t.string "nombre_fantasia", limit: 100, null: false
    t.date "fecha_resolucion", null: false
    t.integer "numero_resolucion", null: false
    t.string "telefono2", limit: 20
    t.string "telefono1", limit: 20
    t.datetime "fecha_creacion", precision: nil, default: -> { "now()" }, null: false
    t.datetime "fecha_actualizacion", precision: nil, default: -> { "now()" }, null: false
    t.integer "pais_id", null: false, comment: "País donde opera la empresa. Define el catálogo de impuestos aplicables."
    t.index ["pais_id"], name: "idx_empresas_pais_id"
  end

  create_table "folios", id: :serial, force: :cascade do |t|
    t.integer "numero", null: false
    t.boolean "usado", default: false, null: false, comment: "indica si el numero de folio ya fue utilizado en un documento."
    t.integer "rango_folio_id", null: false, comment: "Indica a que rango de folios pertenece el numero (FK)"
    t.boolean "anulado", default: false, null: false, comment: "Si el numero de folio fue usado por un documento que fue anulado"
    t.integer "empresa_id", null: false
    t.integer "tipo_habilitado_id", null: false
    t.boolean "reservado", default: false, null: false, comment: "Estadoque indica que el numero de folio esta en el proceso de uso por parte del un usuario, si el usuario aprueba el documento entonces se cambia a usado."
    t.boolean "disponible", default: true, null: false, comment: "Estado incial del folio."

    t.unique_constraint ["numero", "rango_folio_id"], name: "uq_folio_rango"
    t.unique_constraint ["tipo_habilitado_id", "numero"], name: "uq_folio_tipo_habilitado"
  end

  create_table "grupo_actecos", id: :integer, default: nil, comment: "Agrupador de codigos actecos", force: :cascade do |t|
    t.string "nombre", limit: 100, null: false
  end

  create_table "impuesto_valores", id: :serial, comment: "Contiene los valores de los impuestos. El campo fecha es usado para detectar cual fue el valor xon que se genera la venta de un producto, la fecha indica desde cuandoes vigente el valor, una nueva tupla con fecha postrerior indica el periodo de vigencia del valor dl impuesto.", force: :cascade do |t|
    t.integer "impuesto_id", null: false
    t.float "valor", null: false, comment: "Valor del impuesto ( en % , 0-100)"
    t.datetime "fecha_activacion", precision: nil, default: "1970-01-01 00:00:00", null: false, comment: "Fecha desde la que es valido  el valor del impuesto"
    t.datetime "fecha_caducacion", precision: nil, comment: "Fecha en que caduca el valor del impues(no a´si el impuesto). Se usa para sopórtar cambios de valores de impuestos."
  end

  create_table "impuestos", id: { type: :serial, comment: "Llave " }, comment: "Catálogo de impuestos por país. Cada impuesto tiene valores históricos en impuesto_valores.", force: :cascade do |t|
    t.string "nombre", limit: 200, null: false, comment: "nombre largo del impuesto"
    t.string "abreviacion", limit: 50, null: false, comment: "Nombre corto del impuesto"
    t.integer "pais_id", null: false, comment: "País al que aplica este impuesto."

    t.unique_constraint ["pais_id", "abreviacion"], name: "uq_impuestos_pais_abreviacion"
  end

  create_table "onboarding_tokens", id: :serial, comment: "Tokens de un solo uso para verificar email y completar onboarding de personas autorizadas.", force: :cascade do |t|
    t.integer "user_id", null: false, comment: "Usuario de login asociado a la persona autorizada en proceso de enrolamiento."
    t.string "token_digest", limit: 64, null: false, comment: "SHA256 hex del token enviado por correo. Nunca almacenar el token en texto plano."
    t.string "proposito", limit: 30, null: false, comment: "verificar_email: confirma control del correo. establecer_password: permite definir clave propia."
    t.datetime "expires_at", precision: nil, null: false, comment: "Fecha/hora de expiración del token."
    t.datetime "used_at", precision: nil, comment: "Fecha/hora en que el token fue consumido. NULL = aún no usado."
    t.datetime "created_at", precision: nil, default: -> { "now()" }, null: false, comment: "Fecha/hora de emisión del token."
    t.index ["expires_at"], name: "idx_onboarding_tokens_expires_at"
    t.index ["token_digest"], name: "uq_onboarding_tokens_token_digest", unique: true
    t.index ["user_id", "proposito"], name: "idx_onboarding_tokens_user_proposito_activo", where: "(used_at IS NULL)"
    t.check_constraint "proposito::text = ANY (ARRAY['verificar_email'::character varying::text, 'establecer_password'::character varying::text, 'restablecer_password'::character varying::text])", name: "chk_onboarding_tokens_proposito"
  end

  create_table "paises", id: :serial, comment: "Catálogo de países soportados por la plataforma.", force: :cascade do |t|
    t.string "codigo", limit: 3, null: false, comment: "Código ISO del país (ej: CL, PE, AR)."
    t.string "nombre", limit: 100, null: false, comment: "Nombre del país."
    t.boolean "activo", default: true, null: false, comment: "Indica si el país está habilitado en el sistema."

    t.unique_constraint ["codigo"], name: "uq_paises_codigo"
  end

  create_table "personas_autorizadas", id: :serial, comment: "Personas naturales autorizadas a firmar DTE. Independientes del usuario de login.", force: :cascade do |t|
    t.string "rut", limit: 20, null: false
    t.string "nombres", limit: 250, null: false
    t.string "apellido_paterno", limit: 250
    t.string "apellido_materno", limit: 250
    t.string "email", limit: 200, null: false
    t.integer "estado", null: false, comment: "0: inactivo, 1: activo"
    t.integer "orden", default: 1, null: false
    t.integer "user_id", comment: "Opcional. Vinculo futuro con cuenta de usuario (users.id)."
    t.datetime "fecha_creacion", precision: nil, default: -> { "now()" }, null: false
    t.datetime "fecha_actualizacion", precision: nil, default: -> { "now()" }, null: false
    t.index ["estado"], name: "idx_personas_autorizadas_estado"
    t.unique_constraint ["email"], name: "uq_personas_autorizadas_email"
    t.unique_constraint ["rut"], name: "uq_personas_autorizadas_rut"
  end

  create_table "producto_impuestos", id: :serial, force: :cascade do |t|
    t.integer "impuesto_id", null: false
    t.integer "producto_id", null: false
    t.index ["producto_id"], name: "idx_producto_impuestos_producto_id"
    t.unique_constraint ["impuesto_id", "producto_id"], name: "uq_producto_impuestos"
  end

  create_table "productos", id: :serial, force: :cascade do |t|
    t.string "codigo", limit: 50, null: false
    t.string "nombre", limit: 250, null: false
    t.integer "empresa_id", null: false
    t.decimal "precio_unitario", precision: 10, scale: 2, null: false, comment: "Precio vigente al emitir; sin historial de precios en MVP."
    t.datetime "fecha_creacion", precision: nil, default: -> { "now()" }, null: false, comment: "Alta del producto en el catálogo de la empresa."
    t.datetime "fecha_actualizacion", precision: nil, default: -> { "now()" }, null: false, comment: "Última modificación de datos del producto (precio, nombre, impuestos, etc.)."
    t.boolean "activo", default: true, null: false, comment: "FALSE = no se ofrece en emisión; no borra historial de ventas."
    t.index ["empresa_id", "activo"], name: "idx_productos_empresa_activo"
    t.index ["empresa_id", "codigo"], name: "idx_productos_empresa_codigo"
    t.index ["empresa_id"], name: "idx_productos_empresa_id"
    t.unique_constraint ["codigo", "empresa_id"], name: "uq_productos_codigo"
  end

  create_table "proveedores", id: :integer, default: nil, force: :cascade do |t|
    t.string "rut", limit: 12, null: false
    t.string "razon_social", limit: 250, null: false
    t.string "giro", limit: 250, null: false
    t.string "direccion", limit: 250
    t.integer "empresa_id", null: false, comment: "A que empresa pertenece el proveedor."

    t.unique_constraint ["empresa_id", "rut"], name: "uq_proveedores"
  end

  create_table "rango_folios", id: :serial, force: :cascade do |t|
    t.integer "empresa_id", null: false, comment: "Empresa (emisor) a la que pertenecen los folios"
    t.string "td", limit: 10, null: false, comment: "Tipo documento SII (informativo)"
    t.integer "d", null: false, comment: "Desde"
    t.integer "h", null: false
    t.datetime "fa", precision: nil, null: false, comment: "Fecha de autorizacion"
    t.string "rsask", limit: 1000, null: false, comment: "RSA PRIVATE KEY"
    t.string "rsapubk", limit: 1000, null: false, comment: "RSA PUBLIC KEY"
    t.integer "tipo_habilitado_id", null: false
    t.datetime "fecha_uso", precision: nil, comment: "Indica la ultima fecha en ue se uso el rango."
    t.string "archivo", limit: 250, null: false, comment: "Nombre del archivo usado para la carga de la tupla."
    t.string "username", null: false, comment: "Quien realizo la carga del archivo de folios autorizados CAF"
    t.datetime "fecha_subida", precision: nil, null: false, comment: "Cuando se realiza la subida del archivo de folios al sistema."

    t.unique_constraint ["archivo"], name: "uq_rango_folios_archivo"
  end

  create_table "refresh_tokens", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "token", null: false
    t.datetime "expires_at", null: false
    t.datetime "revoked_at"
    t.string "user_agent"
    t.string "ip_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_refresh_tokens_on_expires_at"
    t.index ["token"], name: "index_refresh_tokens_on_token", unique: true
    t.index ["user_id", "revoked_at"], name: "index_refresh_tokens_on_user_id_and_revoked_at"
    t.index ["user_id"], name: "index_refresh_tokens_on_user_id"
  end

  create_table "roles", id: :integer, default: nil, force: :cascade do |t|
    t.string "codigo", limit: 100, null: false, comment: "nombre corto"
    t.string "descripcion", limit: 200, null: false, comment: "nombre largo, mas explicativo"
    t.boolean "esadmin", null: false, comment: "indica rol admin"
  end

  create_table "tipo_documentos", id: :integer, default: nil, force: :cascade do |t|
    t.string "codigo", limit: 10, null: false
    t.string "nombre", limit: 100, null: false
    t.boolean "dte", null: false
    t.boolean "manual", null: false

    t.unique_constraint ["codigo", "dte"], name: "uq_codigos_dte"
    t.unique_constraint ["codigo", "manual"], name: "uq_codigos_manual"
  end

  create_table "tipo_habilitados", id: :serial, comment: "Tipos de documentos habilitados ( validados por SII ) para la empresa.", force: :cascade do |t|
    t.integer "empresa_id", null: false
    t.integer "tipo_documento_id", null: false
    t.datetime "fecha_habilitacion", precision: nil, null: false

    t.unique_constraint ["tipo_documento_id", "empresa_id"], name: "uq_habilitados"
  end

  create_table "token_blacklists", force: :cascade do |t|
    t.string "jti", null: false
    t.datetime "exp", null: false
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["exp"], name: "index_token_blacklists_on_exp"
    t.index ["jti"], name: "index_token_blacklists_on_jti", unique: true
    t.index ["user_id"], name: "index_token_blacklists_on_user_id"
  end

  create_table "user_roles", id: :serial, comment: "roles asignados al usuario", force: :cascade do |t|
    t.integer "rol_id", null: false
    t.integer "user_id", null: false
    t.datetime "timestamp", precision: nil, default: -> { "now()" }, null: false

    t.unique_constraint ["user_id", "rol_id"], name: "uq_user_roles_user_id"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "password_digest", limit: 200, null: false
    t.string "lenguaje", limit: 10, null: false, comment: "es, en, pl, etc"
    t.integer "estado", null: false, comment: "0: inactivo 1: activo"
    t.boolean "visible", default: true, null: false
    t.string "email", limit: 200, null: false
    t.integer "pais_id"
    t.datetime "timestamp", precision: nil, default: -> { "now()" }, null: false
    t.string "username", limit: 50, null: false
    t.string "nombres", limit: 250
    t.string "apellido_paterno", limit: 250
    t.string "apellido_materno", limit: 250
    t.datetime "email_verificado_at", precision: nil, comment: "Momento en que el usuario confirmó control de su correo. NULL = pendiente."
    t.datetime "onboarding_completado_at", precision: nil, comment: "Momento en que terminó el enrolamiento (verificación + password propia)."
    t.boolean "debe_cambiar_password", default: false, null: false, comment: "TRUE mientras la cuenta usa password temporal o debe ser reemplazada en onboarding."

    t.unique_constraint ["email"], name: "uq_usuarios_email"
    t.unique_constraint ["username"], name: "uq_usuarios_username"
  end

  create_table "venta_detalles", id: :integer, default: nil, force: :cascade do |t|
    t.integer "documento_emitido_id", null: false
    t.string "item", limit: 250, null: false, comment: "Describe la entrada en el detalle de un DTE (corresponde al producto, servicio, etc..)"
    t.decimal "cantidad", precision: 10, scale: 2, null: false, comment: "Cantidad del item."
    t.decimal "descuento", precision: 10, scale: 2, default: "0.0", null: false, comment: "Descuento del item."
    t.decimal "precio_unitario", precision: 10, scale: 2, null: false, comment: "PRecio unitario"
    t.boolean "afecto", null: false, comment: "Indica si es afecto a impuesto."
    t.decimal "impuesto", precision: 10, scale: 2, null: false, comment: "Porcentaje ( 0-99.99) de impuesto del afecto."
    t.integer "referencia_detalle_id", comment: "referencia al documento originado en sistema que alimenta al  FO"
    t.integer "producto_id", comment: "Indica el producto vendido, valido este campo para aquellos documentos emitidos en forma autonoma por facturaon (no integrado)"
  end

  add_foreign_key "acteco_empresas", "actecos", name: "fk_acteco_empresas_actecos"
  add_foreign_key "actecos", "grupo_actecos", name: "fk_actecos_grupo_actecos"
  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "audit_events", "empresas", name: "fk_audit_events_empresa", on_delete: :nullify
  add_foreign_key "audit_events", "users", column: "actor_user_id", name: "fk_audit_events_actor_user", on_delete: :nullify
  add_foreign_key "certificados", "personas_autorizadas", column: "persona_autorizada_id", name: "fk_certificados_personas_autorizadas"
  add_foreign_key "documento_emitidos", "clientes", name: "fk_dtev_documentos_dte_clientes"
  add_foreign_key "documento_emitidos", "documento_emitidos", column: "asociado_id", name: "fk_documento_emitidos_documento_emitidos"
  add_foreign_key "documento_emitidos", "dte_envios", name: "fk_documento_emitidos_dte_envios"
  add_foreign_key "documento_emitidos", "tipo_habilitados", name: "fk_documento_emitidos_tipo_habilitados"
  add_foreign_key "documento_emitidos", "users", column: "usuario_id", name: "fk_documento_ventas_usuarios"
  add_foreign_key "dte_envios", "empresas", name: "fk_dte_envios_empresas"
  add_foreign_key "dte_envios", "users", column: "usuario_id", name: "fk_dte_envios_users"
  add_foreign_key "documento_recibidos", "proveedores", name: "fk_documento_compras_proveedores"
  add_foreign_key "documento_recibidos", "tipo_documentos", name: "fk_documento_compras_tipo_documentos"
  add_foreign_key "documento_recibidos", "users", name: "fk_documento_compras_usuarios"
  add_foreign_key "empresa_personas_autorizadas", "empresas", name: "fk_empresa_personas_autorizadas_empresas"
  add_foreign_key "empresa_personas_autorizadas", "personas_autorizadas", column: "persona_autorizada_id", name: "fk_empresa_personas_autorizadas_personas"
  add_foreign_key "empresas", "paises", name: "fk_empresas_paises"
  add_foreign_key "folios", "rango_folios", name: "fk_folios_rango_folios"
  add_foreign_key "folios", "tipo_habilitados", name: "fk_folios_tipo_habilitados"
  add_foreign_key "impuesto_valores", "impuestos", name: "fk_impuesto_valores_impuestos"
  add_foreign_key "impuestos", "paises", name: "fk_impuestos_paises"
  add_foreign_key "onboarding_tokens", "users", name: "fk_onboarding_tokens_users", on_delete: :cascade
  add_foreign_key "personas_autorizadas", "users", name: "fk_personas_autorizadas_users"
  add_foreign_key "producto_impuestos", "impuestos", name: "fk_producto_impuestos_impuestos", on_delete: :restrict
  add_foreign_key "producto_impuestos", "productos", name: "fk_producto_impuesto_productos", on_delete: :cascade
  add_foreign_key "productos", "empresas", name: "fk_productos_empresas", on_delete: :cascade
  add_foreign_key "rango_folios", "tipo_habilitados", name: "fk_folios_tipo_habilitados"
  add_foreign_key "refresh_tokens", "users"
  add_foreign_key "tipo_habilitados", "tipo_documentos", name: "fk_tipo_habilitados_tipo_documentos"
  add_foreign_key "token_blacklists", "users"
  add_foreign_key "user_roles", "roles", name: "fk_user_roles_roles"
  add_foreign_key "user_roles", "users", name: "fk_user_roles_users"
  add_foreign_key "venta_detalles", "documento_emitidos", name: "fk_dte_documento_detalles_dte_documentos"
  add_foreign_key "venta_detalles", "productos", name: "fk_venta_detalles_productos"
end
