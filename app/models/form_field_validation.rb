################################################################################
#  Standard Validation Types
################################################################################
#
# :group => "All",   :name => "Required",        :function => "required"
# 
# :group => "Text",  :name => "Text Format",     :function => "format_with"
# :group => "Text",  :name => "Length",          :function => "length"
# 
# :group => "Number",:name => "Minimum",         :function => "number_min"
# :group => "Number",:name => "Maximum",         :function => "number_max"
# 
# :group => "Date",  :name => "Date Min",        :function => "range_date_min"
# :group => "Date",  :name => "Date Max",        :function => "range_date_max"
#                                                 
# :group => "File",  :name => "File Size",       :function => "size_of"
# :group => "File",  :name => "File Format",     :function => "format_of"
# :group => "File",  :name => "File Format",     :function => "format_of"
#                                                 
# :group => "Image", :name => "File Format",     :function => "format_of"
# :group => "Image", :name => "File Size",       :function => "size_of"
# :group => "Image", :name => "File Format",     :function => "format_of"
# :group => "Image", :name => "Image Dimensions",:function => "dimensions"
#
# :group => "Custom",:name => "Min # Images",    :function => "min_num_img"
# :group => "Custom",:name => "Max # Images",    :function => "max_num_img"
# 
# :group => "All",   :name => "sum_calc",        :function => "sum_calc"
# :group => "All",   :name => "exist_calc",      :function => "exist_calc"
# :group => "All",   :name => "quantity_calc",   :function => "quantity_calc"
# :group => "All",   :name => "eval_calc",       :function => "eval_calc"
################################################################################

class FormFieldValidation
  include MongoMapper::EmbeddedDocument
  
  # Schema
  key :name,        String
  key :message,     String
  key :param,       String
  key :function,    String
  
  # Associations
  belongs_to :form_field
    
  # Instance Methods
  
  def form_field
    self._parent_document
  end
  
  def perform(value)
    begin
      return self.send("field_#{self.function.to_sym}", value)
    rescue NoMethodError
      return "Improper validation on this value #{$!}"
    end
  end
  
  def select_message(default)
    return (self.message.nil? || self.message.empty?) ?
      default :
      self.message
  end
  
  
  ##############################################################################
  # All
  ##############################################################################
  def field_required(value)
    Rails.logger.debug("VALIDATION: REQUIRED.")
    return (
      value.nil? or (value.respond_to?(:empty?) && value.empty?) ?
        select_message("is a required field") :
        nil
    )
  end
  
  ##############################################################################
  # Text
  ##############################################################################
  def field_length(value)
    Rails.logger.debug("VALIDATION: LENGTH")
    return(
      value.length <= self.param.to_i ?
        nil :
        select_message("must be #{self.param} characters or less")
    )
  end
  
  def field_format_with(value)
    Rails.logger.debug("VALIDATION: FORMAT WITH")
    return(
      Regexp.new(self.param) =~ value  ?
        nil :
        select_message("is not correctly formatted")
    )
  end
  
  ##############################################################################
  # Number
  ##############################################################################
  def field_number_min(value)
    Rails.logger.debug("VALIDATION: NUMBER MINIMUM")
    return( 
      value >= self.param.to_i ?
        nil :
        select_message("must be greater than or equal to #{self.param}")
    )
  end
  
  def field_number_max(value)
    Rails.logger.debug("VALIDATION: NUMBER MAXIMUM")
    return( 
      value <= self.param.to_i ?
        nil :
        select_message("must be less than or equal to #{self.param}")
    )
  end
  
  ##############################################################################
  # Date
  ##############################################################################
  def field_range_date_max(value)
    Rails.logger.debug("VALIDATION: DATE MAXIMUM")
    param = Time.parse(self.param)
    return( 
      Time.parse(value) <= param ?
        nil :
        select_message("must be before #{param.to_s(:long)}")
    )
  end
  
  def field_range_date_min(value)
    Rails.logger.debug("VALIDATION: DATE MINIMUM")
    param = Time.parse(self.param)
    return( 
      Time.parse(value) >= param ?
        nil :
        select_message("must be after #{param.to_s(:long)}")
    )
  end
  
  ##############################################################################
  # File and Image
  ##############################################################################
  def field_size_of(value)
    Rails.logger.debug("VALIDATION: SIZE OF")
    max_file_size = self.param.to_i * 1000 # actual_size will be in bytes
    actual_size = value.size
    
    Rails.logger.debug("max: #{max_file_size} actual: #{actual_size}")
    return (
      actual_size <= max_file_size ?
        nil :
        select_message("must be smaller than #{max_file_size}kb")
    )
  end
  
  # HOWTO format_of
  # The params are a comma-delimited list of types. ie: "png, jpg, gif"
  def field_format_of(value)
    Rails.logger.debug("VALIDATION: FORMAT OF")
    
    file_type   = content_type(value)
    reg_string  = ""

    # If the user hasn't set any sort of string for us, then we need to 
    # ensure that the uploaded file is of the proper type.
    if param.blank?
      case self.form_field.field_type.group.downcase
      when /image/
        reg_string = "image"
      when /file/
        reg_string = ".+"
      end
    else
      # The user has provided us with specific types.  
      # They are comma-delimited.  Strip the whitespaces!
      types = param.split(",").map{|p| p.strip }
      
      # Determine how to build the regular expression we'll be using
      if types.size == 1
        reg_string  = types
      else
        reg_string  = "(#{types.join('|')})" # => (png|jpg|gif)
      end
    end

    # Build the regular expression
    regex = Regexp.new(reg_string)

    # TODO ensure displaying the params to the user isn't a security flaw
    return( 
      regex.match(file_type) ? 
        nil :
        select_message("is not the correct file type.  Please try: #{param}")
    )
  end
  
  
  # HOWTO dimensions
  # The params should be a string like ">200x400" or "<200x400"
  # > or < tells us to check that the image 
  # is greater than that size or less than that size, respectively
  # In both cases, this is gte or lte, not just gt or lt
  def field_dimensions(value)
    Rails.logger.debug("VALIDATION: DIMENSIONS")
    
    # Use MiniMagick to evaluate the tempfile...
    image       = MiniMagick::Image.open(value.path)
    dimensions  = image[:dimensions]
    actual_x    = dimensions[0]
    actual_y    = dimensions[1]
    
    Rails.logger.debug("#{actual_x} #{actual_y} #{self.param}")
    
    required    = /(\>|\<)(\d+)x(\d+)/.match(self.param)
    
    Rails.logger.debug(required.inspect)
    
    modifier    = required[1]
    required_x  = required[2].to_i
    required_y  = required[3].to_i
    
    pass = case (modifier === '>')
    when true
      ( actual_x >= required_x) && (actual_y >= required_y)
    when false
      (required_x >= actual_x) && (required_y >= actual_y)
    end
    
    Rails.logger.debug(modifier)
    
    return(
      pass ? 
        nil :
        select_message("must be #{modifier === '>' ? 'over' : 'under'} #{required_x}x#{required_y}")
    )
  end
  
  ##############################################################################
  # File and Image
  ##############################################################################
  
  def field_min_num_img(value)
    Rails.logger.debug("VALIDATION: MIN NUM IMG")
    new_val = value.reject{|r| r.empty? }
    pass    = new_val.count >= self.param.to_i
    
    return(
      pass ? 
        nil :
        select_message("must have at least #{self.param} images selected")
    )
  end
  
  def field_max_num_img(value)
    Rails.logger.debug("VALIDATION: MAX NUM IMG")
    new_val = value.reject{|r| r.empty? }
    pass    = new_val.count <= self.param.to_i
    
    return(
      pass ? 
        nil :
        select_message("must have at most #{self.param} images selected")
    )
  end
  
  ##############################################################################
  # Field Calculation
  ##############################################################################
  
  # We need to iterate through the array of values and save the sum
  # of the selected options' #price to #subtotal
  def sum_calc(value)
    # Grab the options for this field
    options = form_field.options
    
    # Take the value and get rid of blank items
    value = value.delete("")
    subtotal = 0
    
    # Iterate over the values to get the selected option names
    # then add their price to the total
    value.each do |option_value|
      selected_option = options.select{|o| o.value == option_value}.first
      subtotal += selected_option.price
    end
    
    # Store the subtotal in the field
    form_field.update_attributes!(:subtotal => subtotal)
    
    return nil
  end
  
  # If the field has a value, then copy its #price into #subtotal
  def exist_calc(value)
    # Don't do anything if there is no value
    return nil if value.blank?
    
    # Copy price to subtotal
    form_field.update_attributes!(:subtotal => form_field.price)
    
    return nil
  end
  
  # Multiply the selected item's #price by the quantity indicated
  # and store in #subtotal
  def quantity_calc(value)
    
    form_field.update_attributes!( :subtotal => (form_field.price * value.to_i) )
    
    return nil
  end
  
  # Interpolate fields into the param and store the eval into #subtotal
  def eval_calc(value)
    match   = /(\\\\)?\%\{([^\}]+)\}/
    
    result  = value.gsub(match) do
      escaped, pattern, key = $1, $2, $2.to_sym
      
      Rails.logger.debug("[Validations] We've got #{escaped} #{pattern} #{key}")
      ret = pattern
      if !escaped
        Rails.logger.debug("[Validations] Working well... #{pattern}")
        field_data = nil
        
        # Grab the data stored in the field, store 0 if there's an error
        begin
          field_data = form_field._parent_document.form_data.send(pattern.to_sym) || 0
        rescue
          Rails.logger.info("The field specified (#{pattern}) does not exist in this scope (#{form_field._parent_document.name})")
          # If the field doesn't have a value, then we'll store a 0 because we don't want
          # to be throwing errors.  This is a normal use-case
          field_data = 0
        end
        
        Rails.logger.debug("[Validations] Data found for #{pattern}: #{field_data}")
        
        ret = field_data
      end
      
      ret
    end
    
    # We want to clean up the input so nothing malicious gets done in eval
    strip_symbols = /[^\*\^\/\+\-\%\d\s\(\)\[\]]/
    result_to_eval = result.gsub(strip_symbols,"")
    
    # Evaluate this puppy
    subtotal = Kernel.eval(result_to_eval)
    
    # Store the result
    form_field.update_attributes!(:subtotal => subtotal)
    
    return nil
  end
  
  
  
private  
  
  # Credit: straight up stolen from dm-paperclip
  def content_type(file)
    type = (file.original_filename.match(/\.(\w+)$/)[1] rescue "octet-stream").downcase
    case type
    when %r"jpe?g"                 then "image/jpeg"
    when %r"tiff?"                 then "image/tiff"
    when %r"png", "gif", "bmp"     then "image/#{type}"
    when "txt"                     then "text/plain"
    when %r"html?"                 then "text/html"
    when "csv", "xml", "css", "js" then "text/#{type}"
    else "application/x-#{type}"
    end
  end
end