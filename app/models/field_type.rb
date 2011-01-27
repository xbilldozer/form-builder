class FieldType
  include MongoMapper::Document
  
  key :name,          String
  key :group,         String
  key :tag,           Hash
  
end