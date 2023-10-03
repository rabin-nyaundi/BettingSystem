defmodule BettingsystemWeb.UserAccountsForgotPasswordLiveTest do
  use BettingsystemWeb.ConnCase

  import Phoenix.LiveViewTest
  import Bettingsystem.AccountFixtures

  alias Bettingsystem.Account
  alias Bettingsystem.Repo

  describe "Forgot password page" do
    test "renders email page", %{conn: conn} do
      {:ok, lv, html} = live(conn, ~p"/user_acconts/reset_password")

      assert html =~ "Forgot your password?"
      assert has_element?(lv, ~s|a[href="#{~p"/user_acconts/register"}"]|, "Register")
      assert has_element?(lv, ~s|a[href="#{~p"/user_acconts/log_in"}"]|, "Log in")
    end

    test "redirects if already logged in", %{conn: conn} do
      result =
        conn
        |> log_in_user_accounts(user_accounts_fixture())
        |> live(~p"/user_acconts/reset_password")
        |> follow_redirect(conn, ~p"/")

      assert {:ok, _conn} = result
    end
  end

  describe "Reset link" do
    setup do
      %{user_accounts: user_accounts_fixture()}
    end

    test "sends a new reset password token", %{conn: conn, user_accounts: user_accounts} do
      {:ok, lv, _html} = live(conn, ~p"/user_acconts/reset_password")

      {:ok, conn} =
        lv
        |> form("#reset_password_form", user_accounts: %{"email" => user_accounts.email})
        |> render_submit()
        |> follow_redirect(conn, "/")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "If your email is in our system"

      assert Repo.get_by!(Account.UserAccountsToken, user_accounts_id: user_accounts.id).context ==
               "reset_password"
    end

    test "does not send reset password token if email is invalid", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/user_acconts/reset_password")

      {:ok, conn} =
        lv
        |> form("#reset_password_form", user_accounts: %{"email" => "unknown@example.com"})
        |> render_submit()
        |> follow_redirect(conn, "/")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "If your email is in our system"
      assert Repo.all(Account.UserAccountsToken) == []
    end
  end
end
