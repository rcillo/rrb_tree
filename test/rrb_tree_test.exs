defmodule RrbTreeTest do
  use ExUnit.Case
  alias RrbTree.Node, as: Node

  test "index by radix" do
    t = %RrbTree{h: 2,
      node: %Node{
        ranges: {4, 8, 12, 16},
        slots: {
          {1, 2, 3, 4},
          {5, 6, 7, 8},
          {9, 10, 11, 12},
          {13, 14, 15, 16}
        }
      }
    }

    assert RrbTree.get(t, 5) == 6
  end

  test "index is the first item in a leaf" do
    t = %RrbTree{
      h: 2,
      node: %Node{
        ranges: {4, 8, 12, 16},
        slots: {
          {1, 2, 3, 4},
          {5, 6, 7, 8},
          {9, 10, 11, 12},
          {13, 14, 15, 16}
        }
      }
    }

    assert RrbTree.get(t, 0) == 1
    assert RrbTree.get(t, 4) == 5
  end

  test "index with internal nodes and slot misses" do
    t = %RrbTree{
      h: 3,
      node: %Node{ ranges: {15, 31},
      slots: {
        %Node{
          ranges: {4, 8, 12, 15},
          slots: {
            {1, 2, 3, 4},
            {5, 6, 7, 8},
            {9, 10, 11, 12},
            {13, 14, 15}
          }
        },
        %Node{
          ranges: {4, 8, 12, 16},
          slots: {
            {16, 17, 18, 19},
            {20, 21, 22, 23},
            {24, 25, 26, 27},
            {28, 29, 30, 31}
          }
        }
      }}
    }

    assert RrbTree.get(t, 15) == 16
  end

  test "linear search fallback when radix miss" do
    t = %RrbTree{
      h: 2,
      node: %Node{ranges: {3, 6, 10, 11},
      slots: {
        {1, 2, 3},
        {4, 5, 6},
        {7, 8, 9, 10},
        {11}
      }}
    }

    assert RrbTree.get(t, 3) == 4
  end

  test "concatenates two tree of the same height" do
    lt = %RrbTree{h: 2,
      node: %Node{
        ranges: {4, 8, 12, 16},
        slots: {
          {1, 2, 3, 4},
          {5, 6, 7, 8},
          {9, 10, 11, 12},
          {13, 14, 15, 16}
        }
      }
    }

    rt = lt

    t = %RrbTree{
      h: 3,
      node: %Node{
        ranges: {16, 32},
        slots: {lt.node, rt.node}
      }
    }

    assert RrbTree.concat(lt, rt) == t
  end

  test "concatenate hiegher trees" do
    t2 = %RrbTree{h: 2,
      node: %Node{
        ranges: {4, 8, 12, 16},
        slots: {
          {1, 2, 3, 4},
          {5, 6, 7, 8},
          {9, 10, 11, 12},
          {13, 14, 15, 16}
        }
      }
    }

    t3 = %RrbTree{
      h: 3,
      node: %Node{
        ranges: {16, 32},
        slots: {t2.node, t2.node}
      }
    }

    t = %RrbTree{
      h: 3,
      node: %Node{
        ranges: {16, 32, 48, 64},
        slots: {t2.node, t2.node, t2.node, t2.node}
      }
    }

    assert RrbTree.concat(t3, t3) == t
  end

  test "paper figure 7 example" do
    t1 = %RrbTree{h: 2,
      node: %Node{
        ranges: {3, 7, 10, 14},
        slots: {
          {1, 2, 3},
          {4, 5, 6, 7},
          {8, 9, 10},
          {11, 12, 13, 14}
        }
      }
    }

    t2 = %RrbTree{h: 2,
      node: %Node{
        ranges: {4, 6},
        slots: {
          {1, 2, 3, 4},
          {5, 6}
        }
      }
    }

    t3 = %RrbTree{h: 2,
      node: %Node{
        ranges: {3, 5, 7, 10},
        slots: {
          {1, 2, 3},
          {4, 5},
          {6, 7},
          {8, 9 , 10}
        }
      }
    }

    t4 = %RrbTree{h: 2,
      node: %Node{
        ranges: {3, 7},
        slots: {
          {1, 2, 3},
          {4, 5, 6, 7}
        }
      }
    }

    t1_2 = %RrbTree{h: 3,
      node: %Node{
        ranges: {14, 20},
        slots: {t1.node, t2.node}
      }
    }

    t3_4 = %RrbTree{h: 3,
      node: %Node{
        ranges: {10, 17},
        slots: {t3.node, t4.node}
      }
    }

    t = %RrbTree{h: 3,
            node: %RrbTree.Node{ranges: {14, 27, 30, 37},
             slots: {%RrbTree.Node{ranges: {3, 7, 10, 14}, slots: {{1, 2, 3}, {4, 5, 6, 7}, {8, 9, 10}, {11, 12, 13, 14}}},
              %RrbTree.Node{ranges: {4, 8, 11, 13}, slots: {{1, 2, 3, 4}, {5, 6, 1, 2}, {3, 4, 5}, {6, 7}}}, %RrbTree.Node{ranges: {3}, slots: {{8, 9, 10}}},
              %RrbTree.Node{ranges: {3, 7}, slots: {{1, 2, 3}, {4, 5, 6, 7}}}}}}

    assert RrbTree.concat(t1_2, t3_4) == t
  end

  test "left tree higher than right tree" do
    t = %RrbTree{h: 2,
      node: %Node{
        ranges: {4, 8, 12, 16},
        slots: {
          {1, 2, 3, 4},
          {5, 6, 7, 8},
          {9, 10, 11, 12},
          {13, 14, 15, 16}
        }
      }
    }

   lt = %RrbTree{
      h: 3,
      node: %Node{
        ranges: {16, 32},
        slots: {t.node, t.node}
      }
    }


    rt = %RrbTree{h: 2,
      node: %Node{
        ranges: {4},
        slots: {
          {1, 2, 3, 4}
        }
      }
    }

    assert RrbTree.concat(lt, rt) == %RrbTree{h: 3,
      node: %Node{
        ranges: {16, 32, 36},
        slots: {t.node, t.node, rt.node}
      }
    }
  end

  test "left lower higher than right tree" do
    t = %RrbTree{h: 2,
      node: %Node{
        ranges: {4, 8, 12, 16},
        slots: {
          {1, 2, 3, 4},
          {5, 6, 7, 8},
          {9, 10, 11, 12},
          {13, 14, 15, 16}
        }
      }
    }

    lt = %RrbTree{h: 2,
      node: %Node{
        ranges: {4},
        slots: {
          {1, 2, 3, 4}
        }
      }
    }

    rt = %RrbTree{
      h: 3,
      node: %Node{
        ranges: {16, 32},
        slots: {t.node, t.node}
      }
    }

    assert RrbTree.concat(lt, rt) == %RrbTree{h: 3,
            node: %RrbTree.Node{ranges: {16, 20, 36},
             slots: {%RrbTree.Node{ranges: {4, 8, 12, 16}, slots: {{1, 2, 3, 4}, {1, 2, 3, 4}, {5, 6, 7, 8}, {9, 10, 11, 12}}},
              %RrbTree.Node{ranges: {4}, slots: {{13, 14, 15, 16}}},
              %RrbTree.Node{ranges: {4, 8, 12, 16}, slots: {{1, 2, 3, 4}, {5, 6, 7, 8}, {9, 10, 11, 12}, {13, 14, 15, 16}}}}}}
  end

  test "concat with empty tree" do
    t = %RrbTree{h: 2,
      node: %Node{
        ranges: {4},
        slots: {
          {1, 2, 3, 4}
        }
      }
    }

    assert RrbTree.concat(%RrbTree{}, t) == t
    assert t == RrbTree.concat(%RrbTree{}, t)
  end

  test "add element" do
    t = %RrbTree{h: 2,
      node: %Node{
        ranges: {1},
        slots: {
          {1}
        }
      }
    }

    assert RrbTree.add(t, 2) == %RrbTree{h: 2,
      node: %Node{
        ranges: {1, 2},
        slots: {
          {1}, {2}
        }
      }
    }
  end

  test "update element" do
    t = %RrbTree{
      h: 3,
      node: %Node{ ranges: {15, 31},
      slots: {
        %Node{
          ranges: {4, 8, 12, 15},
          slots: {
            {1, 2, 3, 4},
            {5, 6, 7, 8},
            {9, 10, 11, 12},
            {13, 14, 15}
          }
        },
        %Node{
          ranges: {4, 8, 12, 16},
          slots: {
            {16, 17, 18, 19},
            {20, 21, 22, 23},
            {24, 25, 26, 27},
            {28, 29, 30, 31}
          }
        }
      }}
    }

    assert RrbTree.update(t, 18, :a) == %RrbTree{
      h: 3,
      node: %Node{ ranges: {15, 31},
      slots: {
        %Node{
          ranges: {4, 8, 12, 15},
          slots: {
            {1, 2, 3, 4},
            {5, 6, 7, 8},
            {9, 10, 11, 12},
            {13, 14, 15}
          }
        },
        %Node{
          ranges: {4, 8, 12, 16},
          slots: {
            {16, 17, 18, :a},
            {20, 21, 22, 23},
            {24, 25, 26, 27},
            {28, 29, 30, 31}
          }
        }
      }}
    }
  end

  test "delete index" do
    t = %RrbTree{h: 2,
      node: %Node{
        ranges: {4, 8, 12, 16},
        slots: {
          {1, 2, 3, 4},
          {5, 6, 7, 8},
          {9, 10, 11, 12},
          {13, 14, 15, 16}
        }
      }
    }

    assert RrbTree.delete(t, 5) == %RrbTree{h: 2,
      node: %Node{
        ranges: {4, 7, 11, 15},
        slots: {
          {1, 2, 3, 4},
          {5, 7, 8},
          {9, 10, 11, 12},
          {13, 14, 15, 16}
        }
      }
    }
  end

  test "delete removes empty node" do
    t = %RrbTree{h: 2,
      node: %Node{
        ranges: {4, 8, 12, 16},
        slots: {
          {1, 2, 3, 4},
          {5},
          {9, 10, 11, 12},
          {13, 14, 15, 16}
        }
      }
    }

    nt = t |> RrbTree.delete(4)

    assert nt == %RrbTree{h: 2,
      node: %Node{
        ranges: {4, 8, 12},
        slots: {
          {1, 2, 3, 4},
          {9, 10, 11, 12},
          {13, 14, 15, 16}
        }
      }
    }
  end

  # TODO: test case when the tree height gets decreases

  test "split" do
    t = %RrbTree{h: 2,
      node: %Node{
        ranges: {4, 8, 12, 16},
        slots: {
          {1, 2, 3, 4},
          {5, 6, 7, 8},
          {9, 10, 11, 12},
          {13, 14, 15, 16}
        }
      }
    }

    assert RrbTree.split(t, 6) == [
      %RrbTree{h: 2,
        node: %Node{
          ranges: {4, 6},
          slots: { {1, 2, 3, 4}, {5, 6} }
        }
      },
      %RrbTree{h: 2,
        node: %Node{
          ranges: {2, 6, 10},
          slots: { {7, 8}, {9, 10, 11, 12}, {13, 14, 15, 16} }
        }
      }
    ]
  end

  # TODO: test split edge cases: beggining or end of node
end
