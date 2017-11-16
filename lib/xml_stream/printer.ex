defmodule XmlStream.Printer do
  @callback print(term, term) :: {iodata, term}
  @callback init(term) :: term

  def attrs_to_string(attrs) do
    Enum.map(attrs, fn {key, value} ->
      [" ", to_string(key), ~s(="), escape_binary(to_string(value)), ~s(")]
    end)
  end

  def escape_binary(""), do: []
  def escape_binary("&" <> rest), do: ["&amp;" | escape_binary(rest)]
  def escape_binary("\"" <> rest), do: ["&quot;" | escape_binary(rest)]
  def escape_binary("'" <> rest), do: ["&apos;" | escape_binary(rest)]
  def escape_binary("<" <> rest), do: ["&lt;" | escape_binary(rest)]
  def escape_binary(">" <> rest), do: ["&gt;" | escape_binary(rest)]
  def escape_binary(<<char :: utf8>> <> rest), do: [char | escape_binary(rest)]
end
