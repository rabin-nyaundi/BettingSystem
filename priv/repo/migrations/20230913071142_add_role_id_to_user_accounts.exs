defmodule Bettingsystem.Repo.Migrations.AddRoleIdToUserAccounts do
  use Ecto.Migration

  def change do
    alter table(:user_accounts) do
      add :role_id, references(:user_roles, validate: false)
    end
  end
end
