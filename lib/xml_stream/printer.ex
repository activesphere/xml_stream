defmodule XmlStream.Printer do
  alias XmlStream.EncodeError

  @callback print(term, term) :: {iodata, term}
  @callback init(term) :: term

  @doc false
  def attrs_to_string(attrs) do
    Enum.map(attrs, fn {key, value} ->
      [" ", encode_name(key), ~s(="), escape_binary(to_string(value)), ~s(")]
    end)
  end

  @doc false
  def escape_binary(""), do: []
  def escape_binary("&" <> rest), do: ["&amp;" | escape_binary(rest)]
  def escape_binary("\"" <> rest), do: ["&quot;" | escape_binary(rest)]
  def escape_binary("'" <> rest), do: ["&apos;" | escape_binary(rest)]
  def escape_binary("<" <> rest), do: ["&lt;" | escape_binary(rest)]
  def escape_binary(">" <> rest), do: ["&gt;" | escape_binary(rest)]
  def escape_binary(<<char::utf8>> <> rest), do: [<<char::utf8>> | escape_binary(rest)]

  @doc false
  def escape_cdata(""), do: []
  def escape_cdata("]]>" <> rest), do: ["]]]]><![CDATA[>" | escape_cdata(rest)]
  def escape_cdata(<<char::utf8>> <> rest), do: [<<char::utf8>> | escape_cdata(rest)]

  @doc false
  def encode_comment(text) do
    validate_comment!(text)
    text
  end

  defp validate_comment!(""), do: :ok
  defp validate_comment!("-"), do: raise(EncodeError, message: "comment can't end with '-'")

  defp validate_comment!("--" <> _),
    do: raise(EncodeError, message: "'--' is not allowed inside a comment")

  defp validate_comment!(<<_char::utf8>> <> rest), do: validate_comment!(rest)

  @doc false
  def encode_name(name) do
    name = to_string(name)
    validate_name!(name)
    name
  end

  @doc false
  def pi_target_name(name) do
    if String.downcase(name) == "xml" do
      raise EncodeError, message: "'xml' is a reserved name"
    else
      encode_name(name)
    end
  end

  defp validate_name!(""), do: raise(EncodeError, message: "Invalid tag name")

  defp validate_name!(<<char::utf8>> <> rest) do
    validate_name_start!(char)
    validate_name_rest!(rest)
  end

  defp validate_name_start!(char)
       when char in [?:, ?_] or
              char in ?A..?Z or
              char in ?a..?z or
              char in 0xC0..0xD6 or
              char in 0xD8..0xF6 or
              char in 0xF8..0x2FF or
              char in 0x370..0x37D or
              char in 0x37F..0x1FFF,
       do: :ok

  defp validate_name_start!(char)
       when char in 0x200C..0x200D or
              char in 0x2070..0x218F or
              char in 0x2C00..0x2FEF or
              char in 0x3001..0xD7FF or
              char in 0xF900..0xFDCF or
              char in 0xFDF0..0xFFFD or
              char in 0x10000..0xEFFFF,
       do: :ok

  defp validate_name_start!(char),
    do: raise(EncodeError, message: "Invalid tag name start character", value: char)

  defp validate_name_rest!(""), do: :ok

  defp validate_name_rest!(<<char::utf8>> <> rest)
       when char in [?:, ?_, ?-, ?., 0xB7] or
              char in ?0..?9 or
              char in ?A..?Z or
              char in ?a..?z or
              char in 0xC0..0xD6 or
              char in 0xD8..0xF6 or
              char in 0xF8..0x37D or
              char in 0x37F..0x1FFF,
       do: validate_name_rest!(rest)

  defp validate_name_rest!(<<char::utf8>> <> rest)
       when char in 0x200C..0x200D or
              char in 0x203F..0x2040 or
              char in 0x2070..0x218F or
              char in 0x2C00..0x2FEF or
              char in 0x3001..0xD7FF or
              char in 0xF900..0xFDCF or
              char in 0xFDF0..0xFFFD or
              char in 0x10000..0xEFFFF,
       do: validate_name_rest!(rest)

  defp validate_name_rest!(<<char::utf8>> <> _rest),
    do: raise(EncodeError, message: "Invalid tag name character", value: char)
end
