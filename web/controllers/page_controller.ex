defmodule TwitterSocket.PageController do
  use TwitterSocket.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
