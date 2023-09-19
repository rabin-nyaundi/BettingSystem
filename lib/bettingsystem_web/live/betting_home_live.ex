defmodule BettingsystemWeb.BettingHomeLive do
  use BettingsystemWeb, :live_view

  alias Bettingsystem.Repo

  alias Bettingsystem.Bets.Bet
  alias Bettingsystem.Roles.UserRoles

  alias Bettingsystem.BettingEngine.Club
  alias Bettingsystem.BettingEngine.Match, as: Matches

  @impl true
  def render(%{loading: true} = assigns) do
    ~H"""
    Loading matches...
    """
  end

  @impl true
  def render(assigns) do
    clubs = assigns.clubs || []

    ~H"""
    <div class="flex flex-col flex-1 h-full w-full p-2">
      <div class="flex justify-end w-full p-4">
        <%= if length(@permissions) > 0 do %>
          <%= if Enum.any?(@permissions, fn permission -> permission.permission.name == "CanAddGames" end) do %>
            <div>
              <.button
                phx-click={show_modal("new_match_modal")}
                phx-disable-with="Adding new game..."
                class="w-full"
              >
                Add Match <span aria-hidden="true"></span>
              </.button>
            </div>
          <% end %>

          <%= if Enum.any?(@permissions, fn permission -> permission.permission.name == "CanAddSuperAdmin" end) do %>
            <div>
              <.button
                phx-click={show_modal("new_match_modal")}
                phx-disable-with="Adding new game..."
                class="w-full bg-white rounded-full"
              >
                View History <span aria-hidden="true"></span>
              </.button>
            </div>
          <% end %>
        <% end %>
      </div>

      <div class="flex mx-auto w-2/3 border">
        <div
          id="matches"
          phx-update="stream"
          class="flex flex-col justify-center mx-auto gap-8 w-full h-full border border-gray-200 rounded-md p-4"
        >
          <div :for={{dom_id, match} <- @streams.matches} id={dom_id} class="flex flex-col bg-white">
            <div class="flex">
              <div class="w-1/3 flex flex-col justify-center">
                GameID: <%= match.game_uuid %>
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

        <%= if Map.get(assigns, :game_id, "") do %>
          <div class="flex flex-col justify-center px-8 w-1/3 border border-gray-400">
            <h3 class="p-4 uppercase text-2xl text-center">
              Betslip <hr />
            </h3>
            <div class="flex flex-col gap-7">
              <p>Game id: <%= Map.get(assigns, :game_uuid, "") %></p>
              <p>
                <%= if Map.has_key?(assigns, :selected_match) do %>
                  <span>Your Pick: <%= Map.get(assigns, :prediction, "") %></span>
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
      </div>

      <.modal id="new_match_modal">
        <div class="flex justify-center items-center m-auto w-full">
          <.simple_form for={@form} class="w-full" phx-submit="save_match">
            <div class="w-full">
              <.input
                field={@form[:home_club_id]}
                label="Home Club"
                type="select"
                options={Enum.map(@clubs, &{&1.name, &1.id})}
              />
            </div>
            <div class="w-full">
              <.input
                class="w-full"
                field={@form[:away_club_id]}
                label="Away club"
                type="select"
                options={Enum.map(@clubs, &{&1.name, &1.id})}
              />
            </div>
            <div class="w-full">
              <.input field={@form[:home_odds]} label="Home Odds" type="text" required />
            </div>
            <div class="w-full">
              <.input field={@form[:away_odds]} label="Away Odds" type="text" required />
            </div>
            <div class="w-full">
              <.input field={@form[:draw_odds]} label="Draw odds" type="text" required />
            </div>
            <div>
              <.button phx-disable-with="Saving" class="w-full">
                Save<span aria-hidden="true"></span>
              </.button>
            </div>
          </.simple_form>
        </div>
      </.modal>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      clubs = fetch_all_clubs()

      # fetch user role
      user = socket.assigns.current_user_accounts
      role = Repo.get(UserRoles, user.role_id)

      # Fetch user permissions
      permissions = Bettingsystem.UserAccessPermission.list_all_permissions(role)

      form =
        %Matches{}
        |> Matches.changeset(%{})
        |> to_form(as: "match")

      game_form =
        %Bet{}
        |> Bet.changeset(%{})
        |> to_form(as: "game")

      socket =
        socket
        |> assign(form: form, loading: false)
        |> assign(:clubs, clubs)
        |> assign(game_form: game_form, loading: false)
        |> assign(:role, role.name)
        |> assign(:permissions, permissions)
        |> stream(:matches, Bettingsystem.Match.list_matches())

      {:ok, socket}
    else
      {:ok, assign(socket, loading: true)}
    end
  end

  @impl true
  def handle_event("save_match", %{"match" => match_params}, socket) do
    unique_game_id = generate_unique_game_id() |> to_string()

    match_params = Map.put(match_params, "game_uuid", unique_game_id)

    match_params
    |> Bettingsystem.Match.save()
    |> case do
      {:ok, _match} ->
        socket =
          socket
          |> put_flash(:info, "Match created successfully")
          |> push_navigate(to: ~p"/home")

        {:noreply, socket}

      {:error, changeset} ->
        socket =
          socket
          |> put_flash(:error, "An error occurred while saving the match")

        IO.inspect(changeset)

        {:noreply, socket}
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
    match = Repo.get(Matches, game_id)

    socket =
      socket
      |> assign(:prediction, prediction)
      |> assign(:game_id, game_id)
      |> assign(:amount, "")
      |> assign(:picked_odds, picked_odds)
      |> assign(:game_uuid, game_uuid)
      |> assign(:selected_match, match)

    {:noreply, socket}
  end

  def handle_event("submit_bet", _params, socket) do
    picked_odds = socket.assigns.picked_odds
    game_id = socket.assigns.game_id
    game_uuid = socket.assigns.game_uuid
    prediction = socket.assigns.prediction
    user = socket.assigns.current_user_accounts
    amount = "100"

    picked_odds_float = String.to_float(picked_odds)

    amount_int = String.to_integer(amount)

    possible_win =
      calculate_possible_win(amount_int, picked_odds_float - 1)
      |> Float.round()
      |> Float.to_string()

    game_uuid =
      game_uuid
      |> to_string()

    bet_params = %{
      game_id: game_id,
      prediction: prediction,
      amount: amount,
      user_id: user.id,
      possible_win: possible_win,
      status: "Pending"
    }

    bet_params
    |> Bettingsystem.Match.save_bet()
    |> case do
      {:ok, _bet} ->
        socket =
          socket
          |> put_flash(:info, "Bet placed successfully")
          |> push_navigate(to: ~p"/user-bets")

        {:noreply, socket}

      {:error, changeset} ->
        socket =
          socket
          |> put_flash(:error, "Failed to place bet")

        IO.inspect(changeset)

        {:noreply, socket}
    end
  end

  def fetch_all_clubs do
    clubs = Repo.all(Club)
    clubs
  end

  defp calculate_possible_win(amount, odds) do
    amount * odds
  end

  def generate_unique_game_id do
    # Define a list of uppercase letters
    letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

    # Get the current timestamp in milliseconds
    timestamp = System.system_time(:millisecond)

    # Generate a random number between 0 and 999
    random_number = :rand.uniform(1000) - 1

    # Convert the timestamp and the random number to strings
    timestamp_string = Integer.to_string(timestamp)
    random_number_string = Integer.to_string(random_number)

    # Get the last three digits of the timestamp string
    timestamp_suffix = String.slice(timestamp_string, -3..-1)

    # Pad the random number string with zeros if needed
    random_number_prefix = String.pad_leading(random_number_string, 3, "0")

    # Concatenate the random number and the timestamp strings
    number_part = random_number_prefix <> timestamp_suffix

    # Generate three random letters from the list
    letter_part =
      Enum.map(1..3, fn _ ->
        # Generate a random index between 0 and 25
        index = :rand.uniform(26) - 1

        # Get the letter at that index
        letter = String.at(letters, index)

        letter
      end)
      |> Enum.join("")

    # Concatenate the letter part and the number part
    game_uuid = letter_part <> number_part

    # Print the result
    IO.puts(game_uuid)

    game_uuid
  end
end
