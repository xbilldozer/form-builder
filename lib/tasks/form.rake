FIELD_VALIDATIONS = [
  {:group => "All",   :name => "Required",        :function => "required",      :param => false},

  {:group => "Text",  :name => "Text Format",     :function => "format_with",   :param => true},
  {:group => "Text",  :name => "Length",          :function => "length",        :param => true},

  {:group => "Number",:name => "Minimum",         :function => "number_min",    :param => true},
  {:group => "Number",:name => "Maximum",         :function => "number_max",    :param => true},

  {:group => "Date",  :name => "Date Min",        :function => "range_date_min",:param => true},
  {:group => "Date",  :name => "Date Max",        :function => "range_date_max",:param => true},

  {:group => "File",  :name => "File Size",       :function => "size_of",       :param => true},
  {:group => "File",  :name => "File Format",     :function => "format_of",     :param => true},
  {:group => "File",  :name => "File Format",     :function => "format_of",     :param => true},

  {:group => "Image", :name => "File Format",     :function => "format_of",     :param => true},        
  {:group => "Image", :name => "File Size",       :function => "size_of",       :param => true},
  {:group => "Image", :name => "File Format",     :function => "format_of",     :param => true},
  {:group => "Image", :name => "Image Dimensions",:function => "dimensions",    :param => true},
  
  {:group => "Custom",:name => "Min # Images",    :function => "min_num_img",   :param => true},
  {:group => "Custom",:name => "Max # Images",    :function => "max_num_img",   :param => true}
  
  {:group => "All",   :name => "sum_calc",        :function => "sum_calc",      :param => false},
  {:group => "All",   :name => "exist_calc",      :function => "exist_calc",    :param => false},
  {:group => "Number",:name => "quantity_calc",   :function => "quantity_calc", :param => false},
  {:group => "All",   :name => "eval_calc",       :function => "eval_calc",     :param => true}
]

FIELDS = [
  { :name => "Text Field",        :group => "Text", :tag => {}
  },
  { :name => "Text Area",         :group => "Text",
    :tag => { :as => "text", :class => "expand" }
  },
  { :name => "Number",            :group => "Number",
    :tag => { :as => "integer" }
  },
  { :name => "Checkbox (single)", :group => "Boolean",
    :tag => { :as => "boolean" }
  },
  { :name => "Date Picker",       :group => "Date",
    :tag => { :as => "date" }
  },
  { :name => "Image Upload",      :group => "Image",
    :tag => { :as => "file" }
  },
  { :name => "File Upload",       :group => "File",
    :tag => { :as => "file" }
  },
  { :name => "Checkbox (many)",   :group => "Option",
    :tag => { :as => "check_boxes" }
  },
  { :name => "Select",            :group => "Option",
    :tag => { :as => "select" }
  },
  { :name => "Radio Button",      :group => "Option",
    :tag => { :as => "radio" }  
  },
  { :name => "Photo Library",     :group => "Custom",
    :tag => { :as => "check_boxes" }
  },
  { :name => "Preview",           :group => "Custom",
    :tag => { :as => "preview_button" }
  }
]

namespace :form do
  desc "DESTRUCTIVE Seed DB with all relevant Form info"
  task :reseed => [:environment, :types, :validations] do ; end
  
  desc "Update the fields and validations instead of deleting them"
  task :update => [:environment] do
    FIELDS.each do |field|
      f = FieldType.first(:name => field[:name])
      if f
        f.update_attributes!(field)
      else
        FieldType.create(field)
      end
    end
    
    FIELD_VALIDATIONS.each do |validation|
      v = FieldValidation.first(:name => validation[:name])
      if v
        v.update_attributes!(validation) 
      else
        FieldValidation.create(validation)
      end
    end
  end
  
  desc "Seed DB with Form Field Types"
  task :types => [:environment] do
    FieldType.destroy_all
    FieldType.create(FIELDS)
  end
  
  desc "Seed DB with Field Validations"
  task :validations => [:environment] do
    FieldValidation.destroy_all
    FieldValidation.create(VALIDATIONS)
  end
  
  
end
