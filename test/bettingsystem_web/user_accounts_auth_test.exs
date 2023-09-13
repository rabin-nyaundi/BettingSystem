defmodule BettingsystemWeb.UserAccountsAuthTest do
  use BettingsystemWeb.ConnCase, async: true

  alias Phoenix.LiveView
  alias Bettingsystem.Account
  alias BettingsystemWeb.UserAccountsAuth
  import Bettingsystem.AccountFixtures

  @remember_me_cookie "_bettingsystem_web_user_accounts_remember_me"

  setup %{conn: conn} do
    conn =
      conn
      |> Map.replace!(:secret_key_base, BettingsystemWeb.Endpoint.config(:secret_key_base))
      |> init_test_session(%{})

    %{user_accounts: user_accounts_fixture(), conn: conn}
  end

  describe "log_in_user_accounts/3" do
    test "stores the user_accounts token in the session", %{conn: conn, user_accounts: user_accounts} do
      conn = UserAccountsAuth.log_in_user_accounts(conn, user_accounts)
      assert token = get_session(conn, :user_accounts_token)
      assert get_session(conn, :live_socket_id) == "user_acconts_sessions:#{Base.url_encode64(token)}"
      assert redirected_to(conn) == ~p"/"
      assert Account.get_user_accounts_by_session_token(token)
    end

    test "clears everything previously stored in the session", %{conn: conn, user_accounts: user_accounts} do
      conn = conn |> put_session(:to_be_removed, "value") |> UserAccountsAuth.log_in_user_accounts(user_accounts)
      refute get_session(conn, :to_be_removed)
    end

    test "redirects to the configured path", %{conn: conn, user_accounts: user_accounts} do
      conn = conn |> put_session(:user_accounts_return_to, "/hello") |> UserAccountsAuth.log_in_user_accounts(user_accounts)
      assert redirected_to(conn) == "/hello"
    end

    test "writes a cookie if remember_me is configured", %{conn: conn, user_accounts: user_accounts} do
      conn = conn |> fetch_cookies() |> UserAccountsAuth.log_in_user_accounts(user_accounts, %{"remember_me" => "true"})
      assert get_session(conn, :user_accounts_token) == conn.cookies[@remember_me_cookie]

      assert %{value: signed_token, max_age: max_age} = conn.resp_cookies[@remember_me_cookie]
      assert signed_token != get_session(conn, :user_accounts_token)
      assert max_age == 5_184_000
    end
  end

  describe "logout_user_accounts/1" do
    test "erases session and cookies", %{conn: conn, user_accounts: user_accounts} do
      user_accounts_token = Account.generate_user_accounts_session_token(user_accounts)

      conn =
        conn
        |> put_session(:user_accounts_token, user_accounts_token)
        |> put_req_cookie(@remember_me_cookie, user_accounts_token)
        |> fetch_cookies()
        |> UserAccountsAuth.log_out_user_accounts()

      refute get_session(conn, :user_accounts_token)
      refute conn.cookies[@remember_me_cookie]
      assert %{max_age: 0} = conn.resp_cookies[@remember_me_cookie]
      assert redirected_to(conn) == ~p"/"
      refute Account.get_user_accounts_by_session_token(user_accounts_token)
    end

    test "broadcasts to the given live_socket_id", %{conn: conn} do
      live_socket_id = "user_acconts_sessions:abcdef-token"
      BettingsystemWeb.Endpoint.subscribe(live_socket_id)

      conn
      |> put_session(:live_socket_id, live_socket_id)
      |> UserAccountsAuth.log_out_user_accounts()

      assert_receive %Phoenix.Socket.Broadcast{event: "disconnect", topic: ^live_socket_id}
    end

    test "works even if user_accounts is already logged out", %{conn: conn} do
      conn = conn |> fetch_cookies() |> UserAccountsAuth.log_out_user_accounts()
      refute get_session(conn, :user_accounts_token)
      assert %{max_age: 0} = conn.resp_cookies[@remember_me_cookie]
      assert redirected_to(conn) == ~p"/"
    end
  end

  describe "fetch_current_user_accounts/2" do
    test "authenticates user_accounts from session", %{conn: conn, user_accounts: user_accounts} do
      user_accounts_token = Account.generate_user_accounts_session_token(user_accounts)
      conn = conn |> put_session(:user_accounts_token, user_accounts_token) |> UserAccountsAuth.fetch_current_user_accounts([])
      assert conn.assigns.current_user_accounts.id == user_accounts.id
    end

    test "authenticates user_accounts from cookies", %{conn: conn, user_accounts: user_accounts} do
      logged_in_conn =
        conn |> fetch_cookies() |> UserAccountsAuth.log_in_user_accounts(user_accounts, %{"remember_me" => "true"})

      user_accounts_token = logged_in_conn.cookies[@remember_me_cookie]
      %{value: signed_token} = logged_in_conn.resp_cookies[@remember_me_cookie]

      conn =
        conn
        |> put_req_cookie(@remember_me_cookie, signed_token)
        |> UserAccountsAuth.fetch_current_user_accounts([])

      assert conn.assigns.current_user_accounts.id == user_accounts.id
      assert get_session(conn, :user_accounts_token) == user_accounts_token

      assert get_session(conn, :live_socket_id) ==
               "user_acconts_sessions:#{Base.url_encode64(user_accounts_token)}"
    end

    test "does not authenticate if data is missing", %{conn: conn, user_accounts: user_accounts} do
      _ = Account.generate_user_accounts_session_token(user_accounts)
      conn = UserAccountsAuth.fetch_current_user_accounts(conn, [])
      refute get_session(conn, :user_accounts_token)
      refute conn.assigns.current_user_accounts
    end
  end

  describe "on_mount: mount_current_user_accounts" do
    test "assigns current_user_accounts based on a valid user_accounts_token", %{conn: conn, user_accounts: user_accounts} do
      user_accounts_token = Account.generate_user_accounts_session_token(user_accounts)
      session = conn |> put_session(:user_accounts_token, user_accounts_token) |> get_session()

      {:cont, updated_socket} =
        UserAccountsAuth.on_mount(:mount_current_user_accounts, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_user_accounts.id == user_accounts.id
    end

    test "assigns nil to current_user_accounts assign if there isn't a valid user_accounts_token", %{conn: conn} do
      user_accounts_token = "invalid_token"
      session = conn |> put_session(:user_accounts_token, user_accounts_token) |> get_session()

      {:cont, updated_socket} =
        UserAccountsAuth.on_mount(:mount_current_user_accounts, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_user_accounts == nil
    end

    test "assigns nil to current_user_accounts assign if there isn't a user_accounts_token", %{conn: conn} do
      session = conn |> get_session()

      {:cont, updated_socket} =
        UserAccountsAuth.on_mount(:mount_current_user_accounts, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_user_accounts == nil
    end
  end

  describe "on_mount: ensure_authenticated" do
    test "authenticates current_user_accounts based on a valid user_accounts_token", %{conn: conn, user_accounts: user_accounts} do
      user_accounts_token = Account.generate_user_accounts_session_token(user_accounts)
      session = conn |> put_session(:user_accounts_token, user_accounts_token) |> get_session()

      {:cont, updated_socket} =
        UserAccountsAuth.on_mount(:ensure_authenticated, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_user_accounts.id == user_accounts.id
    end

    test "redirects to login page if there isn't a valid user_accounts_token", %{conn: conn} do
      user_accounts_token = "invalid_token"
      session = conn |> put_session(:user_accounts_token, user_accounts_token) |> get_session()

      socket = %LiveView.Socket{
        endpoint: BettingsystemWeb.Endpoint,
        assigns: %{__changed__: %{}, flash: %{}}
      }

      {:halt, updated_socket} = UserAccountsAuth.on_mount(:ensure_authenticated, %{}, session, socket)
      assert updated_socket.assigns.current_user_accounts == nil
    end

    test "redirects to login page if there isn't a user_accounts_token", %{conn: conn} do
      session = conn |> get_session()

      socket = %LiveView.Socket{
        endpoint: BettingsystemWeb.Endpoint,
        assigns: %{__changed__: %{}, flash: %{}}
      }

      {:halt, updated_socket} = UserAccountsAuth.on_mount(:ensure_authenticated, %{}, session, socket)
      assert updated_socket.assigns.current_user_accounts == nil
    end
  end

  describe "on_mount: :redirect_if_user_accounts_is_authenticated" do
    test "redirects if there is an authenticated  user_accounts ", %{conn: conn, user_accounts: user_accounts} do
      user_accounts_token = Account.generate_user_accounts_session_token(user_accounts)
      session = conn |> put_session(:user_accounts_token, user_accounts_token) |> get_session()

      assert {:halt, _updated_socket} =
               UserAccountsAuth.on_mount(
                 :redirect_if_user_accounts_is_authenticated,
                 %{},
                 session,
                 %LiveView.Socket{}
               )
    end

    test "doesn't redirect if there is no authenticated user_accounts", %{conn: conn} do
      session = conn |> get_session()

      assert {:cont, _updated_socket} =
               UserAccountsAuth.on_mount(
                 :redirect_if_user_accounts_is_authenticated,
                 %{},
                 session,
                 %LiveView.Socket{}
               )
    end
  end

  describe "redirect_if_user_accounts_is_authenticated/2" do
    test "redirects if user_accounts is authenticated", %{conn: conn, user_accounts: user_accounts} do
      conn = conn |> assign(:current_user_accounts, user_accounts) |> UserAccountsAuth.redirect_if_user_accounts_is_authenticated([])
      assert conn.halted
      assert redirected_to(conn) == ~p"/"
    end

    test "does not redirect if user_accounts is not authenticated", %{conn: conn} do
      conn = UserAccountsAuth.redirect_if_user_accounts_is_authenticated(conn, [])
      refute conn.halted
      refute conn.status
    end
  end

  describe "require_authenticated_user_accounts/2" do
    test "redirects if user_accounts is not authenticated", %{conn: conn} do
      conn = conn |> fetch_flash() |> UserAccountsAuth.require_authenticated_user_accounts([])
      assert conn.halted

      assert redirected_to(conn) == ~p"/user_acconts/log_in"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) ==
               "You must log in to access this page."
    end

    test "stores the path to redirect to on GET", %{conn: conn} do
      halted_conn =
        %{conn | path_info: ["foo"], query_string: ""}
        |> fetch_flash()
        |> UserAccountsAuth.require_authenticated_user_accounts([])

      assert halted_conn.halted
      assert get_session(halted_conn, :user_accounts_return_to) == "/foo"

      halted_conn =
        %{conn | path_info: ["foo"], query_string: "bar=baz"}
        |> fetch_flash()
        |> UserAccountsAuth.require_authenticated_user_accounts([])

      assert halted_conn.halted
      assert get_session(halted_conn, :user_accounts_return_to) == "/foo?bar=baz"

      halted_conn =
        %{conn | path_info: ["foo"], query_string: "bar", method: "POST"}
        |> fetch_flash()
        |> UserAccountsAuth.require_authenticated_user_accounts([])

      assert halted_conn.halted
      refute get_session(halted_conn, :user_accounts_return_to)
    end

    test "does not redirect if user_accounts is authenticated", %{conn: conn, user_accounts: user_accounts} do
      conn = conn |> assign(:current_user_accounts, user_accounts) |> UserAccountsAuth.require_authenticated_user_accounts([])
      refute conn.halted
      refute conn.status
    end
  end
end
