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

    rt = %RrbTree{h: 2,
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

    t = %RrbTree{
      h: 3,
      node: %Node{
        ranges: {16, 32},
        slots: {lt.node, rt.node}
      }
    }

    assert RrbTree.concat(lt, rt) == t
  end
end
