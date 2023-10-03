defmodule Bettingsystem.UserAccessPermission do
  import Ecto.Query, warn: false

  alias Bettingsystem.Repo

  alias Bettingsystem.Roles.UserRoles
  alias Bettingsystem.UserPermissions.GrantedPermissions

  def list_all_permissions(role) do
    query =
      from p in GrantedPermissions,
        select: p,
        where: p.role_id == ^role.id,
        preload: [:role, :permission]

    Repo.all(query)
  end


  def get_user_role(user) do
    Repo.get(UserRoles, user.id)
  end

end
