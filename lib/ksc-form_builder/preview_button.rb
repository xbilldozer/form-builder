# This is currently a hacked together method of displaying
# preview buttons for Ruport reports.  Or anything, really.
# In the future, this needs to accept better options for location,
# and truthfully it should not be an input, and should be its own
# feature in the actionview extention.  
# There just isn't enough time to do that right now.
module SimpleForm
  module Inputs
    class PreviewInput < Base
      
      def input        
        input_html_options[:class] = "button #{options[:class]}".strip
        
        # HACK
        # TODO Find a way to deal with this properly!!!
        # HACK     
        
        form_field  = object.prototype.form_fields.select{|ff| ff.name == attribute_name.to_s}.first
        text        = form_field.value
        preview     = attribute_name.to_s.gsub("preview_", "")
        url         = "/material_rendering/#{preview}" # HACK
        "<a href='#{url}?p=#{object.prototype.id}' target='_preview' class='#{input_html_options[:class]}'>#{text}</a>" # HACK
      end
      
      def label_input
        input
      end
    
      def input_html_classes
        super.unshift("preview_button")
      end
    
      protected
    
      def limit
        column && column.limit
      end

      def has_placeholder?
        placeholder_present?
      end
      
      def has_required?
        false
      end
      
      def attribute_required?
        false
      end

    end
  end
  
  class FormBuilder
    map_type :preview_button,  :to => SimpleForm::Inputs::PreviewInput
  end
  
end