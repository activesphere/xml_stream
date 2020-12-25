# XmlStream

[![Hex.pm](https://img.shields.io/hexpm/v/xml_stream.svg)](https://hex.pm/packages/xml_stream)

An Elixir library for building XML document in a streaming fashion.


### Use cases

There are cases where constructing the whole XML document in memory is
a not viable option. Exporting records as a xlsx document is a good
example. This library provides primitives to build XML document
as a [stream](https://hexdocs.pm/elixir/Stream.html). Please see
[documentation](https://hexdocs.pm/xml_stream) for more information.
