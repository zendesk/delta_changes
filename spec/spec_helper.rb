require "bundler/setup"
require "delta_changes"
require "active_record"

# connect
ActiveRecord::Base.establish_connection(
  :adapter => "sqlite3",
  :database => ":memory:"
)

# create tables
ActiveRecord::Schema.define(:version => 1) do
  create_table :users do |t|
    t.string :name
    t.string :email
    t.timestamps
  end
end

# create models
class User < ActiveRecord::Base
  include DeltaChanges::Extension
  attr_accessor :foo, :bar

  delta_changes :columns => ["name"], :attributes => ["foo"]

  def full_name
    "Mr. #{name}"
  end
end
