defmodule RrbTree do
  @moduledoc """
  # Relaxed Radix Tree
  #
  # A datastructure that implements indexed collection operations like
  # add, index, update, merges and splits in logarithmic time.
  #
  # A tree is consisted of one Root, many internal Nodes and Leaf nodes.
  """

  use Bitwise, only_operators: true

  alias RrbTree.Node, as: Node

  @m 2 # Integer: tree branching exponent, as in 2^m. E.g, m = 2 so branching factor of 4.

  @b (1 <<< @m)

  @e 1 # Maximum extra steps on radix search miss

  defstruct h: 1,   # the tree height. Leaf nodes have height = 1.
            node: %Node{}

  def concat(%RrbTree{} = ltree, %RrbTree{} = rtree) do
    do_concat(ltree.node, rtree.node, ltree.h, rtree.h)
  end

  # Given two subtrees, returns a balanced tree
  def make_tree(nodes, h) do
    a = Enum.count(nodes)
    p = Enum.reduce(nodes, 0, fn node, sum -> count_items(node) + sum end)
    extra_steps = a - ((p - 1) >>> @m) - 1

    nodes |> balance(extra_steps) |> root(h)
  end

  def root(nodes, h) do
    do_root(nodes, %RrbTree{
      h: h,
      node: %Node{}
    })
  end

  def do_root([], root) do
    root
  end

  def do_root(nodes, root = %RrbTree{node: %Node{slots: root_slots}}) when tuple_size(root_slots) == @b do
    nr = root(nodes, root.h)

    %RrbTree{
      h: root.h + 1,
      node: %Node{
        ranges: { last_range(root.node.ranges), last_range(root.node.ranges) + last_range(nr.node.ranges) },
        slots: { root.node, nr.node }
      }
    }
  end

  def do_root([node = %Node{} | nodes], root = %RrbTree{}) do
    do_root(nodes,
      %{root |
        node: %{ root.node |
          slots: append(root.node.slots, node),
          ranges: append(root.node.ranges, last_range(root.node.ranges) + last_range(node.ranges))
        }
      }
    )
  end

  # TODO: remove duplication of logic for Leaf and Nodes
  def do_root([node | nodes], root = %RrbTree{}) do
    do_root(nodes,
      %{root |
        node: %{ root.node |
          slots: append(root.node.slots, node),
          ranges: append(root.node.ranges, last_range(root.node.ranges) + tuple_size(node)) # TODO: check if || works as expected
        }
      }
    )
  end

  def last_range(ranges) when tuple_size(ranges) == 0 do
    0
  end

  def last_range(ranges) do
    last(ranges)
  end

  def balance(nodes, extra_steps) do
    balance(nodes, extra_steps, [])
  end

  def balance([], _e, result) do
    Enum.reverse(result)
  end

  def balance([x | xs], e, result) when e <= @e do
    balance(xs, e, [x | result])
  end

  def balance([x1 = %Node{}, x2 = %Node{slots: slots} | xs], extra_steps, result) when tuple_size(slots) == 0 do
    balance(xs, extra_steps - 1, [x1 | result])
  end

  def balance([x1 = %Node{slots: slots}, x2 | xs], extra_steps, result) when tuple_size(slots) == @b do
    balance([x2 | xs], extra_steps, [x1 | result])
  end

  def balance([x1 = %Node{slots: slots}, x2 | xs], extra_steps, result) when tuple_size(slots) < @b do
    [x1, x2] = join_nodes(x1, x2)
    balance([x1, x2 | xs], extra_steps, result)
  end

  # TODO: Leaf only
  def balance([x1, x2 | xs], e, result) when tuple_size(x2) == 0 do
    balance(xs, e - 1, [x1 | result])
  end

  def balance([x1, x2 | xs], e, result) when tuple_size(x1) == @b do
    balance([x2 | xs], e, [x1 | result])
  end

  def balance([x1, x2 | xs], extra_steps, result) when tuple_size(x1) < @b do
    [x1, x2] = join_nodes(x1, x2)
    balance([x1, x2 | xs], extra_steps, result)
  end

  # TODO: Node only
  def join_nodes(n1 = %Node{slots: n1_slots}, n2 = %Node{slots: n2_slots}) when tuple_size(n1_slots) == @b or tuple_size(n2_slots) == 0 do
    [n1, n2]
  end

  # TODO: try not to generate many nodes untill have a full node
  # TODO: handle leafs differently then internal nodes
  def join_nodes(n1 = %Node{}, n2 = %Node{}) do
    join_nodes(
      %Node{
        ranges: Tuple.insert_at(n1.ranges, tuple_size(n1.ranges), elem(n2.ranges, tuple_size(n2.ranges) - 1) + elem(n1.ranges, tuple_size(n1.ranges) - 1)),
        slots: Tuple.insert_at(n1.slots, tuple_size(n1.slots), elem(n2.slots, 0))
      },
      %Node{
        ranges: delete_first_range(n2.ranges),
        slots: Tuple.delete_at(n2.slots, 0)
      }
    )
  end

  # TODO: Leaf only
  def join_nodes(n1, n2) when tuple_size(n1) == @b or tuple_size(n2) == 0 do
    [n1, n2]
  end

  def join_nodes(n1, n2) do
    join_nodes(
      append(n1, elem(n2, 0)),
      Tuple.delete_at(n2, 0)
    )
  end

  def count_items(%Node{} = node) do
    tuple_size(node.slots)
  end

  def count_items(leaf) do
    tuple_size(leaf)
  end

  def do_concat(%Node{} = ltree, %Node{} = rtree, _hl = 2, _hr = 2) do
    make_tree(Tuple.to_list(ltree.slots) ++ Tuple.to_list(rtree.slots), 2)
  end

  def do_concat(%Node{} = ltree, %Node{} = rtree, hl, hr) when hl == hr do
    mtree = do_concat(rhand(ltree), lhand(rtree), hl - 1, hr - 1)

    # TODO: check correctness when mtree.h > ltree.h OR mtree.h > rtree.h
    if mtree.h == hl do
      # IO.puts "mtree.h > hl #{inspect mtree}"
      make_tree(Tuple.to_list(lbody(ltree).slots) ++ Tuple.to_list(mtree.node.slots) ++ Tuple.to_list(rbody(rtree).slots), hl)
    else
      # IO.puts "else \nlbody #{inspect(lbody(ltree))}\n mtree #{inspect(mtree)} \n rbody #{inspect(rbody(rtree))}"
      # make_tree([lbody(ltree), mtree.node, rbody(rtree)], hl)
    end
  end

  def do_concat(%Node{} = ltree, %Node{} = rtree, hl, hr) when hl > hr do
    mtree = do_concat(rhand(ltree), rtree, hl - 1, hr)

    make_tree(Tuple.to_list(lbody(ltree).slots) ++ Tuple.to_list(mtree.node.slots), hl)
  end

  def do_concat(%Node{} = ltree, %Node{} = rtree, hl, hr) when hl < hr do
    mtree = do_concat(ltree, lhand(rtree), hl, hr - 1)

    make_tree(Tuple.to_list(mtree.node.slots) ++ Tuple.to_list(rbody(rtree).slots), hr)
  end

  def rhand(%Node{} = node) do
    last(node.slots)
  end

  def lhand(%Node{} = node) do
    first(node.slots)
  end

  def lbody(%Node{ranges: ranges, slots: slots}) do
    %Node{
      ranges: Tuple.delete_at(ranges, tuple_size(ranges) - 1),
      slots: Tuple.delete_at(slots, tuple_size(slots) - 1)
    }
  end

  def rbody(%Node{ranges: ranges, slots: slots}) do
    %Node{
      ranges: delete_first_range(ranges),
      slots: Tuple.delete_at(slots, 0)
    }
  end

  def delete_first_range(ranges) do
    fst = elem(ranges, 0)

    Tuple.delete_at(ranges, 0)
      |> Tuple.to_list
      |> Enum.reduce({}, fn(r, rs) -> append(rs, r - fst) end)
  end

  def first(tuple) do
    elem(tuple, 0)
  end

  def last(tuple) do
    elem(tuple, tuple_size(tuple) - 1)
  end

  def append(tuple, e) do
    Tuple.insert_at(tuple, tuple_size(tuple), e)
  end

  #defp do_concat(%RrbTree{h: hl} = ltree, %RrbTree{h: hr} = rtree) when hl > hr do
  #  mtree = do_concat(rhand(ltree), rtree)
  #  make_tree(ltree, mtree)
  #end

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
