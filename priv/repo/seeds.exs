# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Bettingsystem.Repo.insert!(%Bettingsystem.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Bettingsystem.Repo
alias Bettingsystem.Roles.UserRoles
alias Bettingsystem.BettingEngine.Club
alias Bettingsystem.Permissions.UserPermissions
alias Bettingsystem.UserPermissions.GrantedPermissions

clubs_list = [
  %Club{
    name: "Team A"
  },
  %Club{
    name: "Team B"
  },
  %Club{
    name: "Team C"
  },
  %Club{
    name: "Team E"
  }
]

roles_list = [
  %Bettingsystem.Roles.UserRoles{
    role: "superadmin"
  },
  %Bettingsystem.Roles.UserRoles{
    role: "admin"
  },
  %Bettingsystem.Roles.UserRoles{
    role: "user"
  }
]

permissions_list = [
  %UserPermissions{
    permission: "CanAddSuperAdmin"
  },
  %UserPermissions{
    permission: "CanRevokeAdmin"
  },
  %UserPermissions{
    permission: "CanAddAdmin"
  },
  %UserPermissions{
    permission: "CanRevokeAdmin"
  },
  %UserPermissions{
    permission: "CanAddGames"
  },
  %UserPermissions{
    permission: "CanRemoveGames"
  },
  %UserPermissions{
    permission: "CanViewProfitLoss"
  },
  %UserPermissions{
    permission: "CanViewUser"
  },
  %UserPermissions{
    permission: "CanDeleteUser"
  }
]

granted_permissions_list = [
  %Bettingsystem.UserPermissions.GrantedPermissions{
    role_id: 1,
    permission_id: 1
  },
  %Bettingsystem.UserPermissions.GrantedPermissions{
    role_id: 2,
    permission_id: 2
  }
]

Enum.each(clubs_list, fn club ->
  case Repo.insert(club) do
    {:ok, record} ->
      IO.puts("#{record.name} inserted successfully")

    {:error, changeset} ->
      IO.puts("Failed to insert granted permission:")
      IO.inspect(changeset.errors)
  end
end)

Enum.each(roles_list, fn role ->
  case Repo.insert(role) do
    {:ok, record} ->
      IO.puts("#{record.role} inserted successfully")

    {:error, changeset} ->
      IO.puts("Failed to insert granted permission:")
      IO.inspect(changeset.errors)
  end
end)

Enum.each(permissions_list, fn permission ->
  case Repo.insert(permission) do
    {:ok, record} ->
      IO.puts("#{record.permission} inserted successfully")

    {:error, changeset} ->
      IO.puts("Failed to insert granted permission:")
      IO.inspect(changeset.errors)
  end
end)
