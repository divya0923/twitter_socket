defmodule WriterMapEngine do
    use GenServer

    def start_link(tweetCount, tweetMap) do
        GenServer.start_link(__MODULE__, [tweetCount, tweetMap])
    end

    def handle_call({:writeTweet, tweet, userId}, _from, [tweetCount, tweetMap]) do 
        tweetMap = Map.put(tweetMap, tweetCount, {tweetCount, tweet, userId})
        #IO.puts "tweetMap" <> inspect(tweetMap)
        {:reply, {:ok, tweetCount}, [(tweetCount+1), tweetMap]}
    end

    def handle_call({:findTweet, tweetId}, _from, [tweetCount, tweetMap]) do
        #IO.puts "tweetId" <> inspect(tweetId)
        {:ok, tweet}  = Map.fetch(tweetMap, tweetId)
        {:reply, tweet, [tweetCount, tweetMap]}
    end 
end
    