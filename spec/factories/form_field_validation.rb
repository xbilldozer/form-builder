Factory.sequence :validation_function do |n|
  funcs = [
    "required",     "length",         "format_of",      "size_of",
    "format_with",  "number_min",     "dimensions",
    "number_max",   "range_date_min", "range_date_max" 
  ]
  funcs.at(n % funcs.size)
end

Factory.sequence :validation_name do |n|
  "Test Validation #{n}"
end

Factory.define :form_field_validation do |validation|  
  validation.name { Factory.next(:validation_name) }
  validation.function { Factory.next(:validation_function) }
  validation.param ""
  validation.message "custom validation message"
end

