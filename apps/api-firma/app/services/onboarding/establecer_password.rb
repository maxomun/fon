# frozen_string_literal: true

module Onboarding
  class EstablecerPassword
    Result = Struct.new(:user, :errors, keyword_init: true) do
      def success?
        errors.blank? && user.present?
      end
    end

    def self.call(token:, password:, password_confirmation: nil)
      new(token: token, password: password, password_confirmation: password_confirmation).call
    end

    def initialize(token:, password:, password_confirmation: nil)
      @token = token.to_s.strip
      @password = password
      @password_confirmation = password_confirmation.presence || password
    end

    def call
      if @token.blank?
        return failure(['Token requerido'])
      end

      onboarding_token = OnboardingToken.find_by_raw_token(@token)

      if onboarding_token.nil?
        return failure(['Token inválido'])
      end

      unless onboarding_token.proposito == OnboardingToken::PROPOSITO_ESTABLECER_PASSWORD
        if onboarding_token.proposito == OnboardingToken::PROPOSITO_VERIFICAR_EMAIL
          return failure([
            'Este enlace es para verificar el correo. Complete primero ese paso; ' \
            'luego se habilitará el formulario para establecer su contraseña.'
          ])
        end

        return failure(['Token inválido'])
      end

      user = onboarding_token.user

      unless user.email_verificado?
        return failure(['Debe verificar su correo antes de establecer la contraseña'])
      end

      User.transaction do
        onboarding_token.lock!

        if onboarding_token.consumido?
          user.reload
          return Result.new(user: user, errors: []) if user.onboarding_completado?

          return failure(['Token ya utilizado'])
        end

        if onboarding_token.expirado?
          return failure(['Token expirado'])
        end

        user.password = @password
        user.password_confirmation = @password_confirmation

        unless user.valid?
          return failure(user.errors.full_messages)
        end

        user.save!
        onboarding_token.consumir!
        user.update!(
          onboarding_completado_at: Time.current,
          debe_cambiar_password: false
        )
        user.revocar_todas_las_sesiones!
      end

      Result.new(user: user.reload, errors: [])
    rescue ActiveRecord::RecordInvalid => e
      failure(e.record.errors.full_messages)
    end

    private

    def failure(errors)
      Result.new(user: nil, errors: Array(errors))
    end
  end
end
