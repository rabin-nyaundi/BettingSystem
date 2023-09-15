defmodule Bettingsystem.Repo.Migrations.CreateMatch do
  use Ecto.Migration

  def change do
    create table(:match) do
      add :home_odds, :string
      add :away_odds, :string
      add :draw_odds, :string
      add :home_club_id, references(:clubs, on_delete: :nothing)
      add :away_club_id, references(:clubs, on_delete: :nothing)

      timestamps()
    end

    create index(:match, [:home_club_id])
    create index(:match, [:away_club_id])
  end
end
