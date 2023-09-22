defmodule Bettingsystem.Repo.Migrations.CreateMatch do
  use Ecto.Migration
  import Ecto.SoftDelete.Migration

  def change do
    create table(:match) do
      add :game_uuid, :string
      add :home_odds, :string
      add :away_odds, :string
      add :draw_odds, :string
      add :home_club_id, references(:clubs, on_delete: :nothing)
      add :away_club_id, references(:clubs, on_delete: :nothing)
      add :match_winner_id, references(:clubs, on_delete: :nothing)
      soft_delete_columns()
      timestamps()

    end

    create index(:match, [:home_club_id])
    create index(:match, [:away_club_id])
    create index(:match, [:match_winner_id])
  end
end
