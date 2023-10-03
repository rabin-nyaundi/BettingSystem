defmodule BettingsystemWeb.MatchDetailViewLive do
  use BettingsystemWeb, :live_view

  alias Bettingsystem.Repo
  alias Bettingsystem.Match
  alias Bettingsystem.Bets.Bet
  alias Bettingsystem.BettingEngine.Match, as: Matches

  @impl true
  def render(%{loading: true} = assigns) do
    ~H"""
    Loading matches...
    """
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col mx-auto w-full lg:w-1/3 shadow-md border rounded-md">
      <div class="flex flex-col w-full">
        <h2 class="text-3xl font-bold text-center p-3">Match Details <hr /></h2>
        <div class="flex w-full p-4">
          <div class="flex w-1/3">
            <span class="font-medium">Match ID : </span>
          </div>
          <div class="flex w-flex-1">
            <span>
              <%= @match.game_uuid %>
            </span>
          </div>
        </div>
        <hr />
        <div class="flex w-full p-4">
          <div class="flex w-1/3">
            <span class="font-medium">Home team : </span>
          </div>
          <div class="flex gap-4 w-flex-1">
            <span>
              <%= @match.home_club.name %>
            </span>
          </div>
        </div>
        <hr />
        <div class="flex w-full p-4">
          <div class="flex w-1/3">
            <span class="font-medium">Away team : </span>
          </div>
          <div class="flex w-flex-1">
            <div class="flex flex-col w-flex-1">
              <span>
                <%= @match.away_club.name %>
              </span>
            </div>
          </div>
        </div>

        <hr />

        <div class="flex w-full p-4">
          <div class="flex w-1/3">
            <span class="font-medium">Home win : </span>
          </div>
          <div class="flex w-flex-1">
            <div class="flex flex-col w-flex-1">
              <span>
                <%= @match.home_odds %>
              </span>
            </div>
          </div>
        </div>

        <hr />
        <div class="flex w-full p-4">
          <div class="flex w-1/3">
            <span class="font-medium">Draw : </span>
          </div>
          <div class="flex w-flex-1">
            <div class="flex flex-col w-flex-1">
              <span>
                <%= @match.draw_odds %>
              </span>
            </div>
          </div>
        </div>

        <hr />
        <div class="flex w-full p-4">
          <div class="flex w-1/3">
            <span class="font-medium">Away win : </span>
          </div>
          <div class="flex w-flex-1">
            <div class="flex flex-col w-flex-1">
              <span>
                <%= @match.away_odds %>
              </span>
            </div>
          </div>
        </div>

        <hr />
        <div class="flex w-full p-4">
          <div class="flex w-1/3">
            <span class="font-medium">Match Winner : </span>
          </div>
          <div class="flex w-flex-1">
            <div class="flex flex-col w-flex-1">
              <span>
                <%= @match.match_winner_id %>
              </span>
            </div>
          </div>
        </div>

        <hr />
        <div class="flex w-full p-4">
          <div>
            <.button
              phx-click={show_modal("update_winner_modal")}
              phx-disable-with="Opening..."
              class="w-full"
            >
              Add Match <span aria-hidden="true"></span>
            </.button>
          </div>
        </div>
      </div>
      <.modal id="update_winner_modal">
        <.simple_form for={@form} class="w-full" phx-submit="update_winner">
          <div class="w-full">
            <.input
              field={@form[:match_winner_id]}
              label="Who won"
              type="select"
              options={[
                {"Home", "1"},
                {"Away", "2"},
                {"Draw", "3"}
              ]}
            />
          </div>
          <div>
            <.button phx-disable-with="Saving" class="w-full">
              Save<span aria-hidden="true"></span>
            </.button>
          </div>
        </.simple_form>
      </.modal>
    </div>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    if connected?(socket) do
      %{"match_id" => match_id} = params
      match = Match.get_match(match_id)

      form =
        %Matches{}
        |> Matches.changeset(%{})
        |> to_form(as: "match")

      socket =
        socket
        |> assign(:match, match)
        |> assign(form: form, loading: false)

      {:ok, socket}
    else
      {:ok, assign(socket, loading: true)}
    end
  end

  @impl true
  def handle_event("update_winner", %{"match" => %{"match_winner_id" => winner_id}}, socket) do

      winner_id
      |> String.to_integer()
      |> Match.update_match_results(socket.assigns.match)
      |> case do
        {:ok, _match} ->
          Match.get_all_pending_bets(socket.assigns.match.id)
          |> Enum.each(fn bet ->
            updated_status =
              if bet.prediction == winner_id do
                "won"
              else
                "lost"
              end

            Bet.changeset(bet, %{status: updated_status})
              |> Repo.update()            

          end)

        {:error, _changeset} ->
          socket =
              socket
              |> put_flash(:error, "Failed to update game result")
              |> push_navigate(to: ~p"/")

              {:ok, socket}
      end

    {:noreply, socket}
  end

  def update_bet_status(bets, result) do
    Enum.each(bets, fn bet ->
      updated_status =
        if bet.prediction == result do
          "won"
        else
          "lost"
        end

        Bet.changeset(bet, %{status: updated_status})
        |> Bettingsystem.Repo.update()
    end)
  end
end
