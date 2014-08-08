defmodule RrbTreeTest do
  use ExUnit.Case

  test "index by radix" do
    t = {
      2,
      2,
      {4, 8, 12, 16},
      {
        {1, 2, 3, 4},
        {5, 6, 7, 8},
        {9, 10, 11, 12},
        {13, 14, 15, 16}
      }
    }

    assert RrbTree.get(t, 5) == 6
  end

  test "index is the first item in a leaf" do
    t = {
      2,
      2,
      {4, 8, 12, 16},
      {
        {1, 2, 3, 4},
        {5, 6, 7, 8},
        {9, 10, 11, 12},
        {13, 14, 15, 16}
      }
    }

    assert RrbTree.get(t, 0) == 1
    assert RrbTree.get(t, 4) == 5
  end

  test "index with internal nodes and slot misses" do
    t = {
      3,
      2,
      {15, 31},
      {
        {
          {4, 8, 12, 15},
          {
            {1, 2, 3, 4},
            {5, 6, 7, 8},
            {9, 10, 11, 12},
            {13, 14, 15}
          }
        },
        {
          {4, 8, 12, 16},
          {
            {16, 17, 18, 19},
            {20, 21, 22, 23},
            {24, 25, 26, 27},
            {28, 29, 30, 31}
          }
        }
      }
    }

    assert RrbTree.get(t, 15) == 16
  end

  test "linear search fallback when radix miss" do
    t = {
      2,
      2,
      {3, 6, 10, 11},
      {
        {1, 2, 3},
        {4, 5, 6},
        {7, 8, 9, 10},
        {11}
      }
    }

    assert RrbTree.get(t, 3) == 4
  end
end
