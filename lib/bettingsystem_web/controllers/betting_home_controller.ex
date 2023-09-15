
defmodule BettingsystemWeb.BettingHomeController do
  use BettingsystemWeb, :controller

  def home(conn, params) do
    conn
      |> put_flash(conn, params)
  end
end
