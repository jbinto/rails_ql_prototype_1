class CreateEverything < ActiveRecord::Migration[5.0]
  def change
    create_table :users do |t|
      t.boolean :admin
      t.string :email
    end

    create_table :to_dos do |t|
      t.belongs_to :user

      t.string :status
      t.string :content
    end

  end
end
