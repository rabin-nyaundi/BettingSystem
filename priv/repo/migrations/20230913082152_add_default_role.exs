defmodule Bettingsystem.Repo.Migrations.AddDefaultRole do
  use Ecto.Migration

  def change do
    alter table("user_accounts") do
      modify :role_id, :integer, default: 1
    end
  end
end
