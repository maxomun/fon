# Be sure to restart your server when you modify this file.

# Add new inflection rules using the following format. Inflections
# are locale specific, and you may define rules for as many different
# locales as you wish. All of these examples are active by default:
# ActiveSupport::Inflector.inflections(:en) do |inflect|
#   inflect.plural /^(ox)$/i, "\\1en"
#   inflect.singular /^(ox)en/i, "\\1"
#   inflect.irregular "person", "people"
#   inflect.uncountable %w( fish sheep )
# end

# These inflection rules are supported but not enabled by default:
# ActiveSupport::Inflector.inflections(:en) do |inflect|
#   inflect.acronym "RESTful"
# end

# Inflecciones mínimas para palabras en español que no siguen reglas de inglés.
# Solo para asociaciones has_many donde Rails singulariza incorrectamente.
#
# Problema: Rails en inglés hace "valores" -> "valore" (quita 's')
# Correcto en español: "valores" -> "valor" (quita 'es')

ActiveSupport::Inflector.inflections do |inflect|
  # Palabras que terminan en consonante + "es" → singular quita "es"
  inflect.irregular 'valor', 'valores'
  inflect.irregular 'impuesto_valor', 'impuesto_valores'
  inflect.irregular 'proveedor', 'proveedores'
  inflect.irregular 'rol', 'roles'
end
