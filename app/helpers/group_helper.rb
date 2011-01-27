module GroupHelper
  
  #
  # This is used by #make_groups_from
  #
  class Group
    attr_accessor :name, :members
    def initialize(name)
      @members = []
      @name = name
    end    
  end
  
  
  #
  # This helper creates a workable model from which optgroups can be obtained. 
  # It takes a non-normalized collection which is grouped by #group_member
  #
  #
  #
  
  def make_groups_from(collection, group_member)
    groups = []
    collection.each do |member|
      group_name  = member.send(group_member)
      group       = groups.detect {|g| g.name == group_name}
      groups      << (group = Group.new(group_name)) if group.nil?
      group.members << member
    end
    groups
  end
  
  
  #case "String":
  #     label = "Text";
  # case "Option":
  #     return;
  # case "CheckSingle":
  #     return;
  # case "File":
  #     label = "File";
  # case "Image":
  #     label = "Image";
  # case "Date":
  #     label = "Date";
  # case "Number":
  #     label = "Number";
  def make_group_from_single(collection, group_member, field)
    groups = []
    field_group = field.field_type.group
    Rails.logger.debug("FIELD GROUP: #{field_group}")
    # TODO Remove this when String becomes Text in the form fields
    field_group = "Text" if field_group == "String"
    collection.each do |member|
      group_name  = member.send(group_member)
      Rails.logger.debug("TESTING GROUP: #{group_name}")
      next if (field_group != group_name && group_name != "All")
      Rails.logger.debug("ACCEPTED GROUP: #{group_name} FOR #{field_group}")
      group         = groups.detect {|g| g.name == group_name}
      groups        << (group = Group.new(group_name)) if group.nil?
      group.members << member
    end
    groups
  end
end