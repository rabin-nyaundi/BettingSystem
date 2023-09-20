defmodule Bettingsystem.Account do
  @moduledoc """
  The Account context.
  """

  import Ecto.Query, warn: false
  alias Bettingsystem.Repo

  alias Bettingsystem.Account.{UserAccounts, UserAccountsToken, UserAccountsNotifier}

  ## Database getters

  @doc """
  Gets a user_accounts by email.

  ## Examples

      iex> get_user_accounts_by_email("foo@example.com")
      %UserAccounts{}

      iex> get_user_accounts_by_email("unknown@example.com")
      nil

  """
  def get_user_accounts_by_email(email) when is_binary(email) do
    Repo.get_by(UserAccounts, email: email)
  end

  @doc """
  Gets a user_accounts by email and password.

  ## Examples

      iex> get_user_accounts_by_email_and_password("foo@example.com", "correct_password")
      %UserAccounts{}

      iex> get_user_accounts_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_user_accounts_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user_accounts = Repo.get_by(UserAccounts, email: email)
    if UserAccounts.valid_password?(user_accounts, password), do: user_accounts
  end

  @doc """
  Gets a single user_accounts.

  Raises `Ecto.NoResultsError` if the UserAccounts does not exist.

  ## Examples

      iex> get_user_accounts!(123)
      %UserAccounts{}

      iex> get_user_accounts!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user_accounts!(id) do
    Repo.get!(UserAccounts, id)
    |> Repo.preload([:user_role])
  end

  ## User accounts registration

  @doc """
  Registers a user_accounts.

  ## Examples

      iex> register_user_accounts(%{field: value})
      {:ok, %UserAccounts{}}

      iex> register_user_accounts(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_user_accounts(attrs) do
    %UserAccounts{}
    |> UserAccounts.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user_accounts changes.

  ## Examples

      iex> change_user_accounts_registration(user_accounts)
      %Ecto.Changeset{data: %UserAccounts{}}

  """
  def change_user_accounts_registration(%UserAccounts{} = user_accounts, attrs \\ %{}) do
    UserAccounts.registration_changeset(user_accounts, attrs,
      hash_password: false,
      validate_email: false
    )
  end

  ## Settings

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user_accounts email.

  ## Examples

      iex> change_user_accounts_email(user_accounts)
      %Ecto.Changeset{data: %UserAccounts{}}

  """
  def change_user_accounts_email(user_accounts, attrs \\ %{}) do
    UserAccounts.email_changeset(user_accounts, attrs, validate_email: false)
  end

  @doc """
  Emulates that the email will change without actually changing
  it in the database.

  ## Examples

      iex> apply_user_accounts_email(user_accounts, "valid password", %{email: ...})
      {:ok, %UserAccounts{}}

      iex> apply_user_accounts_email(user_accounts, "invalid password", %{email: ...})
      {:error, %Ecto.Changeset{}}

  """
  def apply_user_accounts_email(user_accounts, password, attrs) do
    user_accounts
    |> UserAccounts.email_changeset(attrs)
    |> UserAccounts.validate_current_password(password)
    |> Ecto.Changeset.apply_action(:update)
  end

  @doc """
  Updates the user_accounts email using the given token.

  If the token matches, the user_accounts email is updated and the token is deleted.
  The confirmed_at date is also updated to the current time.
  """
  def update_user_accounts_email(user_accounts, token) do
    context = "change:#{user_accounts.email}"

    with {:ok, query} <- UserAccountsToken.verify_change_email_token_query(token, context),
         %UserAccountsToken{sent_to: email} <- Repo.one(query),
         {:ok, _} <- Repo.transaction(user_accounts_email_multi(user_accounts, email, context)) do
      :ok
    else
      _ -> :error
    end
  end

  defp user_accounts_email_multi(user_accounts, email, context) do
    changeset =
      user_accounts
      |> UserAccounts.email_changeset(%{email: email})
      |> UserAccounts.confirm_changeset()

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user_accounts, changeset)
    |> Ecto.Multi.delete_all(
      :tokens,
      UserAccountsToken.user_accounts_and_contexts_query(user_accounts, [context])
    )
  end

  @doc ~S"""
  Delivers the update email instructions to the given user_accounts.

  ## Examples

      iex> deliver_user_accounts_update_email_instructions(user_accounts, current_email, &url(~p"/user_acconts/settings/confirm_email/#{&1})")
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_user_accounts_update_email_instructions(
        %UserAccounts{} = user_accounts,
        current_email,
        update_email_url_fun
      )
      when is_function(update_email_url_fun, 1) do
    {encoded_token, user_accounts_token} =
      UserAccountsToken.build_email_token(user_accounts, "change:#{current_email}")

    Repo.insert!(user_accounts_token)

    UserAccountsNotifier.deliver_update_email_instructions(
      user_accounts,
      update_email_url_fun.(encoded_token)
    )
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user_accounts password.

  ## Examples

      iex> change_user_accounts_password(user_accounts)
      %Ecto.Changeset{data: %UserAccounts{}}

  """
  def change_user_accounts_password(user_accounts, attrs \\ %{}) do
    UserAccounts.password_changeset(user_accounts, attrs, hash_password: false)
  end

  @doc """
  Updates the user_accounts password.

  ## Examples

      iex> update_user_accounts_password(user_accounts, "valid password", %{password: ...})
      {:ok, %UserAccounts{}}

      iex> update_user_accounts_password(user_accounts, "invalid password", %{password: ...})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_accounts_password(user_accounts, password, attrs) do
    changeset =
      user_accounts
      |> UserAccounts.password_changeset(attrs)
      |> UserAccounts.validate_current_password(password)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user_accounts, changeset)
    |> Ecto.Multi.delete_all(
      :tokens,
      UserAccountsToken.user_accounts_and_contexts_query(user_accounts, :all)
    )
    |> Repo.transaction()
    |> case do
      {:ok, %{user_accounts: user_accounts}} -> {:ok, user_accounts}
      {:error, :user_accounts, changeset, _} -> {:error, changeset}
    end
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_user_accounts_session_token(user_accounts) do
    {token, user_accounts_token} = UserAccountsToken.build_session_token(user_accounts)
    Repo.insert!(user_accounts_token)
    token
  end

  @doc """
  Gets the user_accounts with the given signed token.
  """
  def get_user_accounts_by_session_token(token) do
    {:ok, query} = UserAccountsToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_user_accounts_session_token(token) do
    Repo.delete_all(UserAccountsToken.token_and_context_query(token, "session"))
    :ok
  end

  ## Confirmation

  @doc ~S"""
  Delivers the confirmation email instructions to the given user_accounts.

  ## Examples

      iex> deliver_user_accounts_confirmation_instructions(user_accounts, &url(~p"/user_acconts/confirm/#{&1}"))
      {:ok, %{to: ..., body: ...}}

      iex> deliver_user_accounts_confirmation_instructions(confirmed_user_accounts, &url(~p"/user_acconts/confirm/#{&1}"))
      {:error, :already_confirmed}

  """
  def deliver_user_accounts_confirmation_instructions(
        %UserAccounts{} = user_accounts,
        confirmation_url_fun
      )
      when is_function(confirmation_url_fun, 1) do
    if user_accounts.confirmed_at do
      {:error, :already_confirmed}
    else
      {encoded_token, user_accounts_token} =
        UserAccountsToken.build_email_token(user_accounts, "confirm")

      Repo.insert!(user_accounts_token)

      UserAccountsNotifier.deliver_confirmation_instructions(
        user_accounts,
        confirmation_url_fun.(encoded_token)
      )
    end
  end

  @doc """
  Confirms a user_accounts by the given token.

  If the token matches, the user_accounts account is marked as confirmed
  and the token is deleted.
  """
  def confirm_user_accounts(token) do
    with {:ok, query} <- UserAccountsToken.verify_email_token_query(token, "confirm"),
         %UserAccounts{} = user_accounts <- Repo.one(query),
         {:ok, %{user_accounts: user_accounts}} <-
           Repo.transaction(confirm_user_accounts_multi(user_accounts)) do
      {:ok, user_accounts}
    else
      _ -> :error
    end
  end

  defp confirm_user_accounts_multi(user_accounts) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user_accounts, UserAccounts.confirm_changeset(user_accounts))
    |> Ecto.Multi.delete_all(
      :tokens,
      UserAccountsToken.user_accounts_and_contexts_query(user_accounts, ["confirm"])
    )
  end

  ## Reset password

  @doc ~S"""
  Delivers the reset password email to the given user_accounts.

  ## Examples

      iex> deliver_user_accounts_reset_password_instructions(user_accounts, &url(~p"/user_acconts/reset_password/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_user_accounts_reset_password_instructions(
        %UserAccounts{} = user_accounts,
        reset_password_url_fun
      )
      when is_function(reset_password_url_fun, 1) do
    {encoded_token, user_accounts_token} =
      UserAccountsToken.build_email_token(user_accounts, "reset_password")

    Repo.insert!(user_accounts_token)

    UserAccountsNotifier.deliver_reset_password_instructions(
      user_accounts,
      reset_password_url_fun.(encoded_token)
    )
  end

  @doc """
  Gets the user_accounts by reset password token.

  ## Examples

      iex> get_user_accounts_by_reset_password_token("validtoken")
      %UserAccounts{}

      iex> get_user_accounts_by_reset_password_token("invalidtoken")
      nil

  """
  def get_user_accounts_by_reset_password_token(token) do
    with {:ok, query} <- UserAccountsToken.verify_email_token_query(token, "reset_password"),
         %UserAccounts{} = user_accounts <- Repo.one(query) do
      user_accounts
    else
      _ -> nil
    end
  end

  @doc """
  Resets the user_accounts password.

  ## Examples

      iex> reset_user_accounts_password(user_accounts, %{password: "new long password", password_confirmation: "new long password"})
      {:ok, %UserAccounts{}}

      iex> reset_user_accounts_password(user_accounts, %{password: "valid", password_confirmation: "not the same"})
      {:error, %Ecto.Changeset{}}

  """
  def reset_user_accounts_password(user_accounts, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user_accounts, UserAccounts.password_changeset(user_accounts, attrs))
    |> Ecto.Multi.delete_all(
      :tokens,
      UserAccountsToken.user_accounts_and_contexts_query(user_accounts, :all)
    )
    |> Repo.transaction()
    |> case do
      {:ok, %{user_accounts: user_accounts}} -> {:ok, user_accounts}
      {:error, :user_accounts, changeset, _} -> {:error, changeset}
    end
  end

  @doc """
  Fetchs all users from the database


  """

  def get_user_accounts do
    UserAccounts
    |> Repo.all()
    |> Repo.preload([:user_role])
  end

  @doc """
  Soft delete a user account
  """
  def soft_delete_user(user) do
   user
   |> Ecto.Changeset.change(%{is_deleted: true})
   |> Repo.update()
  end
end
