defmodule XmlStream.Print.Minified do
  #TODO: escape according to spec
  def print({:open, name, attrs}) do
    attrs = Enum.map(attrs, fn {key, value} ->
      [" ", to_string(key), "=", inspect(value)]
    end)
    ["<", to_string(name), attrs, ">"]
  end

  def print({:close, name}) do
    ["</", to_string(name), ">"]
  end

  def print({:const, value}) do
    [value]
  end

  def print(node) do
    print(node)
  end
end
