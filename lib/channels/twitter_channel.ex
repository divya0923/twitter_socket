defmodule TwitterChannel do 
    use Phoenix.Channel
    require Logger

    def join("twitter", _payload, socket) do
        :global.sync()
        socket = assign(socket, :hEngine, :global.whereis_name(:hashtagEngine))
        socket = assign(socket, :mEngine, :global.whereis_name(:mentionsEngine))
        socket = assign(socket, :uEngine, :global.whereis_name(:userEngine))
        socket = assign(socket, :rEngine, :global.whereis_name(:rcdEngine))
        {:ok, socket}
    end

    def handle_in("new_message", payload, socket) do
        Logger.error ("new_message #{inspect payload}")
        broadcast! socket, "new_message", payload
        {:noreply, socket}
    end
    
    def handle_in("register", payload, socket) do
        GenServer.call socket.assigns[:uEngine], {:register, payload["uid"]}
        zipfNum = round((1/payload["uid"]) * payload["usersCount"]) # do zipf thing here
        fList = Enum.take_random(Enum.to_list(1..payload["usersCount"]) -- [payload["uid"]], zipfNum)
        #Logger.info("followersList #{inspect fList}")
        GenServer.cast socket.assigns[:uEngine], {:subscribe, payload["uid"], fList}
        {:noreply, socket}
    end

    def handle_in("login", userId, socket) do
        GenServer.cast socket.assigns[:rEngine], {:login, userId, socket.channel_pid}       
        {:noreply, socket}
    end 

    def handle_in("postTweet", payload, socket) do
        #Logger.error("postTweet in channel #{inspect payload}")
        GenServer.cast socket.assigns[:uEngine], {:postTweet, payload["uid"], payload["text"]}
        {:noreply, socket}
    end

    def handle_in("retweet", payload, socket) do
        #Logger.error("mentionSearch in channel #{inspect payload}")
        GenServer.cast socket.assigns[:uEngine], {:reTweet, payload["uid"], payload["tid"]}
        #Logger.error("mentionSearch results #{inspect status} #{inspect tweetList}")        
        #push socket, "mSearchResults", %{tList: tweetList, skey: status}
        {:noreply, socket}
    end

    def handle_in("hashtagSearch", payload, socket) do
        #Logger.error("hashtagSearch in channel #{inspect payload}")
        {status, tweetList} = GenServer.call socket.assigns[:hEngine], {:getTweets, payload["hkey"]}        
        #Logger.error("hashtagsearch results #{inspect tweetList}")
        push socket, "hSearchResults", %{tList: tweetList, skey: status}
        {:noreply, socket}
    end

    def handle_in("mentionSearch", payload, socket) do
        #Logger.error("mentionSearch in channel #{inspect payload}")
        {status, tweetList} =  GenServer.call socket.assigns[:mEngine], {:getTweets, payload["uid"]}
        #Logger.error("mentionSearch results #{inspect status} #{inspect tweetList}")        
        push socket, "mSearchResults", %{tList: tweetList, skey: status}
        {:noreply, socket}
    end

    def handle_info(message, socket) do
        case message do 
            {:receiveTweet, list} -> 
                #Logger.error("postTweet socket #{inspect socket} #{inspect self()}")                            
                push socket, "receiveTweet", %{tList: list}
        end
        {:noreply, socket}
    end
end 