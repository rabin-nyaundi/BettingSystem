defmodule BettingsystemWeb.BettingHomeLive do
  use BettingsystemWeb, :live_view

  alias Bettingsystem.Repo

  alias Bettingsystem.Match

  alias Bettingsystem.Roles.UserRoles

  alias Bettingsystem.BettingEngine.Club
  alias Bettingsystem.UserAccessPermission
  alias Bettingsystem.BettingEngine.Match, as: Matches

  @impl true
  def render(%{loading: true} = assigns) do
    ~H"""
    Loading matches...
    """
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col flex-1 h-full w-full p-2">
      <div class="flex gap-8 mx-auto w-2/3">
        <div
          id="matches"
          phx-update="stream"
          class="flex flex-col justify-center mx-auto gap-8 w-full h-full rounded-lg"
        >
          <div
            :for={{dom_id, match} <- @streams.matches}
            id={dom_id}
            class="flex flex-col bg-white shadow-lg p-6 rounded-lg"
          >
            <div class="flex">
              <div class="w-1/3 flex flex-col gap-2 justify-center">
               <span>  GameID: <b> <%= match.game_uuid %> </b> </span>
                <p>
                  <%= match.home_club.name %>
                </p>
                <p>
                  <%= match.away_club.name %>
                </p>
              </div>
              <div class="flex justify-center items-center gap-4">
                <div class="flex flex-col gap-4 ">
                  <div class="flex text-center uppercase">Home</div>
                  <div
                    class="rounded-md p-4 border border-gray-400 cursor-pointer"
                    phx-click="set_prediction"
                    phx-value-prediction="1"
                    phx-value-game_id={match.id}
                    phx-value-game_uuid={match.game_uuid}
                    phx-value-picked_odds={match.home_odds}
                  >
                    <%= match.home_odds %>
                  </div>
                </div>
                <div class="flex flex-col gap-4">
                  <div>Draw</div>
                  <div class="rounded-md p-4 border border-gray-400">234</div>
                </div>
                <div class="flex flex-col gap-4">
                  <div>Away</div>
                  <div class="rounded-md p-4 border border-gray-400">798</div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <%= if @betslip == true do %>
          <%= if Map.get(assigns, :game_id) do %>
            <div class="flex flex-col justify-center px-8 w-1/3 shadow-sm">
              <h3 class="p-4 uppercase text-2xl text-center">
                Betslip <hr />
              </h3>
              <div class="flex flex-col gap-7">
                <p>Game id: <%= Map.get(assigns, :game_uuid, "") %></p>
                <p>
                  <%= if Map.has_key?(assigns, :selected_match) do %>
                    <span>Your Pick: <%= Map.get(assigns, :prediction) %></span>
                  <% end %>
                </p>
                <div class="flex justify-cente items-center gap-2">
                  <div class="flex h-auto">
                    <button
                      phx-click="submit_bet"
                      phx-disable-with="Submitting..."
                      class="w-full border py-3 px-5 rounded-xl bg-blue-400 text-white"
                    >
                      Submit <span aria-hidden="true"></span>
                    </button>
                  </div>
                </div>
              </div>
            </div>
          <% end %>
        <% end %>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      clubs = Match.fetch_all_clubs()

      # fetch user permissions
      permissions =
        UserAccessPermission.get_user_role(socket.assigns.current_user_accounts)
        |> Bettingsystem.UserAccessPermission.list_all_permissions()

      form =
        %Matches{}
        |> Matches.changeset(%{})
        |> to_form(as: "match")

      socket =
        socket
        |> assign(
          form: form,
          clubs: clubs,
          permissions: permissions,
          betslip: false,
          loading: false
        )
        |> stream(:matches, Match.list_matches())

      {:ok, socket}
    else
      {:ok, assign(socket, loading: true)}
    end
  end

  @impl true
  def handle_event(
        "set_prediction",
        %{
          "prediction" => prediction,
          "game_id" => game_id,
          "picked_odds" => picked_odds,
          "game_uuid" => game_uuid
        },
        socket
      ) do
    match = Match.get_match(game_id)

    socket =
      socket
      |> assign(prediction: prediction,
        game_id: game_id,
        picked_odds: picked_odds,
        game_uuid: game_uuid,
        selected_match: match,
        betslip: true
      )

    {:noreply, socket}
  end

  def handle_event("submit_bet", _params, socket) do
    picked_odds = socket.assigns.picked_odds
    game_id = socket.assigns.game_id
    prediction = socket.assigns.prediction
    user = socket.assigns.current_user_accounts
    amount = "100"

    picked_odds_float = String.to_float(picked_odds)

    possible_win =
      String.to_integer(amount)
      |> calculate_possible_win(picked_odds_float - 1)
      |> Float.round()
      |> Float.to_string()

    bet_params = %{
      game_id: game_id,
      prediction: prediction,
      amount: amount,
      user_id: user.id,
      possible_win: possible_win,
      status: "Pending"
    }
    |> Match.save_bet()
    |> case do
      {:ok, _bet} ->
        socket =
          socket
          |> put_flash(:info, "Bet placed successfully")
          |> push_navigate(to: ~p"/user-bets")

        {:noreply, socket}

      {:error, reason} ->
        socket =
          socket
          |> put_flash(:error, "Failed to place bet #{reason}")

        {:noreply, socket}
    end
  end

  defp calculate_possible_win(amount, odds) do
    amount * odds
  end

  defp generate_unique_game_id do
    letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

    timestamp = System.system_time(:millisecond)

    random_number = :rand.uniform(1000) - 1

    timestamp_string = Integer.to_string(timestamp)

    random_number_string = Integer.to_string(random_number)

    timestamp_suffix = String.slice(timestamp_string, -3..-1)

    random_number_prefix = String.pad_leading(random_number_string, 3, "0")

    number_part = random_number_prefix <> timestamp_suffix

    letter_part =
      Enum.map(1..3, fn _ ->
        index = :rand.uniform(26) - 1

        letter = String.at(letters, index)

        letter
      end)
      |> Enum.join("")

    game_uuid = letter_part <> number_part

    game_uuid
  end
end
