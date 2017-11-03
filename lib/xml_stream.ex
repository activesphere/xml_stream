defmodule XmlStream do
  def node(name, attrs, body) do
    fn ->
      {
        [{:open, name, attrs}],
        [body, fn -> {[{:close, name}], []} end]
      }
    end
  end

  def children(bodies) do
    fn ->
      case Stream.take(bodies, 1) |> Enum.to_list do
        [body] -> {[], [body, children(Stream.drop(bodies, 1))]}
        [] -> {[], []}
      end
    end
  end

  def const(value) do
    fn ->
      {[{:const, value}], []}
    end
  end

  def stream(builder) do
    Stream.unfold({builder, []},
      fn {nil, _} -> nil
        {builder, stack} ->
          case builder.() do
            {items, [next | rest]} -> {items, {next, rest ++ stack}}
            {items, []} -> {items, {List.first(stack), Enum.drop(stack, 1)}}
          end
      end)
  end

  #TODO: escape according to spec
  def print({:open, name, attrs}) do
    attrs = Enum.map(attrs, fn {key, value} ->
      [" ", to_string(key), "=", inspect(value)]
    end)
    ["<", to_string(name), attrs, ">\n"]
  end
  def print({:close, name}) do
    ["</", to_string(name), ">\n"]
  end
  def print({:const, value}) do
    [value, "\n"]
  end
end
