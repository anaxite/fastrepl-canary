defmodule CanaryWeb.InsightLive.Index do
  use CanaryWeb, :live_view
  alias PrimerLive.Component, as: Primer

  def render(%{can_use_insights?: false} = assigns) do
    ~H"""
    <div class="w-full h-[calc(100vh-200px)] bg-gray-100 rounded-sm flex flex-col items-center justify-center">
      <p class="text-lg">You don't have access to <span class="text-underline">Insights</span>.</p>
      <p>
        Learn more about our plans <.link navigate={~p"/billing"}>here</.link>.
      </p>
    </div>
    """
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-col gap-4">
      <Primer.subhead>
        Insights
        <:actions>
          <Primer.button is_primary phx-click={Primer.open_dialog("insights-config-dialog")}>
            Config
          </Primer.button>
        </:actions>
      </Primer.subhead>

      <Primer.dialog id="insights-config-dialog" is_backdrop>
        <:header_title>Config</:header_title>
        <:body>
          <.live_component
            id="insights-config"
            module={CanaryWeb.InsightLive.Config}
            current_project={@current_project}
            quries={if @search_breakdown.result, do: @search_breakdown.result.labels, else: []}
          />
        </:body>
      </Primer.dialog>

      <div class={["w-full h-60", if(@search_volume.loading, do: "animate-pulse bg-gray-100")]}>
        <canvas
          :if={!@search_volume.loading}
          id="search-volume"
          phx-hook="BarChart"
          data-title="Search Volume"
          data-labels={Jason.encode!(@search_volume.result.labels)}
          data-points={Jason.encode!(@search_volume.result.points)}
        >
        </canvas>
      </div>

      <div class={["w-full h-60", if(@search_breakdown.loading, do: "animate-pulse bg-gray-100")]}>
        <canvas
          :if={!@search_breakdown.loading}
          id="search-breakdown"
          phx-hook="BarChart"
          data-title="Search Breakdown"
          data-labels={Jason.encode!(@search_breakdown.result.labels)}
          data-points={Jason.encode!(@search_breakdown.result.points)}
        >
        </canvas>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    can_use_insights? = Canary.Membership.can_use_insights?(socket.assigns.current_account)

    project_id = socket.assigns.current_project.public_key
    current_project = socket.assigns.current_project |> Ash.load!(:insights_config)

    aliases =
      if current_project.insights_config do
        current_project.insights_config.aliases || []
      else
        []
      end

    socket =
      socket
      |> assign(can_use_insights?: can_use_insights?)
      |> assign(current_project: current_project)
      |> assign_async(:search_volume, fn ->
        case Canary.Analytics.query("search_volume", %{project_id: project_id}) do
          {:ok, data} ->
            result = %{
              labels: Enum.map(data, & &1["date"]),
              points: Enum.map(data, & &1["count"])
            }

            {:ok, %{search_volume: result}}
        end
      end)
      |> assign_async(:search_breakdown, fn ->
        case Canary.Analytics.query("search_breakdown", %{project_id: project_id}) do
          {:ok, data} ->
            map =
              data
              |> Enum.reduce(%{}, fn %{"query" => query, "count" => count}, acc ->
                key =
                  aliases
                  |> Enum.find(fn %{members: members} -> query in members end)
                  |> then(fn
                    %{name: name} -> name
                    _ -> query
                  end)

                acc
                |> Map.update(key, count, &(&1 + count))
              end)

            result =
              map
              |> Enum.sort_by(fn {_, count} -> count end, :desc)
              |> Enum.unzip()
              |> then(fn {keys, counts} -> %{labels: keys, points: counts} end)

            {:ok, %{search_breakdown: result}}
        end
      end)

    {:ok, socket}
  end
end
