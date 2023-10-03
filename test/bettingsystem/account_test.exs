defmodule Bettingsystem.AccountTest do
  use Bettingsystem.DataCase

  alias Bettingsystem.Account

  import Bettingsystem.AccountFixtures
  alias Bettingsystem.Account.{UserAccounts, UserAccountsToken}

  describe "get_user_accounts_by_email/1" do
    test "does not return the user_accounts if the email does not exist" do
      refute Account.get_user_accounts_by_email("unknown@example.com")
    end

    test "returns the user_accounts if the email exists" do
      %{id: id} = user_accounts = user_accounts_fixture()
      assert %UserAccounts{id: ^id} = Account.get_user_accounts_by_email(user_accounts.email)
    end
  end

  describe "get_user_accounts_by_email_and_password/2" do
    test "does not return the user_accounts if the email does not exist" do
      refute Account.get_user_accounts_by_email_and_password("unknown@example.com", "hello world!")
    end

    test "does not return the user_accounts if the password is not valid" do
      user_accounts = user_accounts_fixture()
      refute Account.get_user_accounts_by_email_and_password(user_accounts.email, "invalid")
    end

    test "returns the user_accounts if the email and password are valid" do
      %{id: id} = user_accounts = user_accounts_fixture()

      assert %UserAccounts{id: ^id} =
               Account.get_user_accounts_by_email_and_password(user_accounts.email, valid_user_accounts_password())
    end
  end

  describe "get_user_accounts!/1" do
    test "raises if id is invalid" do
      assert_raise Ecto.NoResultsError, fn ->
        Account.get_user_accounts!(-1)
      end
    end

    test "returns the user_accounts with the given id" do
      %{id: id} = user_accounts = user_accounts_fixture()
      assert %UserAccounts{id: ^id} = Account.get_user_accounts!(user_accounts.id)
    end
  end

  describe "register_user_accounts/1" do
    test "requires email and password to be set" do
      {:error, changeset} = Account.register_user_accounts(%{})

      assert %{
               password: ["can't be blank"],
               email: ["can't be blank"]
             } = errors_on(changeset)
    end

    test "validates email and password when given" do
      {:error, changeset} = Account.register_user_accounts(%{email: "not valid", password: "not valid"})

      assert %{
               email: ["must have the @ sign and no spaces"],
               password: ["should be at least 12 character(s)"]
             } = errors_on(changeset)
    end

    test "validates maximum values for email and password for security" do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Account.register_user_accounts(%{email: too_long, password: too_long})
      assert "should be at most 160 character(s)" in errors_on(changeset).email
      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "validates email uniqueness" do
      %{email: email} = user_accounts_fixture()
      {:error, changeset} = Account.register_user_accounts(%{email: email})
      assert "has already been taken" in errors_on(changeset).email

      # Now try with the upper cased email too, to check that email case is ignored.
      {:error, changeset} = Account.register_user_accounts(%{email: String.upcase(email)})
      assert "has already been taken" in errors_on(changeset).email
    end

    test "registers user_acconts with a hashed password" do
      email = unique_user_accounts_email()
      {:ok, user_accounts} = Account.register_user_accounts(valid_user_accounts_attributes(email: email))
      assert user_accounts.email == email
      assert is_binary(user_accounts.hashed_password)
      assert is_nil(user_accounts.confirmed_at)
      assert is_nil(user_accounts.password)
    end
  end

  describe "change_user_accounts_registration/2" do
    test "returns a changeset" do
      assert %Ecto.Changeset{} = changeset = Account.change_user_accounts_registration(%UserAccounts{})
      assert changeset.required == [:password, :email]
    end

    test "allows fields to be set" do
      email = unique_user_accounts_email()
      password = valid_user_accounts_password()

      changeset =
        Account.change_user_accounts_registration(
          %UserAccounts{},
          valid_user_accounts_attributes(email: email, password: password)
        )

      assert changeset.valid?
      assert get_change(changeset, :email) == email
      assert get_change(changeset, :password) == password
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "change_user_accounts_email/2" do
    test "returns a user_accounts changeset" do
      assert %Ecto.Changeset{} = changeset = Account.change_user_accounts_email(%UserAccounts{})
      assert changeset.required == [:email]
    end
  end

  describe "apply_user_accounts_email/3" do
    setup do
      %{user_accounts: user_accounts_fixture()}
    end

    test "requires email to change", %{user_accounts: user_accounts} do
      {:error, changeset} = Account.apply_user_accounts_email(user_accounts, valid_user_accounts_password(), %{})
      assert %{email: ["did not change"]} = errors_on(changeset)
    end

    test "validates email", %{user_accounts: user_accounts} do
      {:error, changeset} =
        Account.apply_user_accounts_email(user_accounts, valid_user_accounts_password(), %{email: "not valid"})

      assert %{email: ["must have the @ sign and no spaces"]} = errors_on(changeset)
    end

    test "validates maximum value for email for security", %{user_accounts: user_accounts} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Account.apply_user_accounts_email(user_accounts, valid_user_accounts_password(), %{email: too_long})

      assert "should be at most 160 character(s)" in errors_on(changeset).email
    end

    test "validates email uniqueness", %{user_accounts: user_accounts} do
      %{email: email} = user_accounts_fixture()
      password = valid_user_accounts_password()

      {:error, changeset} = Account.apply_user_accounts_email(user_accounts, password, %{email: email})

      assert "has already been taken" in errors_on(changeset).email
    end

    test "validates current password", %{user_accounts: user_accounts} do
      {:error, changeset} =
        Account.apply_user_accounts_email(user_accounts, "invalid", %{email: unique_user_accounts_email()})

      assert %{current_password: ["is not valid"]} = errors_on(changeset)
    end

    test "applies the email without persisting it", %{user_accounts: user_accounts} do
      email = unique_user_accounts_email()
      {:ok, user_accounts} = Account.apply_user_accounts_email(user_accounts, valid_user_accounts_password(), %{email: email})
      assert user_accounts.email == email
      assert Account.get_user_accounts!(user_accounts.id).email != email
    end
  end

  describe "deliver_user_accounts_update_email_instructions/3" do
    setup do
      %{user_accounts: user_accounts_fixture()}
    end

    test "sends token through notification", %{user_accounts: user_accounts} do
      token =
        extract_user_accounts_token(fn url ->
          Account.deliver_user_accounts_update_email_instructions(user_accounts, "current@example.com", url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert user_accounts_token = Repo.get_by(UserAccountsToken, token: :crypto.hash(:sha256, token))
      assert user_accounts_token.user_accounts_id == user_accounts.id
      assert user_accounts_token.sent_to == user_accounts.email
      assert user_accounts_token.context == "change:current@example.com"
    end
  end

  describe "update_user_accounts_email/2" do
    setup do
      user_accounts = user_accounts_fixture()
      email = unique_user_accounts_email()

      token =
        extract_user_accounts_token(fn url ->
          Account.deliver_user_accounts_update_email_instructions(%{user_accounts | email: email}, user_accounts.email, url)
        end)

      %{user_accounts: user_accounts, token: token, email: email}
    end

    test "updates the email with a valid token", %{user_accounts: user_accounts, token: token, email: email} do
      assert Account.update_user_accounts_email(user_accounts, token) == :ok
      changed_user_accounts = Repo.get!(UserAccounts, user_accounts.id)
      assert changed_user_accounts.email != user_accounts.email
      assert changed_user_accounts.email == email
      assert changed_user_accounts.confirmed_at
      assert changed_user_accounts.confirmed_at != user_accounts.confirmed_at
      refute Repo.get_by(UserAccountsToken, user_accounts_id: user_accounts.id)
    end

    test "does not update email with invalid token", %{user_accounts: user_accounts} do
      assert Account.update_user_accounts_email(user_accounts, "oops") == :error
      assert Repo.get!(UserAccounts, user_accounts.id).email == user_accounts.email
      assert Repo.get_by(UserAccountsToken, user_accounts_id: user_accounts.id)
    end

    test "does not update email if user_accounts email changed", %{user_accounts: user_accounts, token: token} do
      assert Account.update_user_accounts_email(%{user_accounts | email: "current@example.com"}, token) == :error
      assert Repo.get!(UserAccounts, user_accounts.id).email == user_accounts.email
      assert Repo.get_by(UserAccountsToken, user_accounts_id: user_accounts.id)
    end

    test "does not update email if token expired", %{user_accounts: user_accounts, token: token} do
      {1, nil} = Repo.update_all(UserAccountsToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert Account.update_user_accounts_email(user_accounts, token) == :error
      assert Repo.get!(UserAccounts, user_accounts.id).email == user_accounts.email
      assert Repo.get_by(UserAccountsToken, user_accounts_id: user_accounts.id)
    end
  end

  describe "change_user_accounts_password/2" do
    test "returns a user_accounts changeset" do
      assert %Ecto.Changeset{} = changeset = Account.change_user_accounts_password(%UserAccounts{})
      assert changeset.required == [:password]
    end

    test "allows fields to be set" do
      changeset =
        Account.change_user_accounts_password(%UserAccounts{}, %{
          "password" => "new valid password"
        })

      assert changeset.valid?
      assert get_change(changeset, :password) == "new valid password"
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "update_user_accounts_password/3" do
    setup do
      %{user_accounts: user_accounts_fixture()}
    end

    test "validates password", %{user_accounts: user_accounts} do
      {:error, changeset} =
        Account.update_user_accounts_password(user_accounts, valid_user_accounts_password(), %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: ["should be at least 12 character(s)"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{user_accounts: user_accounts} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Account.update_user_accounts_password(user_accounts, valid_user_accounts_password(), %{password: too_long})

      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "validates current password", %{user_accounts: user_accounts} do
      {:error, changeset} =
        Account.update_user_accounts_password(user_accounts, "invalid", %{password: valid_user_accounts_password()})

      assert %{current_password: ["is not valid"]} = errors_on(changeset)
    end

    test "updates the password", %{user_accounts: user_accounts} do
      {:ok, user_accounts} =
        Account.update_user_accounts_password(user_accounts, valid_user_accounts_password(), %{
          password: "new valid password"
        })

      assert is_nil(user_accounts.password)
      assert Account.get_user_accounts_by_email_and_password(user_accounts.email, "new valid password")
    end

    test "deletes all tokens for the given user_accounts", %{user_accounts: user_accounts} do
      _ = Account.generate_user_accounts_session_token(user_accounts)

      {:ok, _} =
        Account.update_user_accounts_password(user_accounts, valid_user_accounts_password(), %{
          password: "new valid password"
        })

      refute Repo.get_by(UserAccountsToken, user_accounts_id: user_accounts.id)
    end
  end

  describe "generate_user_accounts_session_token/1" do
    setup do
      %{user_accounts: user_accounts_fixture()}
    end

    test "generates a token", %{user_accounts: user_accounts} do
      token = Account.generate_user_accounts_session_token(user_accounts)
      assert user_accounts_token = Repo.get_by(UserAccountsToken, token: token)
      assert user_accounts_token.context == "session"

      # Creating the same token for another user_accounts should fail
      assert_raise Ecto.ConstraintError, fn ->
        Repo.insert!(%UserAccountsToken{
          token: user_accounts_token.token,
          user_accounts_id: user_accounts_fixture().id,
          context: "session"
        })
      end
    end
  end

  describe "get_user_accounts_by_session_token/1" do
    setup do
      user_accounts = user_accounts_fixture()
      token = Account.generate_user_accounts_session_token(user_accounts)
      %{user_accounts: user_accounts, token: token}
    end

    test "returns user_accounts by token", %{user_accounts: user_accounts, token: token} do
      assert session_user_accounts = Account.get_user_accounts_by_session_token(token)
      assert session_user_accounts.id == user_accounts.id
    end

    test "does not return user_accounts for invalid token" do
      refute Account.get_user_accounts_by_session_token("oops")
    end

    test "does not return user_accounts for expired token", %{token: token} do
      {1, nil} = Repo.update_all(UserAccountsToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Account.get_user_accounts_by_session_token(token)
    end
  end

  describe "delete_user_accounts_session_token/1" do
    test "deletes the token" do
      user_accounts = user_accounts_fixture()
      token = Account.generate_user_accounts_session_token(user_accounts)
      assert Account.delete_user_accounts_session_token(token) == :ok
      refute Account.get_user_accounts_by_session_token(token)
    end
  end

  describe "deliver_user_accounts_confirmation_instructions/2" do
    setup do
      %{user_accounts: user_accounts_fixture()}
    end

    test "sends token through notification", %{user_accounts: user_accounts} do
      token =
        extract_user_accounts_token(fn url ->
          Account.deliver_user_accounts_confirmation_instructions(user_accounts, url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert user_accounts_token = Repo.get_by(UserAccountsToken, token: :crypto.hash(:sha256, token))
      assert user_accounts_token.user_accounts_id == user_accounts.id
      assert user_accounts_token.sent_to == user_accounts.email
      assert user_accounts_token.context == "confirm"
    end
  end

  describe "confirm_user_accounts/1" do
    setup do
      user_accounts = user_accounts_fixture()

      token =
        extract_user_accounts_token(fn url ->
          Account.deliver_user_accounts_confirmation_instructions(user_accounts, url)
        end)

      %{user_accounts: user_accounts, token: token}
    end

    test "confirms the email with a valid token", %{user_accounts: user_accounts, token: token} do
      assert {:ok, confirmed_user_accounts} = Account.confirm_user_accounts(token)
      assert confirmed_user_accounts.confirmed_at
      assert confirmed_user_accounts.confirmed_at != user_accounts.confirmed_at
      assert Repo.get!(UserAccounts, user_accounts.id).confirmed_at
      refute Repo.get_by(UserAccountsToken, user_accounts_id: user_accounts.id)
    end

    test "does not confirm with invalid token", %{user_accounts: user_accounts} do
      assert Account.confirm_user_accounts("oops") == :error
      refute Repo.get!(UserAccounts, user_accounts.id).confirmed_at
      assert Repo.get_by(UserAccountsToken, user_accounts_id: user_accounts.id)
    end

    test "does not confirm email if token expired", %{user_accounts: user_accounts, token: token} do
      {1, nil} = Repo.update_all(UserAccountsToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert Account.confirm_user_accounts(token) == :error
      refute Repo.get!(UserAccounts, user_accounts.id).confirmed_at
      assert Repo.get_by(UserAccountsToken, user_accounts_id: user_accounts.id)
    end
  end

  describe "deliver_user_accounts_reset_password_instructions/2" do
    setup do
      %{user_accounts: user_accounts_fixture()}
    end

    test "sends token through notification", %{user_accounts: user_accounts} do
      token =
        extract_user_accounts_token(fn url ->
          Account.deliver_user_accounts_reset_password_instructions(user_accounts, url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert user_accounts_token = Repo.get_by(UserAccountsToken, token: :crypto.hash(:sha256, token))
      assert user_accounts_token.user_accounts_id == user_accounts.id
      assert user_accounts_token.sent_to == user_accounts.email
      assert user_accounts_token.context == "reset_password"
    end
  end

  describe "get_user_accounts_by_reset_password_token/1" do
    setup do
      user_accounts = user_accounts_fixture()

      token =
        extract_user_accounts_token(fn url ->
          Account.deliver_user_accounts_reset_password_instructions(user_accounts, url)
        end)

      %{user_accounts: user_accounts, token: token}
    end

    test "returns the user_accounts with valid token", %{user_accounts: %{id: id}, token: token} do
      assert %UserAccounts{id: ^id} = Account.get_user_accounts_by_reset_password_token(token)
      assert Repo.get_by(UserAccountsToken, user_accounts_id: id)
    end

    test "does not return the user_accounts with invalid token", %{user_accounts: user_accounts} do
      refute Account.get_user_accounts_by_reset_password_token("oops")
      assert Repo.get_by(UserAccountsToken, user_accounts_id: user_accounts.id)
    end

    test "does not return the user_accounts if token expired", %{user_accounts: user_accounts, token: token} do
      {1, nil} = Repo.update_all(UserAccountsToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Account.get_user_accounts_by_reset_password_token(token)
      assert Repo.get_by(UserAccountsToken, user_accounts_id: user_accounts.id)
    end
  end

  describe "reset_user_accounts_password/2" do
    setup do
      %{user_accounts: user_accounts_fixture()}
    end

    test "validates password", %{user_accounts: user_accounts} do
      {:error, changeset} =
        Account.reset_user_accounts_password(user_accounts, %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: ["should be at least 12 character(s)"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{user_accounts: user_accounts} do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Account.reset_user_accounts_password(user_accounts, %{password: too_long})
      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "updates the password", %{user_accounts: user_accounts} do
      {:ok, updated_user_accounts} = Account.reset_user_accounts_password(user_accounts, %{password: "new valid password"})
      assert is_nil(updated_user_accounts.password)
      assert Account.get_user_accounts_by_email_and_password(user_accounts.email, "new valid password")
    end

    test "deletes all tokens for the given user_accounts", %{user_accounts: user_accounts} do
      _ = Account.generate_user_accounts_session_token(user_accounts)
      {:ok, _} = Account.reset_user_accounts_password(user_accounts, %{password: "new valid password"})
      refute Repo.get_by(UserAccountsToken, user_accounts_id: user_accounts.id)
    end
  end

  describe "inspect/2 for the UserAccounts module" do
    test "does not include password" do
      refute inspect(%UserAccounts{password: "123456"}) =~ "password: \"123456\""
    end
  end
end
