# frozen_string_literal: true

module Api
  module V1
    class EmpresaPersonasAutorizadasController < BaseController
      include PersonaAutorizadaSerializable
      include EmpresaAuthorizable

      before_action :require_admin_empresa!
      before_action :set_empresa
      before_action :set_asignacion, only: [:update, :destroy, :reenviar_onboarding]

      # GET /api/v1/empresas/:empresa_id/personas_autorizadas
      def index
        asignaciones = @empresa
          .empresa_personas_autorizadas
          .includes(:persona_autorizada)
          .joins(:persona_autorizada)
          .order('personas_autorizadas.orden', 'personas_autorizadas.id')

        render_success(
          data: asignaciones.map do |asignacion|
            persona_autorizada_asignada_payload(
              asignacion.persona_autorizada,
              asignacion: asignacion
            )
          end
        )
      end

      # GET /api/v1/empresas/:empresa_id/personas_autorizadas/buscar?q=
      def buscar
        personas = personas_disponibles_para_asignar

        if params[:q].present?
          query = "%#{params[:q].to_s.strip}%"
          personas = personas.where(
            'rut ILIKE :q OR nombres ILIKE :q OR apellido_paterno ILIKE :q OR apellido_materno ILIKE :q OR email ILIKE :q',
            q: query
          )
        end

        personas = personas.limit(100)

        render_success(data: personas.map { |persona| persona_autorizada_payload(persona) })
      end

      # POST /api/v1/empresas/:empresa_id/personas_autorizadas
      def create
        if crear_persona_nueva?
          crear_y_asignar_persona
        else
          asignar_persona_existente
        end
      end

      # PATCH/PUT /api/v1/empresas/:empresa_id/personas_autorizadas/:id
      def update
        persona = @asignacion.persona_autorizada
        @onboarding_email_enviado = false

        PersonaAutorizada.transaction do
          if persona_detail_params.present?
            unless persona.update(persona_detail_params)
              raise ActiveRecord::Rollback
            end

            if persona.user.present?
              persona.sincronizar_nombre_a_usuario!
            else
              resultado = PersonasAutorizadas::ProvisionarUsuario.call(
                persona_autorizada: persona,
                password: params.dig(:persona_autorizada, :password)
              )
              unless resultado.success?
                persona.errors.add(:base, resultado.errors.join(', '))
                raise ActiveRecord::Rollback
              end

              envio = PersonasAutorizadas::EnviarVerificacionEmail.call(user: persona.user)
              @onboarding_email_enviado = envio.enviado
            end
          end

          if asignacion_params.key?(:es_administrador_empresa) &&
             !@asignacion.update(es_administrador_empresa: cast_boolean(asignacion_params[:es_administrador_empresa]))
            raise ActiveRecord::Rollback
          end
        end

        if persona.errors.any?
          return render_persona_validation_error(persona)
        end

        if @asignacion.errors.any?
          return render_persona_validation_error(@asignacion)
        end

        render_success(
          data: persona_autorizada_asignada_payload(persona.reload, asignacion: @asignacion.reload),
          message: mensaje_onboarding(
            onboarding_email_enviado: @onboarding_email_enviado,
            accion: :actualizada
          )
        )
      end

      # POST /api/v1/empresas/:empresa_id/personas_autorizadas/:id/reenviar_onboarding
      def reenviar_onboarding
        resultado = PersonasAutorizadas::ReenviarOnboarding.call(
          persona_autorizada: @asignacion.persona_autorizada
        )

        if resultado.success?
          render_success(
            data: persona_autorizada_asignada_payload(
              @asignacion.persona_autorizada,
              asignacion: @asignacion
            ),
            message: mensaje_reenvio_onboarding(paso: resultado.paso)
          )
        else
          render_error(
            'No se pudo reenviar el correo de enrolamiento',
            :unprocessable_entity,
            code: 'ONBOARDING_RESEND_FAILED',
            errors: resultado.errors
          )
        end
      end

      # DELETE /api/v1/empresas/:empresa_id/personas_autorizadas/:id
      def destroy
        @asignacion.destroy!
        render_success(message: 'Persona autorizada quitada de la empresa exitosamente')
      end

      private

      def set_empresa
        @empresa = Empresa.find(params[:empresa_id])
      end

      def set_asignacion
        @asignacion = @empresa.empresa_personas_autorizadas.find_by!(persona_autorizada_id: params[:id])
      end

      def personas_disponibles_para_asignar
        asignadas_ids = @empresa.empresa_personas_autorizadas.select(:persona_autorizada_id)
        PersonaAutorizada.por_prioridad.where.not(id: asignadas_ids)
      end

      def crear_persona_nueva?
        asignacion_params[:persona_autorizada_id].blank?
      end

      def crear_y_asignar_persona
        resultado = PersonasAutorizadas::CrearYAsignar.call(
          empresa: @empresa,
          attributes: persona_params_for_create,
          es_administrador_empresa: cast_boolean(asignacion_params[:es_administrador_empresa]),
          password: params.dig(:persona_autorizada, :password)
        )

        if resultado.success?
          render_success(
            data: persona_autorizada_asignada_payload(
              resultado.persona_autorizada,
              asignacion: resultado.asignacion
            ),
            status: :created,
            message: mensaje_onboarding(
              onboarding_email_enviado: resultado.onboarding_email_enviado,
              accion: :creada_y_asignada
            )
          )
        else
          render_error(
            'Error al crear persona autorizada',
            :unprocessable_entity,
            code: 'VALIDATION_ERROR',
            errors: resultado.errors
          )
        end
      end

      def asignar_persona_existente
        persona = PersonaAutorizada.find(asignacion_params[:persona_autorizada_id])

        resultado_usuario = PersonasAutorizadas::ProvisionarUsuario.call(persona_autorizada: persona)
        unless resultado_usuario.success?
          return render_error(
            'No se pudo provisionar el usuario de la persona autorizada',
            :unprocessable_entity,
            code: 'VALIDATION_ERROR',
            errors: resultado_usuario.errors
          )
        end

        asignacion = @empresa.empresa_personas_autorizadas.build(
          persona_autorizada: persona,
          es_administrador_empresa: cast_boolean(asignacion_params[:es_administrador_empresa])
        )

        if asignacion.save
          onboarding_email_enviado = false
          if resultado_usuario.created? || resultado_usuario.linked?
            envio = PersonasAutorizadas::EnviarVerificacionEmail.call(user: persona.user)
            onboarding_email_enviado = envio.enviado
          end

          render_success(
            data: persona_autorizada_asignada_payload(persona, asignacion: asignacion),
            status: :created,
            message: mensaje_onboarding(
              onboarding_email_enviado: onboarding_email_enviado,
              accion: :asignada
            )
          )
        else
          render_persona_validation_error(asignacion)
        end
      end

      def persona_params_for_create
        permitted = persona_detail_params
        permitted[:estado] = PersonaAutorizada::ESTADO_ACTIVO if permitted[:estado].blank?
        permitted[:orden] = 1 if permitted[:orden].blank?
        permitted
      end

      def persona_detail_params
        return {} unless params[:persona_autorizada]

        params.require(:persona_autorizada).permit(
          :rut,
          :nombres,
          :apellido_paterno,
          :apellido_materno,
          :email,
          :estado,
          :orden
        ).to_h
      end

      def asignacion_params
        params.require(:persona_autorizada).permit(
          :persona_autorizada_id,
          :es_administrador_empresa,
          :rut,
          :nombres,
          :apellido_paterno,
          :apellido_materno,
          :email,
          :estado,
          :orden
        )
      end

      def cast_boolean(value)
        ActiveModel::Type::Boolean.new.cast(value) || false
      end
    end
  end
end
