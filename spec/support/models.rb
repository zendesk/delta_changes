# create models
class User < ActiveRecord::Base
  include DeltaChanges::Extension
  attr_accessor :foo, :bar

  before_save :apply_changes

  delta_changes :columns => %w(name score), :attributes => %w(foo)

  def full_name
    "Mr. #{name}"
  end

  def audits
    @audits ||= []
  end

  def changes_to_apply
    @changes ||= []
  end

  def changes_to_apply=(changes)
    @changes = changes
  end

  private

  def apply_changes
    changes_to_apply.each do |change|
      audit = Audit.new
      attr_name = change[:attr_name]
      new_value = change[:value]
      old_value = self[attr_name]

      self.send("#{attr_name}=", new_value)

      delta_changes.keys.each do |attr_name|
        from, to = delta_changes[attr_name]
        change = ChangeEvent.new(
          attr_name: attr_name,
          old_value: from,
          new_value: to,
        )

        audit.changes << change
      end
      self.audits << audit
      reset_delta_changes!
    end
  end
end

class Audit
  def changes
    @changes ||= []
  end
end

class ChangeEvent
  attr_reader :attr_name, :old_value, :new_value

  def initialize(attr_name:, old_value:, new_value:)
    @attr_name = attr_name
    @old_value = old_value
    @new_value = new_value
  end

  def to_h
    {attr_name => [old_value, new_value]}
  end
end
