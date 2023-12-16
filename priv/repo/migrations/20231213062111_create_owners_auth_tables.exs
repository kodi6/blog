defmodule Blogify.Repo.Migrations.CreateOwnersAuthTables do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    create table(:owners, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :email, :citext, null: false
      add :hashed_password, :string, null: false
      add :confirmed_at, :naive_datetime
      timestamps(type: :utc_datetime)
    end

    create unique_index(:owners, [:email])

    create table(:owners_tokens, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :owner_id, references(:owners, type: :binary_id, on_delete: :delete_all), null: false
      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string
      timestamps(updated_at: false)
    end

    create index(:owners_tokens, [:owner_id])
    create unique_index(:owners_tokens, [:context, :token])
  end
end
