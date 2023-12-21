defmodule Blogify.Accounts.OwnerNotifier do
  import Swoosh.Email

  alias Blogify.Mailer

  # Delivers the email using the application mailer.
  defp deliver(recipient, subject, body) do
    email =
      new()
      |> to(recipient)
      |> from({"Blogify", "contact@example.com"})
      |> subject(subject)
      |> text_body(body)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  @doc """
  Deliver instructions to confirm account.
  """
  def deliver_confirmation_instructions(owner, url) do
    deliver(owner.email, "Confirmation instructions", """

    ==============================

    Hi #{owner.email},

    You can confirm your account by visiting the URL below:

    #{url}

    If you didn't create an account with us, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to reset a owner password.
  """
  def deliver_reset_password_instructions(owner, url) do
    deliver(owner.email, "Reset password instructions", """

    ==============================

    Hi #{owner.email},

    You can reset your password by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to update a owner email.
  """
  def deliver_update_email_instructions(owner, url) do
    deliver(owner.email, "Update email instructions", """

    ==============================

    Hi #{owner.email},

    You can change your email by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end
end
