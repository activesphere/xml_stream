defmodule XmlStreamTest do
  use ExUnit.Case
  doctest XmlStream
  import XmlStream
  import SweetXml, only: [sigil_x: 2, xpath: 2, parse: 1]

  test "Pretty Print" do
    expected_pretty = ~s(<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n) <>
      ~s(<workbook date=\"false\"/>\n<sheet>\n\t<row/>\n\t<row>\n\t\t) <>
      ~s(<cell foo=\"bar\">1</cell>\n\t\t<cell/>\n\t</row>\n\t<row>\n\t\t) <>
      ~s(<cell/>\n\t\t<cell foo=\"bar\">1</cell>\n\t</row>\n\t<row/>\n</sheet>)

    assert expected_pretty == pretty_out()
  end

  test "Ugly Print" do
    expected_ugly = ~s(<?xml version="1.0" encoding="UTF-8"?>) <>
      ~s(<workbook date="false"/><sheet><row/><row><cell foo="bar">1</cell>) <>
      ~s(<cell/></row><row><cell/><cell foo="bar">1</cell></row><row/></sheet>)

    assert expected_ugly == ugly_out()
  end

  test "Escapes" do
    common_attrs = %{prop1: "'foo", prop2: "bar\"", prop3: "baz&", prop4: ">"}
    doc = [
      declaration(),
      element("sheet",
        [
          element("row",
            [
              element("cell", common_attrs, content("&<1")),
              element("cell", common_attrs, content("1")),
            ]),
          element("row",
            [
              element("cell", common_attrs, content("<&2")),
              element("cell", common_attrs, content("<&2")),
            ]),
        ]
      )
    ]

    doc = parse(doc_string(doc))
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

  @sample_xml [
    declaration(),
    empty_element("workbook", %{date: "false"}),
    element("sheet",
      [empty_element("row"),
       element("row",
         [
           element("cell", %{foo: "bar"}, content("1")),
           empty_element("cell")
         ]),
       element("row",
         [
           empty_element("cell"),
           element("cell", %{foo: "bar"}, content("1")),
         ]),
       empty_element("row")
      ]
    )
  ]

  defp doc_string(elem_stream, options \\ [printer: XmlStream.Print.Ugly]) do
    stream(elem_stream, options)
    |> Enum.to_list
    |> Enum.join("")
  end

  defp pretty_out() do
    doc_string(@sample_xml, [printer: XmlStream.Print.Pretty])
  end

  defp ugly_out() do
    doc_string(@sample_xml)
  end

  defp assert_xpath(doc, path, expected) do
    assert xpath(doc, path) == expected
  end
end
