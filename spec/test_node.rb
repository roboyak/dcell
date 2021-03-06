# The DCell specs start a completely separate Ruby VM running this code
# for complete integration testing using 0MQ over TCP

require 'rubygems'
require 'bundler'
Bundler.setup

require 'dcell'
Dir['./spec/options/*.rb'].map { |f| require f }

options = {:id => TEST_NODE[:id], :addr => "tcp://#{TEST_NODE[:addr]}:#{TEST_NODE[:port]}"}
options.merge! test_db_options
DCell.start options

class TestActor
  include Celluloid
  attr_reader :value

  def initialize
    @value = 42
  end

  def the_answer
    DCell::Global[:the_answer]
  end

  def win(&block)
    yield 10000
    20000
  end

  def crash
    raise "the spec purposely crashed me :("
  end
end

TestActor.supervise_as :test_actor
sleep
