defmodule BettingsystemWeb.UserBetsLive do
  use BettingsystemWeb, :live_view

  alias Bettingsystem.Roles.UserRoles

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col lg:w-5/6 xl:w-2/3 mx-auto p-10 shadow-xl border rounded-lg">
      Bets
      <.table id="users" rows={@bets}>
        <:col :let={bet} label="Bet ID"><%= bet.id %></:col>
        <:col :let={bet} label="Bet Prediction"><%= bet.prediction %></:col>
        <:col :let={bet} label="Status"><%= bet.status %></:col>
        <:col :let={bet} label="Possible Win  (KES)"><%= bet.possible_win %></:col>
        <:action :let={bet}>
          <%= if "#{bet.status}" != "canceled" do %>
            <.link
              class="text-red-500 p-2"
              phx-click="cancel_bet"
              phx-value-bet_id={bet.id}
              phx-value-status="canceled"
              data-confirm="Are you sure?"
            >
              Cancel
            </.link>
          <% else %>
            <.link navigate={~p"/user-bets/#{bet.id}"} class="text-green-500 p-2">
              
            </.link>
          <% end %>
          <.link navigate={~p"/user-bets/#{bet.id}"} class="text-blue-500 p-2">
            View
          </.link>
        </:action>
      </.table>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user_accounts
    role = Bettingsystem.Repo.get(UserRoles, user.role_id)

    all_bets =
      case role.name do
        "superadmin" ->
          Bettingsystem.Match.fetch_all_bets_for_admins_and_superadmins(user.id)

        "admin" ->
          Bettingsystem.Match.fetch_all_bets_for_admins_and_superadmins(user.id)

        "user" ->
          Bettingsystem.Match.fetch_all_bets(user.id)
      end

    socket =
      socket
      |> assign(:role, role.name)
      |> assign(:bets, all_bets)

    {:ok, socket}
  end

  @impl true
  def handle_event("cancel_bet", %{"bet_id" => bet_id, "status" => status}, socket) do
    if connected?(socket), do: Process.send_after(self(), :update, 30)

    bet_id
    |> String.to_integer()
    |> Bettingsystem.Match.update_bet_status(status)

    socket =
      socket
      |> put_flash(:info, "Bet has been #{status}")
      |> push_navigate(to: ~p"/user-bets")

    {:noreply, socket}
  end
end
