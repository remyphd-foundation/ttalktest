
defmodule DoorController do
  use GenServer

  # Client API
  def start_link(default \\ []) do
    GenServer.start_link(__MODULE__, default, name: __MODULE__)
  end

  def action(open?) do
    GenServer.cast(__MODULE__, {:action, open?})
  end

  # Server Callbacks
  def init(state) do
    {:ok, state}
  end

  def handle_cast({:action, action}, state) do
    IO.puts("action " <> action)
    # Lookup all processes registered under {:websocket_conn, _}
    for {pid, _} <- Registry.lookup(TurtleTalkTest.Registry, :websocket_conn) do
      send(pid, {:action, action})
    end
    {:noreply, state}
  end
end

defmodule WebSocketHandler do

  def init(_args) do
    {:ok, _pid} = Registry.register(TurtleTalkTest.Registry, :websocket_conn, self())
    {:ok, %{}}
  end

  def handle_in({"ping", [opcode: :text]}, state) do
    {:reply, :ok, {:text, "pong"}, state}
  end

  def handle_info({:action, action}, state) when action in ["open", "close"] do
    message = Jason.encode!(%{action: action})
    IO.puts("sending " <> message)
    {:push, {:text, message}, state}
  end

  def terminate(reason, state) do
    :ok = Registry.unregister_match(TurtleTalkTest.Registry, :websocket_conn, self())
    IO.puts("WebSocket connection terminated: #{inspect(reason)}")
    {:ok, state}
  end
end

# Define a Plug Router for HTTP requests and WebSocket upgrades
defmodule Router do
  use Plug.Router

  plug :match
  plug Plug.Logger
  plug :dispatch

  # HTTP endpoint for testing WebSocket in browser
  get "/" do
    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, """
    Output: <div id="output"></div>

    <script type="text/javascript">
    var output = document.getElementById("output");
    var sock = new WebSocket("ws://localhost:4000/websocket");
    sock.addEventListener("message", (message) => {
      output.append(message.data);
    });
    sock.addEventListener("open", () => {
      setInterval(() => sock.send("ping"), 1000);
    });
    </script>
    """)
  end

  # WebSocket endpoint
  get "/websocket" do
    conn
    |> WebSockAdapter.upgrade(WebSocketHandler, [], timeout: 60_000)
    |> halt()
  end

  # Fallback for unmatched routes
  match _ do
    send_resp(conn, 404, "not found")
  end
end


defmodule TurtleTalkTest.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Registry, keys: :unique, name: TurtleTalkTest.Registry},
      {Bandit, plug: Router, scheme: :http, port: 4000},
      {DoorController, []}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TurtleTalkTest.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
