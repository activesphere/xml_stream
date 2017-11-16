defmodule XmlStreamTest do
  require Logger
  use ExUnit.Case
  doctest XmlStream
  import XmlStream
  import SweetXml, only: [sigil_x: 2, xpath: 2, parse: 1]

  # Helper functions, constants
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

  defp pretty_out(indent_with \\ "\t") do
    doc_string(@sample_xml, [printer: XmlStream.Print.Pretty, indent_with: indent_with])
  end

  defp ugly_out() do
    doc_string(@sample_xml)
  end

  defp assert_xpath(doc, path, expected) do
    assert xpath(doc, path) == expected
  end

  def memory_now do
    (:erlang.memory() |> Keyword.fetch!(:total)) / (1024 * 1024)
  end

  # Tests
  test "Pretty Print (tabs)" do
    expected_pretty = """
<?xml version="1.0" encoding="UTF-8"?>
<workbook date="false"/>
<sheet>
	<row/>
	<row>
		<cell foo="bar">1</cell>
		<cell/>
	</row>
	<row>
		<cell/>
		<cell foo="bar">1</cell>
	</row>
	<row/>
</sheet>
"""

    assert expected_pretty == pretty_out() <> "\n"
  end

  test "Pretty Print (spaces)" do
    expected_pretty = """
<?xml version="1.0" encoding="UTF-8"?>
<workbook date="false"/>
<sheet>
 <row/>
 <row>
  <cell foo="bar">1</cell>
  <cell/>
 </row>
 <row>
  <cell/>
  <cell foo="bar">1</cell>
 </row>
 <row/>
</sheet>
"""
    assert expected_pretty == pretty_out(" ") <> "\n"
  end

  test "Ugly Print" do
    expected_ugly = ~S(<?xml version="1.0" encoding="UTF-8"?><workbook date="false"/><sheet><row/><row><cell foo="bar">1</cell><cell/></row><row><cell/><cell foo="bar">1</cell></row><row/></sheet>)

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

  test "Memory Usage" do
    rows = Stream.map(1..1000, fn i ->
      cells = Stream.map(1..40, fn j ->
        element("cell", %{row: to_string(i), column: to_string(j)}, content(to_string(i)))
      end)
      element("row", cells)
    end)

    usage_before = memory_now()
    Logger.debug "Memory usage before: #{usage_before}"
    stream([declaration(), element("sheet", rows)], [printer: XmlStream.Print.Pretty])
    |> Stream.run

    usage_after = memory_now()
    Logger.debug "Memory usage after: #{usage_after}"
    assert usage_after - usage_before <= 5
  end

  test "Pretty Printer indent level" do
    broken_elem = element("pre", [content("foo"), empty_element("br")])
    broken_xml = List.insert_at(@sample_xml, 2, broken_elem)
    stream(broken_xml, [printer: XmlStream.Print.Pretty])
    |> Stream.run
  end
end
