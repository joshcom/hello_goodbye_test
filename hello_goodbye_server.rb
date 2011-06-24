require 'rubygems'
require 'hello_goodbye'
require File.expand_path('../test_console',__FILE__)
require File.expand_path('../test_foreman',__FILE__)

m = HelloGoodbye.manager(8080,"127.0.0.1")
m.register_foreman( :port => 8081, :class => HelloGoodbye::TestForeman )
m.register_foreman( :port => 8082, :class => HelloGoodbye::TestForeman )
m.start!
