defmodule Bettingsystem.Permissions.UserPermissions do
  use Ecto.Schema

  schema "user_permissions" do
    field :permission, :string
  end


end
