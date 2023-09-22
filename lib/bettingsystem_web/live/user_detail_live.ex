defmodule BettingsystemWeb.UserDetailViewLive do
  use BettingsystemWeb, :live_view

  alias Bettingsystem.Repo
  alias Bettingsystem.Account
  alias Bettingsystem.Match
  alias Bettingsystem.Roles.UserRoles
  alias Bettingsystem.UserAccessPermission
  alias Bettingsystem.AuthPermissions

  @impl true
  def render(%{loading: true} = assigns) do
    ~H"""
    Loading matches...
    """
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex gap-6 mx-auto w-full">
      <div class="flex flex-col w-full lg:w-1/3 shadow-md border rounded-md">
        <h2 class="text-3xl font-bold text-center p-3">User Details <hr /></h2>
        <div class="flex w-full p-4">
          <div class="flex w-1/3">
            <span class="font-medium">First Name : </span>
          </div>
          <div class="flex flex-col w-flex-1">
            <span>
              <%= @user.first_name %>
            </span>
          </div>
        </div>
        <hr />
        <div class="flex w-full p-4">
          <div class="flex w-1/3">
            <span class="font-medium">Last Name : </span>
          </div>
          <div class="flex w-flex-1">
            <div class="flex flex-col w-flex-1">
              <span>
                <%= @user.last_name %>
              </span>
            </div>
          </div>
        </div>

        <hr />

        <div class="flex w-full p-4">
          <div class="flex w-1/3">
            <span class="font-medium">Email Address : </span>
          </div>
          <div class="flex w-flex-1">
            <div class="flex flex-col w-flex-1">
              <span>
                <%= @user.email %>
              </span>
            </div>
          </div>
        </div>

        <hr />
        <div class="flex w-full p-4">
          <div class="flex w-1/3">
            <span class="font-medium">Joind At : </span>
          </div>
          <div class="flex w-flex-1">
            <div class="flex flex-col w-flex-1">
              <span>
                <%= @user.inserted_at %>
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
              <%= if @user.is_deleted do %>
                <span class="bg-red-500 px-2 py-1 rounded-full text-white"> In active</span>
              <% else %>
                <span class="bg-green-600 px-2 py-1 rounded-full text-white">Active</span>
              <% end %>
            </div>
          </div>
        </div>

        <hr />
        <div class="flex w-full p-4">
          <div class="flex w-1/3">
            <span class="font-medium">User Type : </span>
          </div>
          <div class="flex flex-1 px-2">
            <div class="flex flex-col w-flex-1">
              <span>
                <%= @user.user_role.name %>
              </span>
            </div>
          </div>
          <div>
            <.button
              phx-click={show_modal("permission_modal")}
              phx-disable-with="Changing permissions..."
              class="w-full"
            >
              change permission <span aria-hidden="true"></span>
            </.button>
            <.modal id="permission_modal">
              <.simple_form for={@role_form} id="role_form" phx-submit="change_role">
                <:actions class="flex flex-col">
                  <div class="w-full">
                    <.input
                      class="flex w-full"
                      field={@role_form[:id]}
                      label="User type"
                      type="select"
                      options={Enum.map(@roles, &{&1.name, &1.id})}
                    />
                  </div>
                </:actions>
                <:actions>
                  <.button phx-disable-with="Changing..." class="w-full">
                    Change <span aria-hidden="true">→</span>
                  </.button>
                </:actions>
              </.simple_form>
            </.modal>
          </div>
        </div>
      </div>

      <div class="flex flex-col flex-1 shadow-md border rounded-md px-4">
        <%= if length(@bets) > 0 do %>
          User Bets
          <.table id="users" rows={@bets}>
            <:col :let={bet} label="Match ID"><%= bet.game.game_uuid %></:col>
            <:col :let={bet} label="Status"><%= "#{bet.status}" %></:col>
            <:col :let={bet} label="Amount"><%= bet.amount %></:col>
            <:col :let={bet} label="Possible Win"><%= bet.possible_win %></:col>
            <:action :let={bet}>
              <%= if "#{bet.status}" != "canceled" do %>
                <.link
                  class="text-blue-500 p-2"
                  phx-click="cancel_bet"
                  phx-value-bet_id={bet.id}
                  phx-value-status="canceled"
                  data-confirm="Are you sure?"
                >
                  Cancel
                </.link>
              <% else %>
                <.link navigate={~p"/admin/user-bets/#{bet.id}"} class="text-green-500 p-2"></.link>
              <% end %>
              <.link class="text-blue-500 p-2" navigate={~p"/admin/user-bets/#{bet.id}"}>
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
    """
  end

  @impl true
  def mount(%{"user_id" => user_id}, _session, socket) do
    # required_permissions = [
    #   "CanViewUser"
    # ]

    role_form =
      %UserRoles{}
      |> UserRoles.changeset(%{})
      |> to_form(as: "role_form")

    roles = Account.get_user_roles()

    user =
      user_id
      |> String.to_integer()
      |> Account.get_user_accounts!()

    bets =
      user_id
      |> String.to_integer()
      |> Match.fetch_all_bets_for_admins_and_superadmins()

    {:ok,
     assign(socket,
       user: user,
       bets: bets,
       role_form: role_form,
       roles: roles
     )}
  end
  
  @impl true
  def handle_event("change_role", %{"role_form" => role_params}, socket) do
    %{"id" => role_id} = role_params

    required_permissions = [
      "CanAddAdmin",
      "CanRevokeAdmin",
      "CanAddSuperAdmin",
      "CanRevokeSuperAdmin",
      "CanAddGames"
    ]

    perm =
      socket
      |> get_current_user_permissions()
      |> check_has_permission(required_permissions)

    if !perm do
      socket =
        socket
        |> put_flash(:error, "You dont't have permissions")
        |> push_navigate(to: ~p"/admin/users")

      {:noreply, socket}
    else
      socket.assigns.user
        |> Account.update_user_role(String.to_integer(role_id))

      socket =
        socket
        |> put_flash(:info, "Changed role for user ")
        |> push_navigate(to: ~p"/admin/users/")

      {:noreply, socket}
    end
  end

  def handle_event("cancel_bet", %{"bet_id" => bet_id, "status" => status}, socket) do
    bet_id
    |> String.to_integer()
    |> Bettingsystem.Match.update_bet_status(status)

    socket =
      socket
      |> put_flash(:info, "Bet has been #{status}")
      |> push_navigate(to: ~p"/user-bets")

    {:noreply, socket}
  end

  defp check_has_permission(granted_perms, required_perms) do
   Enum.any?(required_perms, fn rp ->
        Enum.any?(granted_perms, fn gp ->
          gp.permission.name == rp
        end)
      end)
  end

  defp get_current_user_permissions(socket) do
    UserRoles
    |> Repo.get(socket.assigns.current_user_accounts.role_id)
    |> UserAccessPermission.list_all_permissions()
  end
end
