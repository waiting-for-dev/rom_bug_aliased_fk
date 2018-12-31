require "bundler/setup"
require "rom"

module Types
  include Dry::Types.module
end

rom = ROM.container(:sql, 'sqlite::memory') do |conf|
  conf.default.create_table(:users) do
    primary_key :id
    column :name, String, null: false
  end

  conf.default.create_table(:tasks) do
    primary_key :id
    column :name, String, null: false
    foreign_key :bad_name_id, :users, null: false
  end

  conf.relation(:users) do
    schema(infer: true)
  end

  conf.relation(:tasks_without_alias) do
    schema(:tasks, infer: true, as: :tasks_without_alias) do
      associations do
        belongs_to(:user)
      end
    end
  end

  conf.relation(:tasks_with_alias) do
    schema(:tasks, infer: true, as: :tasks_with_alias) do
      attribute :bad_name_id, Types::Integer.meta(alias: :user_id)

      associations do
        belongs_to(:user)
      end
    end
  end
end

joe = rom.relations[:users].command(:create).(name: "Joe Doe")
rom.relations[:tasks_without_alias].command(:create).(name: "Be happy", bad_name_id: joe[:id])

puts "Output combining from relation without FK aliased"
puts rom.relations[:tasks_without_alias].combine(:users).to_a
# => {:id=>1, :name=>"Be happy", :bad_name_id=>1, :user=>{:id=>1, :name=>"Joe Doe"}}
puts "====================="
puts "Output combining from relation with FK aliased"
puts rom.relations[:tasks_with_alias].combine(:users).to_a
# => {:user_id=>1, :id=>1, :name=>"Be happy", :user=>nil}
