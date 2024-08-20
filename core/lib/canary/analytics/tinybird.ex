defmodule Canary.Analytics do
  defp client() do
    base_url = Application.get_env(:canary, :tinybird) |> Keyword.fetch!(:base_url)
    api_key = Application.get_env(:canary, :tinybird) |> Keyword.fetch!(:api_key)

    Req.new(
      base_url: base_url,
      headers: [{"Authorization", "Bearer #{api_key}"}]
    )
  end

  def event(source, data) do
    result =
      client()
      |> Req.post(
        url: "/v0/events?name=#{source}",
        json: data |> Map.merge(%{timestamp: DateTime.to_iso8601(DateTime.utc_now())})
      )

    case result do
      {:ok, %{status: 202, body: %{"quarantined_rows" => rows}}} when rows > 0 ->
        {:error, :quarantined}

      {:ok, %{status: 202, body: body}} ->
        {:ok, body}

      error ->
        error
    end
  end
end

defmodule Canary.Analytics.FeedbackPage do
  @derive Jason.Encoder
  defstruct [:host, :path, :score, :account_id, :fingerprint, :timestamp]
end
