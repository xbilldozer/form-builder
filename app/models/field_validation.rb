################################################################################
#  Standard Validation Types
################################################################################
#
# Require     => All
# Format      => Text
# Range       => Integer
# Min/Max     => DateTime
# Size        => File/Image
# ContentType => File/Image
# Dimensions  => Image 
#
################################################################################

class FieldValidation
  include MongoMapper::Document
  
  key :name,        String
  key :group,       String
  key :function,    String
  key :param,       Boolean
  key :explanation, String
  
  def has_params?
    self.param == true
  end
  
end