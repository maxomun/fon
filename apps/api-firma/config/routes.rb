Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # API v1
  namespace :api do
    namespace :v1 do
      # Autenticación
      scope :auth do
        post 'login', to: 'authentication#login'
        post 'refresh', to: 'authentication#refresh'
        delete 'logout', to: 'authentication#logout'
        get 'me', to: 'authentication#me'
      end


      # DTE - Documentos Tributarios Electrónicos
      scope :dte do
        post 'test_clasificacion', to: 'dte#test_clasificacion'
        post 'test_folios', to: 'dte#test_folios'
        post 'preparar', to: 'dte#preparar'
        post 'generar_xml', to: 'dte#generar_xml'
        post 'firmar_xml', to: 'dte#firmar_xml'
        post 'generar', to: 'dte#generar'
      end

      # Certificados digitales
      scope :certificados do
        post 'crear', to: 'certificados#crear'
        get 'listar', to: 'certificados#listar'
        post 'verificar', to: 'certificados#verificar'
        delete 'eliminar', to: 'certificados#eliminar'
      end

      # Rangos de Folios (CAF)
      scope :rango_folios do
        post 'cargar', to: 'rango_folios#cargar'
        get 'listar', to: 'rango_folios#listar'
        get 'obtener', to: 'rango_folios#obtener'
        delete 'eliminar', to: 'rango_folios#eliminar'
      end

      # Aquí irán los recursos de la API
      # resources :empresas
      # resources :clientes
      # resources :productos
      # etc.
    end
  end

  # Defines the root path route ("/")
  # root "posts#index"
end
 