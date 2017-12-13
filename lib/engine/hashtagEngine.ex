defmodule HashtagEngine do 
    use GenServer

    def start_link(hMap) do
        GenServer.start_link(__MODULE__, [hMap, 0])                      
    end 

    def handle_call({:addTags, tagList, tweetId}, _from, [hMap, lastRecord]) do 
        hMap = Enum.reduce tagList, hMap, fn(tag, hMap) -> 
            {id, hMap} = Map.get_and_update(hMap, tag, 
                 fn tList -> 
                    if tList == nil do 
                        {tag, [tweetId]}                   
                    else
                        {tag, tList ++ [tweetId]}
                    end
                 end
                 )       
            hMap
        end
        {:reply, :ok, [hMap, (lastRecord+1)]}        
    end

    def handle_call({:getTweets, hashTag}, _from, [hMap, lastRecord]) do
        tweetList = []
        hashToSearch = :ok
        if length(Map.keys(hMap)) == 0 do
            IO.puts "hash tweets list empty"
        else 
            hashToSearch = hashTag
            {:ok, list} = Map.fetch(hMap, hashTag) 
            tweetList = Enum.reduce list, tweetList, fn(id, tweetList) -> 
                #[{id, text, user}] = :ets.lookup(:tweetsTable, id)
                {id, text, user} = GenServer.call :global.whereis_name(:datastore), {:findTweet, id}
                tweetList = [Integer.to_string(user) <> " : " <> text] ++ tweetList
                tweetList
            end 
        end
        #IO.puts "hashSearch sending: " <> inspect(tweetList)
        {:reply, {hashToSearch, tweetList}, [hMap, (lastRecord+1)]}             
    end 

    def handle_call(:getStat, _from, [hMap, lastRecord]) do
        {:reply, lastRecord, [hMap, 0]} 
    end
end    