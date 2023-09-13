defmodule BettingsystemWeb.UserAccountsSessionControllerTest do
  use BettingsystemWeb.ConnCase, async: true

  import Bettingsystem.AccountFixtures

  setup do
    %{user_accounts: user_accounts_fixture()}
  end

  describe "POST /user_acconts/log_in" do
    test "logs the user_accounts in", %{conn: conn, user_accounts: user_accounts} do
      conn =
        post(conn, ~p"/user_acconts/log_in", %{
          "user_accounts" => %{"email" => user_accounts.email, "password" => valid_user_accounts_password()}
        })

      assert get_session(conn, :user_accounts_token)
      assert redirected_to(conn) == ~p"/"

      # Now do a logged in request and assert on the menu
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      assert response =~ user_accounts.email
      assert response =~ ~p"/user_acconts/settings"
      assert response =~ ~p"/user_acconts/log_out"
    end

    test "logs the user_accounts in with remember me", %{conn: conn, user_accounts: user_accounts} do
      conn =
        post(conn, ~p"/user_acconts/log_in", %{
          "user_accounts" => %{
            "email" => user_accounts.email,
            "password" => valid_user_accounts_password(),
            "remember_me" => "true"
          }
        })

      assert conn.resp_cookies["_bettingsystem_web_user_accounts_remember_me"]
      assert redirected_to(conn) == ~p"/"
    end

    test "logs the user_accounts in with return to", %{conn: conn, user_accounts: user_accounts} do
      conn =
        conn
        |> init_test_session(user_accounts_return_to: "/foo/bar")
        |> post(~p"/user_acconts/log_in", %{
          "user_accounts" => %{
            "email" => user_accounts.email,
            "password" => valid_user_accounts_password()
          }
        })

      assert redirected_to(conn) == "/foo/bar"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Welcome back!"
    end

    test "login following registration", %{conn: conn, user_accounts: user_accounts} do
      conn =
        conn
        |> post(~p"/user_acconts/log_in", %{
          "_action" => "registered",
          "user_accounts" => %{
            "email" => user_accounts.email,
            "password" => valid_user_accounts_password()
          }
        })

      assert redirected_to(conn) == ~p"/"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Account created successfully"
    end

    test "login following password update", %{conn: conn, user_accounts: user_accounts} do
      conn =
        conn
        |> post(~p"/user_acconts/log_in", %{
          "_action" => "password_updated",
          "user_accounts" => %{
            "email" => user_accounts.email,
            "password" => valid_user_accounts_password()
          }
        })

      assert redirected_to(conn) == ~p"/user_acconts/settings"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Password updated successfully"
    end

    test "redirects to login page with invalid credentials", %{conn: conn} do
      conn =
        post(conn, ~p"/user_acconts/log_in", %{
          "user_accounts" => %{"email" => "invalid@email.com", "password" => "invalid_password"}
        })

      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Invalid email or password"
      assert redirected_to(conn) == ~p"/user_acconts/log_in"
    end
  end

  describe "DELETE /user_acconts/log_out" do
    test "logs the user_accounts out", %{conn: conn, user_accounts: user_accounts} do
      conn = conn |> log_in_user_accounts(user_accounts) |> delete(~p"/user_acconts/log_out")
      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :user_accounts_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end

    test "succeeds even if the user_accounts is not logged in", %{conn: conn} do
      conn = delete(conn, ~p"/user_acconts/log_out")
      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :user_accounts_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end
  end
end
