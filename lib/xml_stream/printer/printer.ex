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


  defmodule Pretty do
    alias XmlStream.Printer, as: P
    @behaviour Printer

    def init(options \\ [indent_with: "\t"]) do
      {0, false, options}
    end

    def print({:open, name, attrs}) do
      ["<", to_string(name), P.attrs_to_string(attrs), ">"]
    end

    def print({:close, name}) do
      ["</", to_string(name), ">"]
    end

    def print({:decl, attrs}) do
      ["<?xml", P.attrs_to_string(attrs), "?>"]
    end

    def print({:empty_elem, name, attrs}) do
      ["<", to_string(name), P.attrs_to_string(attrs), "/>"]
    end

    def print({:const, value}) do
      [P.escape_binary(to_string(value))]
    end

    def print(node, acc) do
      {acc, alignment} = calculate_alignment(node, acc)
      {[alignment, print(node)], acc}
    end

    defp indent(level, indent_with) do
      String.duplicate(indent_with, level)
    end

    defp safe_subtract(num) do
      if num > 0, do: num - 1, else: 0
    end

    defp calculate_alignment(node, {level, last, opt}) do
      indent_with = opt[:indent_with]
      case elem(node, 0) do
        :open -> {{level + 1, false, opt}, ["\n", indent(level, indent_with)]}
        :const -> {{safe_subtract(level), true, opt}, []}
        :close ->
          if last do
            {{level, false, opt}, []}
          else
            new_level = safe_subtract(level)
            {{new_level, false, opt}, ["\n", indent(new_level, indent_with)]}
          end
        :empty_elem -> {{level, false, opt}, ["\n", indent(level, indent_with)]}
        _ -> {{level, false, opt}, [indent(level, indent_with)]}
      end
    end
  end

  defmodule Ugly do
    alias XmlStream.Printer, as: P
    @behaviour Printer

    def init(_), do: nil

    def print({:open, name, attrs}, _) when attrs == %{} or attrs == [] do
      {["<", to_string(name), ">"], nil}
    end
    def print({:open, name, attrs}, _) do
      {["<", to_string(name), P.attrs_to_string(attrs), ">"], nil}
    end

    def print({:close, name}, _) do
      {["</", to_string(name), ">"], nil}
    end

    def print({:decl, attrs}, _) do
      {["<?xml", P.attrs_to_string(attrs), "?>"], nil}
    end

    def print({:empty_elem, name, attrs}, _) when attrs == %{} or attrs == [] do
      {["<", to_string(name), "/>"], nil}
    end
    def print({:empty_elem, name, attrs}, _) do
      {["<", to_string(name), P.attrs_to_string(attrs), "/>"], nil}
    end

    def print({:const, value}, _) do
      {[P.escape_binary(to_string(value))], nil}
    end
  end
end
