class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :idfa, null: false
      t.string :ban_status, null: false, default: "not_banned"

      t.timestamps
    end

    add_index :users, :idfa, unique: true
  end
end
