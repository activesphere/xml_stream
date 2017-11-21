defmodule XmlStream.Printer.Ugly do
  alias XmlStream.Printer, as: P
  @behaviour XmlStream.Printer

  def init(_), do: nil

  def print({:open, name, attrs}, _) when attrs == %{} or attrs == [] do
    {["<", P.encode_name(name), ">"], nil}
  end
  def print({:open, name, attrs}, _) do
    {["<", P.encode_name(name), P.attrs_to_string(attrs), ">"], nil}
  end

  def print({:close, name}, _) do
    {["</", P.encode_name(name), ">"], nil}
  end

  def print({:decl, attrs}, _) do
    {["<?xml", P.attrs_to_string(attrs), "?>"], nil}
  end

  def print({:pi, target, attrs}, _) when attrs == %{} do
    {["<?", P.pi_target_name(target), "?>"], nil}
  end

  def print({:pi, target, attrs}, _) do
    {["<?", P.pi_target_name(target), P.attrs_to_string(attrs), "?>"], nil}
  end

  def print({:comment, text}, _) do
    {["<!-- ", text, " -->"], nil}
  end

  def print({:cdata, data}, _) do
    {["<![CDATA[", data, "]]>"], nil}
  end

  def print({:doctype, root_name, declaration}, _) do
    {["<!DOCTYPE ", P.encode_name(root_name), " ", declaration, ">"], nil}
  end

  def print({:empty_elem, name, attrs}, _) when attrs == %{} or attrs == [] do
    {["<", P.encode_name(name), "/>"], nil}
  end
  def print({:empty_elem, name, attrs}, _) do
    {["<", P.encode_name(name), P.attrs_to_string(attrs), "/>"], nil}
  end

  def print({:const, value}, _) do
    {[P.escape_binary(to_string(value))], nil}
  end
end
