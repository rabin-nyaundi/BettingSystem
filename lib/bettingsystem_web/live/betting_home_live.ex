defmodule BettingsystemWeb.BettingHomeLive do
  use BettingsystemWeb, :live_view

  alias Bettingsystem.Repo

  alias Bettingsystem.Roles.UserRoles

  alias Bettingsystem.BettingEngine.Match, as: Matches
  alias Bettingsystem.BettingEngine.Club

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
    <div class="flex flex-col flex-1 h-full w-full">
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

      <div
        id="matches"
        phx-update="stream"
        class="flex flex-col justify-center mx-auto gap-8 w-full lg:w-1/2 h-full border border-gray-200 rounded-md p-4"
      >
        <div :for={{dom_id, match} <- @streams.matches} id={dom_id} class="flex flex-col bg-white">
          <div class="flex">
            <div class="w-1/3 flex flex-col">
              <p>
                <%= match.home_club.name %>
              </p>
              <p>
                <%= match.away_club.name %>
              </p>
            </div>
            <div class="flex gap-4">
              <div class="flex flex-col gap-4">
                <div class="flex text-center uppercase">Home</div>
                <div class="rounded-md p-4 border border-gray-400">167</div>
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
        |> stream(:matches, Bettingsystem.Match.list_matches())

      {:ok, socket}
    else
      {:ok, assign(socket, loading: true)}
    end
  end

  @impl true
  def handle_event("save_match", %{"match" => match_params}, socket) do
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

  defp fetch_all_clubs do
    clubs = Repo.all(Club)
    clubs
  end
end
