require "em-synchrony"
require "em-synchrony/tcpsocket"

module Mongoo
  def self.suppress_warnings
    original_verbosity = $VERBOSE
    $VERBOSE = nil
    result = yield
    $VERBOSE = original_verbosity
    return result
  end
end

module Mongoo
  def self.mode
    :async
  end
end

module Mongo
  class Pool
    Mongoo.suppress_warnings { TCPSocket = ::EventMachine::Synchrony::TCPSocket }
  end
end

module Mongo
  class Connection
    Mongoo.suppress_warnings { TCPSocket = ::EventMachine::Synchrony::TCPSocket }
  end
end

if ENV["MONGOO_DEBUG"] == "1"
  puts "* Mongoo Running in Asynchronous Mode"
  puts "  ==> Mongo::Pool::TCPSocket: #{Mongo::Pool::TCPSocket.to_s}"
  puts "  ==> Mongo::Connection::TCPSocket: #{Mongo::Pool::TCPSocket.to_s}"
end
