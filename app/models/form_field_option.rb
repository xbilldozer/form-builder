class FormFieldOption
  include MongoMapper::EmbeddedDocument
  
  # Schema
  key :value,  String
  key :label,  String
  
  # Associations
  belongs_to :form_field

  validates_uniqueness_of :value

  # Instance Methods
  def form_field
    self._parent_document
  end
    
end