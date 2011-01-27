require 'spec_helper'


describe "FormField", :type => :model do

  before :each do
    Form.destroy_all
  end
  
  it "should save" do
    true
  end
  
  describe "dependencies" do
    
    before :each do
      @form = Form.create(:name => "Test")
      @form.create_field(Factory.create(:text_field)).save
      @form.create_field(Factory.create(:text_field)).save
    end
    
    it "should add a dependency" do
      first_field   = @form.current.form_fields[0]
      second_field  = @form.current.form_fields[1]
      
      first_field.dependency(:create, second_field, "test_val").should be_true
      first_field.fields_depended_on.select do |fd| 
        fd['id'] == second_field.field_key
      end.first.blank?.should_not be_true
      @form.reload
      second_field  = @form.current.form_fields[1]
      second_field.dependent_fields.size.should_not == 0
    end
    
    it "should remove a dependency" do
      first_field   = @form.current.form_fields[0]
      second_field  = @form.current.form_fields[1]
      
      first_field.dependency(:create, second_field, "test_val")
      first_field.dependency(:destroy, second_field).should be_true
      
      first_field.fields_depended_on.select do |fd|
        fd['id'] == second_field.field_key
      end.first.blank?.should be_true
      @form.reload
      second_field  = @form.current.form_fields[1]
      second_field.dependent_fields.size.should == 0
    end
    
    it "should know when dependencies are met" do
      first_field   = @form.current.form_fields[0]
      second_field  = @form.current.form_fields[1]
      
      first_field.dependency(:create, second_field, "test_val")
      first_field.dependencies_met?.should_not be_true
      @form.publish
      prototype = @form.to_prototype
      prototype.form_fields[0].dependencies_met?.should_not be_true
      
      name = prototype.form_fields[1].name
      data = prototype.form_data
      data.send("#{name}=", "test_val")
      data.save
      
      prototype.reload
      prototype.form_fields[0].dependencies_met?.should be_true
    end
    
    it "should know when dependencies are not met" do
      first_field   = @form.current.form_fields[0]
      second_field  = @form.current.form_fields[1]
      
      first_field.dependency(:create, second_field, "test_val")
      first_field.dependencies_met?.should_not be_true
      @form.publish
      prototype = @form.to_prototype
      prototype.form_fields[0].dependencies_met?.should_not be_true
      
      name = prototype.form_fields[1].name
      data = prototype.form_data
      data.send("#{name}=", "all lies")
      data.save
      
      prototype.reload
      prototype.form_fields[0].dependencies_met?.should_not be_true
    end
    
  end

end