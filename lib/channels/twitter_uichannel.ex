defmodule TwitterUiChannel do 
    use Phoenix.Channel
    require Logger

    def join("twitterui:123", _payload, socket) do
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
        Logger.error("register #{inspect payload}")
        {userId, ""} = Integer.parse(payload["uid"])
        socket = assign(socket, :uid, userId)
        GenServer.call socket.assigns[:uEngine], {:register, userId} 
        IO.puts "userId " <> inspect(socket.assigns[:uid])
        push socket, "registrationDone", %{done: true}     
        {:noreply, socket}
    end

    def handle_in("registerDone", payload, socket) do 
        Logger.error("registration done")
        push socket, "registration", payload
        {:noreply, socket}
    end 
    

    def handle_in("login", payload, socket) do
        Logger.error("login #{inspect payload}")
        {uid, ""} = Integer.parse(payload["uid"])
        GenServer.cast socket.assigns[:rEngine], {:login, uid, socket.channel_pid}                           
        """
        if uid != 0 do 
            GenServer.cast socket.assigns[:rEngine], {:login, uid, socket.channel_pid}                   
        else
            GenServer.cast socket.assigns[:rEngine], {:login, socket.assigns[:uid], socket.channel_pid}       
        end
        """
        {:noreply, socket}
    end 

    def handle_in("postTweet", payload, socket) do
        Logger.error("postTweet in channel #{inspect payload}")
        GenServer.cast socket.assigns[:uEngine], {:postTweet, socket.assigns[:uid], payload["text"]}
        {:noreply, socket}
    end

    def handle_in("subscribeTo", payload, socket) do 
        Logger.error("subscribeTo #{inspect payload}")
        {fid, ""} = Integer.parse(payload["followerId"])
        IO.inspect fid
        GenServer.cast socket.assigns[:uEngine], {:subscribe, socket.assigns[:uid], [fid]}
        {:noreply, socket}
    end 

    def handle_in("retweet", payload, socket) do
        Logger.error("retweet in channel #{inspect payload}")
        {rid, ""} = Integer.parse(payload["tid"])
        GenServer.cast socket.assigns[:uEngine], {:reTweet, socket.assigns[:uid], rid}
        #Logger.error("mentionSearch results #{inspect status} #{inspect tweetList}")        
        #push socket, "mSearchResults", %{tList: tweetList, skey: status}
        {:noreply, socket}
    end

    def handle_in("hashtagSearch", payload, socket) do
        #Logger.error("hashtagSearch in channel #{inspect payload}")
        {status, tweetList} = GenServer.call socket.assigns[:hEngine], {:getTweets, payload["key"]}        
        #Logger.error("hashtagsearch results #{inspect tweetList}")
        push socket, "searchResults", %{tList: tweetList, skey: status}
        {:noreply, socket}
    end

    def handle_in("mentionSearch", payload, socket) do
        #Logger.error("mentionSearch in channel #{inspect payload}")
        {mid, ""} = Integer.parse(payload["key"])
        {status, tweetList} =  GenServer.call socket.assigns[:mEngine], {:getTweets, mid}
        #Logger.error("mentionSearch results #{inspect status} #{inspect tweetList}")        
        push socket, "searchResults", %{tList: tweetList, skey: status}
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