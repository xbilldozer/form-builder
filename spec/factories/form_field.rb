Factory.sequence :field_name do |n|
  "test_field_#{n}"
end

Factory.sequence :field_label do |n|
  "Test Field #{n}"
end

Factory.define :text_field, :class => :form_field do |form_field|  
  form_field.name { Factory.next(:field_name) }
  form_field.label { Factory.next(:field_label) }
  form_field.field_type FieldType.where(:name => "Text Field").first
end

Factory.define :select_field, :class => :form_field do |form_field|  
  form_field.name { Factory.next(:field_name) }
  form_field.label { Factory.next(:field_label) }
  form_field.field_type FieldType.where(:name => "Select").first
end
