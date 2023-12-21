defmodule Blogify.Repo do
  use Ecto.Repo,
    otp_app: :blogify,
    adapter: Ecto.Adapters.Postgres
end
