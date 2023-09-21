defmodule BettingsystemWeb.BetViewLive do
  use BettingsystemWeb, :live_view

  alias Bettingsystem.Match

  @impl true
  def render(%{loading: true} = assigns) do
    ~H"""
    Loading matches...
    """
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col mx-auto w-full lg:w-1/3 shadow-md border rounded-md">
      <div class="flex flex-col w-full">
        <h2 class="text-3xl font-bold text-center p-3">Bet Details <hr /></h2>
        <div class="flex w-full p-4">
          <div class="flex w-1/3">
            <span class="font-medium">Match ID : </span>
          </div>
          <div class="flex w-flex-1">
            <span>
              <%= @bet.game.game_uuid %>
            </span>
          </div>
        </div>
        <hr />
        <div class="flex w-full p-4">
          <div class="flex w-1/3">
            <span class="font-medium">Match : </span>
          </div>
          <div class="flex flex-col w-flex-1">
            <span>
              <%= @bet.game.home_club.name <> "  vs. " <> @bet.game.away_club.name %>
            </span>
          </div>
        </div>
        <hr />
        <div class="flex w-full p-4">
          <div class="flex w-1/3">
            <span class="font-medium">Your Pick : </span>
          </div>
          <div class="flex w-flex-1">
            <div class="flex flex-col w-flex-1">
              <span>
                <%= @bet.prediction %>
              </span>
            </div>
          </div>
        </div>

        <hr />

        <div class="flex w-full p-4">
          <div class="flex w-1/3">
            <span class="font-medium">Possible Win : </span>
          </div>
          <div class="flex w-flex-1">
            <div class="flex flex-col w-flex-1">
              <span>
                <%= String.to_float(@bet.possible_win) + 100 %>
              </span>
            </div>
          </div>
        </div>

        <hr />
        <div class="flex w-full p-4">
          <div class="flex w-1/3">
            <span class="font-medium">Stake : </span>
          </div>
          <div class="flex w-flex-1">
            <div class="flex flex-col w-flex-1">
              <span>
                100
              </span>
            </div>
          </div>
        </div>

        <hr />

        <div class="flex w-full p-4">
          <div class="flex w-1/3">
            <span class="font-medium">Status : </span>
          </div>
          <div class="flex w-flex-1">
            <div class="flex flex-col w-flex-1">
              <span>
                <%= @bet.status %>
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(%{"bet_id" => bet_id}, _session, socket) do
    if connected?(socket) do

      current_bet =
        bet_id
        |> String.to_integer()
        |> Bettingsystem.Match.get_user_bet(socket.assigns.current_user_accounts.id)

      case current_bet do
        %Bettingsystem.Bets.Bet{} = bet ->
          socket =
            socket
            |> assign(:bet, current_bet)

          {:ok, socket}
        nil ->
          socket =
            socket
            |> put_flash(:error, "No such bet found!")
            |> push_navigate(to: ~p"/user-bets")

          {:ok, socket}

      end
    else
      {:ok, assign(socket, loading: true)}
    end
  end
end
