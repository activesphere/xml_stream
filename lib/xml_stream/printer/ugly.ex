defmodule XmlStream.Printer.Ugly do
  alias XmlStream.Printer, as: P
  @behaviour XmlStream.Printer

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
