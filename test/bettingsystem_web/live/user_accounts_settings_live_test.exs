defmodule BettingsystemWeb.UserAccountsSettingsLiveTest do
  use BettingsystemWeb.ConnCase

  alias Bettingsystem.Account
  import Phoenix.LiveViewTest
  import Bettingsystem.AccountFixtures

  describe "Settings page" do
    test "renders settings page", %{conn: conn} do
      {:ok, _lv, html} =
        conn
        |> log_in_user_accounts(user_accounts_fixture())
        |> live(~p"/user_acconts/settings")

      assert html =~ "Change Email"
      assert html =~ "Change Password"
    end

    test "redirects if user_accounts is not logged in", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/user_acconts/settings")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/user_acconts/log_in"
      assert %{"error" => "You must log in to access this page."} = flash
    end
  end

  describe "update email form" do
    setup %{conn: conn} do
      password = valid_user_accounts_password()
      user_accounts = user_accounts_fixture(%{password: password})
      %{conn: log_in_user_accounts(conn, user_accounts), user_accounts: user_accounts, password: password}
    end

    test "updates the user_accounts email", %{conn: conn, password: password, user_accounts: user_accounts} do
      new_email = unique_user_accounts_email()

      {:ok, lv, _html} = live(conn, ~p"/user_acconts/settings")

      result =
        lv
        |> form("#email_form", %{
          "current_password" => password,
          "user_accounts" => %{"email" => new_email}
        })
        |> render_submit()

      assert result =~ "A link to confirm your email"
      assert Account.get_user_accounts_by_email(user_accounts.email)
    end

    test "renders errors with invalid data (phx-change)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/user_acconts/settings")

      result =
        lv
        |> element("#email_form")
        |> render_change(%{
          "action" => "update_email",
          "current_password" => "invalid",
          "user_accounts" => %{"email" => "with spaces"}
        })

      assert result =~ "Change Email"
      assert result =~ "must have the @ sign and no spaces"
    end

    test "renders errors with invalid data (phx-submit)", %{conn: conn, user_accounts: user_accounts} do
      {:ok, lv, _html} = live(conn, ~p"/user_acconts/settings")

      result =
        lv
        |> form("#email_form", %{
          "current_password" => "invalid",
          "user_accounts" => %{"email" => user_accounts.email}
        })
        |> render_submit()

      assert result =~ "Change Email"
      assert result =~ "did not change"
      assert result =~ "is not valid"
    end
  end

  describe "update password form" do
    setup %{conn: conn} do
      password = valid_user_accounts_password()
      user_accounts = user_accounts_fixture(%{password: password})
      %{conn: log_in_user_accounts(conn, user_accounts), user_accounts: user_accounts, password: password}
    end

    test "updates the user_accounts password", %{conn: conn, user_accounts: user_accounts, password: password} do
      new_password = valid_user_accounts_password()

      {:ok, lv, _html} = live(conn, ~p"/user_acconts/settings")

      form =
        form(lv, "#password_form", %{
          "current_password" => password,
          "user_accounts" => %{
            "email" => user_accounts.email,
            "password" => new_password,
            "password_confirmation" => new_password
          }
        })

      render_submit(form)

      new_password_conn = follow_trigger_action(form, conn)

      assert redirected_to(new_password_conn) == ~p"/user_acconts/settings"

      assert get_session(new_password_conn, :user_accounts_token) != get_session(conn, :user_accounts_token)

      assert Phoenix.Flash.get(new_password_conn.assigns.flash, :info) =~
               "Password updated successfully"

      assert Account.get_user_accounts_by_email_and_password(user_accounts.email, new_password)
    end

    test "renders errors with invalid data (phx-change)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/user_acconts/settings")

      result =
        lv
        |> element("#password_form")
        |> render_change(%{
          "current_password" => "invalid",
          "user_accounts" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })

      assert result =~ "Change Password"
      assert result =~ "should be at least 12 character(s)"
      assert result =~ "does not match password"
    end

    test "renders errors with invalid data (phx-submit)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/user_acconts/settings")

      result =
        lv
        |> form("#password_form", %{
          "current_password" => "invalid",
          "user_accounts" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })
        |> render_submit()

      assert result =~ "Change Password"
      assert result =~ "should be at least 12 character(s)"
      assert result =~ "does not match password"
      assert result =~ "is not valid"
    end
  end

  describe "confirm email" do
    setup %{conn: conn} do
      user_accounts = user_accounts_fixture()
      email = unique_user_accounts_email()

      token =
        extract_user_accounts_token(fn url ->
          Account.deliver_user_accounts_update_email_instructions(%{user_accounts | email: email}, user_accounts.email, url)
        end)

      %{conn: log_in_user_accounts(conn, user_accounts), token: token, email: email, user_accounts: user_accounts}
    end

    test "updates the user_accounts email once", %{conn: conn, user_accounts: user_accounts, token: token, email: email} do
      {:error, redirect} = live(conn, ~p"/user_acconts/settings/confirm_email/#{token}")

      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/user_acconts/settings"
      assert %{"info" => message} = flash
      assert message == "Email changed successfully."
      refute Account.get_user_accounts_by_email(user_accounts.email)
      assert Account.get_user_accounts_by_email(email)

      # use confirm token again
      {:error, redirect} = live(conn, ~p"/user_acconts/settings/confirm_email/#{token}")
      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/user_acconts/settings"
      assert %{"error" => message} = flash
      assert message == "Email change link is invalid or it has expired."
    end

    test "does not update email with invalid token", %{conn: conn, user_accounts: user_accounts} do
      {:error, redirect} = live(conn, ~p"/user_acconts/settings/confirm_email/oops")
      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/user_acconts/settings"
      assert %{"error" => message} = flash
      assert message == "Email change link is invalid or it has expired."
      assert Account.get_user_accounts_by_email(user_accounts.email)
    end

    test "redirects if user_accounts is not logged in", %{token: token} do
      conn = build_conn()
      {:error, redirect} = live(conn, ~p"/user_acconts/settings/confirm_email/#{token}")
      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/user_acconts/log_in"
      assert %{"error" => message} = flash
      assert message == "You must log in to access this page."
    end
  end
end
