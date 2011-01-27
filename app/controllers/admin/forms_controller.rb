class Admin::FormsController < ApplicationController
  include UrlHelper # Include hash_for AJAX helper
  
  layout 'admin'
  respond_to :html
  
  before_filter :verify_clearance
  before_filter :select_form, :only => [:update, :show, :edit, :destroy, :display, :publish]
  
  def index
    @forms = Form.root_forms
    respond_with([:admin, @forms])
  end
  
  def new_form
    @form = Form.new
    @return_path = admin_forms_path
    respond_with([:admin, @form])
  end
  
  def new_child
    @form = Form.new
    @return_path = admin_forms_path
    respond_with([:admin, @form])
  end
  
  def edit
    respond_with([:admin, @form])
  end
  
  def create
    @form = Form.create(params[:form])
    respond_with([:admin, @form], :location => params[:return_path])
  end

  def update
    @form.update_attributes(params[:form])
    respond_with([:admin, @form], :location => params[:return_path])
  end
    
  def show
    respond_with([:admin, @form])
  end
  
  def display
    @version = @form.current
    @return_path = hash_for(admin_forms_path, :sel => @form)
    @form_fields = @version.form_fields.sort_by(&:position)
    render(:show, :layout => false)
  end

  def set_parent
    parent_form_id = params[:parent][:form]
    parent_form = Form.find(parent_form_id)
    form = Form.find(params[:id])

    if parent_form.add_child(form).save
      flash[:notice] = "Parent set successfully"
      redirect_to(admin_form_path(form))
    else
      flash[:notice] = "Unable to set parent"
      redirect_to(admin_form_path(form))
    end
  end
  
  # Remove the child and make it a root node
  def orphan_child
    child_form_id = params[:child_form_id]
    child_form = Form.find(child_form_id)    
    parent_form = Form.find(params[:id])
    child_form = parent_form.remove_child(child_form)

    if child_form.save
      flash[:notice] = "Child orphaned successfully"
      redirect_to(admin_form_path(parent_form))
    else
      flash[:notice] = "Unable to orphan child"
      redirect_to(admin_form_path(parent_form))
    end
  end

  def create_form
    @form = Form.create(params[:form])
    respond_with([:admin, @form], :location => params[:return_path])
  end
  
  def create
    parent_form = Form.find(params[:parent_id])
    
    if parent_form
      new_form = Form.create(:name => params[:title], :position => params[:position])
      parent_form.add_child(new_form)
      render(:json => {:status => :ok, :id => new_form.id.to_s}) and return if parent_form.save
    end
    
    render(:json => {:status => :error})
  end
  
  def destroy
    form = Form.find(params[:id])
    form.destroy_tree
    render(:json => {:status => :ok})
  end
  
  def move
    form = Form.find(params[:id])
    parent_form = Form.find(params[:ref])
    is_copy = params[:copy] == 1
    title = params[:title]
    
    if parent_form.has_child?(form)
      # If the parent already owns the child, just update the kid's position
      form.update_position(params[:position])
      render(:json => {:status => :ok, :id => form.id.to_s}) and return if form.save
    else
      # Otherwise, remove the child form the old form and move it to the new parent
      new_child_form = form.parent_document.remove_child(form)
      parent_form.add_child(new_child_form)
      render(:json => {:status => :ok, :id => new_child_form.id.to_s}) and return if parent_form.save
    end
  end
  
  def sort_fields
    form = Form.find(params[:id])
    field_order = params[:field]
    version = form.current
    
    field_order.each do |field|
      form_field            = version.form_fields.find(field)
      form_field.position   = field_order.index(field)
      form_field.save
    end
    
    render(:json => {:status => :ok})
  end
  
  def publish
    return_to_path = params[:return_path]
    if @form.publish.save
      respond_with([:admin, @form], :location => return_to_path)
    else
      respond_with([:admin, @form], :location => return_to_path)
    end
  end

protected 
  
  def select_form
    @form = Form.find(params[:id])
  end
  
  def verify_clearance
    if current_administrator.type != :manager
      redirect_to '/admin'
    end
  end

end