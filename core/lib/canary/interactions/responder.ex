defmodule Canary.Interactions.Responder do
  alias Canary.Interactions.Responder

  @callback run(
              session :: any(),
              query :: String.t(),
              client :: any(),
              handle_delta :: function()
            ) :: {:ok, any()} | {:error, any()}

  def run(session, query, client, handle_delta \\ nil) do
    impl().run(session, query, client, handle_delta)
  end

  defp impl, do: Application.get_env(:canary, :responder, Responder.Default)
end

defmodule Canary.Interactions.Responder.Default do
  @behaviour Canary.Interactions.Responder
  require Ash.Query

  alias Canary.Interactions.Client

  def run(session, request, %Client{account: account, sources: sources}, handle_delta) do
    Task.Supervisor.start_child(Canary.TaskSupervisor, fn ->
      Canary.Interactions.Message.add_user!(session, request)
    end)

    model = Application.fetch_env!(:canary, :chat_completion_model)
    source = sources |> Enum.at(0)
    {:ok, docs} = Canary.Searcher.run(source, request)

    messages = [
      %{
        role: "user",
        content: """
        #{render_context(docs)}

        #{render_history(session.messages)}

        <user_question>
        #{request}
        </user_question>

        Based on the retrieved documents, answer the user's question within 5 sentences. KEEP IT SIMPLE AND CONCISE.
        If user is asking for nonsense, or the retrieved documents are not relevant, just transparently say it.
        """
      }
    ]

    {:ok, pid} = Agent.start_link(fn -> "" end)

    {:ok, completion} =
      Canary.AI.chat(
        %{
          model: model,
          messages: messages,
          max_tokens: 600,
          stream: handle_delta != nil
        },
        callback: fn data ->
          case data do
            %{"choices" => [%{"finish_reason" => "stop"}]} ->
              :ok

            %{"choices" => [%{"delta" => %{"content" => content}}]} ->
              handle_delta.(%{type: :progress, content: content})
              Agent.update(pid, &(&1 <> content))
          end
        end
      )

    completion = if completion == "", do: Agent.get(pid, & &1), else: completion
    response = if docs != [], do: "#{completion}\n\n#{render_sources(docs)}", else: completion

    Task.Supervisor.start_child(Canary.TaskSupervisor, fn ->
      Canary.Accounts.Billing.increment_ask(account.billing)
      Canary.Interactions.Message.add_assistant!(session, response)
    end)

    {:ok, response}
  end

  defp render_history(history) do
    if history != [] do
      body =
        history
        |> Enum.sort_by(& &1.created_at, &(DateTime.compare(&1, &2) == :lt))
        |> Enum.map(&Canary.Renderable.render/1)
        |> Enum.join("\n\n")

      "<history>\n#{body}\n</history>"
    else
      ""
    end
  end

  defp render_context(docs) do
    if length(docs) > 0 do
      body =
        docs
        |> Enum.map(fn %{title: title, content: content} ->
          "##Title\n#{title}\n\n##Content\n#{content}\n"
        end)
        |> Enum.join("\n-------\n")

      "<retrieved_documents>\n#{body}\n</retrieved_documents>"
    else
      "<retrieved_documents>\nNo relevant documents found.\n</retrieved_documents>"
    end
  end

  defp render_sources(docs) do
    docs
    |> Enum.map(& &1.url)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.map(fn url -> "- <#{url}>" end)
    |> Enum.join("\n")
  end

  defp safe_handel_delta(func, arg) do
    if is_function(func, 1), do: func.(arg), else: :noop
  end
end
