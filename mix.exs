defmodule XmlStream.Mixfile do
  use Mix.Project

  @version "0.3.0"

  def project do
    [
      app: :xml_stream,
      version: @version,
      elixir: "~> 1.4",
      start_permanent: Mix.env() == :prod,
      description: "Streaming XML builder",
      package: package(),
      docs: docs(),
      dialyzer: [
        plt_add_deps: :transitive,
        flags: [:unmatched_returns, :race_conditions, :error_handling, :underspecs]
      ],
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      {:sweet_xml, "~> 0.6", only: [:dev, :test]},
      {:exprof, "~> 0.2.0", only: :dev}
    ]
  end

  defp package do
    %{
      licenses: ["MIT"],
      links: %{"Github" => "https://github.com/activesphere/xml_stream"},
      maintainers: ["ananthakumaran@gmail.com", "shinde.rohitt@gmail.com"]
    }
  end

  defp docs do
    [
      source_url: "https://github.com/activesphere/xml_stream",
      source_ref: "v#{@version}",
      main: XmlStream,
      extras: ["README.md"]
    ]
  end
end
