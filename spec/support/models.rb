# create models
class User < ActiveRecord::Base
  include DeltaChanges::Extension
  attr_accessor :foo, :bar

  delta_changes :columns => %w(name score), :attributes => %w(foo)

  def full_name
    "Mr. #{name}"
  end
end
