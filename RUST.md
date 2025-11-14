# Mojentic Rust Conversion Plan

## 🎯 Current Status (as of January 2025)

**Overall Progress: ~25% Complete** - Phase 1 & Core of Phase 2 Done

### ✅ What's Working Now:
- **Core Infrastructure**: Error handling, type system, traits all implemented
- **Ollama Gateway**: Fully functional with text generation, structured output, tool calling, and embeddings
- **LlmBroker**: Complete with recursive tool calling support
- **Examples**: Three working examples demonstrating key features
- **Basic Documentation**: README and implementation tracking docs

### 🚧 What's Next (Priority Order):
1. **OpenAI Gateway** - Critical for broader adoption
2. **Tracer System** - Essential for debugging and observability
3. **ChatSession** - Convenience wrapper for conversational AI
4. **Testing Infrastructure** - Unit and integration tests
5. **Anthropic Gateway** - Claude support

### ❌ Not Started:
- Agent system (Layer 2) - event-driven coordination
- CI/CD pipeline
- Comprehensive test suite
- Performance benchmarking
- Migration documentation

### 📊 Implementation Matrix

| Component | Status | Priority | Notes |
|-----------|--------|----------|-------|
| **Core Types** | ✅ Done | Critical | Error, Message, Gateway trait |
| **Ollama Gateway** | ✅ Done | High | Full featured |
| **LlmBroker** | ✅ Done | Critical | Tool calling works |
| **Tool System** | ✅ Done | High | Examples included |
| **OpenAI Gateway** | ❌ Todo | High | Next priority |
| **Tracer System** | ❌ Todo | High | Debugging essential |
| **ChatSession** | ❌ Todo | Medium | Convenience wrapper |
| **Anthropic Gateway** | ❌ Todo | Medium | Claude support |
| **Test Suite** | ❌ Todo | High | Quality critical |
| **Agent System** | ❌ Todo | Low | Future enhancement |
| **CI/CD** | ❌ Todo | Medium | Automation |

---

## Executive Summary

This document outlines the conversion of the Mojentic Python library to Rust. Mojentic is an LLM integration framework that provides a clean abstraction over multiple LLM providers (OpenAI, Ollama, Anthropic) with tool support, structured output generation, and an event-driven agent system.

The Rust version will maintain the same architecture and API design philosophy while leveraging Rust's type safety, performance, and concurrency features. We'll use modern Rust idioms and the ecosystem's best practices to create a library that feels native to Rust developers.

## Architecture Overview

### Layer 1: LLM Integration ⚠️ **PARTIALLY COMPLETE (~70%)**

This is the foundational layer providing direct LLM interaction capabilities.

**Core Components:**
- ✅ `LlmBroker` - Main interface for LLM interactions (COMPLETE)
- ✅ `LlmGateway` trait - Abstract interface for LLM providers (COMPLETE)
- ⚠️ Gateway implementations:
  - ❌ `OpenAiGateway` (NOT STARTED)
  - ✅ `OllamaGateway` (COMPLETE)
  - ❌ `AnthropicGateway` (NOT STARTED)
- ✅ Message models and adapters (COMPLETE)
- ✅ Tool system (COMPLETE)
- ❌ Tracer system for observability (NOT STARTED)

### Layer 2: Agent System ❌ **NOT STARTED (0%)**

Event-driven agent coordination system.

**Core Components:**
- ❌ `Dispatcher` - Event routing and processing
- ❌ `Router` - Event-to-agent routing configuration
- ❌ `BaseAgent` trait - Foundation for all agents
- ❌ Specialized agent implementations
- ❌ Async event processing

## Crate Structure

```
mojentic/
├── Cargo.toml                    ✅ COMPLETE
├── README.md                     ✅ COMPLETE
├── LICENSE.md                    ✅ COMPLETE (as LICENSE)
├── src/
│   ├── lib.rs                    ✅ COMPLETE - Main library entry point
│   ├── error.rs                  ✅ COMPLETE - Error types
│   ├── llm/
│   │   ├── mod.rs                ✅ COMPLETE
│   │   ├── broker.rs             ✅ COMPLETE - LlmBroker
│   │   ├── gateway.rs            ✅ COMPLETE - LlmGateway trait
│   │   ├── models.rs             ✅ COMPLETE - LlmMessage, LlmGatewayResponse, etc.
│   │   ├── chat_session.rs       ❌ NOT STARTED - ChatSession
│   │   ├── gateways/
│   │   │   ├── mod.rs            ✅ COMPLETE
│   │   │   ├── openai.rs         ❌ NOT STARTED - OpenAiGateway
│   │   │   ├── ollama.rs         ✅ COMPLETE - OllamaGateway
│   │   │   ├── anthropic.rs      ❌ NOT STARTED - AnthropicGateway
│   │   │   ├── tokenizer.rs      ❌ NOT STARTED - TokenizerGateway
│   │   │   ├── adapters/         ❌ NOT STARTED
│   │   │   │   ├── mod.rs
│   │   │   │   ├── openai.rs     ❌ NOT STARTED - OpenAI message adapter
│   │   │   │   ├── ollama.rs     ✅ COMPLETE (inline in ollama.rs)
│   │   │   │   └── anthropic.rs  ❌ NOT STARTED - Anthropic message adapter
│   │   │   └── registry/         ❌ NOT STARTED
│   │   │       ├── mod.rs
│   │   │       ├── models.rs     ❌ NOT STARTED - Model metadata
│   │   │       └── openai.rs     ❌ NOT STARTED - OpenAI model registry
│   │   └── tools/
│   │       ├── mod.rs            ✅ COMPLETE
│   │       ├── tool.rs           ✅ COMPLETE - LlmTool trait
│   │       ├── date_resolver.rs  ❌ NOT STARTED - Example tool
│   │       └── task_manager/     ❌ NOT STARTED - Task management tools
│   │           └── mod.rs
│   ├── tracer/                   ❌ NOT STARTED (empty directory)
│   │   ├── mod.rs
│   │   ├── system.rs             ❌ NOT STARTED - TracerSystem
│   │   ├── events.rs             ❌ NOT STARTED - Tracer event types
│   │   ├── event_store.rs        ❌ NOT STARTED - EventStore
│   │   └── null_tracer.rs        ❌ NOT STARTED - Null object pattern
│   ├── agents/                   ❌ NOT STARTED - Layer 2 (future)
│   │   ├── mod.rs
│   │   ├── base.rs               ❌ NOT STARTED - BaseAgent trait
│   │   ├── llm_agent.rs          ❌ NOT STARTED - LLM-enabled agents
│   │   └── async_agent.rs        ❌ NOT STARTED - Async agent support
│   ├── dispatcher.rs             ❌ NOT STARTED - Event dispatcher
│   ├── router.rs                 ❌ NOT STARTED - Event router
│   └── event.rs                  ❌ NOT STARTED - Event types
└── examples/
    ├── simple_llm.rs             ✅ COMPLETE
    ├── structured_output.rs      ✅ COMPLETE
    ├── tool_usage.rs             ✅ COMPLETE
    └── chat_session.rs           ❌ NOT STARTED
```

## Type System Design

### Core Models

```rust
// src/llm/models.rs

use serde::{Deserialize, Serialize};
use std::collections::HashMap;

/// Message role in LLM conversation
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum MessageRole {
    System,
    User,
    Assistant,
    Tool,
}

/// Content type for multimodal messages
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "type", rename_all = "lowercase")]
pub enum Content {
    Text {
        text: String,
        #[serde(skip_serializing_if = "Option::is_none")]
        annotations: Option<Annotations>,
    },
    Image {
        data: String, // base64 encoded
        #[serde(rename = "mimeType")]
        mime_type: String,
        #[serde(skip_serializing_if = "Option::is_none")]
        annotations: Option<Annotations>,
    },
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Annotations {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub audience: Option<Vec<MessageRole>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub priority: Option<f32>, // 0.0 to 1.0
}

/// Tool call from LLM
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LlmToolCall {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub id: Option<String>,
    pub name: String,
    pub arguments: HashMap<String, serde_json::Value>,
}

/// Message in LLM conversation
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LlmMessage {
    #[serde(default = "default_role")]
    pub role: MessageRole,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub content: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub tool_calls: Option<Vec<LlmToolCall>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub image_paths: Option<Vec<String>>,
}

fn default_role() -> MessageRole {
    MessageRole::User
}

/// Response from LLM gateway
#[derive(Debug, Clone)]
pub struct LlmGatewayResponse<T = ()> {
    pub content: Option<String>,
    pub object: Option<T>,
    pub tool_calls: Vec<LlmToolCall>,
}

impl LlmMessage {
    pub fn user(content: impl Into<String>) -> Self {
        Self {
            role: MessageRole::User,
            content: Some(content.into()),
            tool_calls: None,
            image_paths: None,
        }
    }

    pub fn system(content: impl Into<String>) -> Self {
        Self {
            role: MessageRole::System,
            content: Some(content.into()),
            tool_calls: None,
            image_paths: None,
        }
    }

    pub fn assistant(content: impl Into<String>) -> Self {
        Self {
            role: MessageRole::Assistant,
            content: Some(content.into()),
            tool_calls: None,
            image_paths: None,
        }
    }

    pub fn with_images(mut self, paths: Vec<String>) -> Self {
        self.image_paths = Some(paths);
        self
    }
}
```

### Error Handling

```rust
// src/error.rs

use thiserror::Error;

#[derive(Error, Debug)]
pub enum MojenticError {
    #[error("LLM gateway error: {0}")]
    GatewayError(String),

    #[error("API error: {0}")]
    ApiError(String),

    #[error("Serialization error: {0}")]
    SerializationError(#[from] serde_json::Error),

    #[error("HTTP error: {0}")]
    HttpError(#[from] reqwest::Error),

    #[error("Tool error: {0}")]
    ToolError(String),

    #[error("Model not supported: {0}")]
    ModelNotSupported(String),

    #[error("Invalid configuration: {0}")]
    ConfigError(String),

    #[error("Tokenization error: {0}")]
    TokenizationError(String),

    #[error("IO error: {0}")]
    IoError(#[from] std::io::Error),
}

pub type Result<T> = std::result::Result<T, MojenticError>;
```

### LLM Gateway Trait

```rust
// src/llm/gateway.rs

use crate::error::Result;
use crate::llm::models::{LlmMessage, LlmGatewayResponse};
use crate::llm::tools::LlmTool;
use async_trait::async_trait;
use serde::{Deserialize, Serialize};

/// Configuration for LLM completion
#[derive(Debug, Clone)]
pub struct CompletionConfig {
    pub temperature: f32,
    pub num_ctx: usize,
    pub max_tokens: usize,
    pub num_predict: Option<i32>,
}

impl Default for CompletionConfig {
    fn default() -> Self {
        Self {
            temperature: 1.0,
            num_ctx: 32768,
            max_tokens: 16384,
            num_predict: None,
        }
    }
}

#[async_trait]
pub trait LlmGateway: Send + Sync {
    /// Complete an LLM request with text response
    async fn complete(
        &self,
        model: &str,
        messages: &[LlmMessage],
        tools: Option<&[Box<dyn LlmTool>]>,
        config: &CompletionConfig,
    ) -> Result<LlmGatewayResponse>;

    /// Complete an LLM request with structured object response
    async fn complete_object<T>(
        &self,
        model: &str,
        messages: &[LlmMessage],
        config: &CompletionConfig,
    ) -> Result<LlmGatewayResponse<T>>
    where
        T: for<'de> Deserialize<'de> + Serialize + Send;

    /// Get list of available models
    async fn get_available_models(&self) -> Result<Vec<String>>;

    /// Calculate embeddings for text
    async fn calculate_embeddings(
        &self,
        text: &str,
        model: Option<&str>,
    ) -> Result<Vec<f32>>;
}
```

### LLM Broker

```rust
// src/llm/broker.rs

use crate::error::Result;
use crate::llm::gateway::{CompletionConfig, LlmGateway};
use crate::llm::models::{LlmMessage, LlmGatewayResponse, MessageRole};
use crate::llm::tools::LlmTool;
use crate::tracer::TracerSystem;
use serde::{Deserialize, Serialize};
use std::sync::Arc;
use std::time::Instant;
use tracing::{info, warn};

/// Main interface for LLM interactions
pub struct LlmBroker {
    model: String,
    gateway: Arc<dyn LlmGateway>,
    tracer: Arc<TracerSystem>,
}

impl LlmBroker {
    /// Create a new LLM broker
    pub fn new(
        model: impl Into<String>,
        gateway: Arc<dyn LlmGateway>,
        tracer: Option<Arc<TracerSystem>>,
    ) -> Self {
        Self {
            model: model.into(),
            gateway,
            tracer: tracer.unwrap_or_else(|| Arc::new(TracerSystem::null())),
        }
    }

    /// Generate text response from LLM
    pub async fn generate(
        &self,
        messages: &[LlmMessage],
        tools: Option<&[Box<dyn LlmTool>]>,
        config: Option<CompletionConfig>,
        correlation_id: Option<String>,
    ) -> Result<String> {
        let config = config.unwrap_or_default();
        let correlation_id = correlation_id.unwrap_or_else(|| uuid::Uuid::new_v4().to_string());

        // Record LLM call
        self.tracer.record_llm_call(
            &self.model,
            messages,
            config.temperature,
            tools,
            Some(&correlation_id),
        );

        let start = Instant::now();
        let mut current_messages = messages.to_vec();

        // Make initial LLM call
        let response = self.gateway.complete(
            &self.model,
            &current_messages,
            tools,
            &config,
        ).await?;

        let duration_ms = start.elapsed().as_millis() as f64;

        // Record LLM response
        self.tracer.record_llm_response(
            &self.model,
            response.content.as_deref(),
            &response.tool_calls,
            Some(duration_ms),
            Some(&correlation_id),
        );

        // Handle tool calls if present
        if !response.tool_calls.is_empty() && tools.is_some() {
            return self.handle_tool_calls(
                current_messages,
                response,
                tools.unwrap(),
                &config,
                &correlation_id,
            ).await;
        }

        Ok(response.content.unwrap_or_default())
    }

    async fn handle_tool_calls(
        &self,
        mut messages: Vec<LlmMessage>,
        response: LlmGatewayResponse,
        tools: &[Box<dyn LlmTool>],
        config: &CompletionConfig,
        correlation_id: &str,
    ) -> Result<String> {
        info!("Tool calls requested: {}", response.tool_calls.len());

        for tool_call in &response.tool_calls {
            // Find matching tool
            if let Some(tool) = tools.iter().find(|t| t.matches(&tool_call.name)) {
                info!("Executing tool: {}", tool_call.name);

                let start = Instant::now();
                let output = tool.run(&tool_call.arguments)?;
                let duration_ms = start.elapsed().as_millis() as f64;

                // Record tool execution
                self.tracer.record_tool_call(
                    &tool_call.name,
                    &tool_call.arguments,
                    &output,
                    Some("LlmBroker"),
                    Some(duration_ms),
                    Some(correlation_id),
                );

                // Add tool call and response to messages
                messages.push(LlmMessage {
                    role: MessageRole::Assistant,
                    content: None,
                    tool_calls: Some(vec![tool_call.clone()]),
                    image_paths: None,
                });
                messages.push(LlmMessage {
                    role: MessageRole::Tool,
                    content: Some(serde_json::to_string(&output)?),
                    tool_calls: Some(vec![tool_call.clone()]),
                    image_paths: None,
                });

                // Recursively call generate with updated messages
                return self.generate(&messages, Some(tools), Some(config.clone()), Some(correlation_id.to_string())).await;
            } else {
                warn!("Tool not found: {}", tool_call.name);
            }
        }

        Ok(response.content.unwrap_or_default())
    }

    /// Generate structured object response from LLM
    pub async fn generate_object<T>(
        &self,
        messages: &[LlmMessage],
        config: Option<CompletionConfig>,
        correlation_id: Option<String>,
    ) -> Result<T>
    where
        T: for<'de> Deserialize<'de> + Serialize + Send,
    {
        let config = config.unwrap_or_default();
        let correlation_id = correlation_id.unwrap_or_else(|| uuid::Uuid::new_v4().to_string());

        self.tracer.record_llm_call(
            &self.model,
            messages,
            config.temperature,
            None,
            Some(&correlation_id),
        );

        let start = Instant::now();
        let response = self.gateway.complete_object::<T>(
            &self.model,
            messages,
            &config,
        ).await?;

        let duration_ms = start.elapsed().as_millis() as f64;

        self.tracer.record_llm_response(
            &self.model,
            Some(&format!("Structured response: {:?}", response.object)),
            &[],
            Some(duration_ms),
            Some(&correlation_id),
        );

        response.object.ok_or_else(|| {
            crate::error::MojenticError::GatewayError("No object in response".to_string())
        })
    }
}
```

### Tool System

```rust
// src/llm/tools/tool.rs

use crate::error::Result;
use std::collections::HashMap;
use serde_json::Value;

/// Descriptor for tool function parameters
#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct ToolDescriptor {
    pub r#type: String,
    pub function: FunctionDescriptor,
}

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct FunctionDescriptor {
    pub name: String,
    pub description: String,
    pub parameters: Value,
}

/// Trait for LLM tools
pub trait LlmTool: Send + Sync {
    /// Execute the tool with given arguments
    fn run(&self, args: &HashMap<String, Value>) -> Result<Value>;

    /// Get tool descriptor for LLM
    fn descriptor(&self) -> ToolDescriptor;

    /// Get tool name
    fn name(&self) -> &str {
        &self.descriptor().function.name
    }

    /// Get tool description
    fn description(&self) -> &str {
        &self.descriptor().function.description
    }

    /// Check if this tool matches the given name
    fn matches(&self, name: &str) -> bool {
        self.name() == name
    }
}

// Example tool implementation
// src/llm/tools/date_resolver.rs

use super::tool::{LlmTool, ToolDescriptor, FunctionDescriptor};
use crate::error::Result;
use serde_json::{json, Value};
use std::collections::HashMap;

pub struct ResolveDateTool;

impl LlmTool for ResolveDateTool {
    fn run(&self, args: &HashMap<String, Value>) -> Result<Value> {
        let relative_date = args.get("relative_date_found")
            .and_then(|v| v.as_str())
            .ok_or_else(|| crate::error::MojenticError::ToolError(
                "Missing relative_date_found parameter".to_string()
            ))?;

        // Implementation would use chrono and similar libraries
        // This is a simplified example
        Ok(json!({
            "relative_date": relative_date,
            "resolved_date": "2025-01-15",
            "summary": format!("The date on '{}' is 2025-01-15", relative_date)
        }))
    }

    fn descriptor(&self) -> ToolDescriptor {
        ToolDescriptor {
            r#type: "function".to_string(),
            function: FunctionDescriptor {
                name: "resolve_date".to_string(),
                description: "Take text that specifies a relative date, and output an absolute date".to_string(),
                parameters: json!({
                    "type": "object",
                    "properties": {
                        "relative_date_found": {
                            "type": "string",
                            "description": "The text referencing a relative date"
                        },
                        "reference_date_in_iso8601": {
                            "type": "string",
                            "description": "The reference date in YYYY-MM-DD format"
                        }
                    },
                    "required": ["relative_date_found"]
                }),
            },
        }
    }
}
```

### OpenAI Gateway Implementation

```rust
// src/llm/gateways/openai.rs

use crate::error::{Result, MojenticError};
use crate::llm::gateway::{CompletionConfig, LlmGateway};
use crate::llm::models::{LlmMessage, LlmGatewayResponse};
use crate::llm::tools::LlmTool;
use async_trait::async_trait;
use reqwest::Client;
use serde::{Deserialize, Serialize};
use std::env;

pub struct OpenAiGateway {
    client: Client,
    api_key: String,
    base_url: String,
}

impl OpenAiGateway {
    pub fn new(api_key: Option<String>, base_url: Option<String>) -> Result<Self> {
        let api_key = api_key
            .or_else(|| env::var("OPENAI_API_KEY").ok())
            .ok_or_else(|| MojenticError::ConfigError(
                "OpenAI API key not provided".to_string()
            ))?;

        let base_url = base_url
            .or_else(|| env::var("OPENAI_API_ENDPOINT").ok())
            .unwrap_or_else(|| "https://api.openai.com/v1".to_string());

        Ok(Self {
            client: Client::new(),
            api_key,
            base_url,
        })
    }

    async fn adapt_parameters_for_model(
        &self,
        model: &str,
        config: &CompletionConfig,
    ) -> CompletionConfig {
        // Handle model-specific parameter adaptations
        // E.g., reasoning models use max_completion_tokens
        config.clone()
    }
}

#[async_trait]
impl LlmGateway for OpenAiGateway {
    async fn complete(
        &self,
        model: &str,
        messages: &[LlmMessage],
        tools: Option<&[Box<dyn LlmTool>]>,
        config: &CompletionConfig,
    ) -> Result<LlmGatewayResponse> {
        let adapted_config = self.adapt_parameters_for_model(model, config).await;

        // Convert messages to OpenAI format
        let openai_messages = adapt_messages_to_openai(messages)?;

        // Build request body
        let mut body = serde_json::json!({
            "model": model,
            "messages": openai_messages,
            "temperature": adapted_config.temperature,
            "max_tokens": adapted_config.max_tokens,
        });

        // Add tools if provided
        if let Some(tools) = tools {
            let tool_defs: Vec<_> = tools.iter()
                .map(|t| serde_json::to_value(t.descriptor()))
                .collect::<Result<Vec<_>, _>>()?;
            body["tools"] = serde_json::Value::Array(tool_defs);
        }

        // Make API request
        let response = self.client
            .post(format!("{}/chat/completions", self.base_url))
            .header("Authorization", format!("Bearer {}", self.api_key))
            .json(&body)
            .send()
            .await?;

        let response_body: serde_json::Value = response.json().await?;

        // Parse response
        // This would include proper error handling and parsing
        Ok(LlmGatewayResponse {
            content: Some(response_body["choices"][0]["message"]["content"]
                .as_str()
                .unwrap_or("")
                .to_string()),
            object: None,
            tool_calls: vec![],
        })
    }

    async fn complete_object<T>(
        &self,
        model: &str,
        messages: &[LlmMessage],
        config: &CompletionConfig,
    ) -> Result<LlmGatewayResponse<T>>
    where
        T: for<'de> Deserialize<'de> + Serialize + Send,
    {
        // Implementation using OpenAI's structured output feature
        todo!("Implement structured output")
    }

    async fn get_available_models(&self) -> Result<Vec<String>> {
        todo!("Implement model listing")
    }

    async fn calculate_embeddings(
        &self,
        text: &str,
        model: Option<&str>,
    ) -> Result<Vec<f32>> {
        todo!("Implement embeddings")
    }
}

// Helper function for message adaptation
fn adapt_messages_to_openai(messages: &[LlmMessage]) -> Result<Vec<serde_json::Value>> {
    messages.iter()
        .map(|msg| Ok(serde_json::json!({
            "role": msg.role,
            "content": msg.content,
        })))
        .collect()
}
```

### Ollama Gateway Implementation

```rust
// src/llm/gateways/ollama.rs

use crate::error::{Result, MojenticError};
use crate::llm::gateway::{CompletionConfig, LlmGateway};
use crate::llm::models::{LlmMessage, LlmGatewayResponse, LlmToolCall};
use crate::llm::tools::LlmTool;
use async_trait::async_trait;
use futures_util::StreamExt;
use reqwest::Client;
use serde::{Deserialize, Serialize};
use serde_json::Value;
use std::collections::HashMap;
use tracing::{debug, error, info};

/// Configuration for connecting to Ollama server
#[derive(Debug, Clone)]
pub struct OllamaConfig {
    pub host: String,
    pub timeout: Option<std::time::Duration>,
    pub headers: HashMap<String, String>,
}

impl Default for OllamaConfig {
    fn default() -> Self {
        Self {
            host: std::env::var("OLLAMA_HOST")
                .unwrap_or_else(|_| "http://localhost:11434".to_string()),
            timeout: None,
            headers: HashMap::new(),
        }
    }
}

/// Gateway for Ollama local LLM service
///
/// This gateway provides access to local LLM models through Ollama,
/// supporting text generation, structured output, tool calling, embeddings,
/// and streaming responses.
pub struct OllamaGateway {
    client: Client,
    config: OllamaConfig,
}

impl OllamaGateway {
    /// Create a new Ollama gateway with default configuration
    pub fn new() -> Self {
        Self::with_config(OllamaConfig::default())
    }

    /// Create a new Ollama gateway with custom configuration
    pub fn with_config(config: OllamaConfig) -> Self {
        let mut client_builder = Client::builder();

        if let Some(timeout) = config.timeout {
            client_builder = client_builder.timeout(timeout);
        }

        let client = client_builder.build().unwrap();

        Self { client, config }
    }

    /// Create gateway with custom host
    pub fn with_host(host: impl Into<String>) -> Self {
        Self::with_config(OllamaConfig {
            host: host.into(),
            ..Default::default()
        })
    }

    /// Pull a model from Ollama library
    pub async fn pull_model(&self, model: &str) -> Result<()> {
        info!("Pulling Ollama model: {}", model);

        let response = self.client
            .post(format!("{}/api/pull", self.config.host))
            .json(&serde_json::json!({
                "name": model
            }))
            .send()
            .await?;

        if !response.status().is_success() {
            return Err(MojenticError::GatewayError(
                format!("Failed to pull model {}: {}", model, response.status())
            ));
        }

        Ok(())
    }

    /// Stream chat completions (async iterator)
    pub async fn complete_stream(
        &self,
        model: &str,
        messages: &[LlmMessage],
        config: &CompletionConfig,
    ) -> Result<impl futures_util::Stream<Item = Result<String>>> {
        debug!("Streaming completion from Ollama");

        let ollama_messages = adapt_messages_to_ollama(messages)?;
        let options = extract_ollama_options(config);

        let body = serde_json::json!({
            "model": model,
            "messages": ollama_messages,
            "options": options,
            "stream": true
        });

        let response = self.client
            .post(format!("{}/api/chat", self.config.host))
            .json(&body)
            .send()
            .await?;

        if !response.status().is_success() {
            return Err(MojenticError::GatewayError(
                format!("Ollama API error: {}", response.status())
            ));
        }

        let stream = response.bytes_stream().map(|chunk_result| {
            chunk_result
                .map_err(|e| MojenticError::GatewayError(e.to_string()))
                .and_then(|chunk| {
                    // Parse each line as JSON
                    let text = String::from_utf8_lossy(&chunk);
                    for line in text.lines() {
                        if let Ok(json) = serde_json::from_str::<Value>(line) {
                            if let Some(content) = json["message"]["content"].as_str() {
                                if !content.is_empty() {
                                    return Ok(content.to_string());
                                }
                            }
                        }
                    }
                    Ok(String::new())
                })
                .and_then(|s| if s.is_empty() {
                    Err(MojenticError::GatewayError("Empty chunk".to_string()))
                } else {
                    Ok(s)
                })
        });

        Ok(stream)
    }
}

#[async_trait]
impl LlmGateway for OllamaGateway {
    async fn complete(
        &self,
        model: &str,
        messages: &[LlmMessage],
        tools: Option<&[Box<dyn LlmTool>]>,
        config: &CompletionConfig,
    ) -> Result<LlmGatewayResponse> {
        info!("Delegating to Ollama for completion");
        debug!("Model: {}, Message count: {}", model, messages.len());

        let ollama_messages = adapt_messages_to_ollama(messages)?;
        let options = extract_ollama_options(config);

        let mut body = serde_json::json!({
            "model": model,
            "messages": ollama_messages,
            "options": options,
            "stream": false
        });

        // Add tools if provided
        if let Some(tools) = tools {
            let tool_defs: Vec<_> = tools.iter()
                .map(|t| t.descriptor())
                .collect();
            body["tools"] = serde_json::to_value(tool_defs)?;
        }

        // Make API request
        let response = self.client
            .post(format!("{}/api/chat", self.config.host))
            .json(&body)
            .send()
            .await?;

        if !response.status().is_success() {
            return Err(MojenticError::GatewayError(
                format!("Ollama API error: {}", response.status())
            ));
        }

        let response_body: Value = response.json().await?;

        // Parse content
        let content = response_body["message"]["content"]
            .as_str()
            .map(String::from);

        // Parse tool calls if present
        let tool_calls = if let Some(calls) = response_body["message"]["tool_calls"].as_array() {
            calls.iter()
                .filter_map(|call| {
                    let name = call["function"]["name"].as_str()?.to_string();
                    let args = call["function"]["arguments"].as_object()?;

                    let arguments: HashMap<String, Value> = args.iter()
                        .map(|(k, v)| (k.clone(), v.clone()))
                        .collect();

                    Some(LlmToolCall {
                        id: call["id"].as_str().map(String::from),
                        name,
                        arguments,
                    })
                })
                .collect()
        } else {
            vec![]
        };

        Ok(LlmGatewayResponse {
            content,
            object: None,
            tool_calls,
        })
    }

    async fn complete_object<T>(
        &self,
        model: &str,
        messages: &[LlmMessage],
        config: &CompletionConfig,
    ) -> Result<LlmGatewayResponse<T>>
    where
        T: for<'de> Deserialize<'de> + Serialize + Send,
    {
        info!("Requesting structured output from Ollama");

        let ollama_messages = adapt_messages_to_ollama(messages)?;
        let options = extract_ollama_options(config);

        // Get JSON schema for the type
        let schema = serde_json::to_value(schemars::schema_for!(T))?;

        let body = serde_json::json!({
            "model": model,
            "messages": ollama_messages,
            "options": options,
            "format": schema,
            "stream": false
        });

        let response = self.client
            .post(format!("{}/api/chat", self.config.host))
            .json(&body)
            .send()
            .await?;

        if !response.status().is_success() {
            return Err(MojenticError::GatewayError(
                format!("Ollama API error: {}", response.status())
            ));
        }

        let response_body: Value = response.json().await?;
        let content = response_body["message"]["content"]
            .as_str()
            .ok_or_else(|| MojenticError::GatewayError(
                "No content in response".to_string()
            ))?;

        // Parse the JSON response into the target type
        let object: T = serde_json::from_str(content)
            .map_err(|e| MojenticError::SerializationError(e))?;

        Ok(LlmGatewayResponse {
            content: Some(content.to_string()),
            object: Some(object),
            tool_calls: vec![],
        })
    }

    async fn get_available_models(&self) -> Result<Vec<String>> {
        debug!("Fetching available Ollama models");

        let response = self.client
            .get(format!("{}/api/tags", self.config.host))
            .send()
            .await?;

        if !response.status().is_success() {
            return Err(MojenticError::GatewayError(
                format!("Failed to get models: {}", response.status())
            ));
        }

        let body: Value = response.json().await?;

        let models = body["models"]
            .as_array()
            .ok_or_else(|| MojenticError::GatewayError(
                "Invalid response format".to_string()
            ))?
            .iter()
            .filter_map(|m| m["name"].as_str().map(String::from))
            .collect::<Vec<_>>();

        Ok(models)
    }

    async fn calculate_embeddings(
        &self,
        text: &str,
        model: Option<&str>,
    ) -> Result<Vec<f32>> {
        let model = model.unwrap_or("mxbai-embed-large");
        debug!("Calculating embeddings with model: {}", model);

        let body = serde_json::json!({
            "model": model,
            "prompt": text
        });

        let response = self.client
            .post(format!("{}/api/embeddings", self.config.host))
            .json(&body)
            .send()
            .await?;

        if !response.status().is_success() {
            return Err(MojenticError::GatewayError(
                format!("Embeddings API error: {}", response.status())
            ));
        }

        let response_body: Value = response.json().await?;

        let embeddings = response_body["embedding"]
            .as_array()
            .ok_or_else(|| MojenticError::GatewayError(
                "Invalid embeddings response".to_string()
            ))?
            .iter()
            .filter_map(|v| v.as_f64().map(|f| f as f32))
            .collect();

        Ok(embeddings)
    }
}

// Message adapter for Ollama format
fn adapt_messages_to_ollama(messages: &[LlmMessage]) -> Result<Vec<Value>> {
    messages.iter()
        .map(|msg| {
            let mut ollama_msg = serde_json::json!({
                "role": match msg.role {
                    crate::llm::models::MessageRole::System => "system",
                    crate::llm::models::MessageRole::User => "user",
                    crate::llm::models::MessageRole::Assistant => "assistant",
                    crate::llm::models::MessageRole::Tool => "tool",
                },
                "content": msg.content.as_deref().unwrap_or("")
            });

            // Add images for user messages
            if let Some(image_paths) = &msg.image_paths {
                ollama_msg["images"] = serde_json::to_value(image_paths)?;
            }

            // Add tool calls for assistant messages
            if let Some(tool_calls) = &msg.tool_calls {
                let calls: Vec<_> = tool_calls.iter()
                    .map(|tc| serde_json::json!({
                        "type": "function",
                        "function": {
                            "name": tc.name,
                            "arguments": tc.arguments
                        }
                    }))
                    .collect();
                ollama_msg["tool_calls"] = serde_json::to_value(calls)?;
            }

            Ok(ollama_msg)
        })
        .collect()
}

// Extract Ollama-specific options from config
fn extract_ollama_options(config: &CompletionConfig) -> Value {
    let mut options = serde_json::json!({
        "temperature": config.temperature,
        "num_ctx": config.num_ctx,
    });

    if let Some(num_predict) = config.num_predict {
        if num_predict > 0 {
            options["num_predict"] = serde_json::json!(num_predict);
        }
    } else if config.max_tokens > 0 {
        options["num_predict"] = serde_json::json!(config.max_tokens);
    }

    options
}
```

### Tracer System

```rust
// src/tracer/system.rs

use crate::llm::models::{LlmMessage, LlmToolCall};
use crate::tracer::events::{TracerEvent, LlmCallEvent, LlmResponseEvent, ToolCallEvent};
use crate::tracer::event_store::EventStore;
use std::collections::HashMap;
use std::sync::{Arc, RwLock};
use serde_json::Value;

pub struct TracerSystem {
    event_store: Arc<RwLock<EventStore>>,
    enabled: bool,
}

impl TracerSystem {
    pub fn new(enabled: bool) -> Self {
        Self {
            event_store: Arc::new(RwLock::new(EventStore::new())),
            enabled,
        }
    }

    pub fn null() -> Self {
        Self::new(false)
    }

    pub fn record_llm_call(
        &self,
        model: &str,
        messages: &[LlmMessage],
        temperature: f32,
        tools: Option<&[Box<dyn crate::llm::tools::LlmTool>]>,
        correlation_id: Option<&str>,
    ) {
        if !self.enabled {
            return;
        }

        let event = LlmCallEvent {
            timestamp: std::time::SystemTime::now(),
            model: model.to_string(),
            messages: messages.to_vec(),
            temperature,
            tools: tools.map(|t| t.iter().map(|tool| tool.name().to_string()).collect()),
            correlation_id: correlation_id.map(String::from),
        };

        let mut store = self.event_store.write().unwrap();
        store.add(TracerEvent::LlmCall(event));
    }

    pub fn record_llm_response(
        &self,
        model: &str,
        content: Option<&str>,
        tool_calls: &[LlmToolCall],
        call_duration_ms: Option<f64>,
        correlation_id: Option<&str>,
    ) {
        if !self.enabled {
            return;
        }

        let event = LlmResponseEvent {
            timestamp: std::time::SystemTime::now(),
            model: model.to_string(),
            content: content.map(String::from),
            tool_calls: tool_calls.to_vec(),
            call_duration_ms,
            correlation_id: correlation_id.map(String::from),
        };

        let mut store = self.event_store.write().unwrap();
        store.add(TracerEvent::LlmResponse(event));
    }

    pub fn record_tool_call(
        &self,
        tool_name: &str,
        arguments: &HashMap<String, Value>,
        result: &Value,
        caller: Option<&str>,
        call_duration_ms: Option<f64>,
        correlation_id: Option<&str>,
    ) {
        if !self.enabled {
            return;
        }

        let event = ToolCallEvent {
            timestamp: std::time::SystemTime::now(),
            tool_name: tool_name.to_string(),
            arguments: arguments.clone(),
            result: result.clone(),
            caller: caller.map(String::from),
            call_duration_ms,
            correlation_id: correlation_id.map(String::from),
        };

        let mut store = self.event_store.write().unwrap();
        store.add(TracerEvent::ToolCall(event));
    }

    pub fn get_events(&self) -> Vec<TracerEvent> {
        let store = self.event_store.read().unwrap();
        store.get_all()
    }

    pub fn clear(&self) {
        let mut store = self.event_store.write().unwrap();
        store.clear();
    }
}
```

### Chat Session

```rust
// src/llm/chat_session.rs

use crate::error::Result;
use crate::llm::broker::LlmBroker;
use crate::llm::gateway::CompletionConfig;
use crate::llm::models::{LlmMessage, MessageRole};
use crate::llm::tools::LlmTool;
use std::sync::Arc;

pub struct ChatSession {
    llm: Arc<LlmBroker>,
    messages: Vec<LlmMessage>,
    tools: Option<Vec<Box<dyn LlmTool>>>,
    config: CompletionConfig,
}

impl ChatSession {
    pub fn new(
        llm: Arc<LlmBroker>,
        system_prompt: Option<String>,
        tools: Option<Vec<Box<dyn LlmTool>>>,
        config: Option<CompletionConfig>,
    ) -> Self {
        let mut messages = Vec::new();
        if let Some(prompt) = system_prompt {
            messages.push(LlmMessage::system(prompt));
        }

        Self {
            llm,
            messages,
            tools,
            config: config.unwrap_or_default(),
        }
    }

    pub async fn send(&mut self, query: impl Into<String>) -> Result<String> {
        self.messages.push(LlmMessage::user(query));

        let response = self.llm.generate(
            &self.messages,
            self.tools.as_deref(),
            Some(self.config.clone()),
            None,
        ).await?;

        self.messages.push(LlmMessage::assistant(&response));

        Ok(response)
    }

    pub fn get_messages(&self) -> &[LlmMessage] {
        &self.messages
    }

    pub fn clear(&mut self) {
        self.messages.clear();
    }
}
```

## Dependencies (Cargo.toml)

```toml
[package]
name = "mojentic"
version = "0.1.0"
edition = "2021"
authors = ["Stacey Vetzal <stacey@vetzal.com>"]
description = "An LLM integration framework for Rust"
license = "MIT"
repository = "https://github.com/svetzal/mojentic-rs"

[dependencies]
# Core async runtime
tokio = { version = "1", features = ["full"] }
async-trait = "0.1"
futures-util = "0.3"

# HTTP client
reqwest = { version = "0.11", features = ["json", "stream"] }

# Serialization
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
schemars = "0.8"  # For JSON schema generation (Ollama structured output)

# Error handling
thiserror = "1.0"
anyhow = "1.0"

# Logging
tracing = "0.1"
tracing-subscriber = { version = "0.3", features = ["env-filter"] }

# UUID generation
uuid = { version = "1.0", features = ["v4", "serde"] }

# Tokenization (consider tiktoken-rs or similar)
tiktoken-rs = "0.5"

# Date/time handling
chrono = "0.4"

# Environment variables
dotenv = "0.15"

# Optional: Anthropic SDK
anthropic-sdk = { version = "0.1", optional = true }

[dev-dependencies]
mockito = "1.0"
tokio-test = "0.4"

[features]
default = ["openai", "ollama"]
openai = []
ollama = []
anthropic = ["anthropic-sdk"]
full = ["openai", "ollama", "anthropic"]
```

## Implementation Strategy

### Phase 1: Core Infrastructure (Week 1-2) ✅ **COMPLETE**

1. **Project Setup** ✅ **COMPLETE**
   - ✅ Initialize Rust project with proper structure
   - ❌ Set up CI/CD with GitHub Actions
   - ❌ Configure linting (clippy), formatting (rustfmt)
   - ❌ Set up documentation generation

2. **Core Types and Traits** ✅ **COMPLETE**
   - ✅ Implement error types
   - ✅ Implement message models
   - ✅ Define `LlmGateway` trait
   - ✅ Define `LlmTool` trait
   - ❌ Implement basic tracer infrastructure

3. **Testing Infrastructure** ❌ **NOT STARTED**
   - ❌ Set up testing framework
   - ❌ Create mock implementations for testing
   - ❌ Write integration test structure

### Phase 2: LLM Integration Layer (Week 3-4) ⚠️ **PARTIALLY COMPLETE**

1. **LlmBroker Implementation** ✅ **COMPLETE**
   - ✅ Core generate() method
   - ✅ Tool calling logic (with recursive Box::pin pattern)
   - ✅ generate_object() for structured output
   - ❌ Token counting integration

2. **OpenAI Gateway** ❌ **NOT STARTED**
   - ❌ Basic completion API
   - ❌ Message adaptation
   - ❌ Model registry and parameter adaptation
   - ❌ Structured output support
   - ❌ Error handling

3. **Ollama Gateway** ✅ **COMPLETE**
   - ✅ Local LLM support
   - ✅ Message adaptation
   - ✅ Embeddings support
   - ✅ Model listing
   - ✅ Pull model helper
   - ✅ Configuration support

4. **Tool System** ✅ **COMPLETE**
   - ✅ Tool trait implementation
   - ✅ Example tools (weather tool in examples)
   - ✅ Tool execution and error handling

### Phase 3: Advanced Features (Week 5-6) ❌ **NOT STARTED**

1. **ChatSession** ❌ **NOT STARTED**
   - ❌ Message history management
   - ❌ Context window management
   - ❌ Token counting and truncation

2. **Tracer System** ❌ **NOT STARTED**
   - ❌ Event recording
   - ❌ Event querying
   - ❌ Correlation ID tracking
   - ❌ Performance metrics

3. **Anthropic Gateway** ❌ **NOT STARTED**
   - ❌ Claude API integration
   - ❌ Message adaptation
   - ❌ Tool support

### Phase 4: Agent System (Week 7-8) ❌ **NOT STARTED**

1. **Event System** ❌ **NOT STARTED**
   - ❌ Event types
   - ❌ Event dispatcher
   - ❌ Router implementation

2. **Base Agent Traits** ❌ **NOT STARTED**
   - ❌ BaseAgent trait
   - ❌ LLM agent implementations
   - ❌ Async agent support

3. **Async Dispatcher** ❌ **NOT STARTED**
   - ❌ Tokio-based event processing
   - ❌ Channel-based message passing
   - ❌ Graceful shutdown

### Phase 5: Polish and Documentation (Week 9-10) ⚠️ **PARTIALLY COMPLETE**

1. **Examples** ⚠️ **PARTIALLY COMPLETE**
   - ✅ Simple LLM usage (simple_llm.rs)
   - ✅ Structured output (structured_output.rs)
   - ✅ Tool usage (tool_usage.rs)
   - ❌ Chat sessions
   - ❌ Agent systems

2. **Documentation** ⚠️ **PARTIALLY COMPLETE**
   - ⚠️ API documentation (rustdoc) - basic, needs expansion
   - ✅ User guide (README.md)
   - ⚠️ Architecture documentation (IMPLEMENTATION.md exists)
   - ❌ Migration guide from Python

3. **Performance Optimization** ❌ **NOT STARTED**
   - ❌ Benchmarking
   - ❌ Memory optimization
   - ❌ Async performance tuning

## Key Design Decisions

### 1. Async by Default

Rust's async ecosystem is mature and well-suited for I/O-bound LLM operations. All gateway operations will be async using `async-trait` and `tokio`.

**Implementation Status**: ✅ **COMPLETE** - All async operations working with tokio

### 2. Type Safety Over Flexibility

Unlike Python's dynamic typing, we'll leverage Rust's type system:
- Enums for message roles and content types
- Generic types for structured output
- Trait objects for dynamic dispatch where needed

**Implementation Status**: ✅ **COMPLETE** - Strong typing throughout

### 3. Error Handling

Use `thiserror` for error types and `Result<T>` returns throughout. Provide detailed error messages and context.

**Implementation Status**: ✅ **COMPLETE** - MojenticError enum with proper conversions

### 4. Zero-Cost Abstractions

- Use trait objects (`dyn Trait`) only where dynamic dispatch is required
- Prefer compile-time polymorphism with generics
- Minimize allocations and cloning

**Implementation Status**: ⚠️ **PARTIAL** - Traits implemented, optimization pending

### 5. Builder Pattern

For complex configuration (like `CompletionConfig`), use the builder pattern for ergonomic API design.

**Implementation Status**: ⚠️ **PARTIAL** - CompletionConfig has defaults, but no builder pattern yet

### 6. Thread Safety

All major types (`LlmBroker`, `TracerSystem`, etc.) should be thread-safe using `Arc` and appropriate synchronization primitives.

**Implementation Status**: ⚠️ **PARTIAL** - LlmBroker uses Arc, TracerSystem not yet implemented

### 7. Feature Flags

Use Cargo features to make dependencies optional:
- `openai` - OpenAI support (default)
- `ollama` - Ollama support (default)
- `anthropic` - Anthropic support (optional)

**Implementation Status**: ✅ **COMPLETE** - Feature flags configured in Cargo.toml

## Implementation Notes & Deviations from Plan

### Significant Design Changes Made:

1. **Trait Object Safety for LlmGateway**
   - **Original Plan**: `complete_object<T>()` method with generic type parameter
   - **Implementation**: Changed to `complete_json()` returning `Value`
   - **Reason**: Generic methods prevent trait objects (`dyn LlmGateway`). Moving deserialization to `LlmBroker` keeps gateway trait object-safe.
   - **Impact**: Cleaner separation - gateways handle API, broker handles type conversion

2. **Async Recursion Pattern**
   - **Challenge**: Recursive async functions in `handle_tool_calls()`
   - **Solution**: Used `Box::pin()` to satisfy Rust's recursion requirements
   - **Code**: `Box::pin(async move { ... })` pattern for recursive tool calling

3. **Schema Generation**
   - **Original Plan**: Not specified in detail
   - **Implementation**: Using `schemars` crate for JSON Schema generation
   - **Reason**: Required for Ollama's structured output feature
   - **Impact**: All structs used with `generate_object()` must derive `JsonSchema`

4. **Tracer Integration**
   - **Original Plan**: Tracer integrated into LlmBroker from start
   - **Implementation**: Tracer system deferred, not yet in LlmBroker
   - **Reason**: Focused on core functionality first
   - **Next Step**: High priority for Phase 3

5. **Message Adaptation**
   - **Original Plan**: Separate adapter modules
   - **Implementation**: Inline adapter functions within gateway implementations
   - **Reason**: Simpler for now, can refactor if other gateways need similar logic
   - **Current**: `adapt_messages_to_ollama()` function in `ollama.rs`

## API Design Examples

### Simple Usage

```rust
use mojentic::prelude::*;

#[tokio::main]
async fn main() -> Result<()> {
    let gateway = OpenAiGateway::new(None, None)?;
    let broker = LlmBroker::new("gpt-4o", Arc::new(gateway), None);

    let messages = vec![
        LlmMessage::user("What is the capital of France?"),
    ];

    let response = broker.generate(&messages, None, None, None).await?;
    println!("Response: {}", response);

    Ok(())
}
```

### Structured Output

```rust
use mojentic::prelude::*;
use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize)]
struct Sentiment {
    label: String,
    confidence: f32,
}

#[tokio::main]
async fn main() -> Result<()> {
    let gateway = OpenAiGateway::new(None, None)?;
    let broker = LlmBroker::new("gpt-4o", Arc::new(gateway), None);

    let messages = vec![
        LlmMessage::user("This is amazing!"),
    ];

    let sentiment: Sentiment = broker.generate_object(&messages, None, None).await?;
    println!("Sentiment: {:?}", sentiment);

    Ok(())
}
```

### Tool Usage

```rust
use mojentic::prelude::*;

#[tokio::main]
async fn main() -> Result<()> {
    let gateway = OpenAiGateway::new(None, None)?;
    let broker = LlmBroker::new("gpt-4o", Arc::new(gateway), None);

    let tools: Vec<Box<dyn LlmTool>> = vec![
        Box::new(ResolveDateTool),
    ];

    let messages = vec![
        LlmMessage::user("What is the date next Friday?"),
    ];

    let response = broker.generate(&messages, Some(&tools), None, None).await?;
    println!("Response: {}", response);

    Ok(())
}
```

### Chat Session

```rust
use mojentic::prelude::*;

#[tokio::main]
async fn main() -> Result<()> {
    let gateway = OpenAiGateway::new(None, None)?;
    let broker = Arc::new(LlmBroker::new("gpt-4o", Arc::new(gateway), None));

    let mut session = ChatSession::new(
        broker,
        Some("You are a helpful assistant.".to_string()),
        None,
        None,
    );

    let response1 = session.send("Hello!").await?;
    println!("Assistant: {}", response1);

    let response2 = session.send("What did I just say?").await?;
    println!("Assistant: {}", response2);

    Ok(())
}
```

### Local LLM with Ollama

```rust
use mojentic::prelude::*;

#[tokio::main]
async fn main() -> Result<()> {
    // Create Ollama gateway (connects to local server by default)
    let gateway = OllamaGateway::new();

    // List available models
    let models = gateway.get_available_models().await?;
    println!("Available models: {:?}", models);

    // Pull a model if needed
    if !models.contains(&"qwen3:32b".to_string()) {
        gateway.pull_model("qwen3:32b").await?;
    }

    // Create broker with local model
    let broker = LlmBroker::new("qwen3:32b", Arc::new(gateway), None);

    let messages = vec![
        LlmMessage::user("Explain what Rust is in one sentence."),
    ];

    let response = broker.generate(&messages, None, None, None).await?;
    println!("Response: {}", response);

    Ok(())
}
```

### Streaming with Ollama

```rust
use mojentic::prelude::*;
use futures_util::StreamExt;

#[tokio::main]
async fn main() -> Result<()> {
    let gateway = OllamaGateway::new();
    let broker = LlmBroker::new("qwen3:32b", Arc::new(gateway), None);

    let messages = vec![
        LlmMessage::user("Write a short story about a robot."),
    ];

    let config = CompletionConfig::default();

    // Get a stream of response chunks
    let mut stream = gateway.complete_stream("qwen3:32b", &messages, &config).await?;

    print!("Response: ");
    while let Some(chunk) = stream.next().await {
        match chunk {
            Ok(text) => print!("{}", text),
            Err(e) => eprintln!("Error: {}", e),
        }
    }
    println!();

    Ok(())
}
```

### Local Embeddings with Ollama

```rust
use mojentic::prelude::*;

#[tokio::main]
async fn main() -> Result<()> {
    let gateway = OllamaGateway::new();

    // Calculate embeddings for semantic similarity
    let text1 = "The cat sits on the mat.";
    let text2 = "A feline rests on the rug.";
    let text3 = "The weather is sunny today.";

    let emb1 = gateway.calculate_embeddings(text1, Some("mxbai-embed-large")).await?;
    let emb2 = gateway.calculate_embeddings(text2, Some("mxbai-embed-large")).await?;
    let emb3 = gateway.calculate_embeddings(text3, Some("mxbai-embed-large")).await?;

    // Calculate cosine similarity
    let sim_1_2 = cosine_similarity(&emb1, &emb2);
    let sim_1_3 = cosine_similarity(&emb1, &emb3);

    println!("Similarity (cat/feline): {:.4}", sim_1_2);
    println!("Similarity (cat/weather): {:.4}", sim_1_3);

    Ok(())
}

fn cosine_similarity(a: &[f32], b: &[f32]) -> f32 {
    let dot: f32 = a.iter().zip(b.iter()).map(|(x, y)| x * y).sum();
    let mag_a: f32 = a.iter().map(|x| x * x).sum::<f32>().sqrt();
    let mag_b: f32 = b.iter().map(|x| x * x).sum::<f32>().sqrt();
    dot / (mag_a * mag_b)
}
```

### Structured Output with Local Models

```rust
use mojentic::prelude::*;
use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize, schemars::JsonSchema)]
struct RecipeAnalysis {
    cuisine: String,
    difficulty: String,
    cooking_time_minutes: u32,
    servings: u32,
}

#[tokio::main]
async fn main() -> Result<()> {
    let gateway = OllamaGateway::new();
    let broker = LlmBroker::new("qwen3:32b", Arc::new(gateway), None);

    let messages = vec![
        LlmMessage::user(
            "Analyze this recipe: Mix pasta with tomato sauce, \
             garlic, and basil. Cook for 15 minutes. Serves 4."
        ),
    ];

    let analysis: RecipeAnalysis = broker.generate_object(&messages, None, None).await?;

    println!("Cuisine: {}", analysis.cuisine);
    println!("Difficulty: {}", analysis.difficulty);
    println!("Time: {} minutes", analysis.cooking_time_minutes);
    println!("Servings: {}", analysis.servings);

    Ok(())
}
```

## Testing Strategy

### Unit Tests

- Test each component in isolation
- Use mock implementations of traits
- Test error conditions thoroughly

### Integration Tests

- Test against mock HTTP servers (using `mockito`)
- Test real API calls in CI (with proper credentials)
- Test tool execution and recursion

### Documentation Tests

- Include examples in rustdoc comments
- Ensure examples compile and run

### Benchmarks

- Benchmark critical paths (message serialization, token counting)
- Compare performance against Python version

## Migration Guide (Python → Rust)

### Key Differences

| Python | Rust | Notes |
|--------|------|-------|
| `LLMBroker` | `LlmBroker` | PEP8 → Rust naming conventions |
| `generate(messages=[...])` | `generate(&[...])` | Pass by reference, not ownership |
| `tools=[Tool()]` | `Some(&tools)` | Explicit Option type |
| `LLMMessage(content='...')` | `LlmMessage::user("...")` | Named constructors |
| Dynamic typing | Generic types | `generate_object::<T>()` |
| `Optional[TracerSystem]` | `Option<Arc<TracerSystem>>` | Explicit ownership |
| Exception handling | `Result<T>` | Explicit error handling |
| Threading/async | `tokio` + `Arc` | Explicit thread safety |

### Code Comparison

**Python:**
```python
from mojentic.llm import LLMBroker
from mojentic.llm.gateways import OpenAIGateway

broker = LLMBroker(model="gpt-4o", gateway=OpenAIGateway())
result = broker.generate(messages=[LLMMessage(content="Hello")])
```

**Rust:**
```rust
use mojentic::prelude::*;

let gateway = OpenAiGateway::new(None, None)?;
let broker = LlmBroker::new("gpt-4o", Arc::new(gateway), None);
let result = broker.generate(&[LlmMessage::user("Hello")], None, None, None).await?;
```

## Documentation Plan

### Rustdoc

- Comprehensive API documentation
- Code examples for all public APIs
- Module-level documentation explaining architecture

### User Guide

- Getting started tutorial
- Common patterns
- Best practices
- Performance tips

### Examples Directory

- `simple_llm.rs` - Basic usage
- `structured_output.rs` - Structured data extraction
- `tool_usage.rs` - Using tools with LLM
- `chat_session.rs` - Building a chat interface
- `async_agents.rs` - Agent coordination

### Architecture Documentation

- System design
- Component interaction diagrams
- Extension points

## Performance Considerations

### Optimization Targets

1. **Minimal Allocations**
   - Use string slices where possible
   - Avoid unnecessary clones
   - Pool buffers for serialization

2. **Async Performance**
   - Use tokio's work-stealing scheduler
   - Batch operations where possible
   - Use channels for agent communication

3. **Memory Efficiency**
   - Stream large responses
   - Implement token window trimming
   - Use Cow<str> for potentially borrowed data

4. **Compile Time**
   - Minimize generic instantiations
   - Use feature flags to reduce dependencies
   - Keep trait hierarchies simple

## Future Enhancements

### Short Term

- WebSocket streaming support for real-time responses
- Enhanced token counting with tiktoken-rs
- Additional gateway implementations (Google, Cohere, etc.)
- Rich tool result types (images, structured data)

### Medium Term

- Agent team coordination patterns
- Persistent conversation storage (SQLite, PostgreSQL)
- Prompt template system
- Rate limiting and retry logic
- Caching layer for LLM responses

### Long Term

- WASM support for browser usage
- Python bindings via PyO3
- Distributed agent execution
- Custom model fine-tuning integration
- Vector database integration for RAG patterns

## Conclusion

This plan outlines a comprehensive conversion of Mojentic from Python to Rust, maintaining its core philosophy while leveraging Rust's strengths in type safety, performance, and concurrency. The resulting library will provide a familiar API for Python users while offering the benefits of Rust's ecosystem to Rust developers.

The phased approach ensures that the most stable and important features (Layer 1: LLM Integration) are implemented first, with the experimental agent system (Layer 2) following once the foundation is solid.
