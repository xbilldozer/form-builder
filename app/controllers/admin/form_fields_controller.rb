class Admin::FormFieldsController < ApplicationController
  include UrlHelper # Include hash_for AJAX helper
  
  before_filter :select_form
  before_filter :edit_pages, :only => [:edit, :validations, :options, :dependencies]

  layout 'admin'
  respond_to :html
  

  def index
    @form_fields = @version.form_fields
    respond_with([:admin, @form_fields])
  end
  
  def show
    @form_field = @version.form_fields.find(params[:id])
    respond_with([:admin, @form_field])
  end
  
  def new
    @form_field = FormField.new
    respond_with([:admin, @form_field])
  end
  
  def edit
    respond_with([:admin, @form_field])
  end
  
  def options
    respond_with([:admin, @form_field])
  end
  
  def validations
    respond_with([:admin, @form_field])
  end
  
  def dependencies
    respond_with([:admin, @form_field])
  end
  
  def field_dependencies
    respond_with([:admin, @form_field])
  end
  
  def create
    form_field      = params[:form_field]
    field_type_id   = form_field.delete(:field_type)
    field_type      = FieldType.find(field_type_id)
    form_field.reverse_merge!({ :field_type => field_type })
    @form_field     = @form.create_field(form_field)
    
    # Determine whether we're creating and continuing or returning immediately
    if params.has_key?("single")
      create_no_continue
    else
      create_and_continue
    end
  end
  
  def create_no_continue
    return_to_path  = "/admin/forms#sel=#{@form.id.to_s}"
    return_to_path  = params[:continue_path] if params[:continue]
    if @form_field.save
      flash[:notice] = "Field successfully created"
      respond_with([:admin, @form], :location => return_to_path)
    else
      respond_with([:admin, @form, @form_field], :location => return_to_path)
    end
  end
  
  def create_and_continue
    return_to_path  = params[:return_path]
    return_to_path  = params[:continue_path] if params[:continue]
    if @form_field.save
      flash[:notice] = "Field successfully created"
      respond_with([:admin, @form, @form_field], :location => return_to_path)
    else
      respond_with([:admin, @form, @form_field], :location => return_to_path)
    end
  end
  
  def update
    @form_field     = @version.form_fields.find(params[:id])
    
    form_field      = params[:form_field]
    field_type_id   = form_field.delete(:field_type)
    form_field.reverse_merge!({ :field_type => FieldType.find(field_type_id) })

    # Determine whether we're creating and continuing or returning immediately
    return_to_path  = params[:return_path]
    return_to_path  = params[:continue_path] if params[:continue]
    
    if @form_field.update_attributes(params[:form_field])
      respond_with([:admin, @form, @form_field], :location => return_to_path)
    else
      logger.debug("There was an error updating this form field")
      flash[:notice] = "There was an error saving this field"
      respond_with([:admin, @form, @form_field], :location => return_to_path)
    end
  end
    
  def destroy
    @form_field = @version.form_fields.find(params[:id])
    @form.destroy_field(@form_field)
    @form.save
    respond_with(@form, :location => hash_for(admin_forms_path, :sel => @form))
  end
  
    
  def create_option
    @form_field = @version.form_fields.find(params[:id])
    opt = params[:form_field_option]
        
    @option = FormFieldOption.new(opt)
    @form_field.manage_field(:options, :push, @option).save
    
    return_to_path = params[:return_path]
    
    redirect_to(params[:return_path])
  end
  
  
  def destroy_option
    @form_field = @version.form_fields.find(params[:id])
    @option = @form_field.options.find(params[:option_id])
    
    @form_field.manage_field(:options, :delete, @option).save
    
    return_to_path = params[:return_path]
    
    redirect_to(params[:return_path])
  end
  
  def create_validation
    @form_field = @version.form_fields.find(params[:id])
    val = params[:form_field_validation]
    base_val = FieldValidation.find(params[:field][:validation])
    
    val[:name] = base_val.name
    val[:function] = base_val.function

    @validation = FormFieldValidation.new(val)
    @form_field.manage_field(:validations, :push, @validation).save

    redirect_to(params[:return_path])
  end
  
  
  def destroy_validation
    @form_field = @version.form_fields.find(params[:id])
    @validation = @form_field.validations.find(params[:validation_id])

    @form_field.manage_field(:validations, :delete, @validation).save
      
    redirect_to(params[:return_path])
  end


  def create_dependency
    @form_field = @version.form_fields.find(params[:id])
    dependency = params[:field_dependency]
    dependent_form = Form.find(dependency[:form_id])
    
    ret = dependent_form.dependency(:create, @form_field, @form, dependency[:value])
    
    if ret && ret.save
      flash[:notice] = t("admin.form_field.dependencies.create.success")
    else
      flash[:notice] = t("admin.form_field.dependencies.create.error")
    end
    
    redirect_to(params[:return_path])
  end
  
  def destroy_dependency
    @form_field = @version.form_fields.find(params[:id])
    dependent_form = Form.find(params[:dep_form_id])
    
    ret = dependent_form.dependency(:destroy, @form_field, @form)

    if ret && ret.save
      flash[:notice] = t("admin.form_field.dependencies.create.success")
    else
      flash[:notice] = t("admin.form_field.dependencies.create.error")
    end
    
    redirect_to(params[:return_path])
  end

  def create_field_dependency
    @form_field = @version.form_fields.find(params[:id])
    dependency = params[:field_dependency]
    dependent_field = @version.form_fields.find(dependency[:field_id])
    ret = dependent_field.dependency(:create, @form_field, dependency[:value])
    
    if ret
      flash[:notice] = t("admin.form_field.dependencies.create.success")
    else
      flash[:notice] = t("admin.form_field.dependencies.create.error")
    end
    
    redirect_to(params[:return_path])
  end
  
  def destroy_field_dependency
    @form_field = @version.form_fields.find(params[:id])
    dependent_field = @version.form_fields.find(params[:dep_field_id])
    
    ret = dependent_field.dependency(:destroy, @form_field)

    if ret
      flash[:notice] = t("admin.form_field.dependencies.create.success")
    else
      flash[:notice] = t("admin.form_field.dependencies.create.error")
    end
    
    redirect_to(params[:return_path])
  end





  protected

  def select_form
    @form         = Form.find(params[:form_id])
    @return_path  = request.fullpath
    @version      = @form.current
  end
  
  def edit_pages
    @form_field = @version.form_fields.find(params[:id])
    @options = @form_field.options
    @validations = @form_field.validations
    @dependencies = @form_field.collect_dependencies
    @field_dependencies = @form_field.collect_field_dependencies
  end
end
  
