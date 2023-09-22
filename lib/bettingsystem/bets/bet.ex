defmodule Bettingsystem.Bets.Bet do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.SoftDelete.Schema

  schema "bets" do
    field :amount, :string
    field :prediction, :string
    field :status, :string
    field :possible_win, :string
    belongs_to :game, Bettingsystem.BettingEngine.Match
    belongs_to :user, Bettingsystem.Account.UserAccounts
    soft_delete_schema()
    timestamps()
  end

  @doc false
  def changeset(bet, attrs) do
    bet
    |> cast(attrs, [:amount, :user_id, :game_id, :prediction, :possible_win, :status])
    |> validate_required([:amount, :user_id, :game_id, :prediction])
  end
end
