defmodule BettingsystemWeb.UserAccountsSessionController do
  use BettingsystemWeb, :controller

  alias Bettingsystem.Account
  alias BettingsystemWeb.UserAccountsAuth

  def create(conn, %{"_action" => "registered"} = params) do
    create(conn, params, "Account created successfully!")
  end

  def create(conn, %{"_action" => "password_updated"} = params) do
    conn
    |> put_session(:user_accounts_return_to, ~p"/user_acconts/settings")
    |> create(params, "Password updated successfully!")
  end

  def create(conn, params) do
    create(conn, params, "Welcome back!")
  end

  defp create(conn, %{"user_accounts" => user_accounts_params}, info) do
    %{"email" => email, "password" => password} = user_accounts_params

    if user_accounts = Account.get_user_accounts_by_email_and_password(email, password) do
      conn
      |> put_flash(:info, info)
      |> UserAccountsAuth.log_in_user_accounts(user_accounts, user_accounts_params)
    else
      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
      conn
      |> put_flash(:error, "Invalid email or password")
      |> put_flash(:email, String.slice(email, 0, 160))
      |> redirect(to: ~p"/user_acconts/log_in")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> UserAccountsAuth.log_out_user_accounts()
  end
end
