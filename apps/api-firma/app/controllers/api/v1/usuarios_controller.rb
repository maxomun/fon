# frozen_string_literal: true

module Api
  module V1
    class UsuariosController < BaseController
      include UserSerializable
      include EmpresaAuthorizable

      before_action :require_administrador_fon!
      before_action :set_usuario, only: [:show, :update, :estado, :reenviar_acceso]

      # GET /api/v1/usuarios?q=&tipo=plataforma|persona|todos
      def index
        usuarios = usuarios_scope
          .includes(:roles, :persona_autorizada)
          .order(:email)

        render_success(
          data: usuarios.map { |usuario| user_admin_payload(usuario) }
        )
      end

      # GET /api/v1/usuarios/:id
      def show
        render_success(data: user_admin_payload(@usuario, detalle: true))
      end

      # POST /api/v1/usuarios
      def create
        resultado = Users::CrearOperador.call(
          attributes: usuario_create_params,
          enviar_acceso: cast_boolean(usuario_create_params[:enviar_acceso])
        )

        if resultado.success?
          render_success(
            data: user_admin_payload(resultado.user.reload, detalle: true),
            status: :created,
            message: mensaje_crear(resultado)
          )
        else
          render_user_error('Error al crear usuario', resultado.errors)
        end
      end

      # PATCH/PUT /api/v1/usuarios/:id
      def update
        resultado = Users::ActualizarOperador.call(
          user: @usuario,
          attributes: usuario_update_params
        )

        if resultado.success?
          render_success(
            data: user_admin_payload(resultado.user.reload, detalle: true),
            message: 'Usuario actualizado exitosamente'
          )
        else
          render_user_error('Error al actualizar usuario', resultado.errors)
        end
      end

      # PATCH /api/v1/usuarios/:id/estado
      def estado
        resultado = Users::CambiarEstado.call(
          user: @usuario,
          activo: usuario_estado_params[:activo],
          actor: current_user
        )

        if resultado.success?
          render_success(
            data: user_admin_payload(resultado.user.reload),
            message: resultado.user.activo? ? 'Usuario activado exitosamente' : 'Usuario desactivado exitosamente'
          )
        else
          render_user_error('No se pudo cambiar el estado del usuario', resultado.errors)
        end
      end

      # POST /api/v1/usuarios/:id/reenviar_acceso
      def reenviar_acceso
        resultado = Users::ReenviarAcceso.call(user: @usuario)

        if resultado.success? && resultado.enviado
          render_success(
            data: user_admin_payload(@usuario.reload),
            message: 'Se envió un correo para restablecer la contraseña'
          )
        elsif resultado.success?
          render_success(
            data: user_admin_payload(@usuario.reload),
            message: resultado.message
          )
        else
          render_error(
            'No se pudo reenviar el acceso',
            :unprocessable_entity,
            code: resultado.code || 'REENVIAR_ACCESO_FAILED',
            errors: resultado.errors
          )
        end
      end

      private

      def set_usuario
        @usuario = User.includes(
          :roles,
          persona_autorizada: [:empresas, :empresa_personas_autorizadas]
        ).find(params[:id])
      end

      def usuarios_scope
        scope = User.all

        case params[:tipo].to_s.strip.downcase
        when 'plataforma'
          scope = scope.where.missing(:persona_autorizada)
        when 'persona', 'persona_autorizada'
          scope = scope.joins(:persona_autorizada)
        end

        if params[:q].present?
          query = "%#{params[:q].to_s.strip}%"
          scope = scope.where(
            <<~SQL.squish,
              users.email ILIKE :q
              OR users.username ILIKE :q
              OR users.nombres ILIKE :q
              OR users.apellido_paterno ILIKE :q
              OR users.apellido_materno ILIKE :q
            SQL
            q: query
          )
        end

        scope.limit(100)
      end

      def usuario_create_params
        params.require(:usuario).permit(
          :email,
          :username,
          :nombres,
          :apellido_paterno,
          :apellido_materno,
          :lenguaje,
          :visible,
          :password,
          :password_confirmation,
          :administrador_fon,
          :enviar_acceso
        ).to_h.symbolize_keys
      end

      def usuario_update_params
        params.require(:usuario).permit(
          :email,
          :username,
          :nombres,
          :apellido_paterno,
          :apellido_materno,
          :lenguaje,
          :visible,
          :password,
          :password_confirmation,
          :administrador_fon
        ).to_h.symbolize_keys
      end

      def usuario_estado_params
        params.require(:usuario).permit(:activo)
      end

      def cast_boolean(value)
        ActiveModel::Type::Boolean.new.cast(value) || false
      end

      def mensaje_crear(resultado)
        if resultado.acceso_enviado
          'Usuario creado exitosamente. Se envió un correo para establecer la contraseña.'
        else
          'Usuario creado exitosamente'
        end
      end

      def render_user_error(message, errors)
        render_error(
          message,
          :unprocessable_entity,
          code: 'VALIDATION_ERROR',
          errors: errors
        )
      end
    end
  end
end
