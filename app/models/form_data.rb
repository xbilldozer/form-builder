class FormData
  include MongoMapper::EmbeddedDocument
  
  attr_accessor :data_changed
  
  # Schema
  
  key :validated,       Boolean, :default => false
  key :skip_validation, Boolean, :default => false
  key :validated_at,    Time
  key :data_key_names,  Array, :default => [:validated, :skip_validation, :validated_at, :keys, :created_at, :updated_at]
  key :created_at,      Time
  key :updated_at,      Time

  SENSITIVE_KEYS = [:id, :_id, :created_at, :updated_at, :validated_at, 
                    :skip_validation, :validated, :prototype, :data_key_names]

  belongs_to :prototype

  # Callbacks

  before_save       :before_save_updates
  after_validation  :update_times
  
  # Instance Methods
  
  def update_times
    self.validated_at = Time.now if !self.skip_validation
    self.updated_at   = Time.now if self.changed?
  end
    
  def prototype
    self._parent_document
  end

  def validate_on_next_save!
    self.skip_validation = false
  end

  def before_save_updates
    save_files
  end

  def mass_assign(attrs)
    # Remove any keys that may have been injected
    SENSITIVE_KEYS.each do |attribute_key|
      attrs.delete(attribute_key) if attrs[attribute_key]
    end
    
    attrs.each do |k,v|
      self.send(:"#{k}=", v)
    end
  end

  def save_files
    self.prototype.form_fields.each do |field|
      if ["File","Image"].include?(field.field_type.group)
        file = self.send(field.name.to_sym)
        # Determine whether this is a file or a path.  No need to save if it's a path
        if file.is_a?(Tempfile)
          
          #TODO: Make this save path customizable.
          name      = "#{field.name}_#{Time.now.to_i}_#{file.original_filename}"
          directory = File.join(Rails.root, "public/data")
          path      = File.join(directory, name)
          
          # Create the directory if it doesn't exist.
          Dir.mkdir(directory) if not File.exists?(directory)
          
          # Save the file here...
          File.open(path, "wb") { |f| f.write(file.read) }  
          
          # Set the field to the file path + name
          self.send("#{field.name.to_sym}=", path)
        end
      end
    end
  end
  
  def valid?(force = false)
    if not force
      # Skip validation if nothing has changed AND the data has already been validated previously.
      return true if self.skip_validation || (self.validated && !self.changed?)
    end
    # We don't need to capture the return value here because it directly affects
    # our class' errors, and will show up automatically (inheritence much?)
    super()
    
    Rails.logger.debug("Validating data...")
    
    fields = self.prototype.form_fields
    fields.each do |field|
      field_name    = field.name.to_sym
      validations   = field.validations
      field_value   = self.send(field_name)
      field_errors  = []

      Rails.logger.debug("Starting validation on #{field_name}")

      # Gather errors
      validations.each do |validation|
        Rails.logger.debug("Checking #{field_name} for: #{validation.name}")
        field_error = validation.perform(field_value)
        Rails.logger.debug("Checking #{field_name} found: #{field_error}")
        field_errors << field_error
      end
      
      field_errors = field_errors.compact
      
      # Delete stored file if it exists already 
      # and we have errors on the file field
      if field_errors.size > 0 && ["File","Image"].include?(field.field_type.group)
        Rails.logger.debug("There was an attachment on #{field_name}, so we're going to remove it.")
        filename = self.send(field.name.to_sym)
        if File.exists?(filename)
          File.delete(filename.path)
        end
      end
      
      # Add the field errors to the actual errors queue.
      field_errors.each do |field_error|
        errors.add(field_name, field_error)
      end
      
      Rails.logger.debug("Finished validation on #{field_name}")
    end
    
    Rails.logger.debug(errors.inspect)
    
    if errors.empty?
      self.validated = true
      return true
    else
      return false
    end
  end
    
end