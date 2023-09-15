defmodule Bettingsystem.Roles.UserRoles do
  use Ecto.Schema

  schema "user_roles" do
    field :name, :string
    has_many :user_accounts, Bettingsystem.Account.UserAccounts, foreign_key: :role_id
  end

end
