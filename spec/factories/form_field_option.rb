Factory.sequence :option_value do |n|
  "test_option_#{n}"
end

Factory.sequence :option_label do |n|
  "Test Option #{n}"
end

Factory.define :form_field_option do |option|  
  option.value { Factory.next(:option_value) }
  option.label { Factory.next(:option_label) }
end
