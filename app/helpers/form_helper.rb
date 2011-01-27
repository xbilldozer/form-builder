module FormHelper
  
  def render_form(form, version = :published, options = {})
    version = get_version(form, version)
    return if version.nil?
    
    form_version = form.get_version(version)
    
    return "There is no form to build for version \"#{version}\"." if form_version.nil?
    
    capture_haml do
      
      form_version.form_fields.each do |form_field|
        render_field(form_field)
      end
      
    end
  end
  
  # This renders a list of all forms, with no real root
  def render_list_of_all_forms
    forms = Form.root_forms
    capture_haml do
      # Get this form and add a node for it
      haml_tag :ul do
        forms.each do |form|
          haml_concat render_list_of_forms_no_root(form)
        end
      end
    end
  end
  
  # Renders a list of subforms with ==form== as root
  def render_list_of_forms(form)
    capture_haml do
      # Get this form and add a node for it
      haml_tag :ul do
        haml_concat render_list_of_forms_no_root(form)
      end
    end
  end
  
  # Helper method for rendering children.
  def render_list_of_forms_no_root(form)
    capture_haml do
      if form.children.count > 0
        haml_tag :li, {:class => "jstree-open", :id => "node_#{form.id}"} do
          haml_tag :a, form.name, {:href => "#"}
          haml_tag :ul do
            form.children.sort(:position).each do |child|
              haml_concat render_list_of_forms_no_root(child)
            end
          end
        end
      else
        haml_tag :li, {:id => "node_#{form.id}"} do
          haml_tag :a, form.name, {:href => "#"}
        end
      end
    end
  end
  
  
  def get_version(form, version)
    return case version
    when :published
      form.published_version
    when :current
      form.current_version
    when /\d/
      version
    else
      nil
    end
  end
  
end