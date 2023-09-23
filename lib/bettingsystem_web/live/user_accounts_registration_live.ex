defmodule BettingsystemWeb.UserAccountsRegistrationLive do
  use BettingsystemWeb, :live_view

  alias Bettingsystem.Account
  alias Bettingsystem.Account.UserAccounts

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-[576px] shadow-lg p-6 gap-8 rounded-xl">
      <.header class="text-center">
        Register for an account
      </.header>

      <.simple_form
        for={@form}
        id="registration_form"
        phx-submit="save"
        phx-change="validate"
        phx-trigger-action={@trigger_submit}
        action={~p"/user_acconts/log_in?_action=registered"}
        method="post"
      >
        <.error :if={@check_errors}>
          Oops, something went wrong! Please check the errors below.
        </.error>

        <div class="flex">
          <div class="flex lg:w-1/2 w-full">
         <.input field={@form[:first_name]} type="text" label="First Name" required />
        </div>
        <div class="flex lg:w-1/2 w-full">
          <.input field={@form[:last_name]} type="text" label="Last Name" required />
        </div>
        </div>

       
        <.input field={@form[:email]} type="email" label="Email" required />
        <.input field={@form[:phone_number]} type="text" label="Phone Number" required />
        <.input field={@form[:password]} type="password" label="Password" required />

        <:actions>
          <.button phx-disable-with="Creating account..." class="w-full">Create an account</.button>
        </:actions>
      </.simple_form>
      <.header class="text-center">
        <:subtitle>
          Already registered?
          <.link navigate={~p"/user_acconts/log_in"} class="font-semibold text-brand hover:underline">
            Sign in
          </.link>
          to your account now.
        </:subtitle>
      </.header>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    changeset = Account.change_user_accounts_registration(%UserAccounts{})

    socket =
      socket
      |> assign(trigger_submit: false, check_errors: false)
      |> assign_form(changeset)

    {:ok, socket, temporary_assigns: [form: nil]}
  end

  def handle_event("save", %{"user_accounts" => user_accounts_params}, socket) do
    case Account.register_user_accounts(user_accounts_params) do
      {:ok, user_accounts} ->
        {:ok, _} =
          Account.deliver_user_accounts_confirmation_instructions(
            user_accounts,
            &url(~p"/user_acconts/confirm/#{&1}")
          )

        changeset = Account.change_user_accounts_registration(user_accounts)
        {:noreply, socket |> assign(trigger_submit: true) |> assign_form(changeset)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(check_errors: true) |> assign_form(changeset)}
    end
  end

  def handle_event("validate", %{"user_accounts" => user_accounts_params}, socket) do
    changeset = Account.change_user_accounts_registration(%UserAccounts{}, user_accounts_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user_accounts")

    if changeset.valid? do
      assign(socket, form: form, check_errors: false)
    else
      assign(socket, form: form)
    end
  end
end
