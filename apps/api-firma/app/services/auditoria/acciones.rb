# frozen_string_literal: true

module Auditoria
  module Acciones
    CATEGORIA_AUTH = 'auth'
    CATEGORIA_USUARIOS = 'usuarios'
    CATEGORIA_PERSONAS = 'personas'
    CATEGORIA_EMPRESA = 'empresa'
    CATEGORIA_CERTIFICADOS = 'certificados'
    CATEGORIA_FOLIOS = 'folios'
    CATEGORIA_CATALOGO = 'catalogo'
    CATEGORIA_DTE = 'dte'
    CATEGORIA_PRODUCTOS = 'productos'

    AUTH_LOGIN_EXITOSO = 'auth.login_exitoso'
    AUTH_LOGIN_FALLIDO = 'auth.login_fallido'
    AUTH_LOGIN_BLOQUEADO = 'auth.login_bloqueado'
    AUTH_LOGOUT = 'auth.logout'
    AUTH_REFRESH_TOKEN = 'auth.refresh_token'
    AUTH_REFRESH_TOKEN_INVALIDO = 'auth.refresh_token_invalido'
    AUTH_PASSWORD_SOLICITAR = 'auth.password_solicitar'
    AUTH_PASSWORD_RESTABLECER = 'auth.password_restablecer'
    AUTH_ONBOARDING_VERIFICAR_EMAIL = 'auth.onboarding_verificar_email'
    AUTH_ONBOARDING_ESTABLECER_PASSWORD = 'auth.onboarding_establecer_password'
    AUTH_ONBOARDING_REENVIAR_VERIFICACION = 'auth.onboarding_reenviar_verificacion'
    AUTH_ACCESO_DENEGADO = 'auth.acceso_denegado'

    USUARIO_CREAR = 'usuario.crear'
    USUARIO_ACTUALIZAR = 'usuario.actualizar'
    USUARIO_ACTIVAR = 'usuario.activar'
    USUARIO_DESACTIVAR = 'usuario.desactivar'
    USUARIO_REENVIAR_ACCESO = 'usuario.reenviar_acceso'
    USUARIO_ROL_FON_ASIGNAR = 'usuario.rol_fon_asignar'
    USUARIO_ROL_FON_QUITAR = 'usuario.rol_fon_quitar'

    PERSONA_CREAR = 'persona.crear'
    PERSONA_ACTUALIZAR = 'persona.actualizar'
    PERSONA_ELIMINAR = 'persona.eliminar'
    PERSONA_ASIGNAR_EMPRESA = 'persona.asignar_empresa'
    PERSONA_QUITAR_EMPRESA = 'persona.quitar_empresa'
    PERSONA_ADMIN_EMPRESA_OTORGAR = 'persona.admin_empresa_otorgar'
    PERSONA_ADMIN_EMPRESA_QUITAR = 'persona.admin_empresa_quitar'
    PERSONA_REENVIAR_ONBOARDING = 'persona.reenviar_onboarding'

    EMPRESA_CREAR = 'empresa.crear'
    EMPRESA_ACTUALIZAR = 'empresa.actualizar'
    EMPRESA_ELIMINAR = 'empresa.eliminar'
    EMPRESA_ACTECO_ASIGNAR = 'empresa.acteco_asignar'
    EMPRESA_ACTECO_QUITAR = 'empresa.acteco_quitar'
    EMPRESA_TIPO_DOCUMENTO_HABILITAR = 'empresa.tipo_documento_habilitar'
    EMPRESA_TIPO_DOCUMENTO_ACTUALIZAR = 'empresa.tipo_documento_actualizar'
    EMPRESA_TIPO_DOCUMENTO_DESHABILITAR = 'empresa.tipo_documento_deshabilitar'

    CERTIFICADO_CREAR = 'certificado.crear'
    CERTIFICADO_ELIMINAR = 'certificado.eliminar'
    CERTIFICADO_REEMPLAZAR = 'certificado.reemplazar'

    FOLIO_CAF_CARGAR = 'folio.caf_cargar'
    FOLIO_CAF_ELIMINAR = 'folio.caf_eliminar'

    IMPUESTO_CREAR = 'impuesto.crear'
    IMPUESTO_ACTUALIZAR = 'impuesto.actualizar'
    IMPUESTO_ELIMINAR = 'impuesto.eliminar'
    IMPUESTO_VALOR_CREAR = 'impuesto_valor.crear'
    IMPUESTO_VALOR_ACTUALIZAR = 'impuesto_valor.actualizar'
    IMPUESTO_VALOR_ELIMINAR = 'impuesto_valor.eliminar'

    DTE_PREPARAR = 'dte.preparar'
    DTE_GENERAR_XML = 'dte.generar_xml'
    DTE_FIRMAR = 'dte.firmar'
    DTE_EMITIR = 'dte.emitir'
    DTE_LIMPIAR_ENVIO = 'dte.limpiar_envio'
    DTE_LIMPIAR_ENVIOS = 'dte.limpiar_envios'

    PRODUCTO_CREAR = 'producto.crear'
    PRODUCTO_ACTUALIZAR = 'producto.actualizar'
    PRODUCTO_ELIMINAR = 'producto.eliminar'

    ETIQUETAS = {
      AUTH_LOGIN_EXITOSO => 'Inicio de sesión exitoso',
      AUTH_LOGIN_FALLIDO => 'Inicio de sesión fallido',
      AUTH_LOGIN_BLOQUEADO => 'Inicio de sesión bloqueado',
      AUTH_LOGOUT => 'Cierre de sesión',
      AUTH_REFRESH_TOKEN => 'Renovación de token',
      AUTH_REFRESH_TOKEN_INVALIDO => 'Renovación de token inválida',
      AUTH_PASSWORD_SOLICITAR => 'Solicitud de restablecimiento de contraseña',
      AUTH_PASSWORD_RESTABLECER => 'Restablecimiento de contraseña',
      AUTH_ONBOARDING_VERIFICAR_EMAIL => 'Verificación de correo (onboarding)',
      AUTH_ONBOARDING_ESTABLECER_PASSWORD => 'Establecer contraseña (onboarding)',
      AUTH_ONBOARDING_REENVIAR_VERIFICACION => 'Reenvío de verificación (onboarding)',
      AUTH_ACCESO_DENEGADO => 'Acceso denegado',
      USUARIO_CREAR => 'Creó operador de plataforma',
      USUARIO_ACTUALIZAR => 'Actualizó operador de plataforma',
      USUARIO_ACTIVAR => 'Activó operador de plataforma',
      USUARIO_DESACTIVAR => 'Desactivó operador de plataforma',
      USUARIO_REENVIAR_ACCESO => 'Reenvió acceso a operador',
      USUARIO_ROL_FON_ASIGNAR => 'Asignó rol administrador FON',
      USUARIO_ROL_FON_QUITAR => 'Quitó rol administrador FON',
      PERSONA_CREAR => 'Creó persona autorizada',
      PERSONA_ACTUALIZAR => 'Actualizó persona autorizada',
      PERSONA_ELIMINAR => 'Eliminó persona autorizada',
      PERSONA_ASIGNAR_EMPRESA => 'Asignó persona a empresa',
      PERSONA_QUITAR_EMPRESA => 'Quitó persona de empresa',
      PERSONA_ADMIN_EMPRESA_OTORGAR => 'Otorgó admin de empresa',
      PERSONA_ADMIN_EMPRESA_QUITAR => 'Quitó admin de empresa',
      PERSONA_REENVIAR_ONBOARDING => 'Reenvió enrolamiento',
      EMPRESA_CREAR => 'Creó empresa',
      EMPRESA_ACTUALIZAR => 'Actualizó empresa',
      EMPRESA_ELIMINAR => 'Eliminó empresa',
      EMPRESA_ACTECO_ASIGNAR => 'Asignó actividad económica',
      EMPRESA_ACTECO_QUITAR => 'Quitó actividad económica',
      EMPRESA_TIPO_DOCUMENTO_HABILITAR => 'Habilitó tipo de documento',
      EMPRESA_TIPO_DOCUMENTO_ACTUALIZAR => 'Actualizó habilitación de tipo de documento',
      EMPRESA_TIPO_DOCUMENTO_DESHABILITAR => 'Deshabilitó tipo de documento',
      CERTIFICADO_CREAR => 'Subió certificado digital',
      CERTIFICADO_ELIMINAR => 'Desactivó certificado digital',
      CERTIFICADO_REEMPLAZAR => 'Reemplazó certificado digital',
      FOLIO_CAF_CARGAR => 'Cargó archivo CAF',
      FOLIO_CAF_ELIMINAR => 'Eliminó rango de folios',
      IMPUESTO_CREAR => 'Creó impuesto',
      IMPUESTO_ACTUALIZAR => 'Actualizó impuesto',
      IMPUESTO_ELIMINAR => 'Eliminó impuesto',
      IMPUESTO_VALOR_CREAR => 'Registró valor de impuesto',
      IMPUESTO_VALOR_ACTUALIZAR => 'Actualizó valor de impuesto',
      IMPUESTO_VALOR_ELIMINAR => 'Eliminó valor de impuesto',
      DTE_PREPARAR => 'Preparó DTE',
      DTE_GENERAR_XML => 'Generó XML de DTE',
      DTE_FIRMAR => 'Firmó DTE',
      DTE_EMITIR => 'Emitió DTE',
      DTE_LIMPIAR_ENVIO => 'Limpió envío DTE de prueba',
      DTE_LIMPIAR_ENVIOS => 'Limpió envíos DTE de prueba',
      PRODUCTO_CREAR => 'Creó producto',
      PRODUCTO_ACTUALIZAR => 'Actualizó producto',
      PRODUCTO_ELIMINAR => 'Eliminó producto'
    }.freeze

    def self.etiqueta(accion)
      ETIQUETAS.fetch(accion, accion)
    end
  end
end
