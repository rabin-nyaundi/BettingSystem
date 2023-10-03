defmodule Bettingsystem.Match do
  import Ecto.Query, warn: false

  alias Bettingsystem.Repo
  alias Bettingsystem.BettingEngine.Club
  alias Bettingsystem.Bets.Bet
  alias Bettingsystem.Account.UserAccounts
  # alias Bettingsystem.UserBets.BetsNotifier
  alias Bettingsystem.BettingEngine.Match, as: Matches

  def list_matches do
    query =
      from m in Bettingsystem.BettingEngine.Match,
        select: m,
        preload: [:home_club, :away_club, :match_winner]

    Repo.all(query)
  end

  def get_match(id) do
    Repo.get(Matches, id)
    |> Repo.preload([:home_club, :away_club, :match_winner])
  end

  def save(match_params) do
    %Matches{}
    |> Matches.changeset(match_params)
    |> Repo.insert()
  end

  def save_bet(bet_params) do
    %Bet{}
    |> Bet.changeset(bet_params)
    |> Repo.insert()
  end

  def fetch_all_bets(user_id) do
    from(b in Bet,
      where: b.user_id == ^user_id,
      order_by: [desc: b.inserted_at]
    )
    |> Repo.all()
    |> Repo.preload([:game, :user])
  end



  def get_user_bet(bet_id, user_id) do
    query =
      from b in Bet,
        where:
          b.id == ^bet_id and
            (b.user_id == ^user_id or
               ^user_id in subquery(
                 from(u in UserAccounts,
                   where: u.role_id <= 2,
                   select: u.id
                 )
               )),
        preload: [:game, :user]

    Repo.one(query)
    |> Repo.preload([:game])
    |> Repo.preload(game: [:home_club, :away_club])
  end

  def fetch_all_bets_for_admins_and_superadmins(user_id) do
    query =
      from(b in Bet,
        where:
          b.user_id == ^user_id or
            ^user_id in subquery(
              from(u in UserAccounts,
                where: u.role_id in [1, 2],
                select: u.id
              )
            ),
        order_by: [desc: b.inserted_at],
        preload: [:game, :user]
      )

    Repo.all(query)
  end

  def update_bet_status(bet_id, status) do
    from(b in Bet,
      where: b.id == ^bet_id
    )
    |> Repo.update_all(set: [status: status])
  end

  def update_match_results(result, match) do
    match
    |> Ecto.Changeset.change(%{match_winner_id: result})
    |> Repo.update()
  end

  def get_all_pending_bets(game_id) do
    query =
      from(b in Bet,
        where: b.game_id == ^game_id and b.status == ^"Pending",
        select: b,
        order_by: [desc: b.inserted_at]
      )

    Repo.all(query)
  end


  @doc """
  Fetch all clubs fro the database

  iex> clusb = fetch_all_clubs
  """

  def fetch_all_clubs do
    Repo.all(Club)
  end
end
