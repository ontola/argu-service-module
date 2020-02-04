# frozen_string_literal: true

require 'argu/test_helpers/request_helpers'

# Runs assert_difference with a number of conditions and varying difference
# counts.
#
# @example
#   assert_differences([['Model1.count', 2], ['Model2.count', 3]])
#
def assert_differences(expression_array, message = nil, &block)
  b = block.send(:binding)
  before = expression_array.map { |expr| eval(expr[0], b) }

  yield

  expression_array.each_with_index do |pair, i|
    e = pair[0]
    difference = pair[1]
    error = "#{e.inspect} didn't change by #{difference}"
    error = "#{message}\n#{error}" if message
    assert_equal(before[i] + difference, eval(e, b), error)
  end
end
