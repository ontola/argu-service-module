class Resource
  include ActiveModel::Model
  alias read_attribute_for_serialization send

  def initialize(new_record)
    @new_record_before_save = new_record
  end

  def id
    'resource_id'
  end

  def as_json(_options = {})
    {}
  end

  def attr_1
    'is'
  end

  def attr_2
    'new'
  end

  def previous_changes
    {attr_1: ['was', 'is'], attr_2: [nil, 'new']}
  end
end
