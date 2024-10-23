defmodule Canary.Crawler do
  @callback run(String.t(), opts :: keyword()) :: {:ok, map()} | {:error, any()}
  @modules [Canary.Crawler.Visitor, Canary.Crawler.Sitemap]

  alias Canary.Sources.Webpage.Config

  def run(%Config{} = config) do
    @modules
    |> Enum.reduce_while({:error, :failed}, fn module, _acc ->
      case module.run(config) do
        {:ok, stream} -> {:halt, {:ok, stream}}
        _ -> {:cont, {:error, :failed}}
      end
    end)
  end

  def run!(config) do
    {:ok, result} = run(config)
    result
  end

  def include?(url, %Config{} = config) do
    cond do
      Enum.any?(config.url_exclude_patterns, &Canary.Native.glob_match(&1, url)) ->
        false

      Enum.empty?(config.url_include_patterns) ->
        true

      true ->
        Enum.any?(config.url_include_patterns, &Canary.Native.glob_match(&1, url))
    end
  end

  def normalize_url(url) do
    url
    |> URI.parse()
    |> Map.put(:query, nil)
    |> Map.put(:fragment, nil)
    |> URI.to_string()
    |> String.replace_trailing("/", "")
  end

  def req() do
    Canary.rest_client(user_agent: "Canary (github.com/fastrepl/canary)")
    |> Canary.Req.MetaRefresh.attach()
    |> Canary.Req.Cache.attach(cachex: :cache, ttl: :timer.minutes(30))
  end
end

defmodule Canary.Crawler.Sitemap do
  alias Canary.Crawler
  alias Canary.Sources.Webpage.Config

  def run(%Config{} = config) do
    urls =
      config.start_urls
      |> Enum.flat_map(&list_sitemaps/1)
      |> Enum.flat_map(&parse_sitemap/1)

    if urls == [] do
      {:error, :not_found}
    else
      async_opts = [ordered: false, max_concurrency: 10, timeout: 10_000]

      stream =
        urls
        |> Stream.filter(&Canary.Crawler.include?(&1, config))
        |> Task.async_stream(
          fn url ->
            html =
              case Crawler.req() |> Req.get(url: url) do
                {:ok, %{status: 200, body: body}} -> body
                _ -> nil
              end

            {Crawler.normalize_url(url), html}
          end,
          async_opts
        )
        |> Stream.filter(&match?({:ok, _}, &1))
        |> Stream.map(fn {:ok, result} -> result end)

      {:ok, stream}
    end
  end

  def list_sitemaps(url) do
    robots_url = URI.new!(url) |> Map.put(:path, "/robots.txt") |> URI.to_string()
    maybe_sitemap = URI.new!(url) |> Map.put(:path, "/sitemap.xml") |> URI.to_string()

    case Canary.rest_client() |> ReqCrawl.Robots.attach() |> Req.get(url: robots_url) do
      {:ok, %{private: %{crawl_robots: %{sitemaps: urls}}}} -> [maybe_sitemap | urls]
      _ -> [maybe_sitemap]
    end
  end

  defp parse_sitemap(sitemap_url) do
    urls =
      case Canary.rest_client() |> ReqCrawl.Sitemap.attach() |> Req.get(url: sitemap_url) do
        {:ok, %{private: %{crawl_sitemap: {:sitemap, list}}}} -> list
        {:ok, %{private: %{crawl_sitemap: {:sitemapindex, list}}}} -> list
        _ -> []
      end

    urls
    |> Enum.flat_map(fn url ->
      if String.contains?(url, "sitemap") and String.ends_with?(url, ".xml") do
        parse_sitemap(url)
      else
        [url]
      end
    end)
  end
end

defmodule Canary.Crawler.Visitor do
  alias Canary.Crawler
  alias Canary.Sources.Webpage.Config

  def run(%Config{} = config) do
    stream =
      config.start_urls
      |> Enum.map(&crawl(&1, config))
      |> Flow.from_enumerables(max_demand: 1, stages: length(config.start_urls))
      |> Flow.map(fn {url, %Req.Response{} = response, _state} ->
        {Crawler.normalize_url(url), response.body}
      end)
      |> Flow.filter(fn {url, _body} -> Canary.Crawler.include?(url, config) end)
      |> Flow.stream(link: true)
      |> Stream.uniq_by(fn {url, _body} -> url end)

    {:ok, stream}
  end

  def crawl(url, crawler_config) do
    config = url |> Hop.new() |> Map.get(:config) |> Keyword.put(:crawler_config, crawler_config)

    url
    |> Hop.new(config: config)
    |> Hop.prefetch(&prefetch/3)
    |> Hop.fetch(&fetch/3)
    |> Hop.next(&next/4)
    |> Hop.stream()
  end

  defp fetch(url, state, opts) do
    crawler_config = opts[:crawler_config]
    puppeteer = Application.get_env(:canary, :puppeteer)

    if not is_nil(puppeteer) and crawler_config.js_render do
      proxy_url =
        URI.parse(puppeteer[:base_url])
        |> Map.put(:path, "/api/render")
        |> URI.to_string()

      opts = [
        url: proxy_url,
        headers: [{"Authorization", "Bearer #{puppeteer[:api_key]}"}],
        params: [url: url],
        receive_timeout: 10_000
      ]

      with {:ok, response} <- Crawler.req() |> Req.get(opts) do
        {:ok, response, state}
      end
    else
      with {:ok, response} <- Crawler.req() |> Req.get(url: url, receive_timeout: 5_000) do
        {:ok, response, state}
      end
    end
  end

  defp prefetch(url, state, opts) do
    {:ok, url}
    |> Hop.validate_hostname(state, opts)
    |> Hop.validate_scheme(state, opts)
    |> Hop.validate_content(state, opts)
    |> validate_status(state, opts)
  end

  defp next(url, %Req.Response{body: body} = resp, state, opts) do
    is_html =
      resp
      |> Req.Response.get_header("content-type")
      |> Enum.any?(&String.contains?(&1, "text/html"))

    if is_html do
      crawler_config = opts[:crawler_config]

      links =
        find_links(url, body)
        |> Enum.filter(&Crawler.include?(&1, crawler_config))

      {:ok, links, state}
    else
      {:ok, [], state}
    end
  end

  defp find_links(url, html) do
    case Floki.parse_document(html) do
      {:ok, doc} ->
        doc
        |> Floki.find("a")
        |> Floki.attribute("href")
        |> Enum.map(fn href ->
          URI.merge(url, href)
          |> Map.put(:query, nil)
          |> Map.put(:fragment, nil)
          |> URI.to_string()
          |> URI.encode()
        end)
        |> Enum.reject(&(URI.parse(&1).host != URI.parse(url).host))
        |> Enum.uniq()

      _error ->
        []
    end
  end

  defp validate_status({:ok, url}, _state, _opts) do
    case Crawler.req() |> Req.get(url: url, receive_timeout: 7_000) do
      {:ok, %Req.Response{status: status}} when status in 200..299 -> {:ok, url}
      _error -> {:error, :invalid_status}
    end
  end

  defp validate_status(value, _state, _opts), do: value
end
