class AddKeyToPlayer < ActiveRecord::Migration
  def change
      add_column :players, :key, :string
  end
end
