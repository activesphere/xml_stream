defmodule XmlStream do

  def declaration(attrs \\ [version: "1.0", encoding: "UTF-8"]) do
    [{:decl, attrs}]
  end

  def empty_element(name, args \\ %{}) do
    [{:empty_elem, name, args}]
  end

  def element(name, body) do
    element(name, %{}, body)
  end
  def element(name, attrs, body) do
    [[{:open, name, attrs}], body, [{:close, name}]]
  end

  def processing_instruction(name, attrs \\ %{}) do
    [{:pi, name, attrs}]
  end

  def comment(text) do
    [{:comment, text}]
  end

  def cdata(data) do
    [{:cdata, data}]
  end

  def doctype(root_name, declaration) do
    [{:doctype, root_name, declaration}]
  end

  def content(value) do
    [{:const, value}]
  end

  @default_options [printer: XmlStream.Printer.Ugly, indent_with: "\t"]
  def stream(node, options \\ []) do
    options = Keyword.merge(@default_options, options)
    printer = options[:printer]
    nodes_stream = stream_builder(node)
    Stream.transform(nodes_stream, printer.init(options), &printer.print/2)
  end

  defp stream_builder(node) do
    Stream.flat_map(node, fn
      operation when is_tuple(operation) -> [operation]
      operation -> stream_builder(operation)
    end)
  end
end
