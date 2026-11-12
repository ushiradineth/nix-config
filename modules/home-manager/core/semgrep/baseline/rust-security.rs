// Static scanner fixtures only. Never build or execute.
use reqwest::Client as HttpClient;
use sqlx::query as raw_query;

fn tls_cases() {
    // ruleid: rust-reqwest-disabled-tls
    let _ = reqwest::Client::builder().danger_accept_invalid_certs(true).build();
    let builder = HttpClient::builder();
    // ruleid: rust-reqwest-disabled-tls
    let _ = builder.danger_accept_invalid_hostnames(true).build();
    // ruleid: rust-reqwest-disabled-tls
    let _ = reqwest::blocking::Client::builder().danger_accept_invalid_certs(true).build();
    let blocking = reqwest::blocking::ClientBuilder::new();
    // ruleid: rust-reqwest-disabled-tls
    let _ = blocking.danger_accept_invalid_hostnames(true).build();
    // ok: rust-reqwest-disabled-tls
    let _ = reqwest::Client::builder().danger_accept_invalid_certs(false).build();
    // ok: rust-reqwest-disabled-tls
    let _ = HttpClient::builder().build();
    // ok: rust-reqwest-disabled-tls
    let _ = unrelated_builder().danger_accept_invalid_certs(true);
}

fn sql_cases(input: &str) {
    // ruleid: rust-sqlx-formatted-query
    let _ = sqlx::query(&format!("SELECT * FROM items WHERE name = '{}'", input));
    let statement = format!("SELECT * FROM items WHERE name = '{}'", input);
    let copied = statement;
    // ruleid: rust-sqlx-formatted-query
    let _ = raw_query(&copied);
    // ruleid: rust-sqlx-formatted-query
    let _ = sqlx::query_as::<_, Item>(&format!("SELECT {} FROM items", input));
    // ruleid: rust-sqlx-formatted-query
    let _ = sqlx::query_scalar::<_, i64>(&format!("SELECT count(*) FROM {}", input));
    // ok: rust-sqlx-formatted-query
    let _ = sqlx::query("SELECT * FROM items WHERE name = $1").bind(input);
    // ok: rust-sqlx-formatted-query
    let _ = raw_query("SELECT * FROM items");
    // ok: rust-sqlx-formatted-query
    let _ = format!("log: {}", input);
}
