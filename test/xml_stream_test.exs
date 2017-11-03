defmodule XmlStreamTest do
  use ExUnit.Case
  doctest XmlStream
  import XmlStream

  test "node" do
    rows = Stream.map(1..100, fn i ->
      cells = Stream.map(1..100, fn i ->
        node("cell", %{}, const(to_string(i)))
      end)
      node("row", %{}, children(cells))
    end)

    stream(node("sheet", %{}, children(rows)))
    |> Stream.each(fn items ->
      IO.write Enum.map(items, &print/1)
    end)
    |> Stream.run
  end
end
