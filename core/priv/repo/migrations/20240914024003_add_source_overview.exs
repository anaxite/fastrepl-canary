defmodule Canary.Repo.Migrations.AddSourceOverview do
  @moduledoc """
  Updates resources based on their most recent snapshots.

  This file was autogenerated with `mix ash_postgres.generate_migrations`
  """

  use Ecto.Migration

  def up do
    alter table(:sources) do
      add :overview, :map
    end
  end

  def down do
    alter table(:sources) do
      remove :overview
    end
  end
end
