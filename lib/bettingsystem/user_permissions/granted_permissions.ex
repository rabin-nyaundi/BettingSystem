defmodule Bettingsystem.UserPermissions.GrantedPermissions do
  use Ecto.Schema

  schema "granted_permissions" do
    belongs_to :role_id, Bettingsystem.Roles.UserRoles
    belongs_to :permission_id, Bettingsystem.Permissions.UserPermissions
  end


end
