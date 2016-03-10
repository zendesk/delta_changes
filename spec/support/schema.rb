# create tables
ActiveRecord::Schema.define(:version => 1) do
  create_table :users do |t|
    t.string :name
    t.string :email
    t.integer :score
    t.timestamps
  end
end
