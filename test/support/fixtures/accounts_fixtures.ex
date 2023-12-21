defmodule Blogify.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Blogify.Accounts` context.
  """

  def unique_owner_email, do: "owner#{System.unique_integer()}@example.com"
  def valid_owner_password, do: "hello world!"

  def valid_owner_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_owner_email(),
      password: valid_owner_password()
    })
  end

  def owner_fixture(attrs \\ %{}) do
    {:ok, owner} =
      attrs
      |> valid_owner_attributes()
      |> Blogify.Accounts.register_owner()

    owner
  end

  def extract_owner_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end
end
