defmodule Bettingsystem.Repo.Migrations.CreateUserAccontsAuthTables do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    create table(:user_accounts, defer_constraints: true) do
      add :first_name, :string, null: false
      add :last_name, :string, null: false
      add :email, :citext, null: false
      add :hashed_password, :string, null: false
      add :is_deleted, :boolean, null: false
      add :confirmed_at, :naive_datetime
      timestamps()
    end

    create unique_index(:user_accounts, [:email])

    create table(:user_accounts_tokens) do
      add :user_accounts_id, references(:user_accounts, on_delete: :delete_all), null: false
      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string
      timestamps(updated_at: false)
    end

    create index(:user_accounts_tokens, [:user_accounts_id])
    create unique_index(:user_accounts_tokens, [:context, :token])

  end
end
