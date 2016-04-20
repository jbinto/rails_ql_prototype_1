class User < ApplicationRecord
  has_many :to_dos
  has_many :complete_to_dos, ->{where(status: :complete)}, class_name: "ToDo"
  has_many :incomplete_to_dos, ->{where(status: :incomplete)}, class_name: "ToDo"
  has_many :users_friends
  has_many :friends, through: :users_friends
end