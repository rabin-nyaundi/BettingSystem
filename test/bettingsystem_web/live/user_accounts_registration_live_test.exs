defmodule BettingsystemWeb.UserAccountsRegistrationLiveTest do
  use BettingsystemWeb.ConnCase

  import Phoenix.LiveViewTest
  import Bettingsystem.AccountFixtures

  describe "Registration page" do
    test "renders registration page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/user_acconts/register")

      assert html =~ "Register"
      assert html =~ "Log in"
    end

    test "redirects if already logged in", %{conn: conn} do
      result =
        conn
        |> log_in_user_accounts(user_accounts_fixture())
        |> live(~p"/user_acconts/register")
        |> follow_redirect(conn, "/")

      assert {:ok, _conn} = result
    end

    test "renders errors for invalid data", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/user_acconts/register")

      result =
        lv
        |> element("#registration_form")
        |> render_change(user_accounts: %{"email" => "with spaces", "password" => "too short"})

      assert result =~ "Register"
      assert result =~ "must have the @ sign and no spaces"
      assert result =~ "should be at least 12 character"
    end
  end

  describe "register user_accounts" do
    test "creates account and logs the user_accounts in", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/user_acconts/register")

      email = unique_user_accounts_email()
      form = form(lv, "#registration_form", user_accounts: valid_user_accounts_attributes(email: email))
      render_submit(form)
      conn = follow_trigger_action(form, conn)

      assert redirected_to(conn) == ~p"/"

      # Now do a logged in request and assert on the menu
      conn = get(conn, "/")
      response = html_response(conn, 200)
      assert response =~ email
      assert response =~ "Settings"
      assert response =~ "Log out"
    end

    test "renders errors for duplicated email", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/user_acconts/register")

      user_accounts = user_accounts_fixture(%{email: "test@email.com"})

      result =
        lv
        |> form("#registration_form",
          user_accounts: %{"email" => user_accounts.email, "password" => "valid_password"}
        )
        |> render_submit()

      assert result =~ "has already been taken"
    end
  end

  describe "registration navigation" do
    test "redirects to login page when the Log in button is clicked", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/user_acconts/register")

      {:ok, _login_live, login_html} =
        lv
        |> element(~s|main a:fl-contains("Sign in")|)
        |> render_click()
        |> follow_redirect(conn, ~p"/user_acconts/log_in")

      assert login_html =~ "Log in"
    end
  end
end
