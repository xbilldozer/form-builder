# SimpleInterpolation adds a subclass to SimpleForm::Inputs::StringInput that 
# allows for interpolated default values using the KSCFormBuilder gem.

module KSCFormBuilder
  module SimpleInterpolation
    class ModifiedString < SimpleForm::Inputs::StringInput
          
      def input
        Rails.logger.debug("Overriding input")
        Rails.logger.debug(input_html_options.inspect)
        Rails.logger.debug(options.inspect)
        
        if input_options.key?(:value)
          Rails.logger.debug("Yeah I'm here bro")
          
          value   = options[:value]
          match   = /(\\\\)?\%\{([^\}]+)\}/
          result  = value.gsub(match) do
            escaped, pattern, key = $1, $2, $2.to_sym
            
            Rails.logger.debug("We've got #{escaped} #{pattern} #{key}")
            ret = pattern
            if !escaped
              Rails.logger.debug("Working well... #{pattern}")
              # Find user
              raise ArgumentError, "You can't specify an interpolation without a user" unless options.key?(:user)
              raise ArgumentError, "You can't specify an interpolation without a user" if options[:user].blank?
              
              user = options[:user]
              
              # Grab the keys
              key_array   = pattern.split(".")
              field_key   = key_array.pop
              form_key    = key_array.join(".")
        
              Rails.logger.debug("Form: #{form_key}\nField: #{field_key}")
                
              # Find form that matched key for user
              prototype   = Prototype.where(:form_key => form_key, :user_id => user.id).first
        
              Rails.logger.debug("Prototype: #{prototype.inspect}")
              
              if prototype.blank?
                ret = ""
              else
                # Find field in form that matches key for user
          
                field       = prototype.form_fields.select{ |ff| ff.field_key == field_key }.first
                field_name  = field.name
          
                # Grab the value that's saved
                field_data  = prototype.form_data.send(field_name.to_sym)
                
                ret = field_data
              end
            end
            
            ret
          end
          
          input_html_options[:value] = result if not result.empty?
        end
        options.delete(:user) if options.key?(:user)
        options.delete(:value) if options.key?(:value)
        super
      end
    end
  end
end


module SimpleForm
  class FormBuilder
    
    class_eval do
      map_type :string, :email, :search, :tel, :url, :to => KSCFormBuilder::SimpleInterpolation::ModifiedString
    end
    
  end
end

