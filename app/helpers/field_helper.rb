module FieldHelper
  
  # Match RegExp for interpolations in FieldType
  MATCH = /(\\\\)?\%\{([^\}]+)\}/
    
  def render_field(field, options = {})
    Rails.logger.debug("FIELD RENDER:  #{field.name}")
    
    form_helper   = options[:form]
    current_user  = options[:user]    if options.key?(:user)
    photos        = options[:photos]  if options.key?(:photos)
    
    # Grab the field group, field type definition, and field tags
    field_type            = field.field_type
    field_group           = field_type.group.dup
    field_tags            = field_type.tag.dup
    
    # Set up a var to catch field options and html input options
    field_options         = {}
    input_options         = {}
    
    # Add interpolations for values that aren't customized
    interpolation_values = [:label, :hint]
    interpolation_values << :value if form_helper.object.send(field.name).blank?
    interpolation_values.each do |tag|
      if !(field_tags.key?(tag) || field.send(tag).blank?)
        field_tags[tag]   = "%{#{tag.to_s}}"
      end
    end
    
    # Grab the tag :as if it's there      
    field_options[:as]        = field_tags.delete(:as) if field_tags[:as]
    # Grab default classes from tags if the tag exists
    field_options[:class]     = field_tags.delete(:class) if field_tags[:class]
    # Set the user object as an option so we can use it later
    field_options[:user]      = current_user if current_user
    # If there aren't any "require" validations on the fields, don't make it required
    field_options[:required]  = false unless field.validations.select{|fv| fv.function == "required"}.count > 0
    
    # Interpolate and merge the changes into the field options
    field_tags            = interpolate_options(field, field_tags).symbolize_keys
    field_options.reverse_merge!(field_tags)

    # Set up an array to hold any rendering we need to do before the final
    # field gets built
    built_field           = []
    post_field            = []
    
    # Determine what kind of evaluation needs to happen 
    # depending on the field tag type
    case field_group.downcase
    when "number"
      Rails.logger.debug("I'm a number field!!")
      # Need to find a max and min or set some defaults
      # First, check to see if we have any validations for the field.
      field_validations = field.validations
      
      field_validations.each do |validation|
        next if not ["number_min","number_max"].include?(validation.function)
        case validation.function
        when "number_min"
          Rails.logger.debug("Number min: #{validation.param}")
          input_options[:min] = validation.param.to_s
        when "number_max"
          Rails.logger.debug("Number max: #{validation.param}")
          input_options[:max] = validation.param.to_s
        end
      end
      
      # Second, set defaults if need be
      input_options[:min] ||= NUMBER_FIELD_MIN
      input_options[:max] ||= NUMBER_FIELD_MAX
      input_options[:step]  = "1"
      input_options[:value] = "0"      
    when "option"

      # Set the collection
      field_options[:collection] = field.collect_options_array
      
      # Check to see if the field supports an "other" option
      if field.has_other_option?
        temp_form, disabled = create_other_field(field, form_helper)
        built_field << temp_form
        # Set the select box to "Other" if the textbox isn't disabled
        input_options[:selected] = FormField::OTHER_FIELD_NAME if !disabled
      end
    when "custom"
      # Are we a Photo Library or a Preview?
      case field_type.name
      when "Photo Library"
        field_options[:collection] = photos
        temp_form = create_add_photo_button(field, form_helper)
        post_field << temp_form
      when "Preview"
        
      end
      
    else
      # Anything additional need to happen?
    end
    
    # Add html options to the field options
    field_options[:input_html] = input_options

    # Render simple form!
    built_field.unshift(form_helper.input(field.name.to_sym, field_options))  
    
    # If there's more, then add it on
    built_field << post_field if not post_field.blank?
    
    # Check if we need to wrap this field up
    if field.fields_depended_on.size > 0
      wrapper = capture_haml do
        wrapper_classes = ["dependent-field"]
        wrapper_classes << ["dependencies-met"] if field.dependencies_met?
        haml_tag :div, {:class => wrapper_classes, 
                        :"data-fields" => field.fields_depended_on.to_json, 
                        :id => "wrapper_#{field.name}"} do
          haml_concat(built_field.to_s.html_safe)
        end
      end
      
      built_field = wrapper
    end
    
    return built_field.to_s.html_safe
  end

  # Set up a field to capture other
  # If this is an option and the option isn't in the collection of options, 
  # then the value needs to go in the "other" field
  #
  # If there is a value in form data for this field that is NOT in the
  # select's collection, OR it is "other", then we'll need to fill in 
  # the "other" field with that (unless it's "other").
  #
  # Submitting a blank "other" form will reset the selected value for the field  
  #
  # Returns TWO variables: STRING temp_form and BOOLEAN disabled
  def create_other_field(field, form_helper) 
    current_value = form_helper.object.send(field.name.to_sym)
    Rails.logger.debug("FOUND THE VALUE: #{current_value}")
    # disabled      = (current_value == FormField::OTHER_FIELD_NAME) || 
    #                 !(field.collect_option_names.include?(current_value))
    disabled      =   (field.collect_option_names.include?(current_value))

    temp          = form_helper.input( 
                      field.name.to_sym,
                      :as => :string, 
                      :hint => t("form.field.hints.other"), 
                      :label => t("form.field.labels.other"), 
                      :required => false,
                      :input_html => {
                        :class => [:other_field],
                        :value => disabled ? "" : current_value
                      },
                      :disabled => disabled
                    )
    
    return [temp, disabled]
  end
  
  # Simple routine to create a button for "Add Photos" for the
  # Photo Library field type.
  def create_add_photo_button(field, form_helper)
    if defined?(NEW_PHOTO_LIBRARY_URL)
      return capture_haml do
        haml_tag :div, {:class => [:row]} do
          haml_tag :div, {:class => [:"photo-button-wrapper", :grid_12, :column]} do
            haml_tag :a, t("photo_library.add_photos"), {
                          :class => [:button, :center], 
                          :href => NEW_PHOTO_LIBRARY_URL }
          end
        end
      end
    else
      return ""
    end
  end
  
  #
  # Takes a hash to replace values in.
  # All replaced values are functions on the FormField model.
  #
  def interpolate_options(field, field_tags)
    Rails.logger.debug("FIELD RENDER:  #{field.name}. Interpolating: #{field_tags.inspect}")
    
    field_tags.each do |tag, value|
      # If the value is another hash, recurse and replace
      if value.is_a?(Hash)
        field_tags[tag] = interpolate_options(field, value)
        next
      end
      
      if value.respond_to?(:force_encoding)
        original_encoding = value.encoding
        value.force_encoding(Encoding::BINARY)
      end
      
      # If the value is text, replace whatever is necessary
      result = value.gsub(MATCH) do
        escaped, pattern, key = $1, $2, $2.to_sym
        if escaped
          pattern
        elsif field.respond_to?(key)
          field.send(key)
        else
          pattern
        end
      end
      
      result.force_encoding(original_encoding) if original_encoding
      field_tags[tag] = result
    end
    
    return field_tags
  end
  
  
  def render_field_value_selector(form_field)
    capture_haml do

      case form_field.field_type.group
      when "Text"
        haml_tag(:div, {:class => "input string required"}) do
          haml_tag(:label, {:for => "field_dependency_value", :class => "string required"}) do
            haml_tag(:abbr, "*", {:title => "required"})
            haml_concat(t("admin.form_field.dependencies.labels.value"))
          end
          haml_tag(:input, {:type => "text", :name => "field_dependency[value]", :id => "field_dependency_value", :class => "string required"})
          haml_tag(:span, {:class => "hint"}) do
            haml_concat(t("admin.form_field.dependencies.hints.value"))
          end
        end
      when "Boolean"
        haml_tag(:div, {:class => "input radio required"}) do
          haml_tag(:label, {:class => "radio required"}) do
            haml_tag(:abbr, "*", {:title => "required"})
            haml_concat(t("admin.form_field.dependencies.labels.value"))
          end
          haml_tag(:label, t("admin.form_field.dependencies.labels.value"), {:for => "field_dependency_value_true"})
          haml_tag(:input, {:type => "radio", :name => "field_dependency[value]", :id => "field_dependency_value_true", :value => "true"})
          haml_tag(:label, t("admin.form_field.dependencies.labels.value"), {:for => "field_dependency_value_false"})
          haml_tag(:input, {:type => "radio", :name => "field_dependency[value]", :id => "field_dependency_value_false", :value => "false"})
        
          haml_tag(:span, {:class => "hint"}) do
            haml_concat(t("admin.form_field.dependencies.hints.value"))
          end
        end
        
      when "Option"
        haml_tag(:div, {:class => "input select required"}) do
          haml_tag(:label, {:for => "field_dependency_value", :class => "select required"}) do
            haml_tag(:abbr, "*", {:title => "required"})
            haml_concat(t("admin.form_field.dependencies.labels.value"))
          end
          haml_tag(:select, {:name => "field_dependency[value]", :id => "field_dependency_value", :class => "select required"}) do
            form_field.options.each do |option|
              haml_tag(:option, option.label, {:value => option.value})
            end
          end
          haml_tag(:span, {:class => "hint"}) do
            haml_concat(t("admin.form_field.dependencies.hints.value"))
          end
        end
      else
        haml_concat(t("admin.form_field.dependencies.labels.not_available"))
      end
    end
  end
  
end