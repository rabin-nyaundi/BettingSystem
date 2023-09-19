defmodule Bettingsystem.BettingEngine.Match do
  use Ecto.Schema
  import Ecto.Changeset

  alias Bettingsystem.BettingEngine.Club

  schema "match" do
    field :game_uuid, :string
    field :home_odds, :string
    field :away_odds, :string
    field :draw_odds, :string
    belongs_to :home_club, Club
    belongs_to :away_club, Club

    timestamps()
  end

  @doc false
  def changeset(match, attrs) do
    match
    |> cast(attrs, [:home_odds, :away_odds, :draw_odds, :home_club_id, :away_club_id, :game_uuid])
    |> validate_required([:home_odds, :away_odds, :draw_odds, :home_club_id, :away_club_id])
  end
end
