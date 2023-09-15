defmodule Bettingsystem.Repo.Migrations.CreateUserPermissions do
  use Ecto.Migration

  def change do
    create table "user_permissions" do
      add :name, :string
    end
  end
end
