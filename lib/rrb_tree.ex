defmodule RrbTree do
  @moduledoc """
  # Relaxed Radix Tree
  #
  # A datastructure that implements indexed collection operations like
  # add, index, update, merges and splits in logarithmic time.
  #
  # A tree is consisted of one Root, many internal Nodes and Leaf nodes.
  """

  @m 2 # Integer: tree branching exponent, as in 2^m. E.g, m = 2 so branching factor of 4.

  defstruct h: nil,   # the tree height. Leaf nodes have height = 1.
            node: nil

  defmodule Node do
    defstruct ranges: nil,
              slots: nil
  end

  use Bitwise, only_operators: true

  def get(%RrbTree{} = t, index) do
    do_get(t.h, t.node, index)
  end

  defp do_get(h, %Node{} = node, i) do
    radix = do_radix(i, h)
    branch_index = do_find_branch_index(node.ranges, radix, i)
    new_index = do_new_index(node.ranges, branch_index, i)

    do_get(h - 1, elem(node.slots, branch_index), new_index)
  end

  defp do_get(_h = 1, leaf, i) do
    elem(leaf, i)
  end

  # Finds the branch in which the index is expected to be found.
  # Equivalent to, since the branching factor is a power of 2:
  #
  # 1. find the number of items in each branch: $n = 2^{m^{h - 1}}$
  # 2. find the branch index $radix = \lfloor \div{i}{n} \rfloor$
  #
  # Bitwise operators are faster than integer arithmetic.
  defp do_radix(i, h) do
    i >>> (@m * (h - 1))
  end

  # Since our constraints over the branching factor $2^m$ are relaxed,
  # e.g. we may have both $2^m - 1$ and $2^m$ branching, sometimes
  # the expected branch calculated with `do_radix` may not be correct,
  # so here we do a linear search for the correct branch.
  defp do_find_branch_index(slots, radix, i) do
    if elem(slots, radix) > i do
      radix
    else
      do_find_branch_index(slots, radix + 1, i)
    end
  end

  # In order to recursively get an item from the tree, we need to
  # adjust the index, reducing it by the number of items to the
  # left of the branch we are going to search.
  defp do_new_index(ranges, branch_index, i) do
    if branch_index == 0 do
     i
    else
      i - elem(ranges, branch_index - 1)
    end
  end
end
