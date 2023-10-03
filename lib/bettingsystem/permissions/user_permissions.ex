defmodule Bettingsystem.Permissions.UserPermissions do
  use Ecto.Schema

  schema "user_permissions" do
    field :name, :string
  end
end
