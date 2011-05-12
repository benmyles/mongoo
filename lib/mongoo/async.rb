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
  class FakeMutex
    def initialize
    end

    def synchronize
      yield
    end

    def lock
      true
    end

    def locked?
      false
    end

    def sleep(timeout=nil)
      true
    end

    def try_lock
      true
    end

    def unlock
      true
    end
  end
end

Mongoo.suppress_warnings do
  module Mongo
    class Connection
      Mutex = Mongoo::FakeMutex
      TCPSocket = TCPSocket = ::EventMachine::Synchrony::TCPSocket
    end
  end

  module Mongo
    class Pool
      Mutex = Mongoo::FakeMutex
      TCPSocket = TCPSocket = ::EventMachine::Synchrony::TCPSocket
    end
  end
end

module Mongoo
  def self.mode
    :async
  end
end

if ENV["MONGOO_DEBUG"] == "1"
  puts "* Mongoo Running in Asynchronous Mode"
  puts "  ==> Mongo::Pool::TCPSocket: #{Mongo::Pool::TCPSocket.to_s}"
  puts "  ==> Mongo::Connection::TCPSocket: #{Mongo::Pool::TCPSocket.to_s}"
end
