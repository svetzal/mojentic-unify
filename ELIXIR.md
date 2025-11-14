# Mojentic Elixir Conversion Plan

## Executive Summary

This document outlines the conversion of the Mojentic Python library to Elixir. Mojentic is an LLM integration framework that provides a clean abstraction over multiple LLM providers (OpenAI, Ollama, Anthropic) with tool support, structured output generation, and an event-driven agent system.

The Elixir version will maintain the same architecture and API design philosophy while leveraging Elixir's strengths: functional programming, pattern matching, OTP supervision trees, and native concurrency via processes. We'll use idiomatic Elixir patterns to create a library that feels natural to Elixir developers.

## Architecture Overview

### Layer 1: LLM Integration (Stable, High Priority)

This is the foundational layer providing direct LLM interaction capabilities.

**Core Components:**
- `Mojentic.LLM.Broker` - Main interface for LLM interactions
- `Mojentic.LLM.Gateway` behaviour - Abstract interface for LLM providers
- Gateway implementations: `OpenAI`, `Ollama`, `Anthropic`
- Message models and adapters
- Tool system via behaviours
- Tracer system for observability

### Layer 2: Agent System (Under Development, Lower Priority)

Event-driven agent coordination system.

**Core Components:**
- `Mojentic.Dispatcher` - Event routing and processing (GenServer)
- `Mojentic.Router` - Event-to-agent routing configuration
- `Mojentic.Agent` behaviour - Foundation for all agents
- Specialized agent implementations
- Async event processing via OTP

## Application Structure

```
mojentic/
├── mix.exs
├── README.md
├── LICENSE.md
├── config/
│   ├── config.exs
│   ├── dev.exs
│   ├── test.exs
│   └── prod.exs
├── lib/
│   ├── mojentic.ex                     # Main module
│   ├── mojentic/
│   │   ├── error.ex                    # Exception types
│   │   ├── llm/
│   │   │   ├── broker.ex               # LLM broker
│   │   │   ├── gateway.ex              # Gateway behaviour
│   │   │   ├── message.ex              # Message struct
│   │   │   ├── tool_call.ex            # Tool call struct
│   │   │   ├── gateway_response.ex     # Response struct
│   │   │   ├── completion_config.ex    # Configuration struct
│   │   │   ├── chat_session.ex         # Chat session GenServer
│   │   │   ├── gateways/
│   │   │   │   ├── openai.ex           # OpenAI gateway
│   │   │   │   ├── ollama.ex           # Ollama gateway
│   │   │   │   ├── anthropic.ex        # Anthropic gateway
│   │   │   │   └── adapters/
│   │   │   │       ├── openai.ex       # OpenAI message adapter
│   │   │   │       ├── ollama.ex       # Ollama message adapter
│   │   │   │       └── anthropic.ex    # Anthropic message adapter
│   │   │   └── tools/
│   │   │       ├── tool.ex             # Tool behaviour
│   │   │       ├── date_resolver.ex    # Example tool
│   │   │       └── task_manager/       # Task management tools
│   │   │           └── task_manager.ex
│   │   ├── tracer/
│   │   │   ├── system.ex               # Tracer GenServer
│   │   │   ├── event.ex                # Event structs
│   │   │   ├── event_store.ex          # Event storage GenServer
│   │   │   └── null_tracer.ex          # Null implementation
│   │   ├── agents/                     # Layer 2 (future)
│   │   │   ├── agent.ex                # Agent behaviour
│   │   │   ├── llm_agent.ex            # LLM-enabled agents
│   │   │   └── async_agent.ex          # Async agent support
│   │   ├── dispatcher.ex               # Event dispatcher GenServer
│   │   ├── router.ex                   # Event router
│   │   └── event.ex                    # Event struct
│   └── mix/
│       └── tasks/                      # Mix tasks for common operations
├── test/
│   ├── test_helper.exs
│   ├── mojentic_test.exs
│   ├── mojentic/
│   │   ├── llm/
│   │   │   ├── broker_test.exs
│   │   │   ├── gateways/
│   │   │   │   ├── openai_test.exs
│   │   │   │   └── ollama_test.exs
│   │   │   └── tools/
│   │   │       └── tool_test.exs
│   │   └── tracer/
│   │       └── system_test.exs
│   └── support/
│       ├── fixtures.ex
│       └── mocks.ex
└── examples/
    ├── simple_llm.exs
    ├── structured_output.exs
    ├── tool_usage.exs
    └── chat_session.exs
```

## Core Type Definitions

### Message Structures

```elixir
# lib/mojentic/llm/message.ex

defmodule Mojentic.LLM.Message do
  @moduledoc """
  Represents a message in an LLM conversation.
  """

  @type role :: :system | :user | :assistant | :tool

  @type t :: %__MODULE__{
    role: role(),
    content: String.t() | nil,
    tool_calls: [Mojentic.LLM.ToolCall.t()] | nil,
    image_paths: [String.t()] | nil
  }

  @enforce_keys [:role]
  defstruct [
    :role,
    :content,
    :tool_calls,
    :image_paths
  ]

  @doc """
  Creates a user message.

  ## Examples

      iex> Message.user("Hello, world!")
      %Message{role: :user, content: "Hello, world!"}
  """
  def user(content) when is_binary(content) do
    %__MODULE__{role: :user, content: content}
  end

  @doc """
  Creates a system message.
  """
  def system(content) when is_binary(content) do
    %__MODULE__{role: :system, content: content}
  end

  @doc """
  Creates an assistant message.
  """
  def assistant(content) when is_binary(content) do
    %__MODULE__{role: :assistant, content: content}
  end

  @doc """
  Adds image paths to a message.
  """
  def with_images(%__MODULE__{} = message, paths) when is_list(paths) do
    %{message | image_paths: paths}
  end
end
```

### Tool Call Structure

```elixir
# lib/mojentic/llm/tool_call.ex

defmodule Mojentic.LLM.ToolCall do
  @moduledoc """
  Represents a tool call from an LLM.
  """

  @type t :: %__MODULE__{
    id: String.t() | nil,
    name: String.t(),
    arguments: map()
  }

  @enforce_keys [:name, :arguments]
  defstruct [:id, :name, :arguments]
end
```

### Gateway Response

```elixir
# lib/mojentic/llm/gateway_response.ex

defmodule Mojentic.LLM.GatewayResponse do
  @moduledoc """
  Represents a response from an LLM gateway.
  """

  @type t :: %__MODULE__{
    content: String.t() | nil,
    object: term() | nil,
    tool_calls: [Mojentic.LLM.ToolCall.t()]
  }

  defstruct [
    content: nil,
    object: nil,
    tool_calls: []
  ]
end
```

### Completion Configuration

```elixir
# lib/mojentic/llm/completion_config.ex

defmodule Mojentic.LLM.CompletionConfig do
  @moduledoc """
  Configuration for LLM completion requests.
  """

  @type t :: %__MODULE__{
    temperature: float(),
    num_ctx: pos_integer(),
    max_tokens: pos_integer(),
    num_predict: integer() | nil
  }

  defstruct [
    temperature: 1.0,
    num_ctx: 32768,
    max_tokens: 16384,
    num_predict: nil
  ]

  @doc """
  Creates a new configuration with default values.
  """
  def new(opts \\ []) do
    struct(__MODULE__, opts)
  end
end
```

## Gateway Behaviour

```elixir
# lib/mojentic/llm/gateway.ex

defmodule Mojentic.LLM.Gateway do
  @moduledoc """
  Behaviour for LLM gateway implementations.

  A gateway handles communication with a specific LLM provider,
  converting between the universal message format and the
  provider-specific API.
  """

  alias Mojentic.LLM.{Message, GatewayResponse, CompletionConfig}
  alias Mojentic.LLM.Tools.Tool

  @type gateway :: module()
  @type error :: {:error, atom() | String.t()}

  @doc """
  Completes an LLM request with text response.

  ## Parameters

  - `model`: Model identifier (e.g., "gpt-4", "qwen3:32b")
  - `messages`: List of conversation messages
  - `tools`: Optional list of available tools
  - `config`: Completion configuration

  ## Returns

  - `{:ok, response}` on success
  - `{:error, reason}` on failure
  """
  @callback complete(
    model :: String.t(),
    messages :: [Message.t()],
    tools :: [Tool.t()] | nil,
    config :: CompletionConfig.t()
  ) :: {:ok, GatewayResponse.t()} | error()

  @doc """
  Completes an LLM request with structured object response.

  The response will be parsed into a struct or map based on
  the provided schema.
  """
  @callback complete_object(
    model :: String.t(),
    messages :: [Message.t()],
    schema :: map(),
    config :: CompletionConfig.t()
  ) :: {:ok, GatewayResponse.t()} | error()

  @doc """
  Gets list of available models from the provider.
  """
  @callback get_available_models() :: {:ok, [String.t()]} | error()

  @doc """
  Calculates embeddings for the given text.
  """
  @callback calculate_embeddings(
    text :: String.t(),
    model :: String.t() | nil
  ) :: {:ok, [float()]} | error()
end
```

## LLM Broker

```elixir
# lib/mojentic/llm/broker.ex

defmodule Mojentic.LLM.Broker do
  @moduledoc """
  Main interface for LLM interactions.

  The broker manages communication with LLM providers through
  gateways, handles tool calling, and integrates with the
  tracer system for observability.
  """

  alias Mojentic.LLM.{Gateway, Message, GatewayResponse, CompletionConfig, ToolCall}
  alias Mojentic.LLM.Tools.Tool
  alias Mojentic.Tracer.System, as: TracerSystem

  @type t :: %__MODULE__{
    model: String.t(),
    gateway: Gateway.gateway(),
    gateway_opts: keyword(),
    tracer: pid() | nil
  }

  defstruct [:model, :gateway, :gateway_opts, :tracer]

  @doc """
  Creates a new LLM broker.

  ## Parameters

  - `model`: Model identifier
  - `gateway`: Gateway module (e.g., Mojentic.LLM.Gateways.Ollama)
  - `opts`: Options
    - `:gateway_opts` - Options to pass to gateway
    - `:tracer` - Tracer process PID

  ## Examples

      iex> Broker.new("qwen3:32b", Mojentic.LLM.Gateways.Ollama)
      %Broker{model: "qwen3:32b", gateway: Mojentic.LLM.Gateways.Ollama}
  """
  def new(model, gateway, opts \\ []) do
    %__MODULE__{
      model: model,
      gateway: gateway,
      gateway_opts: Keyword.get(opts, :gateway_opts, []),
      tracer: Keyword.get(opts, :tracer)
    }
  end

  @doc """
  Generates text response from the LLM.

  ## Parameters

  - `broker`: Broker instance
  - `messages`: List of conversation messages
  - `tools`: Optional list of tools
  - `config`: Optional completion configuration

  ## Returns

  - `{:ok, response_text}` on success
  - `{:error, reason}` on failure

  ## Examples

      iex> broker = Broker.new("qwen3:32b", Ollama)
      iex> messages = [Message.user("What is 2+2?")]
      iex> {:ok, response} = Broker.generate(broker, messages)
  """
  def generate(broker, messages, tools \\ nil, config \\ nil) do
    config = config || %CompletionConfig{}
    correlation_id = generate_correlation_id()

    record_llm_call(broker, messages, config, tools, correlation_id)

    start_time = System.monotonic_time(:millisecond)

    with {:ok, response} <- broker.gateway.complete(
           broker.model,
           messages,
           tools,
           config
         ) do
      duration = System.monotonic_time(:millisecond) - start_time

      record_llm_response(broker, response, duration, correlation_id)

      case response.tool_calls do
        [] ->
          {:ok, response.content || ""}

        tool_calls ->
          handle_tool_calls(
            broker,
            messages,
            response,
            tools,
            config,
            correlation_id
          )
      end
    end
  end

  @doc """
  Generates structured object response from the LLM.

  The response will be a map conforming to the provided schema.

  ## Parameters

  - `broker`: Broker instance
  - `messages`: List of conversation messages
  - `schema`: JSON schema for the expected response structure
  - `config`: Optional completion configuration

  ## Returns

  - `{:ok, parsed_object}` on success
  - `{:error, reason}` on failure
  """
  def generate_object(broker, messages, schema, config \\ nil) do
    config = config || %CompletionConfig{}
    correlation_id = generate_correlation_id()

    record_llm_call(broker, messages, config, nil, correlation_id)

    start_time = System.monotonic_time(:millisecond)

    with {:ok, response} <- broker.gateway.complete_object(
           broker.model,
           messages,
           schema,
           config
         ) do
      duration = System.monotonic_time(:millisecond) - start_time

      record_llm_response(broker, response, duration, correlation_id)

      case response.object do
        nil -> {:error, :no_object_in_response}
        object -> {:ok, object}
      end
    end
  end

  # Private functions

  defp handle_tool_calls(broker, messages, response, tools, config, correlation_id) do
    case tools do
      nil ->
        {:ok, response.content || ""}

      tools ->
        new_messages = messages ++ [build_assistant_message(response)]

        tool_results =
          Enum.map(response.tool_calls, fn tool_call ->
            execute_tool(broker, tool_call, tools, correlation_id)
          end)

        # Add tool result messages
        final_messages =
          Enum.reduce(tool_results, new_messages, fn
            {:ok, tool_message}, acc -> acc ++ [tool_message]
            {:error, _}, acc -> acc
          end)

        # Recursively call generate with updated messages
        generate(broker, final_messages, tools, config)
    end
  end

  defp build_assistant_message(response) do
    %Message{
      role: :assistant,
      content: response.content,
      tool_calls: response.tool_calls
    }
  end

  defp execute_tool(broker, tool_call, tools, correlation_id) do
    case find_tool(tools, tool_call.name) do
      nil ->
        {:error, {:tool_not_found, tool_call.name}}

      tool ->
        start_time = System.monotonic_time(:millisecond)

        case Tool.run(tool, tool_call.arguments) do
          {:ok, result} ->
            duration = System.monotonic_time(:millisecond) - start_time

            record_tool_call(
              broker,
              tool_call.name,
              tool_call.arguments,
              result,
              duration,
              correlation_id
            )

            {:ok, %Message{
              role: :tool,
              content: Jason.encode!(result),
              tool_calls: [tool_call]
            }}

          {:error, reason} ->
            {:error, reason}
        end
    end
  end

  defp find_tool(tools, name) do
    Enum.find(tools, fn tool ->
      Tool.name(tool) == name
    end)
  end

  defp generate_correlation_id do
    UUID.uuid4()
  end

  defp record_llm_call(broker, messages, config, tools, correlation_id) do
    if broker.tracer do
      TracerSystem.record_llm_call(
        broker.tracer,
        broker.model,
        messages,
        config.temperature,
        tools,
        correlation_id
      )
    end
  end

  defp record_llm_response(broker, response, duration, correlation_id) do
    if broker.tracer do
      TracerSystem.record_llm_response(
        broker.tracer,
        broker.model,
        response.content,
        response.tool_calls,
        duration,
        correlation_id
      )
    end
  end

  defp record_tool_call(broker, name, args, result, duration, correlation_id) do
    if broker.tracer do
      TracerSystem.record_tool_call(
        broker.tracer,
        name,
        args,
        result,
        duration,
        correlation_id
      )
    end
  end
end
```

## Tool Behaviour

```elixir
# lib/mojentic/llm/tools/tool.ex

defmodule Mojentic.LLM.Tools.Tool do
  @moduledoc """
  Behaviour for LLM tool implementations.

  Tools allow LLMs to perform actions or retrieve information
  by calling functions that you define.
  """

  @type descriptor :: %{
    type: String.t(),
    function: %{
      name: String.t(),
      description: String.t(),
      parameters: map()
    }
  }

  @doc """
  Executes the tool with the given arguments.

  ## Parameters

  - `tool`: Tool implementation
  - `arguments`: Map of argument name to value

  ## Returns

  - `{:ok, result}` on success
  - `{:error, reason}` on failure
  """
  @callback run(arguments :: map()) :: {:ok, term()} | {:error, term()}

  @doc """
  Returns the tool descriptor for the LLM.

  The descriptor includes the tool's name, description, and
  parameter schema in JSON Schema format.
  """
  @callback descriptor() :: descriptor()

  @doc """
  Returns the tool's name.
  """
  def name(tool) do
    tool.descriptor().function.name
  end

  @doc """
  Returns the tool's description.
  """
  def description(tool) do
    tool.descriptor().function.description
  end

  @doc """
  Checks if a tool matches the given name.
  """
  def matches?(tool, name) do
    name(tool) == name
  end

  @doc """
  Runs a tool with the given arguments.

  Delegates to the tool's run/1 callback.
  """
  def run(tool, arguments) do
    tool.run(arguments)
  end
end
```

## Example Tool Implementation

```elixir
# lib/mojentic/llm/tools/date_resolver.ex

defmodule Mojentic.LLM.Tools.DateResolver do
  @moduledoc """
  Tool for resolving relative dates to absolute dates.
  """

  @behaviour Mojentic.LLM.Tools.Tool

  alias Mojentic.LLM.Tools.Tool

  @impl Tool
  def run(arguments) do
    relative_date = Map.get(arguments, "relative_date_found")
    reference_date = Map.get(arguments, "reference_date_in_iso8601", Date.utc_today())

    case parse_relative_date(relative_date, reference_date) do
      {:ok, resolved_date} ->
        {:ok, %{
          relative_date: relative_date,
          resolved_date: Date.to_iso8601(resolved_date),
          summary: "The date on '#{relative_date}' is #{Date.to_iso8601(resolved_date)}"
        }}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @impl Tool
  def descriptor do
    %{
      type: "function",
      function: %{
        name: "resolve_date",
        description: "Take text that specifies a relative date, and output an absolute date",
        parameters: %{
          type: "object",
          properties: %{
            relative_date_found: %{
              type: "string",
              description: "The text referencing a relative date"
            },
            reference_date_in_iso8601: %{
              type: "string",
              description: "The reference date in YYYY-MM-DD format"
            }
          },
          required: ["relative_date_found"]
        }
      }
    }
  end

  # Private helper to parse relative dates
  defp parse_relative_date(text, reference_date) do
    # Implementation would use date parsing logic
    # This is a simplified example
    cond do
      String.contains?(text, "today") ->
        {:ok, reference_date}

      String.contains?(text, "tomorrow") ->
        {:ok, Date.add(reference_date, 1)}

      String.contains?(text, "yesterday") ->
        {:ok, Date.add(reference_date, -1)}

      true ->
        {:error, :unable_to_parse_date}
    end
  end
end
```

## Ollama Gateway Implementation

```elixir
# lib/mojentic/llm/gateways/ollama.ex

defmodule Mojentic.LLM.Gateways.Ollama do
  @moduledoc """
  Gateway for Ollama local LLM service.

  This gateway provides access to local LLM models through Ollama,
  supporting text generation, structured output, tool calling,
  and embeddings.
  """

  @behaviour Mojentic.LLM.Gateway

  alias Mojentic.LLM.{Gateway, Message, GatewayResponse, CompletionConfig, ToolCall}
  alias Mojentic.LLM.Gateways.Adapters.Ollama, as: Adapter

  @default_host "http://localhost:11434"

  @impl Gateway
  def complete(model, messages, tools, config) do
    host = get_host()

    ollama_messages = Adapter.adapt_messages(messages)
    options = extract_options(config)

    body = %{
      model: model,
      messages: ollama_messages,
      options: options,
      stream: false
    }

    body = maybe_add_tools(body, tools)

    case HTTPoison.post(
           "#{host}/api/chat",
           Jason.encode!(body),
           [{"Content-Type", "application/json"}]
         ) do
      {:ok, %{status_code: 200, body: response_body}} ->
        parse_response(response_body)

      {:ok, %{status_code: status}} ->
        {:error, {:http_error, status}}

      {:error, reason} ->
        {:error, {:request_failed, reason}}
    end
  end

  @impl Gateway
  def complete_object(model, messages, schema, config) do
    host = get_host()

    ollama_messages = Adapter.adapt_messages(messages)
    options = extract_options(config)

    body = %{
      model: model,
      messages: ollama_messages,
      options: options,
      format: schema,
      stream: false
    }

    case HTTPoison.post(
           "#{host}/api/chat",
           Jason.encode!(body),
           [{"Content-Type", "application/json"}]
         ) do
      {:ok, %{status_code: 200, body: response_body}} ->
        parse_object_response(response_body)

      {:ok, %{status_code: status}} ->
        {:error, {:http_error, status}}

      {:error, reason} ->
        {:error, {:request_failed, reason}}
    end
  end

  @impl Gateway
  def get_available_models do
    host = get_host()

    case HTTPoison.get("#{host}/api/tags") do
      {:ok, %{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, %{"models" => models}} ->
            names = Enum.map(models, & &1["name"])
            {:ok, names}

          _ ->
            {:error, :invalid_response}
        end

      {:ok, %{status_code: status}} ->
        {:error, {:http_error, status}}

      {:error, reason} ->
        {:error, {:request_failed, reason}}
    end
  end

  @impl Gateway
  def calculate_embeddings(text, model) do
    host = get_host()
    model = model || "mxbai-embed-large"

    body = %{
      model: model,
      prompt: text
    }

    case HTTPoison.post(
           "#{host}/api/embeddings",
           Jason.encode!(body),
           [{"Content-Type", "application/json"}]
         ) do
      {:ok, %{status_code: 200, body: response_body}} ->
        case Jason.decode(response_body) do
          {:ok, %{"embedding" => embedding}} ->
            {:ok, embedding}

          _ ->
            {:error, :invalid_response}
        end

      {:ok, %{status_code: status}} ->
        {:error, {:http_error, status}}

      {:error, reason} ->
        {:error, {:request_failed, reason}}
    end
  end

  @doc """
  Pulls a model from the Ollama library.
  """
  def pull_model(model) do
    host = get_host()

    body = %{name: model}

    case HTTPoison.post(
           "#{host}/api/pull",
           Jason.encode!(body),
           [{"Content-Type", "application/json"}]
         ) do
      {:ok, %{status_code: 200}} ->
        :ok

      {:ok, %{status_code: status}} ->
        {:error, {:http_error, status}}

      {:error, reason} ->
        {:error, {:request_failed, reason}}
    end
  end

  # Private functions

  defp get_host do
    System.get_env("OLLAMA_HOST") || @default_host
  end

  defp extract_options(config) do
    options = %{
      temperature: config.temperature,
      num_ctx: config.num_ctx
    }

    case config.num_predict do
      nil when config.max_tokens > 0 ->
        Map.put(options, :num_predict, config.max_tokens)

      num when is_integer(num) and num > 0 ->
        Map.put(options, :num_predict, num)

      _ ->
        options
    end
  end

  defp maybe_add_tools(body, nil), do: body
  defp maybe_add_tools(body, []), do: body
  defp maybe_add_tools(body, tools) do
    tool_descriptors = Enum.map(tools, & &1.descriptor())
    Map.put(body, :tools, tool_descriptors)
  end

  defp parse_response(body) do
    case Jason.decode(body) do
      {:ok, %{"message" => message}} ->
        content = Map.get(message, "content")
        tool_calls = parse_tool_calls(message)

        {:ok, %GatewayResponse{
          content: content,
          tool_calls: tool_calls
        }}

      _ ->
        {:error, :invalid_response}
    end
  end

  defp parse_object_response(body) do
    case Jason.decode(body) do
      {:ok, %{"message" => %{"content" => content}}} ->
        case Jason.decode(content) do
          {:ok, object} ->
            {:ok, %GatewayResponse{
              content: content,
              object: object,
              tool_calls: []
            }}

          {:error, _} ->
            {:error, :invalid_json_object}
        end

      _ ->
        {:error, :invalid_response}
    end
  end

  defp parse_tool_calls(%{"tool_calls" => tool_calls}) when is_list(tool_calls) do
    Enum.map(tool_calls, fn call ->
      %ToolCall{
        id: call["id"],
        name: get_in(call, ["function", "name"]),
        arguments: get_in(call, ["function", "arguments"]) || %{}
      }
    end)
  end
  defp parse_tool_calls(_), do: []
end
```

## Dependencies (mix.exs)

```elixir
defmodule Mojentic.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/svetzal/mojentic-ex"

  def project do
    [
      app: :mojentic,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # Hex
      description: "An LLM integration framework for Elixir",
      package: package(),

      # Docs
      name: "Mojentic",
      source_url: @source_url,
      docs: docs(),

      # Testing
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],

      # Dialyzer
      dialyzer: [
        plt_add_apps: [:ex_unit, :mix],
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"}
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger, :crypto]
    ]
  end

  defp deps do
    [
      # HTTP client
      {:httpoison, "~> 2.0"},
      {:hackney, "~> 1.18"},

      # JSON
      {:jason, "~> 1.4"},

      # UUID generation
      {:uuid, "~> 1.1"},

      # Date/time handling
      {:timex, "~> 3.7"},

      # JSON Schema
      {:ex_json_schema, "~> 0.9"},

      # Development and testing
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.18", only: :test},
      {:mox, "~> 1.1", only: :test},
      {:stream_data, "~> 0.6", only: [:dev, :test]}
    ]
  end

  defp package do
    [
      maintainers: ["Stacey Vetzal"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url
      },
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE.md)
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md", "LICENSE.md"],
      source_ref: "v#{@version}",
      groups_for_modules: [
        "LLM Integration": [
          Mojentic.LLM.Broker,
          Mojentic.LLM.Gateway,
          Mojentic.LLM.Message,
          Mojentic.LLM.CompletionConfig,
          Mojentic.LLM.ChatSession
        ],
        Gateways: [
          Mojentic.LLM.Gateways.OpenAI,
          Mojentic.LLM.Gateways.Ollama,
          Mojentic.LLM.Gateways.Anthropic
        ],
        Tools: [
          Mojentic.LLM.Tools.Tool,
          Mojentic.LLM.Tools.DateResolver
        ],
        Observability: [
          Mojentic.Tracer.System,
          Mojentic.Tracer.Event,
          Mojentic.Tracer.EventStore
        ],
        Agents: [
          Mojentic.Agent,
          Mojentic.Dispatcher,
          Mojentic.Router
        ]
      ]
    ]
  end
end
```

## Implementation Strategy

### Phase 1: Core Infrastructure (Week 1-2)

1. **Project Setup**
   - Initialize Mix project with proper structure
   - Set up CI/CD with GitHub Actions
   - Configure code quality tools (Credo, Dialyzer)
   - Set up ExDoc for documentation

2. **Core Types and Behaviours**
   - Implement error types (exceptions)
   - Implement message structs
   - Define `Gateway` behaviour
   - Define `Tool` behaviour
   - Implement basic tracer infrastructure

3. **Testing Infrastructure**
   - Set up ExUnit testing
   - Create mock implementations using Mox
   - Write integration test structure

### Phase 2: LLM Integration Layer (Week 3-4)

1. **Broker Implementation**
   - Core `generate/4` function
   - Tool calling logic with recursion
   - `generate_object/4` for structured output
   - Integration with tracer

2. **Ollama Gateway**
   - Basic completion API
   - Message adaptation
   - Structured output support
   - Tool calling support
   - Embeddings support
   - Error handling

3. **Tool System**
   - Tool behaviour implementation
   - Example tools (date resolver, etc.)
   - Tool execution and error handling

### Phase 3: Advanced Features (Week 5-6)

1. **ChatSession GenServer**
   - Message history management
   - Context window management
   - State supervision

2. **Tracer System**
   - Event recording GenServer
   - Event querying
   - Correlation ID tracking
   - Performance metrics

3. **OpenAI Gateway**
   - OpenAI API integration
   - Message adaptation
   - Model registry and parameter adaptation
   - Structured output support
   - Tool support

### Phase 4: Agent System (Week 7-8)

1. **Event System**
   - Event structs
   - Event dispatcher GenServer
   - Router implementation

2. **Agent Behaviours**
   - Agent behaviour
   - LLM agent implementations
   - Supervision trees

3. **Async Dispatcher**
   - OTP-based event processing
   - GenServer message passing
   - Supervised task execution
   - Graceful shutdown

### Phase 5: Polish and Documentation (Week 9-10)

1. **Examples**
   - Simple LLM usage script
   - Structured output script
   - Tool usage script
   - Chat session script
   - Agent system script

2. **Documentation**
   - ExDoc documentation
   - User guide
   - Architecture documentation
   - Migration guide from Python

3. **Performance Optimization**
   - Benchmarking with Benchee
   - Process optimization
   - Connection pooling for HTTP

## Key Design Decisions

### 1. Functional + OTP Design

Elixir's functional nature combined with OTP provides excellent support for:
- Immutable data structures for messages and configurations
- Pattern matching for message handling
- GenServers for stateful components (ChatSession, Tracer, Dispatcher)
- Supervision trees for fault tolerance

### 2. Behaviours Over Classes

Use Elixir behaviours (similar to traits/interfaces) for:
- Gateway implementations
- Tool implementations
- Agent implementations

This provides clear contracts while allowing flexible implementations.

### 3. Error Handling

Use Elixir's `{:ok, result} | {:error, reason}` pattern throughout:
- Clear error propagation
- Composable with `with` statements
- Easy to pattern match on results

### 4. Process-Based State

For components that need state:
- ChatSession: GenServer for conversation history
- Tracer: GenServer for event collection
- Dispatcher: GenServer for event routing

### 5. Configuration

Use Application configuration and runtime overrides:
- API keys from environment variables
- Host URLs configurable
- Sensible defaults

### 6. Concurrency

Leverage Elixir's lightweight processes:
- Concurrent tool execution where possible
- Async agent processing
- Event-driven architecture

## API Design Examples

### Simple Usage

```elixir
# examples/simple_llm.exs

alias Mojentic.LLM.{Broker, Message}
alias Mojentic.LLM.Gateways.Ollama

# Create broker
broker = Broker.new("qwen3:32b", Ollama)

# Create message
messages = [Message.user("What is the capital of France?")]

# Generate response
{:ok, response} = Broker.generate(broker, messages)

IO.puts("Response: #{response}")
```

### Structured Output

```elixir
# examples/structured_output.exs

alias Mojentic.LLM.{Broker, Message}
alias Mojentic.LLM.Gateways.Ollama

# Define schema
schema = %{
  type: "object",
  properties: %{
    label: %{type: "string"},
    confidence: %{type: "number"},
    reasoning: %{type: "string"}
  },
  required: ["label", "confidence", "reasoning"]
}

# Create broker
broker = Broker.new("qwen3:32b", Ollama)

# Create message
messages = [
  Message.user(
    "Analyze the sentiment of this text: 'I absolutely love this product!'"
  )
]

# Generate structured response
{:ok, sentiment} = Broker.generate_object(broker, messages, schema)

IO.puts("Label: #{sentiment["label"]}")
IO.puts("Confidence: #{sentiment["confidence"]}")
IO.puts("Reasoning: #{sentiment["reasoning"]}")
```

### Tool Usage

```elixir
# examples/tool_usage.exs

alias Mojentic.LLM.{Broker, Message}
alias Mojentic.LLM.Gateways.Ollama
alias Mojentic.LLM.Tools.Tool

# Define weather tool
defmodule WeatherTool do
  @behaviour Tool

  @impl Tool
  def run(args) do
    location = Map.get(args, "location", "unknown")

    {:ok, %{
      location: location,
      temperature: 22,
      condition: "sunny",
      humidity: 60
    }}
  end

  @impl Tool
  def descriptor do
    %{
      type: "function",
      function: %{
        name: "get_weather",
        description: "Get the current weather for a location",
        parameters: %{
          type: "object",
          properties: %{
            location: %{
              type: "string",
              description: "The city or location"
            }
          },
          required: ["location"]
        }
      }
    }
  end
end

# Create broker with tool
broker = Broker.new("qwen3:32b", Ollama)
tools = [WeatherTool]

# Create message
messages = [Message.user("What's the weather like in San Francisco?")]

# Generate response (will use tool)
{:ok, response} = Broker.generate(broker, messages, tools)

IO.puts("Response: #{response}")
```

### Chat Session

```elixir
# examples/chat_session.exs

alias Mojentic.LLM.{Broker, ChatSession}
alias Mojentic.LLM.Gateways.Ollama

# Create broker
broker = Broker.new("qwen3:32b", Ollama)

# Start chat session
{:ok, session} = ChatSession.start_link(
  broker: broker,
  system_prompt: "You are a helpful assistant."
)

# Send messages
{:ok, response1} = ChatSession.send(session, "Hello!")
IO.puts("Assistant: #{response1}")

{:ok, response2} = ChatSession.send(session, "What did I just say?")
IO.puts("Assistant: #{response2}")

# Get conversation history
messages = ChatSession.get_messages(session)
IO.inspect(messages, label: "Conversation")
```

## Testing Strategy

### Unit Tests

```elixir
# test/mojentic/llm/broker_test.exs

defmodule Mojentic.LLM.BrokerTest do
  use ExUnit.Case, async: true

  import Mox

  alias Mojentic.LLM.{Broker, Message, GatewayResponse}

  setup :verify_on_exit!

  describe "generate/4" do
    test "returns response content from gateway" do
      gateway = MockGateway

      expect(gateway, :complete, fn _model, _messages, _tools, _config ->
        {:ok, %GatewayResponse{content: "Paris"}}
      end)

      broker = Broker.new("test-model", gateway)
      messages = [Message.user("What is the capital of France?")]

      assert {:ok, "Paris"} = Broker.generate(broker, messages)
    end

    test "handles tool calls" do
      gateway = MockGateway

      # First call returns tool call
      expect(gateway, :complete, fn _model, _messages, _tools, _config ->
        {:ok, %GatewayResponse{
          tool_calls: [
            %ToolCall{
              name: "get_weather",
              arguments: %{"location" => "SF"}
            }
          ]
        }}
      end)

      # Second call returns final response
      expect(gateway, :complete, fn _model, _messages, _tools, _config ->
        {:ok, %GatewayResponse{content: "It's sunny in SF"}}
      end)

      broker = Broker.new("test-model", gateway)
      tools = [WeatherTool]
      messages = [Message.user("What's the weather in SF?")]

      assert {:ok, response} = Broker.generate(broker, messages, tools)
      assert response =~ "sunny"
    end
  end
end
```

### Integration Tests

```elixir
# test/integration/ollama_gateway_test.exs

defmodule Mojentic.Integration.OllamaGatewayTest do
  use ExUnit.Case

  @moduletag :integration

  alias Mojentic.LLM.{Message, CompletionConfig}
  alias Mojentic.LLM.Gateways.Ollama

  setup do
    # Skip if Ollama not available
    case HTTPoison.get("http://localhost:11434/api/tags") do
      {:ok, %{status_code: 200}} -> :ok
      _ -> {:skip, "Ollama not available"}
    end
  end

  test "completes simple request" do
    messages = [Message.user("Say 'hello' and nothing else.")]
    config = %CompletionConfig{}

    assert {:ok, response} = Ollama.complete("qwen3:32b", messages, nil, config)
    assert response.content =~ ~r/hello/i
  end

  test "returns structured output" do
    schema = %{
      type: "object",
      properties: %{answer: %{type: "number"}},
      required: ["answer"]
    }

    messages = [Message.user("What is 2+2? Respond with just the number.")]
    config = %CompletionConfig{}

    assert {:ok, response} = Ollama.complete_object("qwen3:32b", messages, schema, config)
    assert response.object["answer"] == 4
  end
end
```

### Property-Based Tests

```elixir
# test/mojentic/llm/message_test.exs

defmodule Mojentic.LLM.MessageTest do
  use ExUnit.Case
  use ExUnitProperties

  alias Mojentic.LLM.Message

  property "user/1 always creates user messages" do
    check all content <- string(:printable) do
      message = Message.user(content)
      assert message.role == :user
      assert message.content == content
    end
  end

  property "with_images/2 preserves other fields" do
    check all content <- string(:printable),
              paths <- list_of(string(:printable)) do
      message =
        content
        |> Message.user()
        |> Message.with_images(paths)

      assert message.role == :user
      assert message.content == content
      assert message.image_paths == paths
    end
  end
end
```

## Documentation

### Module Documentation

```elixir
defmodule Mojentic.LLM.Broker do
  @moduledoc """
  Main interface for LLM interactions.

  The broker manages communication with LLM providers through gateways,
  handles tool calling, and integrates with the tracer system for
  observability.

  ## Examples

      # Create a broker with Ollama
      broker = Broker.new("qwen3:32b", Mojentic.LLM.Gateways.Ollama)

      # Generate a simple response
      messages = [Message.user("What is 2+2?")]
      {:ok, response} = Broker.generate(broker, messages)

      # Generate structured output
      schema = %{type: "object", properties: %{answer: %{type: "number"}}}
      {:ok, result} = Broker.generate_object(broker, messages, schema)

  ## Tool Support

  The broker automatically handles tool calls from the LLM:

      tools = [MyTool]
      {:ok, response} = Broker.generate(broker, messages, tools)

  When the LLM requests a tool call, the broker will:
  1. Execute the tool with the provided arguments
  2. Add the tool result to the conversation
  3. Recursively call the LLM to generate the final response

  ## Observability

  Pass a tracer PID to track all LLM interactions:

      {:ok, tracer} = TracerSystem.start_link()
      broker = Broker.new("qwen3:32b", Ollama, tracer: tracer)
  """
end
```

### README Structure

```markdown
# Mojentic

An LLM integration framework for Elixir.

## Features

- 🔌 **Multiple Providers**: OpenAI, Ollama, Anthropic
- 🛠️ **Tool Support**: Allow LLMs to call functions
- 📊 **Structured Output**: Type-safe response parsing
- 🔍 **Observability**: Built-in tracing system
- 🎭 **Agent System**: Event-driven agent coordination
- 🏗️ **OTP Design**: Supervised processes for reliability

## Installation

Add `mojentic` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:mojentic, "~> 0.1.0"}
  ]
end
```

## Quick Start

### Simple Text Generation

```elixir
alias Mojentic.LLM.{Broker, Message}
alias Mojentic.LLM.Gateways.Ollama

broker = Broker.new("qwen3:32b", Ollama)
messages = [Message.user("What is Elixir?")]
{:ok, response} = Broker.generate(broker, messages)
```

### Structured Output

```elixir
schema = %{
  type: "object",
  properties: %{
    sentiment: %{type: "string"},
    confidence: %{type: "number"}
  }
}

{:ok, result} = Broker.generate_object(broker, messages, schema)
```

### Tool Usage

```elixir
defmodule MyTool do
  @behaviour Mojentic.LLM.Tools.Tool

  @impl true
  def run(args), do: {:ok, %{result: "tool result"}}

  @impl true
  def descriptor, do: %{...}
end

tools = [MyTool]
{:ok, response} = Broker.generate(broker, messages, tools)
```

## Documentation

Full documentation is available on [HexDocs](https://hexdocs.pm/mojentic).

## License

MIT License - see LICENSE.md
```

## Migration Guide (Python → Elixir)

### Key Differences

| Python | Elixir | Notes |
|--------|--------|-------|
| `LLMBroker` | `Mojentic.LLM.Broker` | Module naming |
| `generate(messages=[...])` | `Broker.generate(broker, [...])` | Explicit broker param |
| `tools=[Tool()]` | `tools` | List of modules |
| `LLMMessage(content='...')` | `Message.user("...")` | Constructor functions |
| Dynamic typing | Pattern matching | Type specs for documentation |
| `Optional[TracerSystem]` | `tracer: pid() \| nil` | Process PIDs |
| Exception handling | `{:ok, result} \| {:error, reason}` | Explicit error tuples |
| Classes | Modules + Behaviours | Different paradigm |

### Code Comparison

**Python:**
```python
from mojentic.llm import LLMBroker
from mojentic.llm.gateways import OllamaGateway

broker = LLMBroker(model="qwen3:32b", gateway=OllamaGateway())
result = broker.generate(messages=[LLMMessage(content="Hello")])
```

**Elixir:**
```elixir
alias Mojentic.LLM.{Broker, Message}
alias Mojentic.LLM.Gateways.Ollama

broker = Broker.new("qwen3:32b", Ollama)
{:ok, result} = Broker.generate(broker, [Message.user("Hello")])
```

### Architectural Differences

**State Management:**
- Python: Instance variables in classes
- Elixir: GenServer processes or function parameters

**Concurrency:**
- Python: asyncio or threading
- Elixir: Lightweight processes (actors)

**Error Handling:**
- Python: Exceptions with try/catch
- Elixir: Pattern matching on result tuples

**Type Safety:**
- Python: Optional type hints
- Elixir: Dialyzer for gradual typing

## OTP Async Support Implementation Plan

### Overview

Elixir's OTP (Open Telecom Platform) provides world-class support for building concurrent, fault-tolerant systems through the Actor model. This section outlines how we'll leverage OTP to match and exceed the async capabilities of the Python (asyncio), Rust (tokio), and TypeScript (async/await) implementations.

### Core OTP Patterns

#### 1. GenServer for Stateful Components

**ChatSession as GenServer:**
```elixir
defmodule Mojentic.LLM.ChatSession do
  use GenServer

  @moduledoc """
  Manages conversation state across multiple LLM interactions.

  The ChatSession is implemented as a GenServer to provide:
  - Thread-safe message history management
  - Automatic context window management
  - Fault tolerance through supervision
  - Concurrent access from multiple processes
  """

  # Client API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @doc """
  Sends a message and returns the LLM response.
  """
  def send_message(session, content) do
    GenServer.call(session, {:send_message, content}, :infinity)
  end

  @doc """
  Gets the current conversation history.
  """
  def get_messages(session) do
    GenServer.call(session, :get_messages)
  end

  @doc """
  Clears the conversation history.
  """
  def clear_history(session) do
    GenServer.cast(session, :clear_history)
  end

  # Server Callbacks

  @impl true
  def init(opts) do
    state = %{
      broker: Keyword.fetch!(opts, :broker),
      messages: [Message.system(Keyword.get(opts, :system_prompt, ""))],
      tools: Keyword.get(opts, :tools, []),
      config: Keyword.get(opts, :config, %CompletionConfig{}),
      max_context_messages: Keyword.get(opts, :max_context_messages, 50)
    }

    {:ok, state}
  end

  @impl true
  def handle_call({:send_message, content}, _from, state) do
    user_message = Message.user(content)
    messages = state.messages ++ [user_message]

    case Broker.generate(state.broker, messages, state.tools, state.config) do
      {:ok, response} ->
        assistant_message = Message.assistant(response)
        new_messages = trim_messages(messages ++ [assistant_message], state.max_context_messages)

        {:reply, {:ok, response}, %{state | messages: new_messages}}

      {:error, reason} = error ->
        {:reply, error, state}
    end
  end

  @impl true
  def handle_call(:get_messages, _from, state) do
    {:reply, state.messages, state}
  end

  @impl true
  def handle_cast(:clear_history, state) do
    system_message = Enum.find(state.messages, &(&1.role == :system))
    new_messages = if system_message, do: [system_message], else: []
    {:noreply, %{state | messages: new_messages}}
  end

  defp trim_messages(messages, max_messages) do
    system = Enum.filter(messages, &(&1.role == :system))
    others = Enum.filter(messages, &(&1.role != :system))

    trimmed_others = Enum.take(others, -max_messages)
    system ++ trimmed_others
  end
end
```

**Tracer as GenServer:**
```elixir
defmodule Mojentic.Tracer.System do
  use GenServer

  @moduledoc """
  Centralized event tracing system for observability.

  The Tracer is implemented as a GenServer to provide:
  - Concurrent event recording from multiple processes
  - In-memory event storage with query capabilities
  - Correlation ID tracking across async operations
  - Performance metrics aggregation
  """

  # Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def record_llm_call(tracer, model, messages, temperature, tools, correlation_id) do
    event = %Event{
      type: :llm_call,
      timestamp: DateTime.utc_now(),
      correlation_id: correlation_id,
      data: %{
        model: model,
        message_count: length(messages),
        temperature: temperature,
        tool_count: length(tools || [])
      }
    }

    GenServer.cast(tracer, {:record, event})
  end

  def record_llm_response(tracer, model, content, tool_calls, duration_ms, correlation_id) do
    event = %Event{
      type: :llm_response,
      timestamp: DateTime.utc_now(),
      correlation_id: correlation_id,
      data: %{
        model: model,
        content_length: String.length(content || ""),
        tool_call_count: length(tool_calls),
        duration_ms: duration_ms
      }
    }

    GenServer.cast(tracer, {:record, event})
  end

  def query_events(tracer, filters \\ %{}) do
    GenServer.call(tracer, {:query, filters})
  end

  def get_metrics(tracer) do
    GenServer.call(tracer, :get_metrics)
  end

  # Server Callbacks

  @impl true
  def init(_opts) do
    state = %{
      events: [],
      metrics: %{
        total_llm_calls: 0,
        total_tool_calls: 0,
        avg_response_time: 0.0
      }
    }

    {:ok, state}
  end

  @impl true
  def handle_cast({:record, event}, state) do
    new_events = [event | state.events]
    new_metrics = update_metrics(state.metrics, event)

    {:noreply, %{state | events: new_events, metrics: new_metrics}}
  end

  @impl true
  def handle_call({:query, filters}, _from, state) do
    filtered_events = apply_filters(state.events, filters)
    {:reply, filtered_events, state}
  end

  @impl true
  def handle_call(:get_metrics, _from, state) do
    {:reply, state.metrics, state}
  end

  defp update_metrics(metrics, %Event{type: :llm_call}) do
    %{metrics | total_llm_calls: metrics.total_llm_calls + 1}
  end

  defp update_metrics(metrics, %Event{type: :llm_response, data: %{duration_ms: duration}}) do
    total = metrics.total_llm_calls
    current_avg = metrics.avg_response_time
    new_avg = (current_avg * (total - 1) + duration) / total

    %{metrics | avg_response_time: new_avg}
  end

  defp update_metrics(metrics, %Event{type: :tool_call}) do
    %{metrics | total_tool_calls: metrics.total_tool_calls + 1}
  end

  defp update_metrics(metrics, _), do: metrics

  defp apply_filters(events, filters) do
    Enum.filter(events, fn event ->
      Enum.all?(filters, fn {key, value} ->
        Map.get(event, key) == value
      end)
    end)
  end
end
```

#### 2. Task for Concurrent Operations

**Parallel Tool Execution:**
```elixir
defmodule Mojentic.LLM.Broker do
  # ... existing code ...

  @doc """
  Executes multiple tools concurrently using Task.async_stream.
  """
  defp execute_tools_parallel(broker, tool_calls, tools, correlation_id) do
    tool_calls
    |> Task.async_stream(
      fn tool_call ->
        execute_tool(broker, tool_call, tools, correlation_id)
      end,
      max_concurrency: System.schedulers_online(),
      timeout: 30_000
    )
    |> Enum.map(fn
      {:ok, result} -> result
      {:exit, reason} -> {:error, {:tool_timeout, reason}}
    end)
  end

  @doc """
  Streams LLM responses asynchronously.
  """
  def generate_stream(broker, messages, tools \\ nil, config \\ nil) do
    config = config || %CompletionConfig{}

    Task.async(fn ->
      case broker.gateway.generate_stream(broker.model, messages, tools, config) do
        {:ok, stream} ->
          Stream.resource(
            fn -> stream end,
            fn stream ->
              case Enum.take(stream, 1) do
                [] -> {:halt, stream}
                [chunk] -> {[chunk], stream}
              end
            end,
            fn _ -> :ok end
          )

        {:error, reason} ->
          {:error, reason}
      end
    end)
  end
end
```

#### 3. Supervisor Trees for Fault Tolerance

**Application Supervision:**
```elixir
defmodule Mojentic.Application do
  use Application

  @moduledoc """
  Main application supervisor.

  Supervises all long-running OTP processes for fault tolerance.
  """

  @impl true
  def start(_type, _args) do
    children = [
      # Tracer system
      {Mojentic.Tracer.System, []},

      # Event store
      {Mojentic.Tracer.EventStore, []},

      # Dispatcher with dynamic supervisor for agents
      {Mojentic.Dispatcher, []},

      # Task supervisor for concurrent operations
      {Task.Supervisor, name: Mojentic.TaskSupervisor},

      # Registry for named sessions
      {Registry, keys: :unique, name: Mojentic.SessionRegistry},

      # DynamicSupervisor for chat sessions
      {DynamicSupervisor, name: Mojentic.SessionSupervisor, strategy: :one_for_one}
    ]

    opts = [strategy: :one_for_one, name: Mojentic.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

**ChatSession Supervisor:**
```elixir
defmodule Mojentic.LLM.ChatSession.Supervisor do
  @moduledoc """
  Dynamically supervises chat session processes.
  """

  def start_session(opts) do
    session_id = Keyword.get(opts, :id, UUID.uuid4())

    child_spec = %{
      id: ChatSession,
      start: {ChatSession, :start_link, [opts]},
      restart: :transient
    }

    case DynamicSupervisor.start_child(Mojentic.SessionSupervisor, child_spec) do
      {:ok, pid} ->
        Registry.register(Mojentic.SessionRegistry, session_id, pid)
        {:ok, session_id, pid}

      error ->
        error
    end
  end

  def get_session(session_id) do
    case Registry.lookup(Mojentic.SessionRegistry, session_id) do
      [{pid, _}] -> {:ok, pid}
      [] -> {:error, :session_not_found}
    end
  end

  def stop_session(session_id) do
    case get_session(session_id) do
      {:ok, pid} ->
        DynamicSupervisor.terminate_child(Mojentic.SessionSupervisor, pid)

      error ->
        error
    end
  end
end
```

#### 4. GenStage for Backpressure

**Event Processing Pipeline:**
```elixir
defmodule Mojentic.Dispatcher.Producer do
  use GenStage

  @moduledoc """
  Produces events for processing with backpressure.
  """

  def start_link(opts) do
    GenStage.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def dispatch(event) do
    GenServer.call(__MODULE__, {:dispatch, event})
  end

  @impl true
  def init(_opts) do
    {:producer, %{queue: :queue.new(), demand: 0}}
  end

  @impl true
  def handle_call({:dispatch, event}, _from, state) do
    new_queue = :queue.in(event, state.queue)
    {events, new_state} = take_events(new_queue, state.demand)
    {:reply, :ok, events, %{state | queue: new_queue, demand: new_state.demand}}
  end

  @impl true
  def handle_demand(incoming_demand, state) do
    total_demand = state.demand + incoming_demand
    {events, new_state} = take_events(state.queue, total_demand)
    {:noreply, events, new_state}
  end

  defp take_events(queue, demand) do
    {events, new_queue} = take_n(queue, demand)
    remaining_demand = demand - length(events)
    {events, %{queue: new_queue, demand: remaining_demand}}
  end

  defp take_n(queue, n, acc \\ [])
  defp take_n(queue, 0, acc), do: {Enum.reverse(acc), queue}
  defp take_n(queue, n, acc) do
    case :queue.out(queue) do
      {{:value, item}, new_queue} -> take_n(new_queue, n - 1, [item | acc])
      {:empty, queue} -> {Enum.reverse(acc), queue}
    end
  end
end

defmodule Mojentic.Dispatcher.Consumer do
  use GenStage

  @moduledoc """
  Consumes events and routes to appropriate agents.
  """

  def start_link(opts) do
    GenStage.start_link(__MODULE__, opts)
  end

  @impl true
  def init(opts) do
    router = Keyword.fetch!(opts, :router)
    subscribe_to = Keyword.get(opts, :subscribe_to, [Mojentic.Dispatcher.Producer])

    {:consumer, %{router: router}, subscribe_to: subscribe_to}
  end

  @impl true
  def handle_events(events, _from, state) do
    Enum.each(events, fn event ->
      case Router.route(state.router, event) do
        {:ok, agents} ->
          Enum.each(agents, fn agent ->
            Agent.handle_event(agent, event)
          end)

        {:error, reason} ->
          Logger.error("Failed to route event: #{inspect(reason)}")
      end
    end)

    {:noreply, [], state}
  end
end
```

#### 5. Distributed Coordination

**Distributed Agent Communication:**
```elixir
defmodule Mojentic.Agents.DistributedCoordinator do
  @moduledoc """
  Coordinates agents across multiple nodes using pg (Process Groups).
  """

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def join_group(agent_name, agent_pid) do
    :pg.join(:mojentic_agents, agent_name, agent_pid)
  end

  def leave_group(agent_name, agent_pid) do
    :pg.leave(:mojentic_agents, agent_name, agent_pid)
  end

  def broadcast_to_group(agent_name, message) do
    :pg.get_members(:mojentic_agents, agent_name)
    |> Enum.each(fn pid ->
      send(pid, message)
    end)
  end

  def find_agent(agent_name) do
    case :pg.get_members(:mojentic_agents, agent_name) do
      [] -> {:error, :agent_not_found}
      [pid | _] -> {:ok, pid}
    end
  end
end
```

### Async Patterns Comparison

| Pattern | Python (asyncio) | Rust (tokio) | TypeScript (Node.js) | Elixir (OTP) |
|---------|------------------|--------------|----------------------|--------------|
| **Concurrency Model** | Coroutines + event loop | Async tasks + runtime | Promises + event loop | Actors + BEAM scheduler |
| **State Management** | Class instances | Arc<Mutex<T>> | Class instances | GenServer processes |
| **Parallelism** | Threading/multiprocessing | Thread pool | Worker threads | Preemptive processes |
| **Fault Tolerance** | try/except | Result + ? operator | try/catch | Supervisor trees |
| **Backpressure** | Manual semaphores | Stream combinators | Manual buffering | GenStage built-in |
| **Distribution** | Manual (multiprocessing) | Manual (networking) | Manual (cluster module) | Built-in (Node.connect) |

### Performance Characteristics

**BEAM Advantages:**
1. **Preemptive Scheduling**: Unlike cooperative multitasking, BEAM prevents process starvation
2. **Per-Process GC**: Garbage collection doesn't stop the world
3. **Lightweight Processes**: Millions of concurrent processes with ~300 bytes overhead
4. **No Shared Memory**: Eliminates data races and most concurrency bugs
5. **Hot Code Loading**: Update code without stopping the system

**Optimization Strategies:**
1. Use `Task.async_stream/3` for bounded parallelism
2. Use ETS tables for shared read-heavy data
3. Use `:persistent_term` for truly immutable config
4. Profile with `:observer` and `:fprof`
5. Use NIF/Ports for CPU-intensive work

### Testing Async Behavior

```elixir
defmodule Mojentic.LLM.ChatSessionTest do
  use ExUnit.Case, async: true

  test "handles concurrent messages correctly" do
    {:ok, session} = ChatSession.start_link(broker: broker, system_prompt: "Test")

    # Spawn multiple concurrent senders
    tasks =
      for i <- 1..10 do
        Task.async(fn ->
          ChatSession.send_message(session, "Message #{i}")
        end)
      end

    # All should succeed
    results = Task.await_many(tasks)
    assert Enum.all?(results, &match?({:ok, _}, &1))

    # History should have all messages
    messages = ChatSession.get_messages(session)
    user_messages = Enum.filter(messages, &(&1.role == :user))
    assert length(user_messages) == 10
  end

  test "survives agent crashes with supervision" do
    # Start supervised session
    {:ok, session_id, pid} = ChatSession.Supervisor.start_session(broker: broker)

    # Send a message
    {:ok, _} = ChatSession.send_message(pid, "Hello")

    # Simulate crash
    Process.exit(pid, :kill)

    # Session should be restarted
    Process.sleep(100)
    {:ok, new_pid} = ChatSession.Supervisor.get_session(session_id)
    assert Process.alive?(new_pid)
  end
end
```

### Migration Path

**Phase 1: Core GenServers** (Week 1-2)
- Implement ChatSession as GenServer
- Implement Tracer as GenServer
- Add supervision trees
- Test concurrent access patterns

**Phase 2: Task-Based Concurrency** (Week 3)
- Parallel tool execution
- Async streaming responses
- Task supervision

**Phase 3: GenStage Pipeline** (Week 4)
- Event producer/consumer
- Backpressure handling
- Router integration

**Phase 4: Distribution** (Week 5)
- Multi-node coordination
- Distributed agent registry
- Node monitoring

### Example: Complete Async Workflow

```elixir
# Start supervised components
{:ok, _} = Mojentic.Application.start(:normal, [])

# Create a broker with tracer
{:ok, tracer} = Mojentic.Tracer.System.start_link()
broker = Broker.new("qwen3:32b", Ollama, tracer: tracer)

# Start a supervised chat session
{:ok, session_id, session} = ChatSession.Supervisor.start_session(
  broker: broker,
  system_prompt: "You are a helpful assistant.",
  tools: [DateResolverTool, WeatherTool]
)

# Multiple processes can send concurrently
tasks = [
  Task.async(fn -> ChatSession.send_message(session, "What day is tomorrow?") end),
  Task.async(fn -> ChatSession.send_message(session, "What's the weather in SF?") end),
  Task.async(fn -> ChatSession.send_message(session, "What did I just ask?") end)
]

# Wait for all to complete
responses = Task.await_many(tasks, 30_000)

# Get metrics from tracer
metrics = Tracer.System.get_metrics(tracer)
IO.inspect(metrics, label: "Performance Metrics")

# Query specific events
llm_calls = Tracer.System.query_events(tracer, %{type: :llm_call})
IO.inspect(length(llm_calls), label: "Total LLM Calls")

# Clean up
ChatSession.Supervisor.stop_session(session_id)
```

This OTP implementation provides:
- ✅ True parallelism (not just concurrency)
- ✅ Fault tolerance through supervision
- ✅ Automatic process restart on crashes
- ✅ Backpressure and flow control
- ✅ Distribution across multiple nodes
- ✅ Hot code reloading
- ✅ Built-in observability (`:observer`, `:sys`, etc.)

## Performance Considerations

### Optimization Targets

1. **Immutable Data**
   - Elixir's immutable data structures are optimized
   - Structural sharing reduces copying
   - Pattern matching is highly efficient

2. **Process-Based Concurrency**
   - Leverage BEAM's lightweight processes
   - Use concurrent tool execution
   - Async message processing in agents

3. **HTTP Connection Pooling**
   - Use hackney connection pools for HTTP requests
   - Reuse connections to LLM providers
   - Configure timeouts appropriately

4. **Message Passing**
   - Minimize data copying between processes
   - Use ETS for shared read-heavy data
   - Consider streaming for large responses

## Future Enhancements

### Short Term

- Streaming responses using Elixir streams
- Additional gateway implementations
- Phoenix LiveView integration examples
- Ecto integration for conversation persistence

### Medium Term

- Distributed agent coordination with pg2
- Conversation storage with PostgreSQL
- Prompt template system with EEx
- Rate limiting and retry with GenStage

### Long Term

- Nerves support for edge devices
- Broadway pipelines for batch processing
- Nx integration for local embeddings
- Vector database integration for RAG

## Conclusion

This plan outlines a comprehensive conversion of Mojentic from Python to Elixir, maintaining its core philosophy while leveraging Elixir's strengths in functional programming, pattern matching, and OTP concurrency. The resulting library will provide a familiar API for Python users while offering the benefits of the BEAM VM and Elixir ecosystem.

The phased approach ensures that the most stable and important features (Layer 1: LLM Integration) are implemented first, with the experimental agent system (Layer 2) following once the foundation is solid. The three example use cases (simple LLM, structured output, tool usage) will be fully functional in Phase 1.
