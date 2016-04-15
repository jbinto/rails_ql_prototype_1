class User < ApplicationRecord
  has_many :to_dos
  has_many :users_friends
  has_many :friends, through: :users_friends
end