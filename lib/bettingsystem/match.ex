defmodule Bettingsystem.Match do
  import Ecto.Query, warn: false

  alias Bettingsystem.Repo
  alias Bettingsystem.BettingEngine.Match

  def list_matches do
    query =
      from m in Bettingsystem.BettingEngine.Match,
        select: m,
        preload: [:home_club, :away_club]

    Repo.all(query)
  end

  def save(match_params) do
    %Match{}
    |> Match.changeset(match_params)
    |> Repo.insert()
  end
end
