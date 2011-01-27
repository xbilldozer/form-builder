class Prototype
  include MongoMapper::Document
  include KSCFormBuilder::Nestable
  
  key :unique_key,        Integer
  key :vendor_id,         Integer
  key :exhibitor_id,      Integer
  key :form_id,           String
  key :name,              String, :required => true
  key :number,            String, :required => true
  key :state,             String, :default => "draft"
  key :description,       String
  key :created_at,        Time
  key :updated_at,        Time
  key :position,          Integer, :default => 0
  key :dependencies_met,  Boolean, :default => false
  key :validation_mode,   Boolean, :default => false
  key :user_id,           Integer
  
  one                     :form_data
  many                    :form_fields

  before_create   :initialize_dependencies
  
  def is_multipart?
    self.form_fields.each do |field|
      return true if ["Image","File"].include?(field.field_type.group)
    end
  end

  def validation_mode?
    self.validation_mode
  end
  
  def accepted!
    self.state = "accepted"
    self.save
  end

  def submitted!
    self.state = "submitted"
    self.save
  end

  # Checks the validation of all forms
  def prototype_valid?
    
    self.workflow.each do |proto_form|
      next if not proto_form.dependencies_met
      data = proto_form.form_data
      data.skip_validation = false
      return false if not data.valid?
      
      # Save the validity of the data
      data.save!
    end
    return true
  end

  def workflow
    # get root prototype
    root_form = self.is_root_form? ? self : self.get_root
    
    # Collect all children in order
    forms = root_form.descendents(true).flatten
    # Add root form
    forms.unshift(root_form)
  end
  
  # Checks that all of this form's dependencies are met.
  def dependencies_met?
    # Find all dependencies
    prototype_dependencies = self.field_dependencies
    
    # If dependencies is empty, then we're golden
    return true if prototype_dependencies.blank?

    Rails.logger.debug("ME: #{self.name}")
    Rails.logger.debug("DEPS: #{prototype_dependencies.inspect}")

    # If not, then let's check...
    prototype_dependencies.each do |dep|      
      prototype, field  = Prototype.key_to_form_and_field(dep['id'])
      Rails.logger.debug("DEP PROTO: #{prototype.inspect}")
      Rails.logger.debug("DEP FIELD: #{field.inspect}")
      field_data        = prototype.form_data.send(field.name.to_sym)
      return false if (field_data != dep['value'])
    end
    
    return true
  end
  
  # Send a message to all prototypes with dependent fields in this prototype
  # that they should re-check their dependencies.
  def update_dependencies
    fields = self.form_fields
  
    # Go over all fields in this prototype
    fields.each do |field|
      form_keys = field.dependent_forms
      
      # For each dependency, run a check on the prototype
      form_keys.each do |form_key|
        proto_form  = Prototype.key_to_form(form_key)
        met         = proto_form.dependencies_met?
        
        # Update if different
        if proto_form.dependencies_met != met
          proto_form.update_attributes!(:dependencies_met => met)
        end
        
      end
    end
  end
  
protected

  def set_up_prototype
    # Set up attributes that belong in the data set
    data            = FormData.new
    Rails.logger.debug("Prototype creation [#{self.name}]: Available fields #{self.form_fields.inspect}")
    self.form_fields.each do |form_field|
      Rails.logger.debug("Prototype creation [#{self.name}]: Adding #{form_field.name} to form data set")
      data.data_key_names << form_field.name
      data[form_field.name] = ""
    end
    # Create the data set
    self.form_data  = data
    self.save
  end
  
  def initialize_dependencies
    self.dependencies_met = true if self.field_dependencies.blank?
  end
  
end