defmodule XmlStream.EncodeError do
  @type t :: %__MODULE__{message: String.t, value: any}

  defexception message: nil, value: nil

  def message(%{message: nil, value: value}) do
    "unable to encode value: #{inspect(value)}"
  end

  def message(%{message: message, value: nil}) do
    message
  end

  def message(%{message: message, value: value}) do
    message <> " value: " <> to_string([value])
  end
end
