// NOTE: The contents of this file will only be executed if
// you uncomment its entry in "web/static/js/app.js".

// To use Phoenix channels, the first step is to import Socket
// and connect at the socket path in "lib/my_app/endpoint.ex":
import {Socket} from "phoenix"

let socket = new Socket("/socket", {params: {token: window.userToken}})

// When you connect, you'll often need to authenticate the client.
// For example, imagine you have an authentication plug, `MyAuth`,
// which authenticates the session and assigns a `:current_user`.
// If the current user exists you can assign the user's token in
// the connection for use in the layout.
//
// In your "web/router.ex":
//
//     pipeline :browser do
//       ...
//       plug MyAuth
//       plug :put_user_token
//     end
//
//     defp put_user_token(conn, _) do
//       if current_user = conn.assigns[:current_user] do
//         token = Phoenix.Token.sign(conn, "user socket", current_user.id)
//         assign(conn, :user_token, token)
//       else
//         conn
//       end
//     end
//
// Now you need to pass this token to JavaScript. You can do so
// inside a script tag in "web/templates/layout/app.html.eex":
//
//     <script>window.userToken = "<%= assigns[:user_token] %>";</script>
//
// You will need to verify the user token in the "connect/2" function
// in "web/channels/user_socket.ex":
//
//     def connect(%{"token" => token}, socket) do
//       # max_age: 1209600 is equivalent to two weeks in seconds
//       case Phoenix.Token.verify(socket, "user socket", token, max_age: 1209600) do
//         {:ok, user_id} ->
//           {:ok, assign(socket, :user, user_id)}
//         {:error, reason} ->
//           :error
//       end
//     end
//
// Finally, pass the token to the Socket constructor as above.
// Or, remove it from the constructor if you don't care about
// authentication.

socket.connect()

let channel = socket.channel("twitterui:123", {});
let list    = $('#message-list');
let message = $('#message');
let name    = $('#name');
let registerBtn = $('#registerBtn')
let loginBtn = $('#loginBtn')
let uid = 0
let uIdTBox = $('#uid')
let tweetBtn = $('#tweetBtn')
let tweetTxt = $('#tweetTxt')
let followBtn = $('#followBtn')
let followTxt = $('#followTxt')
let hBtn = $('#hBtn')
let hTxt = $('#hTxt')
let mBtn = $('#mBtn')
let mTxt = $('#mTxt')
let rBtn = $('#rBtn')
let rTxt = $('#rId')
let isReg = false;

registerBtn.on('click', event => { 
  console.log("register btn clicked");
  channel.push("register", {uid: uIdTBox.val()});
});

loginBtn.on('click', event => {
  console.log("login btn clicked");
  channel.push("login", {uid : uIdTBox.val()});
});

tweetBtn.on('click', event => {
  console.log("tweet btn clicked");
  channel.push("postTweet", {text: tweetTxt.val()});
  tweetTxt.val('');
});

followBtn.on('click', event => {
  console.log("follow btn clicked");
  channel.push("subscribeTo", {followerId : followTxt.val()});
  followTxt.val('');
});

hBtn.on('click', event => {
  console.log("search btn clicked");
  channel.push("hashtagSearch", {key : hTxt.val()});
});

mBtn.on('click', event => {
  console.log("search btn clicked");
  channel.push("mentionSearch", {key : mTxt.val()});
});

rBtn.on('click', event => {
  console.log("rBtn clicked");
  channel.push("retweet", {tid : rTxt.val()});
});

channel.on('registrationDone', payload => {
  loginBtn.prop('disabled', false);  
  isReg = true;
});

channel.on('receiveTweet', payload =>  {
  console.log("payload from receiveTweet %o", payload);
  for(var i = 0; i < payload.tList.length; i++) {
    var tweet = payload.tList[i];
    console.log("text " + tweet["tweet"])
    list.append(`<b> ${tweet["tweet"]} </b>  || retweet id: ${tweet["tid"]}  </br>`)
  }

  if(payload.tList.length != 0)
    console.log("tweet %o", payload.tList[0]);
  //list.append(`<b>${payload.name || 'Anonymous'}:</b> ${payload.message} </b> ${payload.msg2}`);
  //list.prop({scrollTop: list.prop("scrollHeight")});
});

channel.on('searchResults', payload =>  {
  console.log("payload from receiveTweet %o", payload);
  if(payload["skey"] == "ok") 
    list.append(`no results found for search`);
  else {
    list.append('<b> Search results </b> </br>');
    for(var i = 0; i < payload.tList.length; i++) {
      var tweet = payload.tList[i];
      list.append(`<b> ${tweet} </b> </br>`)
    }
  }

});

message.on('keypress', event => {
  if (event.keyCode == 13) {
    var msg = message.val();
    console.log("mesage %o", msg);
    channel.push('new_message', {name: name.val(), message: msg, msg2: "hello"});
    message.val('');
  }
});

channel.on('new_message', payload => {
  list.append(`<b>${payload.name || 'Anonymous'}:</b> ${payload.message} </b> ${payload.msg2}`);
  list.prop({scrollTop: list.prop("scrollHeight")});
});

channel.join()
  .receive("ok", resp => { 
    //console.log("Joined successfully", resp) ;
    registerBtn.prop('disabled', false);  
  })
  .receive("error", resp => { console.log("Unable to join", resp) })

export default socket
  
