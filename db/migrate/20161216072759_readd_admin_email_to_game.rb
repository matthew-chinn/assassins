class ReaddAdminEmailToGame < ActiveRecord::Migration
  def change
      add_column :games, :admin_email, :string
  end
end
