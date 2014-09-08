module Enumerable
  def flat_group_by &block
    reduce({}) do |hash, val|
      key = block.call(val)
      hash[key] = val
    end
  end
end
