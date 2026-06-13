# frozen_string_literal: true

# Parche para asegurar que Active Storage cree los directorios necesarios
# antes de escribir archivos en el Disk service

Rails.application.config.to_prepare do
  # Cargar Active Storage si no está cargado
  require 'active_storage/service/disk_service'
  
  ActiveStorage::Service::DiskService.class_eval do
    # Sobrescribir make_path_for para crear directorios
    def make_path_for(key)
      path = path_for(key)
      FileUtils.mkdir_p(File.dirname(path))
      path
    end
  end
end
