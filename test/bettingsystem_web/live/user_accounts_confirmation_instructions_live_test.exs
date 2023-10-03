defmodule BettingsystemWeb.UserAccountsConfirmationInstructionsLiveTest do
  use BettingsystemWeb.ConnCase

  import Phoenix.LiveViewTest
  import Bettingsystem.AccountFixtures

  alias Bettingsystem.Account
  alias Bettingsystem.Repo

  setup do
    %{user_accounts: user_accounts_fixture()}
  end

  describe "Resend confirmation" do
    test "renders the resend confirmation page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/user_acconts/confirm")
      assert html =~ "Resend confirmation instructions"
    end

    test "sends a new confirmation token", %{conn: conn, user_accounts: user_accounts} do
      {:ok, lv, _html} = live(conn, ~p"/user_acconts/confirm")

      {:ok, conn} =
        lv
        |> form("#resend_confirmation_form", user_accounts: %{email: user_accounts.email})
        |> render_submit()
        |> follow_redirect(conn, ~p"/")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "If your email is in our system"

      assert Repo.get_by!(Account.UserAccountsToken, user_accounts_id: user_accounts.id).context == "confirm"
    end

    test "does not send confirmation token if user_accounts is confirmed", %{conn: conn, user_accounts: user_accounts} do
      Repo.update!(Account.UserAccounts.confirm_changeset(user_accounts))

      {:ok, lv, _html} = live(conn, ~p"/user_acconts/confirm")

      {:ok, conn} =
        lv
        |> form("#resend_confirmation_form", user_accounts: %{email: user_accounts.email})
        |> render_submit()
        |> follow_redirect(conn, ~p"/")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "If your email is in our system"

      refute Repo.get_by(Account.UserAccountsToken, user_accounts_id: user_accounts.id)
    end

    test "does not send confirmation token if email is invalid", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/user_acconts/confirm")

      {:ok, conn} =
        lv
        |> form("#resend_confirmation_form", user_accounts: %{email: "unknown@example.com"})
        |> render_submit()
        |> follow_redirect(conn, ~p"/")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "If your email is in our system"

      assert Repo.all(Account.UserAccountsToken) == []
    end
  end
end
