defmodule XmlStream do
  def element(name, attrs, body) do
    Stream.concat([[{:open, name, attrs}], body, [{:close, name}]])
  end

  def const(value) do
    [{:const, value}]
  end

  def stream(node) do
    Stream.transform(node, [], fn i, acc ->
      if is_tuple(i) do
        {[print(i)], acc}
      else
        {stream(i), acc}
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
