defmodule Canary.Interface.Ask do
  @callback run(any(), String.t(), function(), keyword()) :: {:ok, map()} | {:error, any()}

  def run(project, query, handle_delta, opts \\ []) do
    impl().run(project, query, handle_delta, opts)
  end

  defp impl(), do: Application.get_env(:canary, :interface_ask, Canary.Interface.Ask.Default)
end

defmodule Canary.Interface.Ask.Default do
  @behaviour Canary.Interface.Ask

  alias Canary.Index.Trieve

  def run(project, query, handle_delta, opts) do
    client = Trieve.client(project)
    opts = opts |> Keyword.put(:rag, true)

    {:ok, groups} = client |> Trieve.search(query, opts)

    results =
      groups
      |> Enum.take(5)
      |> Enum.map(fn %{"chunks" => chunks, "group" => %{"tracking_id" => group_id}} ->
        Task.async(fn ->
          matched_chunk_ids = chunks |> Enum.map(& &1["chunk"]["id"])

          case Trieve.get_chunks(client, group_id) do
            {:ok, %{"chunks" => full_chunks}} ->
              indices =
                full_chunks
                |> Enum.map(& &1["id"])
                |> Enum.with_index()
                |> Enum.filter(fn {id, _index} -> Enum.member?(matched_chunk_ids, id) end)
                |> Enum.map(fn {_id, index} -> index end)

              full_chunks
              |> Enum.with_index()
              |> Enum.filter(fn {_chunk, index} -> Enum.any?(indices, &(abs(&1 - index) <= 2)) end)
              |> Enum.map(fn {chunk, _index} ->
                %{
                  "url" => chunk["link"],
                  "content" => chunk["chunk_html"],
                  "metadata" => chunk["metadata"]
                }
              end)

            _ ->
              nil
          end
        end)
      end)
      |> Task.await_many(3_000)
      |> Enum.reject(&is_nil/1)

    {:ok, pid} = Agent.start_link(fn -> "" end)

    {:ok, completion} =
      Canary.AI.chat(
        %{
          model: Application.fetch_env!(:canary, :responder_model),
          messages: [
            %{
              role: "system",
              content: Canary.Prompt.format("responder_system", %{})
            },
            %{
              role: "user",
              content: Jason.encode!(%{query: query, docs: results})
            }
          ],
          temperature: 0,
          frequency_penalty: 0.02,
          max_tokens: 5000,
          response_format: %{type: "json_object"},
          stream: handle_delta != nil
        },
        callback: fn data ->
          case data do
            %{"choices" => [%{"finish_reason" => reason}]}
            when reason in ["stop", "length", "eos"] ->
              :ok

            %{"choices" => [%{"delta" => %{"content" => content}}]} ->
              safe(handle_delta, {:delta, content})
              Agent.update(pid, &(&1 <> content))

            _ ->
              :ok
          end
        end
      )

    completion = if completion == "", do: Agent.get(pid, & &1), else: completion
    safe(handle_delta, {:done, completion})

    {:ok, %{response: completion}}
  end

  defp safe(func, arg) do
    if is_function(func, 1), do: func.(arg), else: :noop
  end
end
