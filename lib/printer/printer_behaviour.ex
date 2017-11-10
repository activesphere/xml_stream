defmodule Printer do
  @type element_types :: :open | :const | :close
  @type attrs :: %{required(String.t) => String.t}
  @type element :: {element_types, String.t, attrs}
  @type acc :: {element, number}

  @callback print(element, acc | nil) :: {[String.t], acc | nil}
  @callback init() :: term
end
