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
      <.table id="users" rows={@users}>
        <:col :let={user} label="First Name"><%= user.first_name <> " " <> user.last_name %></:col>
        <:col :let={user} label="Email"><%= user.email %></:col>
        <:col :let={user} label="Status">
          <%= if user.is_deleted do %>
            <span class="bg-red-500 px-2 py-1 rounded-full text-white"> In active</span>
          <% else %>
            <span class="bg-green-600 px-2 py-1 rounded-full text-white">Active</span>
          <% end %>
        </:col>
        <:col :let={user} label="User Type"><%= user.user_role.name %></:col>
        <:col :let={user} label="Date Joined"><%= user.inserted_at %></:col>
        <:action :let={user}>
          <div class="sr-only"></div>
        </:action>
        <:action :let={user}>
          <.link class="text-blue-500 p-2" phx-click={show_modal("edit_user_modal")}>
            Edit
          </.link>
          <.link class="text-blue-500 p-2" navigate={~p"/admin/users/#{user.id}"}>
            View
          </.link>
          <.link
            class="text-red-500 p-2"
            phx-click="delete_user"
            phx-value-user_id={user.id}
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

    {:ok, socket}
  end

  def handle_event("delete_user", %{"user_id" => user_id}, socket) do
    user =
      user_id
      |> Account.get_user_accounts!()
      |> Account.soft_delete_user()

    socket =
      socket
      |> push_navigate(to: ~p"/users")

    {:noreply, socket}
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
