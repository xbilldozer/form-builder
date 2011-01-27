require 'spec_helper'


describe "Form", :type => :model do

  before :each do
    Form.destroy_all
  end
  
  it "should save" do
    form = Form.new(:name => "Test")
    form.save.should be_true
  end

  describe "versions" do
    
    before(:each) do
      @form = Form.create(:name => "Test")
    end
    
    it "should have a base version after creation" do
      @form.form_versions.count.should == 1
    end
    
    it "should have a current version of 1" do
      @form.current_version.should == 1
    end
    
    it "should have a published version of 0" do
      @form.published_version.should == 0
    end
    
    describe "when published is current" do

      it "should migrate on form alteration" do
        @form.publish
        @form.create_field(Factory.create(:text_field))
        @form.published_version.should_not == @form.current_version
      end

    end

    describe "when published is not current" do
      
      it "should not migrate on form alteration" do
        # On create, published version != current_version
        pv = @form.current_version
        @form.create_field(Factory.create(:text_field))
        # And current version should still equal old current version
        @form.current_version.should == pv
      end

    end
    
  end
  
  describe "children" do
    
    before(:each) do
      @form = Form.create(:name => "Test")
      @child_form = Form.create(:name => "Test Child")
    end
    
    it "should be able to have children" do
      @form.add_child(@child_form).save
      
      @form.has_children?.should be_true
    end
    
    it "should know if it is a root form" do
      @form.is_root_form?.should be_true
    end
    
    it "should know if it is not a root form" do
      @form.add_child(@child_form).save
      
      @child_form.is_root_form?.should_not be_true
    end
    
    it "should recognize its parent" do
      @form.add_child(@child_form).save
      
      @child_form.parent_document.should == @form
    end
    
    it "should count children correctly" do
      @form.add_child(@child_form).save
      
      @form.children.count.should == 1
      
      @child_form_two = Form.create(:name => "Test Child 2")
      @form.add_child(@child_form_two).save
      
      @form.children.count.should == 2
    end
    
    it "should count descendents correctly" do
      @child_form_two = Form.create(:name => "Test Child 2")
      @child_form.add_child(@child_form_two).save
      @form.add_child(@child_form).save
      
      @form.descendents.count.should == 2
    end
    
    it "should remove children" do
      # Remove single child and place it into the root domain
      @form.add_child(@child_form).save
      
      child = @form.remove_child(@child_form)
      @form.save
      
      child.is_root_form?.should be_true
      @form.children.count.should == 0
    end
    
    it "should destroy child lineage" do
      # Destroy a tree of children
      @child_form_two = Form.create(:name => "Test Child 2")
      @child_form.add_child(@child_form_two).save
      @form.add_child(@child_form).save
      
      @child_form.destroy_tree
      @form.descendents.count.should == 0
    end
    
  end
  
  describe "keys" do
    
    before(:each) do
      @form = Form.create(:name => "Test")
    end
    
    it "should generate a key on form validation" do
      @form.valid?
      @form.form_key.should_not be_nil
    end
    
    it "should generate a valid key for root form" do
      key_chain = @form.key_chain
      true_key_chain = @form.name.gsub(/[^a-zA-Z0-9]+/,"_")
      key_chain.should == true_key_chain
    end
    
    it "should generate a valid key for nested form" do
      @child_form = Form.create(:name => "Test Child")
      @form.add_child(@child_form).save
      
      @child_form.reload
      
      key_chain = @child_form.key_chain
      
      true_key_chain = @form.name.gsub(/[^a-zA-Z0-9]+/,"_")
      true_key_chain << "." 
      true_key_chain << @child_form.name.gsub(/[^a-zA-Z0-9]+/,"_")
      
      key_chain.should == true_key_chain
    end

  end
    
  describe "form fields" do
    
    before(:each) do
      @form = Form.create(:name => "Test")
    end
    
    it "should add form fields" do
      @form.create_field(Factory.create(:text_field)).save
      @form.current.form_fields.count.should_not == 0
    end
    
  end
  
  describe "dependencies" do
    
    before(:each) do
      @form = Form.create(:name => "Test")
      
      @child_form = Form.create(:name => "Test Child")
      @form.add_child(@child_form).save
      
      @form.create_field(Factory.create(:text_field)).save
    end
    
    it "should add a dependency" do
      field = @form.current.form_fields.first
      valid_string = "dep is true"
      @child_form.dependency(:create, field, @form, valid_string).save
      
      @child_form.field_dependencies.size.should_not == 0
      
      @form.reload
      field = @form.current.form_fields.first
      
      is_in_field = field.dependent_forms.include?(@child_form.key_chain)
      is_in_field.should == true
    end
    
    it "should destroy a dependency" do
      field = @form.current.form_fields.first
      valid_string = "dep is true"
      @child_form.dependency(:create, field, @form, valid_string).save
      
      @child_form.field_dependencies.size.should_not == 0
      
      @child_form.dependency(:destroy, field, @form).save
      
      @form.reload
      field = @form.current.form_fields.first
      
      is_in_field = field.dependent_forms.include?(@child_form.key_chain)
      is_in_field.should == false
    end
    
    it "should know that a dependency exists" do
      field = @form.current.form_fields.first
      valid_string = "dep is true"
      @child_form.dependency(:create, field, @form, valid_string).save
      
      @child_form.field_dependencies.size.should_not == 0
      
      @child_form.dependency(:exists?, field, @form).should == true
    end
    
    it "should not accept an owner with a form.field key any action" do
      field = "fake.owner.key"
      valid_string = "dep is true"
      
      [:create, :destroy, :exists?].each do |action|
        ret = @child_form.dependency(action, field, @form, valid_string)
        ret.should == false
      end
      
    end
    
    it "should not accept a FormField without an owner any action" do
      field = @form.current.form_fields.first
      
      [:create, :destroy, :exists?].each do |action|
        ret = @child_form.dependency(action, field)
        ret.should == false
      end
      
    end
    
    it "should not accept a string for an owner for any action" do
      field = @form.current.form_fields.first
      valid_string = "dep is true"
      form = "fake.owner"
      
      [:create, :destroy, :exists?].each do |action|
        ret = @child_form.dependency(action, field, form, valid_string)
        ret.should == false
      end
      
    end
    
    it "should get updated when field name is changed" do
      field = @form.current.form_fields.first
      valid_string = "dep is true"
      @child_form.dependency(:create, field, @form, valid_string).save
      
      field.name = "whiskey tango"
      field.save
      
      @form.reload
      @child_form.reload
      
      @child_form.dependency(:exists?, field, @form).should == true
    end
    
    it "should update fields when its name is changed" do
      field = @form.current.form_fields.first
      valid_string = "dep is true"
      @child_form.dependency(:create, field, @form, valid_string).save
      
      @form.name = "whiskey tango"
      @form.save
      
      @form.reload
      @child_form.reload
      field = @form.current.form_fields.first
      
      @child_form.dependency(:exists?, field, @form).should == true
    end
    
  end
  
  describe "to_prototype" do

    before(:each) do
      @form = Form.create(:name => "Test Form")
    end

    it "should not create a prototype if a form is not published" do
      prototype = @form.to_prototype
      prototype.should be_nil
    end
    
    it "should create a prototype if a form is published" do
      @form.publish
      prototype = @form.to_prototype
      prototype.is_a?(Prototype).should be_true
    end
    
  end

end
