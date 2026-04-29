defmodule XmlStream.Printer do
  alias XmlStream.EncodeError

  @callback print(term, term) :: {iodata, term}
  @callback init(term) :: term

  @doc false
  def attrs_to_string([]), do: []

  def attrs_to_string(attrs) do
    Enum.reduce(attrs, <<>>, fn {key, value}, acc ->
      acc <> " " <> encode_name(key) <> ~s(=") <> escape_binary(to_string(value)) <> ~s(")
    end)
  end

  @doc false
  def escape_binary(binary) when is_binary(binary), do: escape_binary(binary, binary)

  defp escape_binary(<<>>, original), do: original

  defp escape_binary(<<?&, rest::bits>>, original) do
    pos = byte_size(original) - byte_size(rest) - 1
    escape_binary(rest, original, pos + 1, 0, binary_part(original, 0, pos) <> "&amp;")
  end

  defp escape_binary(<<?", rest::bits>>, original) do
    pos = byte_size(original) - byte_size(rest) - 1
    escape_binary(rest, original, pos + 1, 0, binary_part(original, 0, pos) <> "&quot;")
  end

  defp escape_binary(<<?', rest::bits>>, original) do
    pos = byte_size(original) - byte_size(rest) - 1
    escape_binary(rest, original, pos + 1, 0, binary_part(original, 0, pos) <> "&apos;")
  end

  defp escape_binary(<<?<, rest::bits>>, original) do
    pos = byte_size(original) - byte_size(rest) - 1
    escape_binary(rest, original, pos + 1, 0, binary_part(original, 0, pos) <> "&lt;")
  end

  defp escape_binary(<<?>, rest::bits>>, original) do
    pos = byte_size(original) - byte_size(rest) - 1
    escape_binary(rest, original, pos + 1, 0, binary_part(original, 0, pos) <> "&gt;")
  end

  defp escape_binary(<<char, rest::bits>>, original) when char < 0x80,
    do: escape_binary(rest, original)

  defp escape_binary(<<_::utf8, rest::bits>>, original), do: escape_binary(rest, original)

  defp escape_binary(<<>>, _original, _skip, 0, acc), do: acc
  defp escape_binary(<<>>, original, skip, len, acc), do: acc <> binary_part(original, skip, len)

  defp escape_binary(<<?&, rest::bits>>, original, skip, 0, acc),
    do: escape_binary(rest, original, skip + 1, 0, acc <> "&amp;")

  defp escape_binary(<<?&, rest::bits>>, original, skip, len, acc),
    do:
      escape_binary(
        rest,
        original,
        skip + len + 1,
        0,
        acc <> binary_part(original, skip, len) <> "&amp;"
      )

  defp escape_binary(<<?", rest::bits>>, original, skip, 0, acc),
    do: escape_binary(rest, original, skip + 1, 0, acc <> "&quot;")

  defp escape_binary(<<?", rest::bits>>, original, skip, len, acc),
    do:
      escape_binary(
        rest,
        original,
        skip + len + 1,
        0,
        acc <> binary_part(original, skip, len) <> "&quot;"
      )

  defp escape_binary(<<?', rest::bits>>, original, skip, 0, acc),
    do: escape_binary(rest, original, skip + 1, 0, acc <> "&apos;")

  defp escape_binary(<<?', rest::bits>>, original, skip, len, acc),
    do:
      escape_binary(
        rest,
        original,
        skip + len + 1,
        0,
        acc <> binary_part(original, skip, len) <> "&apos;"
      )

  defp escape_binary(<<?<, rest::bits>>, original, skip, 0, acc),
    do: escape_binary(rest, original, skip + 1, 0, acc <> "&lt;")

  defp escape_binary(<<?<, rest::bits>>, original, skip, len, acc),
    do:
      escape_binary(
        rest,
        original,
        skip + len + 1,
        0,
        acc <> binary_part(original, skip, len) <> "&lt;"
      )

  defp escape_binary(<<?>, rest::bits>>, original, skip, 0, acc),
    do: escape_binary(rest, original, skip + 1, 0, acc <> "&gt;")

  defp escape_binary(<<?>, rest::bits>>, original, skip, len, acc),
    do:
      escape_binary(
        rest,
        original,
        skip + len + 1,
        0,
        acc <> binary_part(original, skip, len) <> "&gt;"
      )

  defp escape_binary(<<char, rest::bits>>, original, skip, len, acc) when char < 0x80,
    do: escape_binary(rest, original, skip, len + 1, acc)

  defp escape_binary(<<cp::utf8, rest::bits>>, original, skip, len, acc) when cp < 0x800,
    do: escape_binary(rest, original, skip, len + 2, acc)

  defp escape_binary(<<cp::utf8, rest::bits>>, original, skip, len, acc) when cp < 0x10000,
    do: escape_binary(rest, original, skip, len + 3, acc)

  defp escape_binary(<<_::utf8, rest::bits>>, original, skip, len, acc),
    do: escape_binary(rest, original, skip, len + 4, acc)

  @doc false
  def escape_cdata(binary) when is_binary(binary) do
    escape_cdata(binary, binary, 0, 0)
  end

  defp escape_cdata(<<>>, original, 0, _len), do: original
  defp escape_cdata(<<>>, original, skip, len), do: [binary_part(original, skip, len)]

  defp escape_cdata(<<"]]>", rest::bits>>, original, skip, 0),
    do: ["]]]]><![CDATA[>" | escape_cdata(rest, original, skip + 3, 0)]

  defp escape_cdata(<<"]]>", rest::bits>>, original, skip, len),
    do: [
      binary_part(original, skip, len),
      "]]]]><![CDATA[>" | escape_cdata(rest, original, skip + len + 3, 0)
    ]

  defp escape_cdata(<<char, rest::bits>>, original, skip, len) when char < 0x80,
    do: escape_cdata(rest, original, skip, len + 1)

  defp escape_cdata(<<cp::utf8, rest::bits>>, original, skip, len) when cp < 0x800,
    do: escape_cdata(rest, original, skip, len + 2)

  defp escape_cdata(<<cp::utf8, rest::bits>>, original, skip, len) when cp < 0x10000,
    do: escape_cdata(rest, original, skip, len + 3)

  defp escape_cdata(<<_::utf8, rest::bits>>, original, skip, len),
    do: escape_cdata(rest, original, skip, len + 4)

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
  def encode_name(name) when is_binary(name) do
    validate_name!(name)
    name
  end

  def encode_name(name) when is_atom(name) do
    encode_name(Atom.to_string(name))
  end

  def encode_name(name), do: encode_name(to_string(name))

  @doc false
  def pi_target_name(<<x, m, l>>)
      when (x === ?x or x === ?X) and (m === ?m or m === ?M) and (l === ?l or l === ?L) do
    raise EncodeError, message: "'xml' is a reserved name"
  end

  def pi_target_name(name), do: encode_name(name)

  defp validate_name!(""), do: raise(EncodeError, message: "Invalid tag name")

  defp validate_name!(<<char, rest::bits>>)
       when char in ?A..?Z or char in ?a..?z or char === ?_ or char === ?: do
    validate_name_rest!(rest)
  end

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

  defp validate_name_rest!(<<char, rest::bits>>)
       when char in ?A..?Z or char in ?a..?z or char in ?0..?9 or
              char === ?_ or char === ?: or char === ?- or char === ?. do
    validate_name_rest!(rest)
  end

  defp validate_name_rest!(<<char::utf8>> <> rest)
       when char === 0xB7 or
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
