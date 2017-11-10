defmodule XmlStream do

  def declaration(attrs \\ %{version: "1.0", encoding: "UTF-8"}) do
    [{:decl, attrs}]
  end

  def empty_element(name, args \\ %{}) do
    [{:empty_elem, name, args}]
  end

  def element(name, body) do
    element(name, %{}, body)
  end
  def element(name, attrs, body) do
    Stream.concat([[{:open, name, attrs}], body, [{:close, name}]])
  end

  def content(value) do
    [{:const, value}]
  end

  def stream(node, options) do
    printer = options[:printer]
    nodes_stream = stream_builder(node)
    acc = printer.init()
    Stream.transform(nodes_stream, acc, fn i, acc ->
      printer.print(i, acc)
    end)
  end

  defp stream_builder(node) do
    Stream.flat_map(node, fn operation ->
      if is_tuple(operation) do
        [operation]
      else
        stream_builder(operation)
      end
    end)
  end
end
