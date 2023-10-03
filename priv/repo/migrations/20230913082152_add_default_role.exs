defmodule Bettingsystem.Repo.Migrations.AddDefaultRole do
  use Ecto.Migration

  def change do
    alter table("user_accounts") do
      modify :role_id, :integer, default: 3
    end
  end
end
