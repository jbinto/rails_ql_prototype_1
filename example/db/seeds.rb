# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

User.delete_all
ToDo.delete_all

User.create! admin: true, email: "admin@test.com"
User.create! admin: false, email: "average_joe@test.com"

i = 0
User.all.each do |user|
  5.times do
    user.to_dos.create!(
      content: "lorem ipsum and stuff #{i += 1}",
      status: i % 3 == 0 ? :complete : :incomplete
    )
  end
end
