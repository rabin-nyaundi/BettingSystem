defmodule BettingsystemWeb.UsersLive do
  use BettingsystemWeb, :live_view

  alias Bettingsystem.Account
  alias Bettingsystem.Roles.UserRoles

  @impl true
  def render(%{loading: true} = assigns) do
    ~H"""
    Loading matches...
    """
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col lg:w-5/6 xl:w-2/3 mx-auto p-10 shadow-xl border rounded-lg">
      Users
      <.table id="users" rows={@users} row_click={&JS.navigate(~p"/bets/#{&1}")}>
        <:col :let={user} label="First Name"><%= user.first_name <> " " <> user.last_name %></:col>
        <%!-- <:col :let={user} label="Last Name"><%= user.id %></:col> --%>
        <:col :let={user} label="Email"><%= user.email %></:col>
        <:col :let={user} label="Status">
          <%= if user.is_deleted do %>
            <span> Inactive</span>
          <% else %>
            <span>Active</span>
          <% end %>
        </:col>
        <:col :let={user} label="Role"><%= user.user_role.name %></:col>
        <:col :let={user} label="Date Joined"><%= user.inserted_at %></:col>
        <:action :let={user}>
          <div class="sr-only"></div>
        </:action>
        <:action :let={user}>
          <.link class="text-blue-500 p-2" phx-click={show_modal("edit_user_modal")}>
            Edit
          </.link>

          
            <div class="flex flex-col justify-start items-start bg-yellow-900">
              Edit user <%= user.first_name <> " " <> user.last_name %>            
            </div>
         
          <.link class="text-blue-500 p-2" navigate={~p"/bets/#{user.id}"}>
            View
          </.link>
          <.link
            class="text-red-500 p-2"
            phx-click="cancel_bet"
            phx-value-bet_id={user.id}
            phx-value-status="canceled"
            data-confirm="Are you sure?"
          >
            Delete
          </.link>
        </:action>
      </.table>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    # Fetch users
    users = Account.get_user_accounts()

    role_form = 
      %UserRoles{}
      |> UserRoles.changeset(%{})
      |> to_form(as: "role_form")

    socket =
      socket
      |> assign(:users, users)
      |> assign(role_form: role_form)

    IO.inspect("################################")
    IO.inspect(socket)
    IO.inspect("################################")

    {:ok, socket}
  end

  # def format_date(date) do
  #   new_date = 
  #   with {:ok, today} <- Date.new(date.inserted_at) do
  #     [today.year, today.month, today.day]
  #     |> Enum.map(&to_string)
  #     |> Enum.join("/")
  #   end
  # end
end
