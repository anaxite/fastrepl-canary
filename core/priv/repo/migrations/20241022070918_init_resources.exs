defmodule Canary.Repo.Migrations.InitResources do
  @moduledoc """
  Updates resources based on their most recent snapshots.

  This file was autogenerated with `mix ash_postgres.generate_migrations`
  """

  use Ecto.Migration

  def up do
    create table(:users, primary_key: false) do
      add :confirmed_at, :utc_datetime_usec
      add :id, :uuid, null: false, default: fragment("gen_random_uuid()"), primary_key: true
      add :email, :citext, null: false
      add :hashed_password, :text
      add :account_id, :uuid
    end

    create table(:user_identities, primary_key: false) do
      add :refresh_token, :text
      add :access_token_expires_at, :utc_datetime_usec
      add :access_token, :text
      add :uid, :text, null: false
      add :strategy, :text, null: false
      add :id, :uuid, null: false, default: fragment("gen_random_uuid()"), primary_key: true

      add :user_id,
          references(:users,
            column: :id,
            name: "user_identities_user_id_fkey",
            type: :uuid,
            prefix: "public"
          )
    end

    create unique_index(:user_identities, [:strategy, :uid, :user_id],
             name: "user_identities_unique_on_strategy_and_uid_and_user_id_index"
           )

    create table(:tokens, primary_key: false) do
      add :updated_at, :utc_datetime_usec,
        null: false,
        default: fragment("(now() AT TIME ZONE 'utc')")

      add :created_at, :utc_datetime_usec,
        null: false,
        default: fragment("(now() AT TIME ZONE 'utc')")

      add :extra_data, :map
      add :purpose, :text, null: false
      add :expires_at, :utc_datetime, null: false
      add :subject, :text, null: false
      add :jti, :text, null: false, primary_key: true
    end

    create table(:sources, primary_key: false) do
      add :id, :uuid, null: false, default: fragment("gen_random_uuid()"), primary_key: true

      add :created_at, :utc_datetime_usec,
        null: false,
        default: fragment("(now() AT TIME ZONE 'utc')")

      add :last_fetched_at, :utc_datetime
      add :state, :text, null: false, default: "idle"
      add :name, :text, null: false
      add :overview, :map
      add :config, :map, null: false
      add :project_id, :uuid, null: false
    end

    create table(:source_events, primary_key: false) do
      add :id, :uuid, null: false, default: fragment("gen_random_uuid()"), primary_key: true

      add :created_at, :utc_datetime_usec,
        null: false,
        default: fragment("(now() AT TIME ZONE 'utc')")

      add :meta, :map, null: false

      add :source_id,
          references(:sources,
            column: :id,
            name: "source_events_source_id_fkey",
            type: :uuid,
            prefix: "public"
          ),
          null: false
    end

    create table(:projects, primary_key: false) do
      add :id, :uuid, null: false, default: fragment("gen_random_uuid()"), primary_key: true
    end

    alter table(:sources) do
      modify :project_id,
             references(:projects,
               column: :id,
               name: "sources_project_id_fkey",
               type: :uuid,
               prefix: "public"
             )
    end

    alter table(:projects) do
      add :name, :text, null: false
      add :selected, :boolean, null: false, default: false
      add :public_key, :text, null: false
      add :index_id, :text, null: false
      add :account_id, :uuid, null: false
    end

    create table(:insights_configs, primary_key: false) do
      add :id, :uuid, null: false, default: fragment("gen_random_uuid()"), primary_key: true
      add :aliases, {:array, :map}, default: []

      add :project_id,
          references(:projects,
            column: :id,
            name: "insights_configs_project_id_fkey",
            type: :uuid,
            prefix: "public"
          ),
          null: false
    end

    create table(:github_repos, primary_key: false) do
      add :id, :uuid, null: false, default: fragment("gen_random_uuid()"), primary_key: true
      add :full_name, :text, null: false
      add :app_id, :uuid, null: false
    end

    create table(:github_apps, primary_key: false) do
      add :id, :uuid, null: false, default: fragment("gen_random_uuid()"), primary_key: true
    end

    alter table(:github_repos) do
      modify :app_id,
             references(:github_apps,
               column: :id,
               name: "github_repos_app_id_fkey",
               type: :uuid,
               prefix: "public",
               on_delete: :delete_all
             )
    end

    create unique_index(:github_repos, [:app_id, :full_name],
             name: "github_repos_unique_repo_index"
           )

    alter table(:github_apps) do
      add :installation_id, :bigint, null: false
      add :account_id, :uuid, null: false
    end

    create table(:documents, primary_key: false) do
      add :id, :uuid, null: false, default: fragment("gen_random_uuid()"), primary_key: true

      add :created_at, :utc_datetime_usec,
        null: false,
        default: fragment("(now() AT TIME ZONE 'utc')")

      add :index_id, :uuid, null: false
      add :parent_index_id, :text, null: false
      add :meta, :map, null: false
      add :chunks, {:array, :map}, null: false

      add :source_id,
          references(:sources,
            column: :id,
            name: "documents_source_id_fkey",
            type: :uuid,
            prefix: "public"
          ),
          null: false
    end

    create table(:billings, primary_key: false) do
      add :id, :uuid, null: false, default: fragment("gen_random_uuid()"), primary_key: true
      add :stripe_customer, :map
      add :stripe_subscription, :map
      add :count_ask, :bigint, null: false, default: 0
      add :count_search, :bigint, null: false, default: 0
      add :account_id, :uuid, null: false
    end

    create table(:accounts, primary_key: false) do
      add :id, :uuid, null: false, default: fragment("gen_random_uuid()"), primary_key: true
    end

    alter table(:users) do
      modify :account_id,
             references(:accounts,
               column: :id,
               name: "users_account_id_fkey",
               type: :uuid,
               prefix: "public"
             )
    end

    create unique_index(:users, [:email], name: "users_unique_email_index")

    alter table(:projects) do
      modify :account_id,
             references(:accounts,
               column: :id,
               name: "projects_account_id_fkey",
               type: :uuid,
               prefix: "public"
             )
    end

    create unique_index(:projects, [:public_key], name: "projects_unique_public_key_index")

    alter table(:github_apps) do
      modify :account_id,
             references(:accounts,
               column: :id,
               name: "github_apps_account_id_fkey",
               type: :uuid,
               prefix: "public",
               on_delete: :delete_all
             )
    end

    alter table(:billings) do
      modify :account_id,
             references(:accounts,
               column: :id,
               name: "billings_account_id_fkey",
               type: :uuid,
               prefix: "public",
               on_delete: :nothing
             )
    end

    alter table(:accounts) do
      add :super_user, :boolean, default: false
      add :name, :text, null: false
      add :selected, :boolean, null: false, default: false
    end

    create table(:account_users, primary_key: false) do
      add :user_id,
          references(:users,
            column: :id,
            name: "account_users_user_id_fkey",
            type: :uuid,
            prefix: "public"
          ),
          primary_key: true,
          null: false

      add :account_id,
          references(:accounts,
            column: :id,
            name: "account_users_account_id_fkey",
            type: :uuid,
            prefix: "public"
          ),
          primary_key: true,
          null: false
    end

    create table(:account_invites, primary_key: false) do
      add :id, :uuid, null: false, default: fragment("gen_random_uuid()"), primary_key: true

      add :created_at, :utc_datetime_usec,
        null: false,
        default: fragment("(now() AT TIME ZONE 'utc')")

      add :email, :text, null: false

      add :account_id,
          references(:accounts,
            column: :id,
            name: "account_invites_account_id_fkey",
            type: :uuid,
            prefix: "public"
          ),
          null: false
    end

    execute(
      "ALTER TABLE documents alter CONSTRAINT documents_source_id_fkey DEFERRABLE INITIALLY DEFERRED"
    )

    execute(
      "ALTER TABLE insights_configs alter CONSTRAINT insights_configs_project_id_fkey DEFERRABLE INITIALLY DEFERRED"
    )

    execute(
      "ALTER TABLE source_events alter CONSTRAINT source_events_source_id_fkey DEFERRABLE INITIALLY DEFERRED"
    )

    execute(
      "ALTER TABLE sources alter CONSTRAINT sources_project_id_fkey DEFERRABLE INITIALLY DEFERRED"
    )

    create unique_index(:sources, [:name, :project_id], name: "sources_unique_name_index")
  end

  def down do
    drop_if_exists unique_index(:sources, [:name, :project_id], name: "sources_unique_name_index")

    drop constraint(:account_invites, "account_invites_account_id_fkey")

    drop table(:account_invites)

    drop constraint(:account_users, "account_users_user_id_fkey")

    drop constraint(:account_users, "account_users_account_id_fkey")

    drop table(:account_users)

    alter table(:accounts) do
      remove :selected
      remove :name
      remove :super_user
    end

    drop constraint(:billings, "billings_account_id_fkey")

    alter table(:billings) do
      modify :account_id, :uuid
    end

    drop constraint(:github_apps, "github_apps_account_id_fkey")

    alter table(:github_apps) do
      modify :account_id, :uuid
    end

    drop_if_exists unique_index(:projects, [:public_key],
                     name: "projects_unique_public_key_index"
                   )

    drop constraint(:projects, "projects_account_id_fkey")

    alter table(:projects) do
      modify :account_id, :uuid
    end

    drop_if_exists unique_index(:users, [:email], name: "users_unique_email_index")

    drop constraint(:users, "users_account_id_fkey")

    alter table(:users) do
      modify :account_id, :uuid
    end

    drop table(:accounts)

    drop table(:billings)

    drop constraint(:documents, "documents_source_id_fkey")

    drop table(:documents)

    alter table(:github_apps) do
      remove :account_id
      remove :installation_id
    end

    drop_if_exists unique_index(:github_repos, [:app_id, :full_name],
                     name: "github_repos_unique_repo_index"
                   )

    drop constraint(:github_repos, "github_repos_app_id_fkey")

    alter table(:github_repos) do
      modify :app_id, :uuid
    end

    drop table(:github_apps)

    drop table(:github_repos)

    drop constraint(:insights_configs, "insights_configs_project_id_fkey")

    drop table(:insights_configs)

    alter table(:projects) do
      remove :account_id
      remove :index_id
      remove :public_key
      remove :selected
      remove :name
    end

    drop constraint(:sources, "sources_project_id_fkey")

    alter table(:sources) do
      modify :project_id, :uuid
    end

    drop table(:projects)

    drop constraint(:source_events, "source_events_source_id_fkey")

    drop table(:source_events)

    drop table(:sources)

    drop table(:tokens)

    drop_if_exists unique_index(:user_identities, [:strategy, :uid, :user_id],
                     name: "user_identities_unique_on_strategy_and_uid_and_user_id_index"
                   )

    drop constraint(:user_identities, "user_identities_user_id_fkey")

    drop table(:user_identities)

    drop table(:users)

    execute(
      "ALTER TABLE sources alter CONSTRAINT sources_project_id_fkey DEFERRABLE INITIALLY DEFERRED"
    )

    execute(
      "ALTER TABLE source_events alter CONSTRAINT source_events_source_id_fkey DEFERRABLE INITIALLY DEFERRED"
    )

    execute(
      "ALTER TABLE insights_configs alter CONSTRAINT insights_configs_project_id_fkey DEFERRABLE INITIALLY DEFERRED"
    )

    execute(
      "ALTER TABLE documents alter CONSTRAINT documents_source_id_fkey DEFERRABLE INITIALLY DEFERRED"
    )
  end
end
