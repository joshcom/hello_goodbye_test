require 'rubygems'
require 'json'

module TestClient
  @@next_command = nil

  def self.next_command=(c)
    @@next_command = c
  end

  def self.last_data
    @@last_data
  end

  def post_init
    @@last_data = nil
    send_data({:command => @@next_command}.to_json)
  end

  def receive_data(data)
    @@last_data = JSON.parse(data)
    close_connection
  end
end
