defmodule BettingsystemWeb.UserAccountsConfirmationLiveTest do
  use BettingsystemWeb.ConnCase

  import Phoenix.LiveViewTest
  import Bettingsystem.AccountFixtures

  alias Bettingsystem.Account
  alias Bettingsystem.Repo

  setup do
    %{user_accounts: user_accounts_fixture()}
  end

  describe "Confirm user_accounts" do
    test "renders confirmation page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/user_acconts/confirm/some-token")
      assert html =~ "Confirm Account"
    end

    test "confirms the given token once", %{conn: conn, user_accounts: user_accounts} do
      token =
        extract_user_accounts_token(fn url ->
          Account.deliver_user_accounts_confirmation_instructions(user_accounts, url)
        end)

      {:ok, lv, _html} = live(conn, ~p"/user_acconts/confirm/#{token}")

      result =
        lv
        |> form("#confirmation_form")
        |> render_submit()
        |> follow_redirect(conn, "/")

      assert {:ok, conn} = result

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "UserAccounts confirmed successfully"

      assert Account.get_user_accounts!(user_accounts.id).confirmed_at
      refute get_session(conn, :user_accounts_token)
      assert Repo.all(Account.UserAccountsToken) == []

      # when not logged in
      {:ok, lv, _html} = live(conn, ~p"/user_acconts/confirm/#{token}")

      result =
        lv
        |> form("#confirmation_form")
        |> render_submit()
        |> follow_redirect(conn, "/")

      assert {:ok, conn} = result

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "UserAccounts confirmation link is invalid or it has expired"

      # when logged in
      {:ok, lv, _html} =
        build_conn()
        |> log_in_user_accounts(user_accounts)
        |> live(~p"/user_acconts/confirm/#{token}")

      result =
        lv
        |> form("#confirmation_form")
        |> render_submit()
        |> follow_redirect(conn, "/")

      assert {:ok, conn} = result
      refute Phoenix.Flash.get(conn.assigns.flash, :error)
    end

    test "does not confirm email with invalid token", %{conn: conn, user_accounts: user_accounts} do
      {:ok, lv, _html} = live(conn, ~p"/user_acconts/confirm/invalid-token")

      {:ok, conn} =
        lv
        |> form("#confirmation_form")
        |> render_submit()
        |> follow_redirect(conn, ~p"/")

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "UserAccounts confirmation link is invalid or it has expired"

      refute Account.get_user_accounts!(user_accounts.id).confirmed_at
    end
  end
end
