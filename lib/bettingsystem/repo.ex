defmodule Bettingsystem.Repo do
  use Ecto.Repo,
    otp_app: :bettingsystem,
    adapter: Ecto.Adapters.Postgres
end
