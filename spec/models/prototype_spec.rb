require 'spec_helper'


describe "Prototype", :type => :model do

  before :each do
    Rails.logger.debug("PrototypeSpec: Destroying old forms and prototypes")
    Form.destroy_all
    Prototype.destroy_all
  end
  
  it "should save" do
    Prototype.create(:name => "Test").should be_true
  end

  it "should convert from form" do
    form = Form.create(:name => "Test Form")
    form.publish
    prototype = form.to_prototype
    prototype.is_a?(Prototype).should be_true
    prototype.name.should == form.name
  end
  
  
  it "should have been converted from last published version" do
    @form = Form.create(:name => "Test Form")
    @form.publish
    # Add form fields and validations
    0.upto(5) do |num|
      @form.create_field(Factory.create(:text_field))
    end
    
    @prototype = @form.to_prototype
    # Old published version
    @prototype.form_fields.count.should == 0
    
    # Publish new version
    @form.publish
    @prototype = @form.to_prototype
    @prototype.form_fields.count.should == @form.current.form_fields.count
  end
  
  
  
  describe "children" do
    
    describe "basic" do
      before(:each) do
        @form = Form.create(:name => "Test")
        @child_form = Form.create(:name => "Test Child")
        @form.add_child(@child_form).save
        @form.publish
        
        @prototype = @form.to_prototype
        @prototype.save
      end
    
      it "should be able to have children" do
        @prototype.has_children?.should be_true
      end
    
      it "should know if it is a root form" do
        @prototype.is_root_form?.should be_true
      end
    
      it "should know if it is not a root form" do
        @prototype.children.first.is_root_form?.should_not be_true
      end
    
      it "should recognize its parent" do
        @prototype.children.first.parent_document.should == @prototype
      end
    end
    
    describe "extended" do
      
      before(:each) do
        @form = Form.create(:name => "Test")
        @child_form = Form.create(:name => "Test Child")
        @child_form_two = Form.create(:name => "Test Child 2")
      end
      
      it "should count children correctly" do
        @form.add_child(@child_form).save
        @form.publish
        @prototype = @form.to_prototype
        @prototype.children.count.should == 1

        @form.add_child(@child_form_two).save
        @form.publish
        @prototype = @form.to_prototype
        @prototype.children.count.should == 2
      end
  
      it "should count descendents correctly" do
        @child_form.add_child(@child_form_two).save
        @form.add_child(@child_form).save
        @form.publish
        @prototype = @form.to_prototype
        @prototype.descendents.count.should == 2
      end
      
      describe "dependencies" do
        
        before(:each) do
          @valid_string = "dep is true"
          @invalid_string = "dep is false"
          
          @form.add_child(@child_form).save
          @form.create_field(Factory.create(:text_field)).save
          # @form.reload
          
          field = @form.current.form_fields.first
          
          @child_form.dependency(:create, field, @form, @valid_string).save
          @form.publish
          
          @prototype = @form.to_prototype
          
          @proto_child = @prototype.children.first
        end
        
        it "should exist" do
          @proto_child.field_dependencies.size.should > 0
        end
        
        it "should start knowing that dependencies are not met" do
          @proto_child.dependencies_met?.should == false
        end
        
        describe "specific" do
          
          before(:each) do
            @prototype.send(:set_up_prototype)
            @prototype.save
            
            @data                 = @prototype.form_data
            dep                   = @proto_child.field_dependencies.first
            dep = dep.symbolize_keys!
            @dep_form, @dep_field = Prototype.key_to_form_and_field(dep[:id])
          end
          
          it "should know when dependencies are met" do
            # Alter data so field is corect
            @dep_form.form_data.send(:"#{@dep_field.name}=", @valid_string)
            @dep_form.save

            # check deps met
            @proto_child.reload
            met = @proto_child.dependencies_met?
            met.should == true
          end
      
          it "should know when dependencies are NOT met" do          
            # Alter data so field is corect
            @data.send(:"#{@dep_field.name}=", @invalid_string)
            @data.save
            
            # check deps met
            @proto_child.reload
            met = @proto_child.dependencies_met?
            met.should == false
          end
          
          it "should distinguish change from true to false" do
            # valid dep
            @data.send(:"#{@dep_field.name}=", @valid_string)
            @data.save
            
            # invalid dep
            @data.send(:"#{@dep_field.name}=", @invalid_string)
            @data.save
            
            # test
            @proto_child.reload
            met = @proto_child.dependencies_met?
            met.should == false
          end
          
        end
        
      end
      
    end
    
  end
  
  
  describe "should convert properly from Form" do
    
    describe "when form has no child forms" do
      before(:each) do
        @form = Form.create(:name => "Test Form")
        # Add form fields and validations
        tf1 = @form.create_field(Factory.create(:text_field))
        tf2 = @form.create_field(Factory.create(:text_field))
        sf1 = @form.create_field(Factory.create(:select_field))
        sf2 = @form.create_field(Factory.create(:select_field))
        
        0.upto(5) do |num|
          sf1.manage_field(:options, :push, Factory.create(:form_field_option)).save
          sf2.manage_field(:options, :push, Factory.create(:form_field_option)).save
          sf1.manage_field(:validations, :push, Factory.create(:form_field_validation)).save
          sf2.manage_field(:validations, :push, Factory.create(:form_field_validation)).save
        end
        @form.save
        @form.publish
        @prototype = @form.to_prototype
      end

      it "should have form fields" do
        @prototype = @form.to_prototype
        @prototype.form_fields.count.should == @form.published.form_fields.count
      end

      it "should have base validations" do
        # Form validation count for each field should equal that of prototype
        @prototype.form_fields.each do |proto_field|
          form_field = @form.published.form_fields.detect{|ff| ff.name == proto_field.name}
          pc = proto_field.validations.count
          fc = form_field.validations.count
          pc.should == fc
        end
      end

      it "should have base options" do
        # Form option count for each field should equal that of prototype
        @prototype.form_fields.each do |proto_field|
          form_field = @form.published.form_fields.detect{|ff| ff.name == proto_field.name}
          pc = proto_field.options.count
          fc = form_field.options.count
          pc.should == fc
        end
      end
      
      it "should have the same key as its form counterpart" do
        @prototype.form_key.should == @form.form_key
      end
      
    end
    
    
    # NOTE on prototype child testing
    # All child events can be proven through induction since forms just hold forms
    # and prototypes just hold prototypes, and forms are converted to prototypes 
    # recursively using the same function.
  end
  

end
