class User < ActiveRecord::Base
  has_many :to_dos
end