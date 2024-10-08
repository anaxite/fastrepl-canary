defmodule Canary.Repo.Migrations.AddEventsDeferrable do
  @moduledoc """
  Updates resources based on their most recent snapshots.

  This file was autogenerated with `mix ash_postgres.generate_migrations`
  """

  use Ecto.Migration

  def up do
    drop constraint(:source_events, "source_events_source_id_fkey")

    alter table(:source_events) do
      modify :source_id,
             references(:sources,
               column: :id,
               name: "source_events_source_id_fkey",
               type: :uuid,
               prefix: "public"
             )
    end

    execute(
      "ALTER TABLE source_events alter CONSTRAINT source_events_source_id_fkey DEFERRABLE INITIALLY DEFERRED"
    )
  end

  def down do
    drop constraint(:source_events, "source_events_source_id_fkey")

    alter table(:source_events) do
      modify :source_id,
             references(:sources,
               column: :id,
               name: "source_events_source_id_fkey",
               type: :uuid,
               prefix: "public"
             )
    end

    execute(
      "ALTER TABLE source_events alter CONSTRAINT source_events_source_id_fkey NOT DEFERRABLE"
    )
  end
end
