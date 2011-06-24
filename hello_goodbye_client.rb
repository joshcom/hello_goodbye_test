require 'rubygems'
require 'eventmachine'
require 'socket'
require 'json'

@console_hash = { :manager => { :port => 8080 }, :clients => [
    {:port => 8081, :name => "test", :status => "stopped", :id => nil},
    {:port => 8082, :name => "test", :status => "stopped", :id => nil}
  ]
}

@test_number = 0

def check_foremen
  r = next_manager_action("foremen")
  pass = true
  clients = @console_hash[:clients]
  r["results"].size.times do |x|
    f = r["results"][x]
    if f["name"] == clients[x][:name] && f["status"] == clients[x][:status]
      next
    else
      pass = false
      break
    end
  end

  if pass
    report_success("foremen")
  else
    report_failure("foremen",r)
  end
end

def create_command(c)
  "{\"command\":\"#{c}\"}"
end

def test_number
  @test_number
end

def next_test
  @test_number += 1
end

def next_manager_action(command)
  p = TCPSocket.open("127.0.0.1", @console_hash[:manager][:port])
  p.send create_command(command), 0
  r = p.recv(1000)
  if r == ""
    r = "{\"success\":true,\"message\":\"goodbye\"}"
  end
  p.close
  JSON.parse(r)
end

def report_success(response)
  puts "PASSED --> Test #{test_number} for response #{response}"
end

def report_failure(response,hash)
  puts "FAILURE --> Test #{test_number} for response #{response} failed with response: #{hash.inspect}"
end

def assert_success(response,hash)
  next_test
  if hash["success"] == true && hash["message"] == response
    report_success(response)
  else
    report_failure(response,hash)
  end
end

def process_manager
  assert_success("hello",next_manager_action("hello"))
  check_foremen
  assert_success("goodbye",next_manager_action("goodbye"))
end

process_manager
