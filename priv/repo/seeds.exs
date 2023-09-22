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
  %UserRoles{
    name: "superadmin"
  },
  %UserRoles{
    name: "admin"
  },
  %UserRoles{
    name: "user"
  }
]

permissions_list = [
  %UserPermissions{
    name: "CanRevokeSuperAdmin"
  },
  %UserPermissions{
    name: "CanAddSuperAdmin"
  },
  %UserPermissions{
    name: "CanRevokeAdmin"
  },
  %UserPermissions{
    name: "CanAddAdmin"
  },
  %UserPermissions{
    name: "CanAddGames"
  },
  %UserPermissions{
    name: "CanRemoveGames"
  },
  %UserPermissions{
    name: "CanViewProfitLoss"
  },
  %UserPermissions{
    name: "CanViewUser"
  },
  %UserPermissions{
    name: "CanDeleteUser"
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
      IO.puts("#{record.name} inserted successfully")

    {:error, changeset} ->
      IO.puts("Failed to insert granted permission:")
      IO.inspect(changeset.errors)
  end
end)

Enum.each(permissions_list, fn permission ->
  case Repo.insert(permission) do
    {:ok, record} ->
      IO.puts("#{record.name} inserted successfully")

    {:error, changeset} ->
      IO.puts("Failed to insert granted permission:")
      IO.inspect(changeset.errors)
  end
end)
