defmodule XmlStream do
  def element(name, attrs, body) do
    Stream.concat([[{:open, name, attrs}], body, [{:close, name}]])
  end

  def const(value) do
    [{:const, value}]
  end

  def stream_builder(node) do
    Stream.transform(node, [], fn i, acc ->
      if is_tuple(i) do
        {[i], acc}
      else
        {stream_builder(i), acc}
      end
    end)
  end

  def stream(node, options) do
    printer = options.printer
    nodes_stream = stream_builder(node)
    acc = {[], 0}
    Stream.transform(nodes_stream, acc, fn i, acc ->
      printer.print(i, acc)
    end)
  end
end
