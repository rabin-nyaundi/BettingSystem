defmodule Bettingsystem.Repo.Migrations.CreateGrantedPermissions do
  use Ecto.Migration

  def change do
    create table(:granted_permissions) do
      add :role_id, references(:user_roles, on_delete: :nothing), null: false
      add :permission_id, references(:user_permissions, on_delete: :nothing), null: false
      timestamps()
    end
  end
end
