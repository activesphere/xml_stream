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

  def content(value) do
    [{:const, value}]
  end

  def stream(node, options) do
    printer = options[:printer]
    nodes_stream = stream_builder(node)
    Stream.transform(nodes_stream, printer.init(), &printer.print/2)
  end

  defp stream_builder(node) do
    Stream.flat_map(node, fn
      operation when is_tuple(operation) -> [operation]
      operation -> stream_builder(operation)
    end)
  end
end
