# frozen_string_literal: true

module OnboardingSessionBlockable
  extend ActiveSupport::Concern

  class OnboardingSessionBlockedError < StandardError
    attr_reader :bloqueo, :user

    def initialize(bloqueo, user)
      @bloqueo = bloqueo
      @user = user
      super(bloqueo.message)
    end
  end

  private

  def enforce_session_onboarding_access!(user)
    bloqueo = Users::VerificarAccesoSesion.call(user)
    return if bloqueo.nil?

    raise OnboardingSessionBlockedError.new(bloqueo, user)
  end

  def render_onboarding_blocked(bloqueo, user:)
    response = {
      success: false,
      message: bloqueo.message,
      code: bloqueo.code,
      data: onboarding_blocked_payload(user)
    }
    render json: response, status: :unauthorized
  end

  def onboarding_blocked_payload(user)
    {
      email: user.email,
      email_verificado: user.email_verificado?,
      onboarding_completado: user.onboarding_completado?,
      requiere_verificacion_email: user.requiere_verificacion_email?,
      requiere_onboarding: user.requiere_onboarding?
    }
  end
end
