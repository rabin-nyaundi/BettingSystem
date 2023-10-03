defmodule BettingsystemWeb.UserAccountsConfirmationInstructionsLive do
  use BettingsystemWeb, :live_view

  alias Bettingsystem.Account

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm">
      <.header class="text-center">
        No confirmation instructions received?
        <:subtitle>We'll send a new confirmation link to your inbox</:subtitle>
      </.header>

      <.simple_form for={@form} id="resend_confirmation_form" phx-submit="send_instructions">
        <.input field={@form[:email]} type="email" placeholder="Email" required />
        <:actions>
          <.button phx-disable-with="Sending..." class="w-full">
            Resend confirmation instructions
          </.button>
        </:actions>
      </.simple_form>

      <p class="text-center mt-4">
        <.link href={~p"/user_acconts/register"}>Register</.link>
        | <.link href={~p"/user_acconts/log_in"}>Log in</.link>
      </p>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, form: to_form(%{}, as: "user_accounts"))}
  end

  def handle_event("send_instructions", %{"user_accounts" => %{"email" => email}}, socket) do
    if user_accounts = Account.get_user_accounts_by_email(email) do
      Account.deliver_user_accounts_confirmation_instructions(
        user_accounts,
        &url(~p"/user_acconts/confirm/#{&1}")
      )
    end

    info =
      "If your email is in our system and it has not been confirmed yet, you will receive an email with instructions shortly."

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> redirect(to: ~p"/")}
  end
end
