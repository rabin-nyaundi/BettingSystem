defmodule Bettingsystem.UserBets.BetsNotifier do
  import Swoosh.Email
  alias Bettingsystem.Mailer

  def deliver_bet_status(%{name: name, email: email}) do
    new()
    |> to({name, email})
    |> from({"Phoenix Team", "team@example.com"})
    |> subject("Welcome to Phoenix, #{name}!")
    |> html_body("<h1>Hello, #{name}</h1>")
    |> text_body("Hello, #{name}\n")
    |> Mailer.deliver()
  end

  def deliver_bet_status_confirmation(%{name: name, email: email}) do
    new()
    |> to({name, email})
    |> from({"Phoenix Team", "team@example.com"})
    |> subject("Welcome to Phoenix, #{name}!")
    |> html_body("<h1>Hello, #{name}</h1>")
    |> text_body("Hello, #{name}\n")
    |> Mailer.deliver()
  end


    defp deliver(recipient, subject, body) do
    email =
      new()
      |> to(recipient)
      |> from({"Bettingsystem", "rabitechs@gmail.com"})
      |> subject(subject)
      |> text_body(body)

    with {:ok, memetadata} <- Mailer.deliver(email) do

      IO.inspect("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@")
      IO.inspect(memetadata)
      IO.inspect("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@")
      {:ok, email}
    end
  end

  @doc """
  Deliver instructions to confirm account.
  """
  def deliver_status_confirmation(user_accounts, status, bet) do
    deliver(user_accounts.email, "Bet Confirmation instructions", """

    ==============================

    Hi #{user_accounts.email},

    You #{status} the bet placed;
    Bet ID: #{bet}

    If you didn't create an account with us, please ignore this.

    ==============================
    """)
  end
end
