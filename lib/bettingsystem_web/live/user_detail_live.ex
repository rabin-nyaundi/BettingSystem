defmodule BettingsystemWeb.UserDetailViewLive do
  use BettingsystemWeb, :live_view

  alias Bettingsystem.Account
  alias Bettingsystem.Match

  @impl true
  def render(%{loading: true} = assigns) do
    ~H"""
    Loading matches...
    """
  end

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
              <p>
                Change permissions
              </p>
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
              <div class="sr-only"></div>
            </:action>
            <:action :let={user}>
              <.link class="text-blue-500 p-2" phx-click={show_modal("edit_user_modal")}>
                Edit
              </.link>
              <.link class="text-blue-500 p-2" navigate={~p"/bets/#{user.id}"}>
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

  def mount(params, session, socket) do
    %{"user_id" => user_id} = params

    user =
      user_id
      |> String.to_integer()
      |> Account.get_user_accounts!()

    bets =
      user_id
      |> String.to_integer()
      |> Match.fetch_all_bets_for_admins_and_superadmins()

    {:ok, assign(socket, user: user, bets: bets)}
  end
end
