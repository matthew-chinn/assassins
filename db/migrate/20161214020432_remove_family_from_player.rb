class RemoveFamilyFromPlayer < ActiveRecord::Migration
  def change
      remove_column :players, :family, :string
  end
end
