class UsersHaveFriends < ActiveRecord::Migration[5.0]
  def change
    create_table :users_friends do |t|
      t.belongs_to :user
      t.integer :friend_id

      t.index :friend_id
    end
  end
end
