defmodule Blogify.AccountsTest do
  use Blogify.DataCase

  alias Blogify.Accounts

  import Blogify.AccountsFixtures
  alias Blogify.Accounts.{Owner, OwnerToken}

  describe "get_owner_by_email/1" do
    test "does not return the owner if the email does not exist" do
      refute Accounts.get_owner_by_email("unknown@example.com")
    end

    test "returns the owner if the email exists" do
      %{id: id} = owner = owner_fixture()
      assert %Owner{id: ^id} = Accounts.get_owner_by_email(owner.email)
    end
  end

  describe "get_owner_by_email_and_password/2" do
    test "does not return the owner if the email does not exist" do
      refute Accounts.get_owner_by_email_and_password("unknown@example.com", "hello world!")
    end

    test "does not return the owner if the password is not valid" do
      owner = owner_fixture()
      refute Accounts.get_owner_by_email_and_password(owner.email, "invalid")
    end

    test "returns the owner if the email and password are valid" do
      %{id: id} = owner = owner_fixture()

      assert %Owner{id: ^id} =
               Accounts.get_owner_by_email_and_password(owner.email, valid_owner_password())
    end
  end

  describe "get_owner!/1" do
    test "raises if id is invalid" do
      assert_raise Ecto.NoResultsError, fn ->
        Accounts.get_owner!("11111111-1111-1111-1111-111111111111")
      end
    end

    test "returns the owner with the given id" do
      %{id: id} = owner = owner_fixture()
      assert %Owner{id: ^id} = Accounts.get_owner!(owner.id)
    end
  end

  describe "register_owner/1" do
    test "requires email and password to be set" do
      {:error, changeset} = Accounts.register_owner(%{})

      assert %{
               password: ["can't be blank"],
               email: ["can't be blank"]
             } = errors_on(changeset)
    end

    test "validates email and password when given" do
      {:error, changeset} = Accounts.register_owner(%{email: "not valid", password: "not valid"})

      assert %{
               email: ["must have the @ sign and no spaces"],
               password: ["should be at least 12 character(s)"]
             } = errors_on(changeset)
    end

    test "validates maximum values for email and password for security" do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Accounts.register_owner(%{email: too_long, password: too_long})
      assert "should be at most 160 character(s)" in errors_on(changeset).email
      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "validates email uniqueness" do
      %{email: email} = owner_fixture()
      {:error, changeset} = Accounts.register_owner(%{email: email})
      assert "has already been taken" in errors_on(changeset).email

      # Now try with the upper cased email too, to check that email case is ignored.
      {:error, changeset} = Accounts.register_owner(%{email: String.upcase(email)})
      assert "has already been taken" in errors_on(changeset).email
    end

    test "registers owners with a hashed password" do
      email = unique_owner_email()
      {:ok, owner} = Accounts.register_owner(valid_owner_attributes(email: email))
      assert owner.email == email
      assert is_binary(owner.hashed_password)
      assert is_nil(owner.confirmed_at)
      assert is_nil(owner.password)
    end
  end

  describe "change_owner_registration/2" do
    test "returns a changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_owner_registration(%Owner{})
      assert changeset.required == [:password, :email]
    end

    test "allows fields to be set" do
      email = unique_owner_email()
      password = valid_owner_password()

      changeset =
        Accounts.change_owner_registration(
          %Owner{},
          valid_owner_attributes(email: email, password: password)
        )

      assert changeset.valid?
      assert get_change(changeset, :email) == email
      assert get_change(changeset, :password) == password
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "change_owner_email/2" do
    test "returns a owner changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_owner_email(%Owner{})
      assert changeset.required == [:email]
    end
  end

  describe "apply_owner_email/3" do
    setup do
      %{owner: owner_fixture()}
    end

    test "requires email to change", %{owner: owner} do
      {:error, changeset} = Accounts.apply_owner_email(owner, valid_owner_password(), %{})
      assert %{email: ["did not change"]} = errors_on(changeset)
    end

    test "validates email", %{owner: owner} do
      {:error, changeset} =
        Accounts.apply_owner_email(owner, valid_owner_password(), %{email: "not valid"})

      assert %{email: ["must have the @ sign and no spaces"]} = errors_on(changeset)
    end

    test "validates maximum value for email for security", %{owner: owner} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Accounts.apply_owner_email(owner, valid_owner_password(), %{email: too_long})

      assert "should be at most 160 character(s)" in errors_on(changeset).email
    end

    test "validates email uniqueness", %{owner: owner} do
      %{email: email} = owner_fixture()
      password = valid_owner_password()

      {:error, changeset} = Accounts.apply_owner_email(owner, password, %{email: email})

      assert "has already been taken" in errors_on(changeset).email
    end

    test "validates current password", %{owner: owner} do
      {:error, changeset} =
        Accounts.apply_owner_email(owner, "invalid", %{email: unique_owner_email()})

      assert %{current_password: ["is not valid"]} = errors_on(changeset)
    end

    test "applies the email without persisting it", %{owner: owner} do
      email = unique_owner_email()
      {:ok, owner} = Accounts.apply_owner_email(owner, valid_owner_password(), %{email: email})
      assert owner.email == email
      assert Accounts.get_owner!(owner.id).email != email
    end
  end

  describe "deliver_owner_update_email_instructions/3" do
    setup do
      %{owner: owner_fixture()}
    end

    test "sends token through notification", %{owner: owner} do
      token =
        extract_owner_token(fn url ->
          Accounts.deliver_owner_update_email_instructions(owner, "current@example.com", url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert owner_token = Repo.get_by(OwnerToken, token: :crypto.hash(:sha256, token))
      assert owner_token.owner_id == owner.id
      assert owner_token.sent_to == owner.email
      assert owner_token.context == "change:current@example.com"
    end
  end

  describe "update_owner_email/2" do
    setup do
      owner = owner_fixture()
      email = unique_owner_email()

      token =
        extract_owner_token(fn url ->
          Accounts.deliver_owner_update_email_instructions(%{owner | email: email}, owner.email, url)
        end)

      %{owner: owner, token: token, email: email}
    end

    test "updates the email with a valid token", %{owner: owner, token: token, email: email} do
      assert Accounts.update_owner_email(owner, token) == :ok
      changed_owner = Repo.get!(Owner, owner.id)
      assert changed_owner.email != owner.email
      assert changed_owner.email == email
      assert changed_owner.confirmed_at
      assert changed_owner.confirmed_at != owner.confirmed_at
      refute Repo.get_by(OwnerToken, owner_id: owner.id)
    end

    test "does not update email with invalid token", %{owner: owner} do
      assert Accounts.update_owner_email(owner, "oops") == :error
      assert Repo.get!(Owner, owner.id).email == owner.email
      assert Repo.get_by(OwnerToken, owner_id: owner.id)
    end

    test "does not update email if owner email changed", %{owner: owner, token: token} do
      assert Accounts.update_owner_email(%{owner | email: "current@example.com"}, token) == :error
      assert Repo.get!(Owner, owner.id).email == owner.email
      assert Repo.get_by(OwnerToken, owner_id: owner.id)
    end

    test "does not update email if token expired", %{owner: owner, token: token} do
      {1, nil} = Repo.update_all(OwnerToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert Accounts.update_owner_email(owner, token) == :error
      assert Repo.get!(Owner, owner.id).email == owner.email
      assert Repo.get_by(OwnerToken, owner_id: owner.id)
    end
  end

  describe "change_owner_password/2" do
    test "returns a owner changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_owner_password(%Owner{})
      assert changeset.required == [:password]
    end

    test "allows fields to be set" do
      changeset =
        Accounts.change_owner_password(%Owner{}, %{
          "password" => "new valid password"
        })

      assert changeset.valid?
      assert get_change(changeset, :password) == "new valid password"
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "update_owner_password/3" do
    setup do
      %{owner: owner_fixture()}
    end

    test "validates password", %{owner: owner} do
      {:error, changeset} =
        Accounts.update_owner_password(owner, valid_owner_password(), %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: ["should be at least 12 character(s)"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{owner: owner} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Accounts.update_owner_password(owner, valid_owner_password(), %{password: too_long})

      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "validates current password", %{owner: owner} do
      {:error, changeset} =
        Accounts.update_owner_password(owner, "invalid", %{password: valid_owner_password()})

      assert %{current_password: ["is not valid"]} = errors_on(changeset)
    end

    test "updates the password", %{owner: owner} do
      {:ok, owner} =
        Accounts.update_owner_password(owner, valid_owner_password(), %{
          password: "new valid password"
        })

      assert is_nil(owner.password)
      assert Accounts.get_owner_by_email_and_password(owner.email, "new valid password")
    end

    test "deletes all tokens for the given owner", %{owner: owner} do
      _ = Accounts.generate_owner_session_token(owner)

      {:ok, _} =
        Accounts.update_owner_password(owner, valid_owner_password(), %{
          password: "new valid password"
        })

      refute Repo.get_by(OwnerToken, owner_id: owner.id)
    end
  end

  describe "generate_owner_session_token/1" do
    setup do
      %{owner: owner_fixture()}
    end

    test "generates a token", %{owner: owner} do
      token = Accounts.generate_owner_session_token(owner)
      assert owner_token = Repo.get_by(OwnerToken, token: token)
      assert owner_token.context == "session"

      # Creating the same token for another owner should fail
      assert_raise Ecto.ConstraintError, fn ->
        Repo.insert!(%OwnerToken{
          token: owner_token.token,
          owner_id: owner_fixture().id,
          context: "session"
        })
      end
    end
  end

  describe "get_owner_by_session_token/1" do
    setup do
      owner = owner_fixture()
      token = Accounts.generate_owner_session_token(owner)
      %{owner: owner, token: token}
    end

    test "returns owner by token", %{owner: owner, token: token} do
      assert session_owner = Accounts.get_owner_by_session_token(token)
      assert session_owner.id == owner.id
    end

    test "does not return owner for invalid token" do
      refute Accounts.get_owner_by_session_token("oops")
    end

    test "does not return owner for expired token", %{token: token} do
      {1, nil} = Repo.update_all(OwnerToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Accounts.get_owner_by_session_token(token)
    end
  end

  describe "delete_owner_session_token/1" do
    test "deletes the token" do
      owner = owner_fixture()
      token = Accounts.generate_owner_session_token(owner)
      assert Accounts.delete_owner_session_token(token) == :ok
      refute Accounts.get_owner_by_session_token(token)
    end
  end

  describe "deliver_owner_confirmation_instructions/2" do
    setup do
      %{owner: owner_fixture()}
    end

    test "sends token through notification", %{owner: owner} do
      token =
        extract_owner_token(fn url ->
          Accounts.deliver_owner_confirmation_instructions(owner, url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert owner_token = Repo.get_by(OwnerToken, token: :crypto.hash(:sha256, token))
      assert owner_token.owner_id == owner.id
      assert owner_token.sent_to == owner.email
      assert owner_token.context == "confirm"
    end
  end

  describe "confirm_owner/1" do
    setup do
      owner = owner_fixture()

      token =
        extract_owner_token(fn url ->
          Accounts.deliver_owner_confirmation_instructions(owner, url)
        end)

      %{owner: owner, token: token}
    end

    test "confirms the email with a valid token", %{owner: owner, token: token} do
      assert {:ok, confirmed_owner} = Accounts.confirm_owner(token)
      assert confirmed_owner.confirmed_at
      assert confirmed_owner.confirmed_at != owner.confirmed_at
      assert Repo.get!(Owner, owner.id).confirmed_at
      refute Repo.get_by(OwnerToken, owner_id: owner.id)
    end

    test "does not confirm with invalid token", %{owner: owner} do
      assert Accounts.confirm_owner("oops") == :error
      refute Repo.get!(Owner, owner.id).confirmed_at
      assert Repo.get_by(OwnerToken, owner_id: owner.id)
    end

    test "does not confirm email if token expired", %{owner: owner, token: token} do
      {1, nil} = Repo.update_all(OwnerToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert Accounts.confirm_owner(token) == :error
      refute Repo.get!(Owner, owner.id).confirmed_at
      assert Repo.get_by(OwnerToken, owner_id: owner.id)
    end
  end

  describe "deliver_owner_reset_password_instructions/2" do
    setup do
      %{owner: owner_fixture()}
    end

    test "sends token through notification", %{owner: owner} do
      token =
        extract_owner_token(fn url ->
          Accounts.deliver_owner_reset_password_instructions(owner, url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert owner_token = Repo.get_by(OwnerToken, token: :crypto.hash(:sha256, token))
      assert owner_token.owner_id == owner.id
      assert owner_token.sent_to == owner.email
      assert owner_token.context == "reset_password"
    end
  end

  describe "get_owner_by_reset_password_token/1" do
    setup do
      owner = owner_fixture()

      token =
        extract_owner_token(fn url ->
          Accounts.deliver_owner_reset_password_instructions(owner, url)
        end)

      %{owner: owner, token: token}
    end

    test "returns the owner with valid token", %{owner: %{id: id}, token: token} do
      assert %Owner{id: ^id} = Accounts.get_owner_by_reset_password_token(token)
      assert Repo.get_by(OwnerToken, owner_id: id)
    end

    test "does not return the owner with invalid token", %{owner: owner} do
      refute Accounts.get_owner_by_reset_password_token("oops")
      assert Repo.get_by(OwnerToken, owner_id: owner.id)
    end

    test "does not return the owner if token expired", %{owner: owner, token: token} do
      {1, nil} = Repo.update_all(OwnerToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Accounts.get_owner_by_reset_password_token(token)
      assert Repo.get_by(OwnerToken, owner_id: owner.id)
    end
  end

  describe "reset_owner_password/2" do
    setup do
      %{owner: owner_fixture()}
    end

    test "validates password", %{owner: owner} do
      {:error, changeset} =
        Accounts.reset_owner_password(owner, %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: ["should be at least 12 character(s)"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{owner: owner} do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Accounts.reset_owner_password(owner, %{password: too_long})
      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "updates the password", %{owner: owner} do
      {:ok, updated_owner} = Accounts.reset_owner_password(owner, %{password: "new valid password"})
      assert is_nil(updated_owner.password)
      assert Accounts.get_owner_by_email_and_password(owner.email, "new valid password")
    end

    test "deletes all tokens for the given owner", %{owner: owner} do
      _ = Accounts.generate_owner_session_token(owner)
      {:ok, _} = Accounts.reset_owner_password(owner, %{password: "new valid password"})
      refute Repo.get_by(OwnerToken, owner_id: owner.id)
    end
  end

  describe "inspect/2 for the Owner module" do
    test "does not include password" do
      refute inspect(%Owner{password: "123456"}) =~ "password: \"123456\""
    end
  end
end
