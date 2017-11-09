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
    printer = if options.pretty,
      do: Module.concat(options.printer, Pretty),
      else: Module.concat(options.printer, Minified)

    nodes_stream = stream_builder(node)
    Stream.transform(nodes_stream, [], fn i, acc ->
      if options.pretty do
        {acc, level} = update_acc(acc, i)
        {[printer.print(i, level)], acc}
      else
        {[printer.print(i)], acc}
      end
    end)
  end

  defp update_acc(stack, i) do
    if stack == [] do
      {[i] ++ stack, 0}
    else
      curr_type = elem(i, 0)
      curr_name = elem(i, 1)
      prev_name = elem(hd(stack), 1)

      cond do
        curr_type == :const ->
          {stack, length(stack)}
        curr_type == :close && curr_name == prev_name ->
          {tl(stack), length(stack) - 1}
        true ->
          {[i] ++ stack, length(stack)}
      end
    end
  end
end
