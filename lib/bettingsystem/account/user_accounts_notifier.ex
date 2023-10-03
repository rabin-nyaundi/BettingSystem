defmodule Bettingsystem.Account.UserAccountsNotifier do
  import Swoosh.Email

  alias Bettingsystem.Mailer

  # Delivers the email using the application mailer.
  defp deliver(recipient, subject, body) do
    email =
      new()
      |> to(recipient)
      |> from({"Bettingsystem", "contact@example.com"})
      |> subject(subject)
      |> text_body(body)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  @doc """
  Deliver instructions to confirm account.
  """
  def deliver_confirmation_instructions(user_accounts, url) do
    deliver(user_accounts.email, "Confirmation instructions", """

    ==============================

    Hi #{user_accounts.email},

    You can confirm your account by visiting the URL below:

    #{url}

    If you didn't create an account with us, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to reset a user_accounts password.
  """
  def deliver_reset_password_instructions(user_accounts, url) do
    deliver(user_accounts.email, "Reset password instructions", """

    ==============================

    Hi #{user_accounts.email},

    You can reset your password by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to update a user_accounts email.
  """
  def deliver_update_email_instructions(user_accounts, url) do
    deliver(user_accounts.email, "Update email instructions", """

    ==============================

    Hi #{user_accounts.email},

    You can change your email by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end
end
