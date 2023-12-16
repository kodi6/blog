defmodule Blogify.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias Blogify.Repo

  alias Blogify.Accounts.{Owner, OwnerToken, OwnerNotifier}

  ## Database getters

  @doc """
  Gets a owner by email.

  ## Examples

      iex> get_owner_by_email("foo@example.com")
      %Owner{}

      iex> get_owner_by_email("unknown@example.com")
      nil

  """
  def get_owner_by_email(email) when is_binary(email) do
    Repo.get_by(Owner, email: email)
  end

  @doc """
  Gets a owner by email and password.

  ## Examples

      iex> get_owner_by_email_and_password("foo@example.com", "correct_password")
      %Owner{}

      iex> get_owner_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_owner_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    owner = Repo.get_by(Owner, email: email)
    if Owner.valid_password?(owner, password), do: owner
  end

  @doc """
  Gets a single owner.

  Raises `Ecto.NoResultsError` if the Owner does not exist.

  ## Examples

      iex> get_owner!(123)
      %Owner{}

      iex> get_owner!(456)
      ** (Ecto.NoResultsError)

  """
  def get_owner!(id), do: Repo.get!(Owner, id)

  ## Owner registration

  @doc """
  Registers a owner.

  ## Examples

      iex> register_owner(%{field: value})
      {:ok, %Owner{}}

      iex> register_owner(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_owner(attrs) do
    %Owner{}
    |> Owner.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking owner changes.

  ## Examples

      iex> change_owner_registration(owner)
      %Ecto.Changeset{data: %Owner{}}

  """
  def change_owner_registration(%Owner{} = owner, attrs \\ %{}) do
    Owner.registration_changeset(owner, attrs, hash_password: false, validate_email: false)
  end

  ## Settings

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the owner email.

  ## Examples

      iex> change_owner_email(owner)
      %Ecto.Changeset{data: %Owner{}}

  """
  def change_owner_email(owner, attrs \\ %{}) do
    Owner.email_changeset(owner, attrs, validate_email: false)
  end

  @doc """
  Emulates that the email will change without actually changing
  it in the database.

  ## Examples

      iex> apply_owner_email(owner, "valid password", %{email: ...})
      {:ok, %Owner{}}

      iex> apply_owner_email(owner, "invalid password", %{email: ...})
      {:error, %Ecto.Changeset{}}

  """
  def apply_owner_email(owner, password, attrs) do
    owner
    |> Owner.email_changeset(attrs)
    |> Owner.validate_current_password(password)
    |> Ecto.Changeset.apply_action(:update)
  end

  @doc """
  Updates the owner email using the given token.

  If the token matches, the owner email is updated and the token is deleted.
  The confirmed_at date is also updated to the current time.
  """
  def update_owner_email(owner, token) do
    context = "change:#{owner.email}"

    with {:ok, query} <- OwnerToken.verify_change_email_token_query(token, context),
         %OwnerToken{sent_to: email} <- Repo.one(query),
         {:ok, _} <- Repo.transaction(owner_email_multi(owner, email, context)) do
      :ok
    else
      _ -> :error
    end
  end

  defp owner_email_multi(owner, email, context) do
    changeset =
      owner
      |> Owner.email_changeset(%{email: email})
      |> Owner.confirm_changeset()

    Ecto.Multi.new()
    |> Ecto.Multi.update(:owner, changeset)
    |> Ecto.Multi.delete_all(:tokens, OwnerToken.by_owner_and_contexts_query(owner, [context]))
  end

  @doc ~S"""
  Delivers the update email instructions to the given owner.

  ## Examples

      iex> deliver_owner_update_email_instructions(owner, current_email, &url(~p"/owners/settings/confirm_email/#{&1})")
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_owner_update_email_instructions(%Owner{} = owner, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, owner_token} = OwnerToken.build_email_token(owner, "change:#{current_email}")

    Repo.insert!(owner_token)
    OwnerNotifier.deliver_update_email_instructions(owner, update_email_url_fun.(encoded_token))
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the owner password.

  ## Examples

      iex> change_owner_password(owner)
      %Ecto.Changeset{data: %Owner{}}

  """
  def change_owner_password(owner, attrs \\ %{}) do
    Owner.password_changeset(owner, attrs, hash_password: false)
  end

  @doc """
  Updates the owner password.

  ## Examples

      iex> update_owner_password(owner, "valid password", %{password: ...})
      {:ok, %Owner{}}

      iex> update_owner_password(owner, "invalid password", %{password: ...})
      {:error, %Ecto.Changeset{}}

  """
  def update_owner_password(owner, password, attrs) do
    changeset =
      owner
      |> Owner.password_changeset(attrs)
      |> Owner.validate_current_password(password)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:owner, changeset)
    |> Ecto.Multi.delete_all(:tokens, OwnerToken.by_owner_and_contexts_query(owner, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{owner: owner}} -> {:ok, owner}
      {:error, :owner, changeset, _} -> {:error, changeset}
    end
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_owner_session_token(owner) do
    {token, owner_token} = OwnerToken.build_session_token(owner)
    Repo.insert!(owner_token)
    token
  end

  @doc """
  Gets the owner with the given signed token.
  """
  def get_owner_by_session_token(token) do
    {:ok, query} = OwnerToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_owner_session_token(token) do
    Repo.delete_all(OwnerToken.by_token_and_context_query(token, "session"))
    :ok
  end

  ## Confirmation

  @doc ~S"""
  Delivers the confirmation email instructions to the given owner.

  ## Examples

      iex> deliver_owner_confirmation_instructions(owner, &url(~p"/owners/confirm/#{&1}"))
      {:ok, %{to: ..., body: ...}}

      iex> deliver_owner_confirmation_instructions(confirmed_owner, &url(~p"/owners/confirm/#{&1}"))
      {:error, :already_confirmed}

  """
  def deliver_owner_confirmation_instructions(%Owner{} = owner, confirmation_url_fun)
      when is_function(confirmation_url_fun, 1) do
    if owner.confirmed_at do
      {:error, :already_confirmed}
    else
      {encoded_token, owner_token} = OwnerToken.build_email_token(owner, "confirm")
      Repo.insert!(owner_token)
      OwnerNotifier.deliver_confirmation_instructions(owner, confirmation_url_fun.(encoded_token))
    end
  end

  @doc """
  Confirms a owner by the given token.

  If the token matches, the owner account is marked as confirmed
  and the token is deleted.
  """
  def confirm_owner(token) do
    with {:ok, query} <- OwnerToken.verify_email_token_query(token, "confirm"),
         %Owner{} = owner <- Repo.one(query),
         {:ok, %{owner: owner}} <- Repo.transaction(confirm_owner_multi(owner)) do
      {:ok, owner}
    else
      _ -> :error
    end
  end

  defp confirm_owner_multi(owner) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:owner, Owner.confirm_changeset(owner))
    |> Ecto.Multi.delete_all(:tokens, OwnerToken.by_owner_and_contexts_query(owner, ["confirm"]))
  end

  ## Reset password

  @doc ~S"""
  Delivers the reset password email to the given owner.

  ## Examples

      iex> deliver_owner_reset_password_instructions(owner, &url(~p"/owners/reset_password/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_owner_reset_password_instructions(%Owner{} = owner, reset_password_url_fun)
      when is_function(reset_password_url_fun, 1) do
    {encoded_token, owner_token} = OwnerToken.build_email_token(owner, "reset_password")
    Repo.insert!(owner_token)
    OwnerNotifier.deliver_reset_password_instructions(owner, reset_password_url_fun.(encoded_token))
  end

  @doc """
  Gets the owner by reset password token.

  ## Examples

      iex> get_owner_by_reset_password_token("validtoken")
      %Owner{}

      iex> get_owner_by_reset_password_token("invalidtoken")
      nil

  """
  def get_owner_by_reset_password_token(token) do
    with {:ok, query} <- OwnerToken.verify_email_token_query(token, "reset_password"),
         %Owner{} = owner <- Repo.one(query) do
      owner
    else
      _ -> nil
    end
  end

  @doc """
  Resets the owner password.

  ## Examples

      iex> reset_owner_password(owner, %{password: "new long password", password_confirmation: "new long password"})
      {:ok, %Owner{}}

      iex> reset_owner_password(owner, %{password: "valid", password_confirmation: "not the same"})
      {:error, %Ecto.Changeset{}}

  """
  def reset_owner_password(owner, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:owner, Owner.password_changeset(owner, attrs))
    |> Ecto.Multi.delete_all(:tokens, OwnerToken.by_owner_and_contexts_query(owner, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{owner: owner}} -> {:ok, owner}
      {:error, :owner, changeset, _} -> {:error, changeset}
    end
  end
end
