class CreateIntegrityLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :integrity_logs do |t|
      t.string :idfa, null: false
      t.string :ban_status, null: false
      t.string :ip
      t.boolean :rooted_device, null: false, default: false
      t.string :country
      t.boolean :proxy, null: false, default: false
      t.boolean :vpn, null: false, default: false

      t.datetime :created_at, null: false
    end

    add_index :integrity_logs, :idfa
  end
end
