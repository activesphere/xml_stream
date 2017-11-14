defmodule XmlStreamTest do
  use ExUnit.Case
  doctest XmlStream
  import XmlStream
  import SweetXml, only: [sigil_x: 2, xpath: 2, parse: 1]

  def assert_xpath(doc, path, expected) do
    assert xpath(doc, path) == expected
  end

  test "node" do
    rows = Stream.map(1..2, fn i ->
      cells = Stream.map(1..2, fn j ->
        element("cell", %{row: to_string(i), column: to_string(j)}, content(to_string(i)))
      end)
      element("row", cells)
    end)

    options = [
      printer: XmlStream.Print.Pretty
    ]

    stream([declaration(), empty_element("workbook", %{date: "false"}), element("sheet", rows)], options)
    |> Stream.each(fn item ->
      IO.write item
    end)
    |> Stream.run
  end

  test "escape" do
    rows = Stream.map(1..2, fn i ->
      cells = Stream.map(1..2, fn _ ->
        attrs = %{prop1: "'foo", prop2: "bar\"", prop3: "baz&", prop4: ">"}
        content_text = case i do
                         1 -> "&<"
                         2 -> "<&"
                         true -> ""
                       end
        element("cell", attrs, content(content_text <> to_string(i)))
      end)
      element("row", cells)
    end)

    options = [
      printer: XmlStream.Print.Ugly
    ]

    xml_string = stream([declaration(), element("sheet", rows)], options)
    |> Enum.to_list()
    |> Enum.join("")

    doc = parse(xml_string)
    # First row text, should be '&<1'
    assert_xpath(doc, ~x"//sheet/row/cell/text()", '&<1')

    # Second row text, should be '<&2'
    assert_xpath(doc, ~x"//sheet/row[2]/cell/text()", '<&2')

    # Attributes
    assert_xpath(doc, ~x"//sheet/row/cell/@prop1", '\'foo')
    assert_xpath(doc, ~x"//sheet/row/cell/@prop2", 'bar"')
    assert_xpath(doc, ~x"//sheet/row/cell/@prop3", 'baz&')
    assert_xpath(doc, ~x"//sheet/row/cell/@prop4", '>')
  end
end
