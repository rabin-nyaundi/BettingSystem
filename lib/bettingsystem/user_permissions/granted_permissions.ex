defmodule Bettingsystem.UserPermissions.GrantedPermissions do
  use Ecto.Schema

  schema "granted_permissions" do
    belongs_to :role, Bettingsystem.Roles.UserRoles, foreign_key: :role_id
    belongs_to :permission, Bettingsystem.Permissions.UserPermissions, foreign_key: :permission_id
  end
end
