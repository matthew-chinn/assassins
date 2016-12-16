class ChangeAdminInGame < ActiveRecord::Migration
  def change
    remove_column :games, :admin_email, :string
    rename_column :games, :password, :key
  end
end
