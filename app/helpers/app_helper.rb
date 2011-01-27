module AppHelper
  
  def version_current?(form, form_version)
    form.current_version == form_version.version
  end

  def display_group(group)
    group == "Option" ? "display: block;" : "display: none;"
  end


end
