require 'minitest/autorun'
require_relative '../../lib/stg/differencing'

class TestDifferencing < Minitest::Test
  def setup
    @diffCalc = DiffCalc.new
  end

  def test_differencing_func
    puts 'test'
  end
end
