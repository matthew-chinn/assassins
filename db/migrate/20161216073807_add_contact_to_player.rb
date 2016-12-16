class AddContactToPlayer < ActiveRecord::Migration
  def change
      add_column :players, :contact, :string
      add_column :players, :phone, :boolean
  end
end
