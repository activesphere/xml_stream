defmodule XmlStream.Print do
  def attrs_to_string(attrs) do
    Enum.map(attrs, fn {key, value} ->
      [" ", to_string(key), "=", quote_attribute_value(value)]
    end)
  end

  #TODO: Escape according to spec
  defp quote_attribute_value(val) do
    double = String.contains?(val, ~s|"|)
    single = String.contains?(val, "'")
    escaped = escape(val)

    cond do
      double && single ->
        escaped |> String.replace("\"", "&quot;") |> quote_attribute_value
      double -> "'#{escaped}'"
      true -> ~s|"#{escaped}"|
    end
  end

  def escape(string) do
    string
    |> String.replace(">", "&gt;")
    |> String.replace("<", "&lt;")
    |> replace_ampersand
  end

  defp replace_ampersand(string) do
    Regex.replace(~r/&(?!lt;|gt;|quot;)/, string, "&amp;")
  end

  defmodule Pretty do
    alias XmlStream.Print, as: P
    @behaviour Printer

    def init(),  do: {[], 0}

    def print({:open, name, attrs}) do
      ["<", to_string(name), P.attrs_to_string(attrs), ">\n"]
    end

    def print({:close, name}) do
      ["</", to_string(name), ">\n"]
    end

    def print({:decl, attrs}) do
      ["<?xml", P.attrs_to_string(attrs), "?>\n"]
    end

    def print({:empty_elem, name, attrs}) do
      ["<", to_string(name), P.attrs_to_string(attrs), "/>\n"]
    end

    def print({:const, value}) do
      [P.escape(value), "\n"]
    end

    def print(node, acc) do
      acc = update_acc(node, acc)
      level = elem(acc, 1)
      {[indent(level), print(node)], acc}
    end

    defp indent(level, indent_with \\ "\t") do
      String.duplicate(indent_with, level)
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
          curr_type == :decl ->
            {prev, level}
          curr_type == :empty_elem ->
            {prev, level}
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

  defmodule Ugly do
    alias XmlStream.Print, as: P
    @behaviour Printer

    def init(), do: nil

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
      [P.escape(value)]
    end

    def print(node, _) do
      {print(node), nil}
    end
  end
end
