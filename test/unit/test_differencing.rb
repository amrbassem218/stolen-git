require 'minitest/autorun'
require_relative '../../lib/stg/differencing'

class TestDifferencing < Minitest::Test
  def setup
    @diffCalc = Object.new.extend(DiffCalc)
  end

  def test_differencing_counts_insertions_and_deletions
    @diffCalc.compute_diff(%w[a b c], %w[a x c d])
    diff = @diffCalc.build_sequences

    assert_equal 2, diff[:insertions]
    assert_equal 1, diff[:deletions]
  end
end
