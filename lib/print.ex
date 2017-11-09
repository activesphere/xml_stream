defmodule XmlStream.Print do



  defmodule Pretty do
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

  defmodule Minified do
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

    def print(node, _) do
      print(node)
    end
  end

end
