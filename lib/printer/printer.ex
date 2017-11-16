defmodule XmlStream.Print do
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
    alias XmlStream.Print, as: P
    @behaviour Printer

    def init(),  do: {0, false}

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

    defp indent(level, indent_with \\ "\t") do
      String.duplicate(indent_with, level)
    end

    defp safe_subtract(num) do
      if num > 0, do: num - 1, else: 0
    end

    defp calculate_alignment(node, {level, last}) do
      case elem(node, 0) do
        :open -> {{level + 1, false}, ["\n", indent(level)]}
        :const -> {{safe_subtract(level), true}, []}
        :close ->
          if last do
            {{level, false}, []}
          else
            {{safe_subtract(level), false}, ["\n", indent(safe_subtract(level))]}
          end
        :empty_elem -> {{level, false}, ["\n", indent(level)]}
        _ -> {{level, false}, [indent(level)]}
      end
    end
  end

  defmodule Ugly do
    alias XmlStream.Print, as: P
    @behaviour Printer

    def init(), do: nil

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
