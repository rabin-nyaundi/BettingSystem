defmodule Bettingsystem.Repo.Migrations.CreateUserRoles do
  use Ecto.Migration

  def change do
    create table(:user_roles, defer_constraints: true) do
      add :role, :string
    end
  end
end
