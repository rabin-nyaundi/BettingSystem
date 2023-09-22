defmodule BettingsystemWeb.CreateMatchLive do
  use BettingsystemWeb, :live_view

  alias Bettingsystem.Repo

  alias Bettingsystem.Roles.UserRoles

  alias Bettingsystem.BettingEngine.Club
  alias Bettingsystem.BettingEngine.Match, as: Matches

  @impl true
  def render(%{loading: true} = assigns) do
    ~H"""
    Loading matches...
    """
  end

  def render(assigns) do
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
        <% end %>
      </div>

      <div class="flex gap-8 mx-auto lg:w-2/3 w-full">
        <div class="flex flex-col flex-1 shadow-md border rounded-md px-4">
          <%= if length(@matches) > 0 do %>
            <h3 class="font-bold text-2xl p-2">Matches</h3>
            <.table id="users" rows={@matches}>
              <:col :let={match} label="Match ID"><%= match.game_uuid %></:col>
              <:col :let={match} label="Home Team"><%= match.home_club.name %></:col>
              <:col :let={match} label="Away Team"><%= match.away_club.name %></:col>
              <:col :let={match} label="Match Winner">
                <%= if match.match_winner do %>
                <%= match.match_winner_id %>
                <% else %>
                  ___
                <% end %>
              </:col>
              <:action :let={match}>
                <.link
                  class="text-blue-500 p-2"
                  navigate={~p"/admin/matches/#{match.id}"}
                >
                  View
                </.link>
                <.link
                  class="text-red-500 p-2"
                  phx-click="cancel_bet"
                  phx-value-status="canceled"
                  data-confirm="Are you sure?"
                >
                  Delete
                </.link>
              </:action>
            </.table>
          <% else %>
            <div class="flex flex-col h-full items-center justify-center">
              <p>
                No records found
              </p>
            </div>
          <% end %>
        </div>
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

      socket =
        socket
        |> assign(form: form, loading: false)
        |> assign(:clubs, clubs)
        |> assign(:role, role.name)
        |> assign(:permissions, permissions)
        |> assign(:matches, Bettingsystem.Match.list_matches())

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

      {:error, _changeset} ->
        socket =
          socket
          |> put_flash(:error, "An error occurred while saving the match")

        {:noreply, socket}
    end
  end


  def fetch_all_clubs do
    Repo.all(Club)
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

    # Print the result
    IO.puts(game_uuid)

    game_uuid
  end
end
