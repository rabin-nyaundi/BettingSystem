defmodule Bettingsystem.Repo.Migrations.CreateUserPermissions do
  use Ecto.Migration

  def change do
    create table "user_permissions" do
      add :permission, :string
    end
  end
end
