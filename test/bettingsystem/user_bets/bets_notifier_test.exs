defmodule Bettingsystem.UserBets.BetsNotifierTest do
  use ExUnit.Case, async: true
  import Swoosh.TestAssertions

  alias Bettingsystem.UserBets.BetsNotifier

  test "deliver_bet_status/1" do
    user = %{name: "Alice", email: "alice@example.com"}

    BetsNotifier.deliver_bet_status(user)

    assert_email_sent(
      subject: "Welcome to Phoenix, Alice!",
      to: {"Alice", "alice@example.com"},
      text_body: ~r/Hello, Alice/
    )
  end

  test "deliver_bet_status_confirmation/1" do
    user = %{name: "Alice", email: "alice@example.com"}

    BetsNotifier.deliver_bet_status_confirmation(user)

    assert_email_sent(
      subject: "Welcome to Phoenix, Alice!",
      to: {"Alice", "alice@example.com"},
      text_body: ~r/Hello, Alice/
    )
  end
end
