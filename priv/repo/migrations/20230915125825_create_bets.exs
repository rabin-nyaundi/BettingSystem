defmodule Bettingsystem.Repo.Migrations.CreateBets do
  use Ecto.Migration
  import Ecto.SoftDelete.Migration

  def change do
    create table(:bets) do
      add :amount, :string
      add :prediction, :string
      add :game_id, references(:match, on_delete: :nothing)
      add :user_id, references(:user_accounts, on_delete: :nothing)
      add :status, :string
      add :possible_win, :string
      soft_delete_columns()

      timestamps()
    end

    create index(:bets, [:game_id])
    create index(:bets, [:user_id])
  end
end
