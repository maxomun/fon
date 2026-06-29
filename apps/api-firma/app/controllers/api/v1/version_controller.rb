# frozen_string_literal: true

module Api
  module V1
    class VersionController < ApplicationController
      # GET /api/v1/version
      def show
        render json: {
          success: true,
          data: {
            version: ApiFirma::VERSION,
            servicio: 'api-firma'
          }
        }
      end
    end
  end
end
