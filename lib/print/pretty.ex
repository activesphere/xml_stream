defmodule XmlStream.Print.Pretty do
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

  def print(node, level) do
    [indent(level)] ++ print(node)
  end

  defp indent(level, indent_with \\ "\t") do
    String.duplicate(indent_with, level)
  end
end
