#
# Model functions for nestable forms/prototypes
#
module KSCFormBuilder
  module Nestable
    
    def self.included(base)
      Rails.logger.debug("Included in #{base}")
      base.extend KSCFormBuilder::Nestable::ClassMethods
      
      base.class_eval do
        key         :field_dependencies,  Array
        key         :form_key,            String
        
        many        :children, :class_name => "#{self}"
        belongs_to  :parent_document, :class_name => "#{self}"
      end
      
      base.send(:include, KSCFormBuilder::Nestable::InstanceMethods)
      
      super
    end
    
    module ClassMethods
      
      # Class method to find all root forms
      def root_forms
        all(:parent => nil)
      end

      # Alias the root_forms method so we can do .roots as well
      alias :roots :root_forms
      
      def parent_collection(form)
        all - [form] - form.descendents
      end
      
      def complete_collection
        collections = []
        root_forms.each do |parents|
          collections << parents.collect_children
        end
        collections
      end
      
      # Use only with a form key
      def key_to_form(f_key)
        self.where(:form_key => f_key).first
      end
      
      # Use when a field key has been joined with a form key
      # ie: form.keys.field_key
      # Returns [form, field]
      def key_to_form_and_field(whole_key)
        
        split_keys    = whole_key.split(".")
        field_key     = split_keys.pop
        form_key_name = split_keys.join(".")
        form          = key_to_form(form_key_name)
        
        return [nil,nil] if form.blank?
        
        # Find the field within form
        field = form.key_to_field(field_key)
        
        return [nil,nil] if field.blank?
        return [form, field]
      end
      
    end
    
    module InstanceMethods
      
      def add_child(child)
        self.children << child
        child.parent_document = self
        child.save
        self
      end
      
      # Determine if this is a root form or not
      def is_root_form?
        self.parent_document.nil?
      end
      
      # Recursively determine root
      def get_root
        return self if self.is_root_form?
        return self.parent_document.get_root
      end
      
      # Recursively collect parent names
      def collect_parent_names(child = nil)
        return [] if !child.blank? && child.is_root_form?
        return [self.name] if self.is_root_form?
        if child.blank?
          return self.parent_document.collect_parent_names << self.name
        else
          return self.parent_document.collect_parent_names
        end
      end
      
      # Generate a key for this form based on parent names.
      # Names with \W and \D have those chars replaced with a single underscore
      def key_chain
        chain = self.collect_parent_names(self) << self.name
        chain = chain.flatten.compact
        chain = chain.map{|form_name| form_name.gsub(/[^a-zA-Z0-9]+/,"_") }
        chain.join(".")
      end
      
      # Use only with a field key
      def key_to_field(field_key)
        if self.is_a?(Form)
          field = self.current.form_fields.select{|ff| ff[:field_key] == field_key }
        else
          field = self.form_fields.select{|ff| ff[:field_key] == field_key }
        end
        return field.first if not field.blank?  
        return field
      end

      # Determine if there are any children that belong to this form
      def has_children?
        self.children.size > 0
      end

      def has_child?(child)
        # TODO fix this hack.  This is not the best way to do this.
        self.children.select{|s| s.id == child.id}.count > 0
      end
      
      def has_descendent?(child)
        self.descendents.select{|s| s.id == child.id}.count > 0
      end
      
      # Return all descendents in order
      def descendents(order = true)
        return [] if !self.has_children?
        _children = order ? self.children.sort(:position) : self.children
        _descendents = []
        _children.each do |child|
          _descendents << child
          _descendents << child.descendents
        end
        _descendents
      end

      # Recursively collect all child forms
      # The result will be something like: 
      # :root => form_a,
      # :children => [  
      #   { :root => form_aa,
      #     :children => [
      #       { :root => form_aaa }
      #       { :root => form_aab } 
      #     ]
      #   } 
      #   { :root => form_ab }
      #   { :root => form_ac} 
      # ]
      #
      def collect_children
        forms = {:root => self}

        kids = self.children
        forms[:children] = []

        kids.each do |child|
          forms[:children] << child.collect_children
        end

        return forms
      end
      
      def child_count
        self.descendents.count
      end
      
      ################################################################################
      # Begin Form Dependencies
      ################################################################################
      
      def dependency(action, key_or_field, owner = nil, value = nil)
        return false if not [:create, :destroy, :exists?].include?(action)

        # Save time for create and value condition
        return false if value.blank? && (action == :create)

        if owner.blank?
          # key_or_field MUST be a key
          return false if not key_or_field.is_a?(String)

          # Grab the field and form from the key
          form, field = self.class.key_to_form_and_field(key_or_field)
        else
          # key_or_field MUST be a field
          # owner MUST NOT be a string
          return false if not key_or_field.is_a?(FormField)
          return false if owner.is_a?(String)
          
          form = owner
          field = key_or_field
        end  

        # Set up keys
        form_key    = form.form_key
        field_key   = field.field_key
        dep_key     = "#{form_key}.#{field_key}"
                
        # Check for dependency existence
        # the || is because hash can't decide whether this will 
        # be a string or a symbol, and symbolize_keys! won't work correctly
        dependency  = self.field_dependencies.select{|d| d['id'] == dep_key || d[:id] == dep_key }

        case action
        when :create
          # Ensure that this isn't a duplicate
          return false if !dependency.blank?

          # Create a hash for the field
          field_dep = {:id => dep_key, :value => value}

          # Add dependency to form
          self.field_dependencies << field_dep
          field.dependent_forms   << self.form_key if not field.dependent_forms.include?(self.form_key)
          field.save
        when :destroy
          # NOTE: We won't return false here because the dependency not existing
          # and removing the dependency are the same thing, I think
          
          # Remove dependency from form
          self.field_dependencies.delete(dependency.first)  if dependency
          field.dependent_forms.delete(self.form_key)       if dependency
          field.save
        when :exists?  
          return !dependency.blank?
        end
        
        return self
      end
    
    
    end
  
  end
end