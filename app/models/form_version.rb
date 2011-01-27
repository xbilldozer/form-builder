class FormVersion
  include MongoMapper::EmbeddedDocument
  
  # Schema
  key :version,     Integer
  
  key :created_at,  Time
  key :updated_at,  Time
  
  
  # Associations
  belongs_to :form
  many :form_fields

  # Validations
  validates_presence_of :version
  validates_associated
  
  # Callbacks
  before_update :update_version
  
  # Instance Methods
  
  def update_version
    # There is no create hook for embedded docs... Must use #new?
    self.created_at = Time.now if self.new?
    self.updated_at = Time.now
  end
  
end