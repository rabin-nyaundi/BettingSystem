defmodule Bettingsystem.Match do
  import Ecto.Query, warn: false

  alias Bettingsystem.Repo
  alias Bettingsystem.Bets.Bet
  alias Bettingsystem.BettingEngine.Match, as: Games

  def list_matches do
    query =
      from m in Bettingsystem.BettingEngine.Match,
        select: m,
        preload: [:home_club, :away_club]

    Repo.all(query)
  end

  def get_match(id) do
    Repo.get(Games, id)
    |> Repo.preload([:home_club, :away_club])
  end

  def save(match_params) do
    %Games{}
    |> Games.changeset(match_params)
    |> Repo.insert()
  end

  def save_bet(bet_params) do
    %Bet{}
    |> Bet.changeset(bet_params)
    |> Repo.insert()
  end

  def fetch_all_bets(user_id) do
    from(b in Bettingsystem.Bets.Bet,
      where: b.user_id == ^user_id,
      order_by: [desc: b.inserted_at]
    )
    |> Repo.all()
    |> Repo.preload([:game])
  end

  def get_user_bet(bet_id, user_id) do

    query = 
    from b in Bet,
    where: b.id == ^bet_id and b.user_id == ^user_id

    Repo.one(query)
    |> Repo.preload([:game])
    |> Repo.preload(game: [:home_club, :away_club])
  end

  def fetch_all_bets_for_admins_and_superadmins(user_id) do
    query =
      from(b in Bettingsystem.Bets.Bet,
        where:
          b.user_id == ^user_id or
            ^user_id in subquery(
              from(u in Bettingsystem.Account.UserAccounts,
                where: u.role_id in [1, 2],
                select: u.id
              )
            ),
        order_by: [desc: b.inserted_at],
        preload: [:game]
      )

    Repo.all(query)
  end

  def update_bet_status(bet_id, status) do
    from(b in Bettingsystem.Bets.Bet,
      where: b.id == ^bet_id
    )
    |> Repo.update_all(set: [status: status])
  end
end