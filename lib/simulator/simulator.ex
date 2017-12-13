defmodule Simulator do
  use GenServer
  @moduledoc """
  Documentation for Simulator.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Simulator.hello
      :world

  """
  def main(args) do
    process(args)
  end

  def start_link(totalUsers, currUser) do
    #IO.puts "UID is:" <> inspect(uId)
    GenServer.start_link(__MODULE__, [totalUsers, currUser])
  end

  def handle_cast(:startSimulation, [totalUsers, currUser]) do
    process(totalUsers, currUser)
    {:noreply, [totalUsers, currUser]}
  end 

  def process([]) do
    IO.puts "No arguments given"
  end

  def process(numUsers, selUser) do
    """
    if length(args) != 2 do
      IO.puts "Run as ./simulator num_of_users <select user for display>"
    else
    
      _ = System.cmd("epmd", ['-daemon'])
      #Node.start(String.to_atom("client@" <> Enum.at(args, 2)))
      Node.start(String.to_atom("slave@" <> "127.0.0.1"))
      Node.set_cookie(:dsiuvryaaj)
      #Node.connect(String.to_atom("server@" <> Enum.at(args, 1)))
      Node.connect(String.to_atom("server@" <> "127.0.0.1"))
      :global.sync()
    """

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

    hEng = hEngine
    mEng = mEngine
    rcdEng = rcdEngine
    userEng = userEngine

      #IO.puts "*****" <> inspect(hEng) <> inspect(mEng) <> inspect(rcdEng) <> inspect(userEng)
      #{numUsers, ""} = Integer.parse(Enum.at(args, 0))
      #{selUser, ""} = Integer.parse(Enum.at(args, 1))
      userPidList = loop(rcdEng, userEng, hEng, mEng, numUsers, numUsers, [], selUser)
      IO.puts "Starting simulation . . ."
      #startloop2(userPidList)
      #send userEng, :record
      #loop3()
  end 

  def loop(rcdEng, userEng, hEng, mEng, numUsers, number2, clientList, selUser) do
      if number2 != 0 do
          #IO.puts "number2 is" <> inspect(number2) <> " " <> inspect(numUsers)
          #{:ok, pidClient} = Client.start_link(rcdEng, userEng, hEng, mEng, numUsers, number2, [], selUser) 
          {:ok, pidClient} = TwitterClient.start_link(number2, numUsers)
          
          #IO.puts "pidC: " <> inspect(pidClient)
          
          #GenServer.call pidClient, :register
          Process.send(pidClient, {:register, "register"}, [])
          
          clientList = [pidClient | clientList]
          loop(rcdEng, userEng, hEng, mEng, numUsers, (number2 - 1), clientList, selUser)
        else
          clientList
      end
  end

  def startloop2([user | userPidList]) do
    #send user, 0
    Process.send(user, {:login, "login"}, [])
    startloop2(userPidList)
  end

  def startloop2([]) do
      :ok
  end

  def loop3() do
    loop3()
  end
  
end
