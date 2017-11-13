defmodule XmlStream.Print do
  def attrs_to_string(attrs) do
    Enum.map(attrs, fn {key, value} ->
      [" ", to_string(key), "=", wrap_quotes(escape(value))]
    end)
  end

  def wrap_quotes(string) do
    ~s(") <> string <> ~s(")
  end

  def escape(data) do
    to_string(data)
    |> :binary.replace("&", "&amp;", [:global])
    |> :binary.replace("\"", "&quot;", [:global])
    |> :binary.replace("'", "&apos;", [:global])
    |> :binary.replace("<", "&lt;", [:global])
    |> :binary.replace(">", "&gt;", [:global])
  end

  defmodule Pretty do
    alias XmlStream.Print, as: P
    @behaviour Printer

    def init(),  do: {[], 0}

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

    def print(node, acc) do
      {acc, newline} = update_acc(node, acc)
      level = elem(acc, 1)
      if newline do
        {["\n", indent(level), print(node)], acc}
      else
        {[print(node)], acc}
      end
    end

    defp indent(level, indent_with \\ "\t") do
      String.duplicate(indent_with, level)
    end

    defp update_acc(curr, {prev, level}) do
      curr_name = elem(curr, 1)
      curr_type = elem(curr, 0)
      if prev == [] do
        cond do
          curr_type == :decl ->
            {{prev, 0}, false}
          curr_type == :empty_elem ->
            {{prev, level}, true}
          true ->
            {{curr, 0}, true}
        end
      else
        prev_name = elem(prev, 1)
        cond do
          curr_type == :const ->
            {{prev, level}, false}
          curr_type == :empty_elem ->
            {{prev, level}, true}
          curr_type == :close ->
            if curr_name == prev_name do
              {{curr, level}, false}
            else
              {{curr, level - 1}, true}
            end
          curr_type == :open && curr_name == prev_name ->
            {{curr, level}, true}
          true ->
            {{curr, level + 1}, true}
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
