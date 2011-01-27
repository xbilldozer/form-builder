require 'rails'
require 'ksc-form_builder/nestable.rb'

module KSCFormBuilder
  class Engine < Rails::Engine
     
    initializer "static assets" do |app|
      app.middleware.use ::ActionDispatch::Static, "#{root}/public"
    end
    
    initializer "simple_form modifications" do |app|
      require 'ksc-form_builder/simple_interpolation'
      require 'ksc-form_builder/photo_checkboxes'
      require 'ksc-form_builder/preview_button'
    end
    
  end
end