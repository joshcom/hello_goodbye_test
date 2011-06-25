require 'rubygems'
require 'eventmachine'
require 'socket'
require 'json'

@console_hash = { 
  :manager => { :port => 8080 }, 
  :clients => [
    {:port => 8081, :name => "test", :status => "stopped", :id => nil},
    {:port => 8082, :name => "test", :status => "stopped", :id => nil}
  ]
}

@test_number = 0
@failures = 0

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
  next_action(@console_hash[:manager][:port],command)
end

def next_client_action(command,index)
  next_action(@console_hash[:clients][index][:port],command)
end

def next_action(port,command)
  p = TCPSocket.open("127.0.0.1", port)
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
  @failures += 1
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

def enable_clients_by_name
  @console_hash[:clients].each do |client|
    next_manager_action("start #{client[:name]}")
    assert_success("ok",h)
    client[:status] = "running"
  end
end

def disable_clients_by_name
  @console_hash[:clients].each do |client|
    h + next_manager_action("stop #{client[:name]}")
    assert_success("ok",h)
    client[:status] = "stopped"
  end
end

def enable_all_clients
  h = next_manager_action("start all")
  assert_success("ok",h)
  @console_hash[:clients].each do |client|
    client[:status] = "running"
  end
end

def disable_all_clients
  h = next_manager_action("stop all")
  assert_success("ok",h)
  @console_hash[:clients].each do |client|
    client[:status] = "stopped"
  end
end

def process_manager
  assert_success("hello",next_manager_action("hello"))
  check_foremen
  assert_success("goodbye",next_manager_action("goodbye"))
end

def process_client(ind)
  assert_success("hello",next_client_action("hello",ind))
  assert_success(@console_hash[:clients][ind][:status],next_client_action("status",ind))
  assert_success("goodbye",next_client_action("goodbye",ind))
end

def enable_client(ind)
  assert_success("ok",next_client_action("start",ind))
  @console_hash[:clients][ind][:status] = "running"
end

def disable_client(ind)
  assert_success("ok",next_client_action("stop",ind))
  @console_hash[:clients][ind][:status] = "stopped"
end

puts "--> Testing manager <--"
process_manager

puts "--> Testing clients <--"
@console_hash[:clients].size.times do |x|
  process_client(x)
  enable_client(x)
end

puts "--> Testing manager <--"
process_manager

puts "--> Testing clients <--"
@console_hash[:clients].size.times do |x|
  process_client(x)
  disable_client(x)
  process_client(x)
end

puts "--> Enabling clients through manager <--"
enable_all_clients
puts "--> Testing manager <--"
process_manager

puts "--> Testing clients <--"
@console_hash[:clients].size.times do |x|
  process_client(x)
end

puts "--> Disabling clients through manager <--"
enable_all_clients
puts "--> Testing manager <--"
process_manager

puts "--> Testing clients <--"
@console_hash[:clients].size.times do |x|
  process_client(x)
end

puts "--> Finished.  (#{@test_number} tests, #{@failures} failures)."
