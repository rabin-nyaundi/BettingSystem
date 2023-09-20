defmodule Bettingsystem.Roles.UserRoles do
  use Ecto.Schema
  import Ecto.Changeset

  schema "user_roles" do
    field :name, :string
    has_many :user_accounts, Bettingsystem.Account.UserAccounts, foreign_key: :role_id
  end

  @doc false
    def changeset(role, attrs) do
    role
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end

end
