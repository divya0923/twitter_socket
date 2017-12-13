defmodule TwitterSocket do
  use Application

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    IO.puts "application start"
    #{:ok, simulator} = Simulator.start_link(5,1)
    #IO.puts "simulator" <> inspect(simulator)
    #GenServer.cast simulator, :startSimulation

    {:ok, hEngine} = HashtagEngine.start_link(%{})
    {:ok, mEngine} = MentionsEngine.start_link(%{})
    {:ok, wEngine} = WriterMapEngine.start_link(1, %{})   
    :global.register_name(:datastore, wEngine)    
    :global.register_name(:hashtagEngine, hEngine)
    :global.register_name(:mentionsEngine, mEngine)
    :global.sync()
    
    {:ok, userEngine} = UserEngine.start_link([], %{}, %{})
    {:ok, rcdEngine} = RCDEngine.start_link(userEngine)
    
    :global.register_name(:userEngine, userEngine)
    :global.register_name(:rcdEngine, rcdEngine)
    :global.sync()
 
    """
    count = 6
    {:ok, client1} = TwitterClient.start_link(1, count)
    {:ok, client2} = TwitterClient.start_link(2, count)  
    
    Process.send(client1, {:register, "jhdfj"}, [])
    Process.send(client1, {:login, "fdfdk"}, [])

    Process.send(client2, {:register, "fdf"}, [])
    Process.send(client2, {:login, "dfdf"}, [])

    {:ok, client3} = TwitterClient.start_link(3,count)
    {:ok, client4} = TwitterClient.start_link(4, count) 
    {:ok, client5} = TwitterClient.start_link(5, count)
    {:ok, client6} = TwitterClient.start_link(6, count) 
    
    Process.send(client3, {:register, ""}, [])
    Process.send(client3, {:login, ""}, [])

    Process.send(client4, {:register, ""}, [])
    Process.send(client4, {:login, ""}, [])

    Process.send(client5, {:register, ""}, [])
    Process.send(client5, {:login, ""}, [])

    Process.send(client6, {:register, ""}, [])
    Process.send(client6, {:login, ""}, [])

    Process.send(client2, {:postTweet, "Go Gators #gators"}, [])
    Process.send(client2, {:postTweet, "Gators are great #great"}, [])

    Process.send(client3, {:postTweet, "Go Gators #gators"}, [])
    Process.send(client3, {:postTweet, "Gators are great #great"}, [])

    Process.send(client4, {:postTweet, "Go Gators #gators"}, [])
    Process.send(client4, {:postTweet, "Gators are great #great"}, [])

    Process.send(client5, {:postTweet, "Go Gators #gators @1"}, [])
    Process.send(client5, {:postTweet, "Gators are great #great @1"}, [])

    Process.send(client1, {:hSearch, "#great"}, [])
    Process.send(client1, :mSearch, [])
        
    """

    #Process.send(client1, "hashTagSearch", [])

    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    children = [
      # Start the Ecto repository
      # supervisor(TwitterSocket.Repo, []),
      # Start the endpoint when the application starts
      supervisor(TwitterSocket.Endpoint, []),
      # Start your own worker by calling: TwitterSocket.Worker.start_link(arg1, arg2, arg3)
      # worker(TwitterSocket.Worker, [arg1, arg2, arg3]),
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options


    opts = [strategy: :one_for_one, name: TwitterSocket.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    TwitterSocket.Endpoint.config_change(changed, removed)
    :ok
  end
end
