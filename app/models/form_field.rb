# Notes:
# 
# Create and destroy methods are in FormVersion because you get better
# control over versioning and storage that way.
#
# HOW #has_other_option WORKS
# If "Other" is an option and the option saved in FormData isn't in the 
# collection of options, then the value will go in the "other" text field
#
# If there is a value in FormData for this field that is NOT in the
# select's collection, OR it is "other", then we'll need to fill in 
# the "other" field with that (unless it's "other").
#
# Submitting a blank "other" form will reset the selected value for the field
#

class FormField
  include MongoMapper::EmbeddedDocument

  OTHER_FIELD_NAME = "other_selected"

  # Schema
  key :name,              String, :required => true
  key :label,             String, :required => true
  key :value,             String
  key :hint,              String
  key :size,              Integer
  key :price,             Float
  key :subtotal,          Float
  key :position,          Integer, :default => 0
  key :has_other_option,  Boolean, :default => false
  key :field_key,         String
  key :dependent_forms,   Array
  key :created_at,        Time
  key :updated_at,        Time
  


  # Associations
  belongs_to  :field_type
  many        :validations, :class_name => 'FormFieldValidation'
  many        :options,     :class_name => 'FormFieldOption'


  # Validations
  validates_uniqueness_of :name
  # validates_uniqueness_of :position
  validates_associated
  
  # Callbacks
  before_update :update_field
  before_save   :initialize_form_field
  after_save    :update_dependencies

  # Instance Methods
  
  def form
    self._root_document
  end
  
  def siblings
    self._parent_document.form_fields
  end
  
  def update_field
    # This conditional is important.  Without it, Prototype breaks.    
    if self.form.is_a?(Form)
      check_field_update ? update_time : false
    end
  end
  
  def update_time
    self.updated_at = Time.now
  end

  # Return an array with dependency hashes for this field
  # [{:id, :form, :field, :value}]
  def collect_dependencies
    dependency_array = []
    
    self.dependent_forms.each do |dep_form_key|
      dep_form    = Form.key_to_form(dep_form_key)
      
      # The key stored on the dep field is the key to THIS field object
      whole_key   = "#{self.form.form_key}.#{self.field_key}"
      field_deps  = dep_form.field_dependencies
      dependencies  = field_deps.select {|fd| fd["id"] == whole_key}      
      dependencies.each do |dependency|
        dependency_array << dependency.symbolize_keys!.merge({:form => dep_form, :field => self}).dup
      end
    end
    
    dependency_array
  end

  # Collect field options into an array that can be used in a collection
  def collect_options_array
    options_array = []
    self.options.each do |option|
      Rails.logger.debug("Available Option: #{option.inspect}")
      options_array << [option.label, option.value]
    end
    
    # If this field has an other option, add it to the list
    options_array << ["Other", OTHER_FIELD_NAME] if self.has_other_option
    
    options_array
  end
  
  def collect_option_names
    options_array = []
    
    self.options.each do |option|
      Rails.logger.debug("Available Option: #{option.inspect}")
      options_array << option.value
    end
    
    options_array
  end

  ##############################################################################
  #  Field Management
  ##############################################################################
  
  # Duplicate with field type. Won't happen with normal #dup
  # def duplicate
  #   new_field             = self.dup
  #   new_field.field_type  = self.field_type
  #   return new_field
  # end
    
  def check_field_update
    # if self.changed? && form.needs_to_migrate?
    if form.needs_to_migrate?
      # Save changed keys and clear changes before doing this.
      # If we don't do this, we'll enter hang time in a save loop
      
      # dirty_keys = self.changes
      # @changed_keys.clear # FIXME This is a hack
      
      #new_form_version = self.form.dup_version
      
      # migrate_dirty_keys(dirty_keys, new_form_version)
      return false
    end
    return true
  end
  
  # def migrate_dirty_keys(dirty_keys, new_form_version)
  #   dirty_keys.each do |dirty_key|
  #     # Poor operation, but that's just how the array is constructed:
  #     # key = [field, [old_val, new_val]]
  #     new_form_version[dirty_key[0]] = dirty_key[1][1] 
  #   end
  #   self.form.save
  # end

  ##############################################################################
  #  Child Management
  ##############################################################################  
  
  # You can manage any of the many-child types with this
  def manage_field(type, action, object)
    return if not [:options, :validations].include?(type)
    return if not [:push, :delete].include?(action)
    
    if self.form.needs_to_migrate?
      new_form_version = self.form.dup_version
      self.form.save
      new_field = new_form_version.form_fields.detect {|field| field.name == self.name }
      return new_field.manage_field(type, action, object)
    else
      self.send(type).send(action, object)
      return self
    end
  end


protected

  def initialize_form_field
    set_position
    normalize_name
    save_key
  end

  def normalize_name
    self.name = self.name.gsub(/[^\w\d]+/,"_")
  end

  def set_position
    if self.new?
      max_pos = 0
      sibs = self.siblings
    
      # Leave position at 0 if there are no siblings
      return if sibs.blank?
    
      sibs.each do |sib|
        max_pos = sib.position if sib.position >= max_pos
      end
    
      self.position = max_pos + 1
    end
  end
  
  def save_key      
    @old_key        = self.field_key
    self.field_key  = self.name.gsub(/[^\w\d]+/,"_")
  end
  
  def update_dependencies
    if self.field_key != @old_key
      self.dependent_forms.each do |dep_form|
      
        form              = Form.key_to_form(dep_form)
        field_deps        = form.field_dependencies
      
        field_deps.each_with_index do |field_dep, index|
          old_id          = field_dep['id']
          id_array        = old_id.split(".")
          id_array.last.gsub!(@old_key, self.name.gsub(/[^\w\d]+/,"_"))
          field_dep['id'] = id_array.join(".")
          form.field_dependencies[index] = field_dep
        end
      
        form.save
      end
    end
  end
    
  
end
