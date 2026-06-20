# frozen_string_literal: true

module PersonasAutorizadas
  # Provisiona usuarios de login para personas autorizadas existentes sin user_id.
  #
  # Ejemplo:
  #   resultado = PersonasAutorizadas::BackfillUsuarios.call
  #   resultado = PersonasAutorizadas::BackfillUsuarios.call(dry_run: true, solo_activas: true)
  #
  class BackfillUsuarios
    ErrorEntry = Struct.new(:persona_id, :rut, :email, :errors, keyword_init: true)

    Result = Struct.new(
      :procesadas,
      :exitosas,
      :creadas,
      :vinculadas,
      :fallidas,
      :pendientes,
      :errores,
      :dry_run,
      keyword_init: true
    ) do
      def success?
        fallidas.zero?
      end
    end

    def self.call(dry_run: false, solo_activas: false)
      new(dry_run: dry_run, solo_activas: solo_activas).call
    end

    def initialize(dry_run: false, solo_activas: false)
      @dry_run = dry_run
      @solo_activas = solo_activas
    end

    def call
      result = Result.new(
        procesadas: 0,
        exitosas: 0,
        creadas: 0,
        vinculadas: 0,
        fallidas: 0,
        pendientes: 0,
        errores: [],
        dry_run: @dry_run
      )

      scope.find_each do |persona|
        result.procesadas += 1

        if @dry_run
          preview = preview_persona(persona)
          if preview[:success]
            result.exitosas += 1
            result.creadas += 1 if preview[:action] == :created
            result.vinculadas += 1 if preview[:action] == :linked
          else
            result.fallidas += 1
            result.errores << ErrorEntry.new(
              persona_id: persona.id,
              rut: persona.rut,
              email: persona.email,
              errors: preview[:errors]
            )
          end
          next
        end

        provision = ProvisionarUsuario.call(persona_autorizada: persona)

        if provision.success?
          result.exitosas += 1
          result.creadas += 1 if provision.created?
          result.vinculadas += 1 if provision.linked?
        else
          result.fallidas += 1
          result.errores << ErrorEntry.new(
            persona_id: persona.id,
            rut: persona.rut,
            email: persona.email,
            errors: provision.errors
          )
        end
      end

      result.pendientes = PersonaAutorizada.where(user_id: nil).count
      result
    end

    private

    def scope
      relation = PersonaAutorizada.where(user_id: nil).order(:id)
      @solo_activas ? relation.activas : relation
    end

    def preview_persona(persona)
      existing_user = User.find_by(email: persona.email)

      if existing_user
        otra_persona = existing_user.persona_autorizada
        if otra_persona.present? && otra_persona.id != persona.id
          return {
            success: false,
            errors: [
              "El email #{persona.email} ya está asociado a otra persona autorizada (id=#{otra_persona.id})"
            ]
          }
        end

        return { success: true, action: :linked }
      end

      if default_password.blank?
        return {
          success: false,
          errors: ['Configure PERSONA_AUTORIZADA_DEFAULT_PASSWORD para crear usuarios de personas autorizadas']
        }
      end

      { success: true, action: :created }
    end

    def default_password
      ENV.fetch(ProvisionarUsuario::DEFAULT_PASSWORD_ENV, nil).presence
    end
  end
end
