defmodule Bettingsystem.Repo.Migrations.CreateClubs do
  use Ecto.Migration

  def change do
    create table(:clubs) do
      add :name, :string

      timestamps()
    end
  end
end
