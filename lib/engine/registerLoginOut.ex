defmodule RCDEngine do 
    use GenServer

    def start_link(userEngine) do
        GenServer.start_link(__MODULE__, [userEngine])              
    end

    def handle_cast({:login, userId, userPid}, [userEngine]) do
        IO.puts "login user:" <> inspect(userId) <>  " " <> inspect(userPid)
        #initialFeed = GenServer.call userEngine, {:test, userId}
        initialFeed = getFeed(userId, 1, [])
        #IO.puts "initial feed: " <> inspect(initialFeed)
        #GenServer.cast userPid, {:recieveTweet, initialFeed}
        #IO.puts "login user: " <> inspect(userId) <> " pid: " <> inspect(userPid)

        :global.register_name(userId, userPid)
        :global.sync()
        Process.send(userPid, {:receiveTweet, initialFeed}, [])        
        {:noreply, [userEngine]}
    end 

    def handle_call({:logout, userId}, _from, [userEngine]) do
        #IO.puts "logout user: " <> inspect(userId) 
        :global.unregister_name(userId)
        :global.sync()
        {:reply, :ok, [userEngine]}
    end

    def getFeed(userId, count, itList) do
        if count == 6 do 
            IO.puts "getFeed end " <> inspect(userId)
            itList
        else
            #IO.puts "engineactor: " <> inspect(:global.whereis_name("actor" <> Integer.to_string(count))) <> " u: " <> inspect(userId)
            tempList = GenServer.call :global.whereis_name("actor" <> Integer.to_string(count)), {:getTweets, userId}
            #IO.puts "got: " <> inspect(tempList)
            if tempList != nil do
                tempList = Enum.reduce tempList, itList, fn(tweet, itList) -> 
                    {id, ts, rt} = tweet 
                    #[{id, text, user}] = :ets.lookup(:tweetsTable, id)
                    {id, text, user} = GenServer.call :global.whereis_name(:datastore), {:findTweet, id}                    
                    if rt != 0 do 
                        text = Integer.to_string(rt) <> " ReTweeted- " <> Integer.to_string(user) <> " : " <> text 
                    else 
                        text = Integer.to_string(user) <> " : " <> text
                    end                                  
                    itList = [{id, ts, text}] ++ itList
                    itList
                end 
            end
            getFeed(userId, (count+1), itList)
        end
        
    end 
end