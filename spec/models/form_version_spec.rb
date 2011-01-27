require 'spec_helper'


describe "FormVersion", :type => :model do

  before :each do
    Form.destroy_all
    @form = Form.create(:name => "Test Form")
  end
  
  it "should exist" do
    @form.current.is_a?(FormVersion).should be_true
  end
  
end