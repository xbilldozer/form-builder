# TODO Make forms auto-migrate to v 1 on initialize
# TODO Add publish method to form_versions

class Form
  include MongoMapper::Document
  include KSCFormBuilder::Nestable
  
  attr_accessor :old_key
  
  # Schema
  key :unique_key,        Integer
  key :vendor_id,         Integer
  key :name,              String, :required => true
  key :number,            String, :required => true
  key :description,       String
  key :created_at,        Time
  key :updated_at,        Time
  key :position,          Integer, :default => 0    
  key :current_version,   Integer, :default => 0
  key :published_version, Integer, :default => 0
  
  # Associations
  many :form_versions

  # Callbacks
  after_create            :set_up_form
  before_create           :set_create_time
  before_create           :initialize_unique_key
  before_update           :set_update_time
  after_update            :update_dependencies
  
  # Validations
  validates_uniqueness_of :form_key
  validates_associated    :form_versions
  
  # Instance Methods
  # Essentially a "before_valid" callback
  def valid?
    # Grab the key chain
    key_chain = self.key_chain
    # Set a form key if it's blank or if it's been updated
    if self.form_key.blank? || key_chain != self.form_key
      @old_key ||= self.form_key
      self.form_key = key_chain
    end
    
    super
    
    return errors.empty?
  end
  
  def set_up_form
    create_first_version_form
  end
  
  def update_form
    #check_form_versions
    set_update_time
  end
  
  def set_update_time
    self.updated_at = Time.now
  end
  
  def initialize_unique_key
    if !Form.all.empty?
      self.unique_key = Form.all(:order => "unique_key").last.unique_key + 1
    else
      self.unique_key = 1
    end
  end
  
  def set_create_time
    self.created_at = Time.now
    if not self.parent_document.blank?
      self.position = self.siblings.count
    end
  end
  
  def increment_version
    self.current_version += 1
    self.current_version
  end
    
  def get_version(version)
    return self.form_versions.detect {|v| v.version == version}
  end
  
  def published
    return self.get_version(self.published_version)
  end
  
  def current
    return self.get_version(self.current_version)
  end
  
  # Publish this form and recursively publish all children
  def publish
    self.published_version = self.current_version
    self.children.each do |child|
      child.publish.save
    end
    self
  end

  def up_to_date?
    me_up_to_date = self.published_version == self.current_version
    self.children.each do |child|
      me_up_to_date &= child.up_to_date?
    end
    return me_up_to_date
  end

################################################################################
# Begin Hierarchy for Form nesting
################################################################################

  # Destroy self and all children without checking immutability
  def destroy_tree
    self.children.each do |child|
      child.destroy_tree
    end
    self.destroy
  end
  
  def remove_child(child)
    child_form                  = child.dup
    child_form.parent_document  = nil
    child_form.form_id          = nil # No idea why, but this is required to remove the association
    self.children.find(child.id).destroy
    child_form
  end
  
  def has_child?(child)
    # TODO fix this hack.  This is not the best way to do this.
    self.children.select{|s| s.id == child.id}.count > 0
  end
  
  def siblings
    return  ( self.parent_document.blank? ?
                [] : (self.parent_document.children - [self]) )
  end
  
  # Update the positioning of the children
  # This iterates through all siblings and adjusts position
  # NOTE We could reduce the time complexity of this by checking beforehand which
  # direction we are moving this form and skipping adjustments on siblings 
  # accordingly.
  def update_position(_position)
    _position  = _position.to_i
        
    # Get all siblings, minus this form, and order by position
    to_update = self.siblings.sort{|a,b| a.position <=> b.position }
    # Set up an index for positions
    index = 0
    
    to_update.each do |sibling|
      if sibling.position == _position
        if self.position < _position
          # If this form started at a lower position than the current sibling,
          # Then we can use the current index as the sibling's new position,
          # And skip the rest of the list because it will already be sorted
          sibling.update_attributes(:position => index)
          return self.position = _position
        else
          # If this form started higher than the sibling it is replacing, 
          # Then we will need to make room for it by skipping an index
          # And continuing to sort the list.
          index += 1 
        end
      end
      
      # Set the position
      sibling.update_attributes(:position => index)
      
      # Inc position
      index += 1
    end
    
    # Set this form's new position
    self.position = _position
  end

################################################################################
# End Hierarchy for Form nesting
################################################################################


################################################################################
# Begin Form Manipulation
################################################################################

  # Checks to see if the published form version is the same as 
  # the form version that this field belongs to
  def needs_to_migrate?
    return self.published_version == self.current_version
  end

  # Duplicate the form version.
  # This action will automatically update the version.  
  def dup_version
    new_form_version          = self.current.dup
    self.form_versions        << new_form_version
    new_form_version.version  = self.increment_version
    return new_form_version
  end
  
  def new_version
    new_form_version          = FormVersion.new()
    self.form_versions        << new_form_version
    new_form_version.version  = self.increment_version
    save
  end

  def create_field(*args)
    new_form_field = args.first.is_a?(FormField) ? args.first : FormField.new(*args)
  
    if self.needs_to_migrate?
      new_form_version              = self.dup_version
      new_form_version.form_fields  << new_form_field
    else
      self.current.form_fields      << new_form_field
    end
    
    save ? new_form_field : false
  end

  def destroy_field(field)
    if self.needs_to_migrate?
      new_form_version  = self.dup_version
      new_form_field    = new_form_version.form_fields.find(field.id)
      new_form_version.form_fields.delete(new_form_field)
    else
      self.current.form_fields.delete(field)
    end
    
    save
  end


################################################################################
# End Form Manipulation
################################################################################



  def form_versions_desc
    self.form_versions.sort(:version).reverse
  end


  # Create a new form version
  def create_first_version_form
    self.new_version
  end


  # Create a Prototype class from Form class
  def to_prototype
    published_form = self.published
    return nil if published_form.blank?
    
    attrs = self.attributes.dup
    attrs.delete(:form_versions)
    attrs.delete(:published_version)
    attrs.delete(:current_version)
    attrs.delete(:_id)
    attrs.delete(:id)
    attrs.delete(:form_id)
    prototype = Prototype.new(attrs)
    
    # Migrate fields
    published_form.form_fields.each do |form_field|
      prototype.form_fields << form_field.dup
      prototype.save
    end
    # Migrate subforms
    
    self.children.each do |child|
      child_prototype = child.to_prototype
      prototype.add_child(child_prototype).save
    end
    
    prototype.send(:set_up_prototype)
    
    prototype.save
    prototype
  end
  
  def initialize_prototype(model_id)
    self.publish.save #TODO: later on we should allow the admin to control publishing
    _prototype = self.to_prototype
    _prototype.update_attributes!(:exhibitor_id => model_id, :form_id => self.id)
    _prototype
  end

  # alias :proto :to_prototype


protected

  def update_dependencies
    return true if @old_key.blank?  
    if  self.field_dependencies.size > 0 || 
        self.current.form_fields.count > 0
      
      # Update forms in dependent fields
      self.field_dependencies.each do |complete_key|
        puts "wicked #{complete_key.inspect}"
        complete_key.symbolize_keys!
        field = Form.key_to_form_and_field(complete_key[:id])[1]
        # puts "wicked2"
        next if field.dependent_forms.include?(self.form_key)
        puts "Actually updating field"
        field.dependent_forms = field.dependent_forms.delete(@old_key)
        field.dependent_forms << self.form_key
        field.save
      end
      
      # Update dependent forms from our fields
      self.current.form_fields.each do |my_field|
        next if my_field.dependent_forms.blank?
        my_field.dependent_forms.each do |dep_form_key|
          puts dep_form_key.inspect
          dependent_form = Form.key_to_form(dep_form_key)
          dependent_form.field_dependencies.each do |dep_hash|
            dep_hash.symbolize_keys!
            puts "Hash: #{dep_hash[:id]}, oldkey: #{@old_key}, new_key: #{self.form_key}"
            next if not dep_hash[:id].include?(@old_key)
            puts "Changing #{dependent_form.form_key} which has hash #{dep_hash[:id]}"
            dep_hash[:id] = "#{self.form_key}.#{my_field.field_key}"
            puts "Changed #{dependent_form.form_key} to #{dep_hash[:id]}"
          end
          dependent_form.save
        end
      end
    end
  end

end

