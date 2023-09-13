defmodule Bettingsystem.AccountFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Bettingsystem.Account` context.
  """

  def unique_user_accounts_email, do: "user_accounts#{System.unique_integer()}@example.com"
  def valid_user_accounts_password, do: "hello world!"

  def valid_user_accounts_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_user_accounts_email(),
      password: valid_user_accounts_password()
    })
  end

  def user_accounts_fixture(attrs \\ %{}) do
    {:ok, user_accounts} =
      attrs
      |> valid_user_accounts_attributes()
      |> Bettingsystem.Account.register_user_accounts()

    user_accounts
  end

  def extract_user_accounts_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end
end
