defmodule BettingsystemWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use BettingsystemWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # The default endpoint for testing
      @endpoint BettingsystemWeb.Endpoint

      use BettingsystemWeb, :verified_routes

      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import BettingsystemWeb.ConnCase
    end
  end

  setup tags do
    Bettingsystem.DataCase.setup_sandbox(tags)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  @doc """
  Setup helper that registers and logs in user_acconts.

      setup :register_and_log_in_user_accounts

  It stores an updated connection and a registered user_accounts in the
  test context.
  """
  def register_and_log_in_user_accounts(%{conn: conn}) do
    user_accounts = Bettingsystem.AccountFixtures.user_accounts_fixture()
    %{conn: log_in_user_accounts(conn, user_accounts), user_accounts: user_accounts}
  end

  @doc """
  Logs the given `user_accounts` into the `conn`.

  It returns an updated `conn`.
  """
  def log_in_user_accounts(conn, user_accounts) do
    token = Bettingsystem.Account.generate_user_accounts_session_token(user_accounts)

    conn
    |> Phoenix.ConnTest.init_test_session(%{})
    |> Plug.Conn.put_session(:user_accounts_token, token)
  end
end