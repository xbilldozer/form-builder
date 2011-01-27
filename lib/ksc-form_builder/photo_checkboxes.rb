module SimpleForm  
  module ActionViewExtensions
    module Builder

      def collection_check_boxes(attribute, collection, value_method, text_method, options={}, html_options={})
        render_collection(
          attribute, collection, value_method, text_method, options, html_options
        ) do |value, text, default_html_options|
          default_html_options[:multiple] = true
                    
          # This is a fix to select boxes that were previously checked
          object_data = object.send(attribute)
          default_html_options[:checked] = true if object_data.include?(value.to_s)

          check_box = check_box(attribute, default_html_options, value, '')
          collection_label(attribute, value, check_box, text, :class => "collection_check_boxes")
        end
      end
            
    end
  end
end