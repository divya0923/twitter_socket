defmodule TwitterClient do 
    @moduledoc false
    require Logger
    alias Phoenix.Channels.GenSocketClient
    @behaviour GenSocketClient

    def start_link(id, count) do
        GenSocketClient.start_link(
            __MODULE__,
            Phoenix.Channels.GenSocketClient.Transport.WebSocketClient,
            ["ws://localhost:4000/socket/websocket", id, count]
          )
    end 

    def init([url, id, count]) do
        {:connect, url, [], %{uid: id, usersCount: count}}
    end 

    def handle_info(:connect, _transport, state) do
        {:connect, state}
    end

    def handle_connected(transport, state) do
        GenSocketClient.join(transport, "twitter")
        {:ok, state}
    end

    def handle_disconnected(reason, state) do
        Logger.error("disconnected: #{inspect reason}")
        {:ok, state}
    end

    def handle_joined(topic, _payload, transport, state) do
        #:timer.send_interval(:timer.seconds(1), self(), :register)
        {:ok, state}
    end

    def handle_reply("twitter", _ref, %{"status" => "ok"} = payload, _transport, state) do
        {:ok, state}
    end

    def handle_message("twitter", "receiveTweet", payload, transport, state) do 
        #Logger.info("receiveTweet in client #{inspect payload}  uid: #{inspect state.uid}")
        tweetList = payload["tList"]
        forReTweet = tweetList
        Enum.each tweetList, fn tweet -> 
            Logger.warn("#{inspect tweet["tweet"]}")
        end
        
        #retweet
        hprob = :rand.uniform()
        if hprob<0.5 do
            if length(forReTweet) != 0 do
                retweet = Enum.random(forReTweet)
                #Logger.error("retweet #{inspect retweet["tid"]}")
                GenSocketClient.push(transport, "twitter", "retweet", %{uid: state.uid, tid: retweet["tid"]})                    
            end 
        end 
        {:ok, state}
    end 

    def handle_message("twitter", "hSearchResults", payload, transport, state) do 
        #Logger.info("receiveTweet in client #{inspect payload}  uid: #{inspect state.uid}")
        status = payload["skey"]
        if status == :ok do 
            Logger.warn("No results found for hashtag search")
        else 
            tweetList = payload["tList"]
            Logger.warn("Hashtag search results for key: #{payload["skey"]} #{inspect tweetList}")      
        end
        {:ok, state}
    end 

    def handle_message("twitter", "mSearchResults", payload, transport, state) do 
        #Logger.info("receiveTweet in client #{inspect payload}  uid: #{inspect state.uid}")
        status = payload["skey"]
        if status == :ok do 
            Logger.warn("No results found for mentions search for user #{state.uid}")
        else 
            tweetList = payload["tList"]
            Logger.warn("Mentions search results for user: #{state.uid}} #{inspect tweetList}")      
        end
        {:ok, state}
    end 


    def handle_info(:register, transport, state) do
        GenSocketClient.push(transport, "twitter", "register", %{uid: state.uid, usersCount: state.usersCount})        
        {:ok, state}
    end

    def handle_info(:login, transport, state) do
        GenSocketClient.push(transport, "twitter", "login", state.uid)        
        {:ok, state}
    end

    def handle_info(:sendTweet, transport, state) do
        #generate a tweet, n some hashtags,
        randTweet = :crypto.strong_rand_bytes((Enum.random(8..40)) |> round) |> Base.url_encode64
        randHashes = ""
        hprob = :rand.uniform(10)
        if hprob > 4 do
            randHashes = generateHash(:rand.uniform(3), "")
            #IO.puts "hahes: " <> inspect(randHashes)
        end
        
        #tag some users
        utag = ""
        hprob = :rand.uniform(10)
        if hprob > 7 do
            tList = Enum.take_random(Enum.to_list(1..state.usersCount) -- [state.uid], :rand.uniform(3))
            utag = concatUsers(tList, "")
        end
        randTweet = randTweet <> randHashes <> utag

        GenSocketClient.push(transport, "twitter", "postTweet", %{uid: state.uid, text: randTweet})  
        Process.send_after(self(), :startTweeting, state.uid*10)        
        {:ok, state}
    end

    def handle_info({:sendTweet, tweet}, transport, state) do 
        #Logger.error("postTweet in client #{inspect tweet}")
        GenSocketClient.push(transport, "twitter", "postTweet", %{uid: state.uid, text: tweet})
        {:ok, state}
    end 

    def handle_info({:hashtagSearch, key}, transport, state) do 
        #Logger.error("postTweet in client #{inspect tweet}")
        GenSocketClient.push(transport, "twitter", "hashtagSearch", %{uid: state.uid, hkey: key})
        {:ok, state}
    end
    
    def handle_info(:mentionSearch, transport, state) do 
        #Logger.error("postTweet in client #{inspect tweet}")
        GenSocketClient.push(transport, "twitter", "mentionSearch", %{uid: state.uid})
        {:ok, state}
    end

    def handle_info(message, transport, state) do
        Logger.warn("Unhandled message #{inspect message}")
        case message do
            {:register, msg} ->
                Process.send_after(self(), :register, :timer.seconds(1))
            {:login, msg} ->
                Process.send_after(self(), :login, :timer.seconds(2))   
                Process.send_after(self(), :sendTweet, :timer.seconds(10))     
            :startTweeting ->
                Process.send_after(self(), :sendTweet, :timer.seconds(2)) 
                """
                << i1 :: unsigned-integer-32, i2 :: unsigned-integer-32, i3 :: unsigned-integer-32>> = :crypto.strong_rand_bytes(12)
                :rand.seed(:exsplus, {i1, i2, i3})
                hprob = :rand.uniform()
                if hprob >0.85 && rem(state.uid, 2) == 0 do
                    #GenServer.cast self(), :hSearch
                    Process.send_after(self(), {:hSearch, "#great"}, 0)
                end
                << i1 :: unsigned-integer-32, i2 :: unsigned-integer-32, i3 :: unsigned-integer-32>> = :crypto.strong_rand_bytes(12)
                :rand.seed(:exsplus, {i1, i2, i3})
                :rand.uniform()
                if hprob >0.85 && rem(state.uid, 2) == 1 do
                    #GenServer.cast self(), :mSearch
                    Process.send_after(self(), :mSearch, 0)
                end
                """
            {:postTweet, tweet} ->
                Process.send_after(self(), {:sendTweet, tweet}, :timer.seconds(2))    
            {:hSearch, searchKey} ->
                Logger.info("hashTagSearch")
                Process.send_after(self(), {:hashtagSearch, searchKey}, :timer.seconds(5))
            :mSearch ->
                Logger.info("mentions Search")
                Process.send_after(self(), :mentionSearch, :timer.seconds(5))                
            end
        {:ok, state}
    end

    def generateHash(nHashes, hashes) do
        if nHashes == 0 do
            #IO.puts "***h: " <> inspect(hashes)
            hashes    
        else
            hashes = hashes <> " #" <> (:crypto.strong_rand_bytes(:rand.uniform(3)+1) |> Base.url_encode64)
            generateHash((nHashes-1), hashes)
        end
    end

    def concatUsers([tag | tList], utag) do
        utag = utag <> " @"<> Integer.to_string(tag)
    end

    def concatUsers([], utag) do
        utag
    end

end 