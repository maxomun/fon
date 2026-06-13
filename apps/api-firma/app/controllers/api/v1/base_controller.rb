# frozen_string_literal: true

module Api
  module V1
    class BaseController < ApplicationController
      include Authenticable

      # Manejo de excepciones global
      rescue_from ActiveRecord::RecordNotFound, with: :not_found
      rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity
      rescue_from ActionController::ParameterMissing, with: :bad_request

      private

      def not_found(exception)
        render_error("Recurso no encontrado: #{exception.message}", :not_found, code: 'NOT_FOUND')
      end

      def unprocessable_entity(exception)
        render_error(
          'Error de validación',
          :unprocessable_entity,
          code: 'VALIDATION_ERROR',
          errors: exception.record.errors.full_messages
        )
      end

      def bad_request(exception)
        render_error("Parámetro requerido: #{exception.param}", :bad_request, code: 'BAD_REQUEST')
      end

      # Helper para paginación
      def pagination_params
        {
          page: params[:page]&.to_i || 1,
          per_page: [params[:per_page]&.to_i || 25, 100].min
        }
      end

      # Helper para respuesta paginada
      def render_paginated(collection, serializer: nil)
        pagination = pagination_params
        paginated = collection.page(pagination[:page]).per(pagination[:per_page])

        data = serializer ? paginated.map { |item| serializer.new(item).as_json } : paginated

        render_success(
          data: data,
          meta: {
            current_page: paginated.current_page,
            total_pages: paginated.total_pages,
            total_count: paginated.total_count,
            per_page: pagination[:per_page]
          }
        )
      end
    end
  end
end
