use anyhow::Result;
use backend_blindbit_native::async_trait::async_trait;
use backend_blindbit_native::HttpClient;
use std::time::Duration;

/// Async HTTP client implementation using reqwest
#[derive(Clone)]
pub struct ReqwestClient {
    client: reqwest::Client,
}

impl ReqwestClient {
    pub fn new() -> Result<Self> {
        // Configure client with performance optimizations
        // No global timeouts - they were causing 10x performance degradation
        let client = reqwest::Client::builder()
            .pool_max_idle_per_host(10)                        // Keep 10 connections per host for reuse
            .pool_idle_timeout(Duration::from_secs(90))        // Keep idle connections alive for 90s
            .tcp_nodelay(true)                                 // Disable Nagle's algorithm for lower latency
            .tcp_keepalive(Some(Duration::from_secs(60)))      // TCP keep-alive to prevent connection drops
            .build()?;
        
        Ok(Self { client })
    }
}

#[async_trait]
impl HttpClient for ReqwestClient {
    async fn get(&self, url: &str, query_params: &[(&str, String)]) -> Result<String> {
        let mut req = self.client.get(url);
        
        for (key, val) in query_params {
            req = req.query(&[(key, val)]);
        }
        
        let response = req.send().await?;
        let text = response.text().await?;
        Ok(text)
    }

    async fn post_json(&self, url: &str, json_body: &str) -> Result<String> {
        let response = self.client
            .post(url)
            .header("Content-Type", "application/json")
            .body(json_body.to_string())
            .send()
            .await?;
        
        let text = response.text().await?;
        Ok(text)
    }
}

