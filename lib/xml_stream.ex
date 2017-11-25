defmodule XmlStream do
  @moduledoc """
  This module provides primitives to build XML document as a `Stream`

  ## Example

      import XmlStream

      rows = Stream.map(1..1000, fn i ->
        cells = Stream.map(1..40, fn j ->
          element("cell", %{row: to_string(i), column: to_string(j)}, content(to_string(i)))
        end)
        element("row", cells)
      end)

      stream!([declaration(), element("sheet", rows)], printer: XmlStream.Printer.Ugly)
      |> Stream.into(File.stream!("sheet.xml"))
      |> Stream.run


  The body of an element could be either a eager `Enumerable` or a
  lazy one built via `Stream` module. The primitive functions like
  `element/3`, `content/1` are used to build a tree structure where
  some nodes are not fully evaluated (child nodes could a
  stream). `stream!/2` does a depth first traversal of the tree and
  runs the stream as necessary when it encounters one and returns a
  new stream of element type `iodata`
  """

  @typedoc """
  Could be either `Keyword` or `map`. Order of the attributes are
  preserved in case of `Keyword`
  """
  @type attrs :: map | Keyword.t
  @opaque fragment :: [tuple | fragment]

  @typedoc """
  The elements of `Enumerable` should be of type `t:fragment/0`
  """
  @type body :: Enumerable.t

  @spec declaration(attrs) :: fragment
  def declaration(attrs \\ [version: "1.0", encoding: "UTF-8"]) do
    [{:decl, attrs}]
  end

  @spec empty_element(String.t, attrs) :: fragment
  def empty_element(name, attrs \\ %{}) do
    [{:empty_elem, name, attrs}]
  end

  @spec element(String.t, body) :: fragment
  def element(name, body) do
    element(name, %{}, body)
  end
  @spec element(String.t, attrs, body) :: fragment
  def element(name, attrs, body) do
    [{:open, name, attrs}, body, {:close, name}]
  end

  @spec processing_instruction(String.t, attrs) :: fragment
  def processing_instruction(name, attrs \\ %{}) do
    [{:pi, name, attrs}]
  end

  @spec comment(String.t) :: fragment
  def comment(text) do
    [{:comment, text}]
  end

  @spec cdata(String.t) :: fragment
  def cdata(text) do
    [{:cdata, text}]
  end

  @spec doctype(String.t, String.t) :: fragment
  def doctype(root_name, declaration) do
    [{:doctype, root_name, declaration}]
  end

  @spec content(String.t) :: fragment
  def content(text) do
    [{:const, text}]
  end

  @default_options [printer: XmlStream.Printer.Ugly, indent_with: "\t"]

  @doc """
  Creates a xml document stream.

  ## Options

  * `:printer` (module) - The printer that should be used for formatting
  Available options are `XmlStream.Printer.Pretty` and `XmlStream.Printer.Ugly`

  * `:indent_with` (string) - The string that should be used for indentation. Defaults to `"\\t"`.
  """
  @spec stream!(fragment, Keyword.t) :: Enumerable.t
  def stream!(nodes, options \\ []) do
    options = Keyword.merge(@default_options, options)
    printer = options[:printer]
    flatten(nodes)
    |> Stream.transform(printer.init(options), &printer.print/2)
  end

  defp flatten(node) do
    Stream.flat_map(node, fn
      operation when is_tuple(operation) -> [operation]
      operation -> flatten(operation)
    end)
  end
end
