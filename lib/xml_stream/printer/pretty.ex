defmodule XmlStream.Printer.Pretty do
  alias XmlStream.Printer, as: P
  @behaviour XmlStream.Printer

  def init(options \\ [indent_with: "\t"]) do
    {0, false, options[:indent_with]}
  end

  def print({:open, name, attrs}) do
    ["<", P.encode_name(name), P.attrs_to_string(attrs), ">"]
  end

  def print({:close, name}) do
    ["</", P.encode_name(name), ">"]
  end

  def print({:decl, attrs}) do
    ["<?xml", P.attrs_to_string(attrs), "?>"]
  end

  def print({:empty_elem, name, attrs}) do
    ["<", P.encode_name(name), P.attrs_to_string(attrs), "/>"]
  end

  def print({:pi, target, attrs}) when attrs == %{} do
    ["<?", P.pi_target_name(target), "?>"]
  end

  def print({:pi, target, attrs}) do
    ["<?", P.pi_target_name(target), P.attrs_to_string(attrs), "?>"]
  end

  def print({:comment, text}) do
    ["<!-- ", text, " -->"]
  end

  def print({:cdata, data}) do
    ["<![CDATA[", data, "]]>"]
  end

  def print({:doctype, root_name, declaration}) do
    ["<!DOCTYPE ", P.encode_name(root_name), " ", declaration, ">"]
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

  defp calculate_alignment(node, {level, last, indent_with}) do
    case elem(node, 0) do
      :decl -> {{level, false, indent_with}, []}
      :open -> {{level + 1, false, indent_with}, ["\n", indent(level, indent_with)]}
      :const -> {{safe_subtract(level), true, indent_with}, []}
      :close ->
        if last do
          {{level, false, indent_with}, []}
        else
          new_level = safe_subtract(level)
          {{new_level, false, indent_with}, ["\n", indent(new_level, indent_with)]}
        end
      :empty_elem -> {{level, false, indent_with}, ["\n", indent(level, indent_with)]}
      _ -> {{level, false, indent_with}, ["\n", indent(level, indent_with)]}
    end
  end
end
