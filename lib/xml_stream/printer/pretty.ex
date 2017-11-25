defmodule XmlStream.Printer.Pretty do
  alias XmlStream.Printer, as: P
  @behaviour XmlStream.Printer

  def init(options \\ [indent_with: "\t"]) do
    # {indent-level, last-was-constant?, first-element?, options}
    {0, false, true, options[:indent_with]}
  end

  defp print({:open, name, attrs}) do
    ["<", P.encode_name(name), P.attrs_to_string(attrs), ">"]
  end

  defp print({:close, name}) do
    ["</", P.encode_name(name), ">"]
  end

  defp print({:decl, attrs}) do
    ["<?xml", P.attrs_to_string(attrs), "?>"]
  end

  defp print({:empty_elem, name, attrs}) do
    ["<", P.encode_name(name), P.attrs_to_string(attrs), "/>"]
  end

  defp print({:pi, target, attrs}) when attrs == %{} do
    ["<?", P.pi_target_name(target), "?>"]
  end

  defp print({:pi, target, attrs}) do
    ["<?", P.pi_target_name(target), P.attrs_to_string(attrs), "?>"]
  end

  defp print({:comment, text}) do
    ["<!--", P.encode_comment(text), "-->"]
  end

  defp print({:cdata, data}) do
    ["<![CDATA[", P.escape_cdata(data), "]]>"]
  end

  defp print({:doctype, root_name, declaration}) do
    ["<!DOCTYPE ", P.encode_name(root_name), " ", declaration, ">"]
  end

  defp print({:const, value}) do
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

  defp calculate_alignment(node, {level, last_const, true, indent_with}) do
    {{level, false, false, indent_with}, []}
  end
  defp calculate_alignment(node, {level, last, _, indent_with}) do
    case elem(node, 0) do
      :open -> {{level + 1, false, false, indent_with}, ["\n", indent(level, indent_with)]}
      x when x in [:const, :comment, :cdata] -> {{safe_subtract(level), true, false, indent_with}, []}
      :close ->
        if last do
          {{level, false, false, indent_with}, []}
        else
          new_level = safe_subtract(level)
          {{new_level, false, false, indent_with}, ["\n", indent(new_level, indent_with)]}
        end
      :empty_elem -> {{level, false, false, indent_with}, ["\n", indent(level, indent_with)]}
      _ -> {{level, false, false, indent_with}, ["\n", indent(level, indent_with)]}
    end
  end
end
