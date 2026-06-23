# frozen_string_literal: true

module EmpresaAuthorizable
  extend ActiveSupport::Concern

  private

  def require_administrador_fon!
    authorize_role!(User::ROL_ADMINISTRADOR_FON)
  end

  def require_admin_empresa!
    authorize_admin_empresa!(params[:empresa_id])
  end

  def require_empresas_visibility!
    return if current_user.administrador_fon?
    return if current_user.empresas_como_administrador.exists?

    audit_acceso_denegado!(
      codigo: 'FORBIDDEN',
      mensaje: 'No tiene empresas asignadas para administrar'
    )
    render_error(
      'No tiene empresas asignadas para administrar',
      :forbidden,
      code: 'FORBIDDEN'
    )
  end

  def authorize_empresa_show!
    return if current_user.administrador_fon?

    authorize_admin_empresa!(params[:id])
  end
end
