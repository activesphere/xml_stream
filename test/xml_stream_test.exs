defmodule XmlStreamTest do
  use ExUnit.Case
  doctest XmlStream
  import XmlStream

  test "node" do
    rows = Stream.map(1..100, fn i ->
      cells = Stream.map(1..100, fn j ->
        element("cell", %{row: to_string(i), column: to_string(j)}, const(to_string(i)))
      end)
      element("row", %{}, cells)
    end)

    stream(element("sheet", %{}, rows))
    |> Stream.each(fn item ->
      IO.write item
    end)
    |> Stream.run
  end
end
