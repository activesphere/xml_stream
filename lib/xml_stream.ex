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
      acc = update_acc(i, acc)
      level = elem(acc, 1)
      {[printer.print(i, level)], acc}
    end)
  end

  defp update_acc(curr, {prev, level}) do
    if prev == [] do
      {curr, 0}
    else
      curr_type = elem(curr, 0)
      curr_name = elem(curr, 1)
      prev_name = elem(prev, 1)
      cond do
        curr_type == :const ->
          {prev, level + 1}
        curr_type == :close ->
          {curr, level - 1}
        curr_type == :open && curr_name == prev_name ->
          {curr, level}
        true ->
          {curr, level + 1}
      end
    end
  end
end
