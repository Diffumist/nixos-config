use std::{
    collections::{BTreeMap, HashMap, HashSet},
    env,
    net::SocketAddr,
    path::{Path, PathBuf},
    sync::Arc,
    time::Duration,
};

use anyhow::{Context, Result, anyhow};
use axum::{
    Json, Router,
    extract::State,
    http::{HeaderMap, StatusCode},
    routing::{get, post},
};
use chrono::{DateTime, Utc};
use reqwest::{Client, Url, header as reqwest_header};
use serde::{Deserialize, Serialize};
use tokio::{
    net::TcpListener,
    sync::{Mutex, RwLock},
    time,
};
use tower_http::trace::TraceLayer;
use tracing::{error, info, warn};
use tracing_subscriber::{EnvFilter, fmt};

const TOKEN_HEADER: &str = "x-sema-token";

#[derive(Clone, Debug, Deserialize)]
struct Config {
    bind_addr: SocketAddr,
    #[serde(default = "default_scan_interval_seconds")]
    scan_interval_seconds: u64,
    #[serde(default = "default_state_path")]
    state_path: PathBuf,
    #[serde(default = "default_webhook_timeout_seconds")]
    webhook_timeout_seconds: u64,
    #[serde(default = "default_webhook_retry_attempts")]
    webhook_retry_attempts: u8,
    checks: Vec<CheckConfig>,
}

#[derive(Clone, Debug, Deserialize)]
struct CheckConfig {
    id: String,
    token: String,
    period_seconds: u64,
    grace_seconds: u64,
    #[serde(default)]
    remind_every_seconds: Option<u64>,
    #[serde(default)]
    webhooks: Vec<WebhookConfig>,
}

#[derive(Clone, Debug, Deserialize)]
struct WebhookConfig {
    url: String,
    #[serde(default)]
    headers: BTreeMap<String, String>,
}

#[derive(Clone, Debug, Deserialize, Serialize)]
struct StoredState {
    checks: BTreeMap<String, CheckState>,
    #[serde(default)]
    outbox: BTreeMap<String, QueuedNotification>,
}

#[derive(Clone, Debug, Deserialize, Serialize)]
struct CheckState {
    created_at: DateTime<Utc>,
    last_ping_at: Option<DateTime<Utc>>,
    status: CheckStatus,
    last_down_notified_at: Option<DateTime<Utc>>,
    last_recovery_notified_at: Option<DateTime<Utc>>,
}

#[derive(Clone, Copy, Debug, Deserialize, Eq, PartialEq, Serialize)]
#[serde(rename_all = "snake_case")]
enum CheckStatus {
    Up,
    Down,
}

#[derive(Clone, Debug, Deserialize, Serialize)]
struct QueuedNotification {
    id: String,
    group_id: String,
    check_id: String,
    event: NotificationEvent,
    payload: NotificationPayload,
    webhook_index: usize,
    created_at: DateTime<Utc>,
}

#[derive(Clone, Debug)]
struct NotificationDispatch {
    id: String,
    check_id: String,
    webhook_index: usize,
    payload: NotificationPayload,
}

#[derive(Clone, Debug)]
struct PersistedMutation<T> {
    value: T,
    changed: bool,
}

#[derive(Clone)]
struct AppState {
    config: Arc<Config>,
    token_index: Arc<HashMap<String, String>>,
    check_index: Arc<HashMap<String, CheckConfig>>,
    state: Arc<RwLock<StoredState>>,
    persist_lock: Arc<Mutex<()>>,
    in_flight_notifications: Arc<Mutex<HashSet<String>>>,
    started_at: DateTime<Utc>,
    client: Client,
}

#[derive(Clone, Debug, Serialize)]
struct CheckSnapshot {
    id: String,
    status: CheckStatus,
    created_at: DateTime<Utc>,
    last_ping_at: Option<DateTime<Utc>>,
    due_at: DateTime<Utc>,
    seconds_until_down: i64,
    last_down_notified_at: Option<DateTime<Utc>>,
    last_recovery_notified_at: Option<DateTime<Utc>>,
}

#[derive(Clone, Debug, Serialize)]
struct PingResponse {
    id: String,
    status: CheckStatus,
    received_at: DateTime<Utc>,
}

#[derive(Clone, Debug, Serialize)]
struct ErrorResponse {
    error: String,
}

#[derive(Clone, Debug, Deserialize, Serialize)]
struct NotificationPayload {
    event: NotificationEvent,
    check_id: String,
    status: CheckStatus,
    detected_at: DateTime<Utc>,
    last_ping_at: Option<DateTime<Utc>>,
    overdue_seconds: i64,
}

#[derive(Clone, Copy, Debug, Deserialize, Eq, PartialEq, Serialize)]
#[serde(rename_all = "snake_case")]
enum NotificationEvent {
    Down,
    DownReminder,
    Recovery,
}

#[tokio::main]
async fn main() -> Result<()> {
    init_tracing();

    let config_path = parse_config_path(env::args())?;
    let config = Arc::new(read_config(&config_path).await?);
    validate_config(&config)?;

    let client = Client::builder()
        .timeout(Duration::from_secs(config.webhook_timeout_seconds))
        .build()
        .context("failed to build webhook HTTP client")?;

    let state = Arc::new(RwLock::new(load_or_init_state(&config).await?));
    {
        let state_guard = state.read().await;
        persist_state(&config.state_path, &state_guard).await?;
    }

    let app_state = AppState {
        token_index: Arc::new(build_token_index(&config)),
        check_index: Arc::new(build_check_index(&config)),
        config,
        state,
        persist_lock: Arc::new(Mutex::new(())),
        in_flight_notifications: Arc::new(Mutex::new(HashSet::new())),
        started_at: Utc::now(),
        client,
    };

    spawn_scanner(app_state.clone());

    let app = Router::new()
        .route("/health", get(health))
        .route("/status", get(status))
        .route("/ping", post(ping))
        .layer(TraceLayer::new_for_http())
        .with_state(app_state.clone());

    let listener = TcpListener::bind(app_state.config.bind_addr)
        .await
        .with_context(|| format!("failed to bind {}", app_state.config.bind_addr))?;

    info!(addr = %app_state.config.bind_addr, "sema listening");

    axum::serve(listener, app)
        .with_graceful_shutdown(shutdown_signal())
        .await
        .context("server failed")?;

    Ok(())
}

fn init_tracing() {
    let filter = EnvFilter::try_from_default_env().unwrap_or_else(|_| EnvFilter::new("info"));
    fmt().with_env_filter(filter).init();
}

fn parse_config_path(args: impl IntoIterator<Item = String>) -> Result<PathBuf> {
    let mut args = args.into_iter().skip(1);
    let mut config_path = PathBuf::from("sema.toml");

    while let Some(arg) = args.next() {
        match arg.as_str() {
            "--config" | "-c" => {
                config_path = args
                    .next()
                    .map(PathBuf::from)
                    .ok_or_else(|| anyhow!("{arg} requires a path"))?;
            }
            "--help" | "-h" => {
                println!("Usage: sema [--config sema.toml]");
                std::process::exit(0);
            }
            other => return Err(anyhow!("unknown argument: {other}")),
        }
    }

    Ok(config_path)
}

async fn read_config(path: &Path) -> Result<Config> {
    let raw = tokio::fs::read_to_string(path)
        .await
        .with_context(|| format!("failed to read config {}", path.display()))?;

    toml::from_str(&raw).with_context(|| format!("failed to parse config {}", path.display()))
}

fn validate_config(config: &Config) -> Result<()> {
    let mut ids = HashMap::new();
    let mut tokens = HashMap::new();

    if config.scan_interval_seconds == 0 {
        return Err(anyhow!("scan_interval_seconds must be > 0"));
    }
    if config.webhook_timeout_seconds == 0 {
        return Err(anyhow!("webhook_timeout_seconds must be > 0"));
    }

    for check in &config.checks {
        if check.id.trim().is_empty() {
            return Err(anyhow!("check id cannot be empty"));
        }
        if check.token.len() < 24 {
            return Err(anyhow!(
                "check {} token is too short; use at least 24 characters",
                check.id
            ));
        }
        if check.period_seconds == 0 {
            return Err(anyhow!("check {} period_seconds must be > 0", check.id));
        }
        if check.grace_seconds == 0 {
            return Err(anyhow!("check {} grace_seconds must be > 0", check.id));
        }
        let due_seconds = check
            .period_seconds
            .checked_add(check.grace_seconds)
            .ok_or_else(|| anyhow!("check {} deadline seconds overflow", check.id))?;
        if due_seconds > i64::MAX as u64 {
            return Err(anyhow!("check {} deadline seconds exceed i64", check.id));
        }
        if ids.insert(check.id.as_str(), ()).is_some() {
            return Err(anyhow!("duplicate check id {}", check.id));
        }
        if tokens
            .insert(check.token.as_str(), check.id.as_str())
            .is_some()
        {
            return Err(anyhow!("duplicate token for check {}", check.id));
        }
        for webhook in &check.webhooks {
            validate_webhook(check, webhook)?;
        }
    }

    Ok(())
}

fn validate_webhook(check: &CheckConfig, webhook: &WebhookConfig) -> Result<()> {
    let url = Url::parse(&webhook.url)
        .with_context(|| format!("check {} has invalid webhook URL", check.id))?;
    if !matches!(url.scheme(), "http" | "https") {
        return Err(anyhow!(
            "check {} webhook URL must use http or https",
            check.id
        ));
    }

    for (name, value) in &webhook.headers {
        reqwest_header::HeaderName::from_bytes(name.as_bytes())
            .with_context(|| format!("check {} has invalid webhook header {name}", check.id))?;
        reqwest_header::HeaderValue::from_str(value).with_context(|| {
            format!(
                "check {} has invalid webhook header value for {name}",
                check.id
            )
        })?;
    }

    Ok(())
}

fn build_token_index(config: &Config) -> HashMap<String, String> {
    config
        .checks
        .iter()
        .map(|check| (check.token.clone(), check.id.clone()))
        .collect()
}

fn build_check_index(config: &Config) -> HashMap<String, CheckConfig> {
    config
        .checks
        .iter()
        .map(|check| (check.id.clone(), check.clone()))
        .collect()
}

async fn load_or_init_state(config: &Config) -> Result<StoredState> {
    let now = Utc::now();
    let stored = match tokio::fs::read_to_string(&config.state_path).await {
        Ok(raw) => match serde_json::from_str::<StoredState>(&raw) {
            Ok(state) => state,
            Err(error) => {
                warn!(
                    path = %config.state_path.display(),
                    error = %error,
                    "state file is invalid; starting with empty state"
                );
                empty_state()
            }
        },
        Err(error) if error.kind() == std::io::ErrorKind::NotFound => empty_state(),
        Err(error) => {
            return Err(error)
                .with_context(|| format!("failed to read state {}", config.state_path.display()));
        }
    };

    Ok(merge_configured_checks(config, stored, now))
}

fn empty_state() -> StoredState {
    StoredState {
        checks: BTreeMap::new(),
        outbox: BTreeMap::new(),
    }
}

fn merge_configured_checks(
    config: &Config,
    mut stored: StoredState,
    now: DateTime<Utc>,
) -> StoredState {
    let configured: BTreeMap<_, _> = config
        .checks
        .iter()
        .map(|check| (check.id.as_str(), check))
        .collect();

    stored
        .checks
        .retain(|id, _| configured.contains_key(id.as_str()));
    stored.outbox.retain(|_, notification| {
        configured
            .get(notification.check_id.as_str())
            .is_some_and(|check| notification.webhook_index < check.webhooks.len())
    });

    for check in &config.checks {
        stored
            .checks
            .entry(check.id.clone())
            .or_insert_with(|| CheckState {
                created_at: now,
                last_ping_at: None,
                status: CheckStatus::Up,
                last_down_notified_at: None,
                last_recovery_notified_at: None,
            });
    }

    stored
}

async fn persist_state(path: &Path, state: &StoredState) -> Result<()> {
    let encoded = serde_json::to_string_pretty(state).context("failed to encode state")?;
    if let Some(parent) = path.parent().filter(|parent| !parent.as_os_str().is_empty()) {
        tokio::fs::create_dir_all(parent)
            .await
            .with_context(|| format!("failed to create state directory {}", parent.display()))?;
    }

    let temp_path = path.with_extension(format!(
        "tmp.{}.{}",
        std::process::id(),
        Utc::now().timestamp_nanos_opt().unwrap_or_default()
    ));

    tokio::fs::write(&temp_path, encoded)
        .await
        .with_context(|| format!("failed to write state temp file {}", temp_path.display()))?;
    tokio::fs::rename(&temp_path, path).await.with_context(|| {
        format!(
            "failed to replace state {} with {}",
            path.display(),
            temp_path.display()
        )
    })
}

async fn health() -> StatusCode {
    StatusCode::NO_CONTENT
}

async fn status(State(app): State<AppState>) -> Json<Vec<CheckSnapshot>> {
    let now = Utc::now();
    let state = app.state.read().await;
    let snapshots = app
        .config
        .checks
        .iter()
        .filter_map(|check| {
            state.checks.get(&check.id).map(|check_state| {
                let due_at = due_at(check, check_state);
                CheckSnapshot {
                    id: check.id.clone(),
                    status: check_state.status,
                    created_at: check_state.created_at,
                    last_ping_at: check_state.last_ping_at,
                    due_at,
                    seconds_until_down: (due_at - now).num_seconds(),
                    last_down_notified_at: check_state.last_down_notified_at,
                    last_recovery_notified_at: check_state.last_recovery_notified_at,
                }
            })
        })
        .collect();

    Json(snapshots)
}

async fn ping(
    State(app): State<AppState>,
    headers: HeaderMap,
) -> Result<Json<PingResponse>, (StatusCode, Json<ErrorResponse>)> {
    let token = extract_token(&headers)?;
    let Some(check_id) = app.token_index.get(token).cloned() else {
        return Err((
            StatusCode::NOT_FOUND,
            Json(ErrorResponse {
                error: "unknown check token".to_string(),
            }),
        ));
    };

    let Some(check) = app.check_index.get(&check_id).cloned() else {
        return Err((
            StatusCode::NOT_FOUND,
            Json(ErrorResponse {
                error: "check is not configured".to_string(),
            }),
        ));
    };

    let now = Utc::now();
    update_state(&app, |state| {
        let check_state = state
            .checks
            .get_mut(&check_id)
            .ok_or_else(|| anyhow!("check state is missing"))?;

        let was_down = check_state.status == CheckStatus::Down;
        check_state.last_ping_at = Some(now);
        check_state.status = CheckStatus::Up;

        if was_down {
            let payload = NotificationPayload {
                event: NotificationEvent::Recovery,
                check_id: check.id.clone(),
                status: CheckStatus::Up,
                detected_at: now,
                last_ping_at: check_state.last_ping_at,
                overdue_seconds: 0,
            };
            enqueue_notification(state, &check, payload, now);
        }

        Ok(PersistedMutation {
            value: (),
            changed: true,
        })
    })
    .await
    .map_err(|error| internal_error(error.to_string()))?;

    dispatch_outbox(app.clone()).await;

    Ok(Json(PingResponse {
        id: check_id,
        status: CheckStatus::Up,
        received_at: now,
    }))
}

fn extract_token(headers: &HeaderMap) -> Result<&str, (StatusCode, Json<ErrorResponse>)> {
    headers
        .get(TOKEN_HEADER)
        .ok_or_else(|| {
            (
                StatusCode::UNAUTHORIZED,
                Json(ErrorResponse {
                    error: format!("missing {TOKEN_HEADER} header"),
                }),
            )
        })?
        .to_str()
        .map_err(|_| {
            (
                StatusCode::BAD_REQUEST,
                Json(ErrorResponse {
                    error: format!("{TOKEN_HEADER} header is not valid ASCII"),
                }),
            )
        })
}

fn internal_error(error: String) -> (StatusCode, Json<ErrorResponse>) {
    (
        StatusCode::INTERNAL_SERVER_ERROR,
        Json(ErrorResponse { error }),
    )
}

async fn update_state<T>(
    app: &AppState,
    mutate: impl FnOnce(&mut StoredState) -> Result<PersistedMutation<T>>,
) -> Result<T> {
    let _persist_guard = app.persist_lock.lock().await;
    let (old_state, next_state, result, changed) = {
        let mut state = app.state.write().await;
        let old_state = state.clone();
        let mutation = mutate(&mut state)?;
        let next_state = state.clone();
        (old_state, next_state, mutation.value, mutation.changed)
    };

    if !changed {
        return Ok(result);
    }

    if let Err(error) = persist_state(&app.config.state_path, &next_state).await {
        let mut state = app.state.write().await;
        *state = old_state;
        return Err(error);
    }

    Ok(result)
}

fn spawn_scanner(app: AppState) {
    tokio::spawn(async move {
        let mut interval = time::interval(Duration::from_secs(app.config.scan_interval_seconds));
        interval.set_missed_tick_behavior(time::MissedTickBehavior::Delay);

        loop {
            interval.tick().await;
            if let Err(error) = scan_once(app.clone()).await {
                error!(error = %error, "scan failed");
            }
        }
    });
}

async fn scan_once(app: AppState) -> Result<()> {
    let now = Utc::now();
    update_state(&app, |state| {
        let mut changed = false;
        for check in &app.config.checks {
            if is_in_startup_grace(app.started_at, check, now) {
                continue;
            }

            let Some(check_state) = state.checks.get(&check.id).cloned() else {
                warn!(check_id = %check.id, "configured check has no state");
                continue;
            };

            let due_at = due_at(check, &check_state);
            if now < due_at {
                continue;
            }

            let overdue_seconds = (now - due_at).num_seconds();
            match check_state.status {
                CheckStatus::Up => {
                    if let Some(stored_check) = state.checks.get_mut(&check.id) {
                        stored_check.status = CheckStatus::Down;
                    }
                    let payload = NotificationPayload {
                        event: NotificationEvent::Down,
                        check_id: check.id.clone(),
                        status: CheckStatus::Down,
                        detected_at: now,
                        last_ping_at: check_state.last_ping_at,
                        overdue_seconds,
                    };
                    enqueue_notification(state, check, payload, now);
                    changed = true;
                }
                CheckStatus::Down => {
                    if should_send_reminder(check, &check_state, now)
                        && !has_pending_down_notification(state, &check.id)
                    {
                        let payload = NotificationPayload {
                            event: NotificationEvent::DownReminder,
                            check_id: check.id.clone(),
                            status: CheckStatus::Down,
                            detected_at: now,
                            last_ping_at: check_state.last_ping_at,
                            overdue_seconds,
                        };
                        enqueue_notification(state, check, payload, now);
                        changed = true;
                    }
                }
            }
        }

        Ok(PersistedMutation { value: (), changed })
    })
    .await?;

    dispatch_outbox(app.clone()).await;

    Ok(())
}

fn is_in_startup_grace(started_at: DateTime<Utc>, check: &CheckConfig, now: DateTime<Utc>) -> bool {
    (now - started_at).num_seconds() < check.grace_seconds as i64
}

fn should_send_reminder(check: &CheckConfig, state: &CheckState, now: DateTime<Utc>) -> bool {
    let Some(remind_every_seconds) = check.remind_every_seconds else {
        return false;
    };
    if remind_every_seconds == 0 {
        return false;
    }

    state
        .last_down_notified_at
        .is_none_or(|last| (now - last).num_seconds() >= remind_every_seconds as i64)
}

fn has_pending_down_notification(state: &StoredState, check_id: &str) -> bool {
    state.outbox.values().any(|notification| {
        notification.check_id == check_id
            && matches!(
                notification.event,
                NotificationEvent::Down | NotificationEvent::DownReminder
            )
    })
}

fn enqueue_notification(
    state: &mut StoredState,
    check: &CheckConfig,
    payload: NotificationPayload,
    created_at: DateTime<Utc>,
) {
    if check.webhooks.is_empty() {
        warn!(
            check_id = %payload.check_id,
            event = ?payload.event,
            "check has no webhook targets"
        );
        return;
    }

    let group_id = notification_group_id(&payload);
    if state
        .outbox
        .values()
        .any(|notification| notification.group_id == group_id)
    {
        return;
    }

    for webhook_index in 0..check.webhooks.len() {
        let id = notification_id(&group_id, webhook_index);
        state.outbox.insert(id.clone(), QueuedNotification {
            id,
            group_id: group_id.clone(),
            check_id: check.id.clone(),
            event: payload.event,
            payload: payload.clone(),
            webhook_index,
            created_at,
        });
    }
}

fn notification_group_id(payload: &NotificationPayload) -> String {
    format!(
        "{}:{}:{}",
        payload.detected_at.timestamp_millis(),
        payload.check_id,
        event_key(payload.event)
    )
}

fn notification_id(group_id: &str, webhook_index: usize) -> String {
    format!("{group_id}:{webhook_index}")
}

fn event_key(event: NotificationEvent) -> &'static str {
    match event {
        NotificationEvent::Down => "down",
        NotificationEvent::DownReminder => "down_reminder",
        NotificationEvent::Recovery => "recovery",
    }
}

async fn dispatch_outbox(app: AppState) {
    let candidates = {
        let state = app.state.read().await;
        dispatch_candidates(&state)
    };

    let mut dispatches = Vec::new();
    {
        let mut in_flight = app.in_flight_notifications.lock().await;
        for candidate in candidates {
            if in_flight.insert(candidate.id.clone()) {
                dispatches.push(candidate);
            }
        }
    }

    for dispatch in dispatches {
        let app = app.clone();
        tokio::spawn(async move {
            if deliver_notification(&app, &dispatch).await
                && let Err(error) = complete_notification(&app, &dispatch).await
            {
                error!(
                    notification_id = %dispatch.id,
                    error = %error,
                    "failed to persist delivered notification"
                );
            }

            let mut in_flight = app.in_flight_notifications.lock().await;
            in_flight.remove(&dispatch.id);
        });
    }
}

fn dispatch_candidates(state: &StoredState) -> Vec<NotificationDispatch> {
    let mut active_groups = HashMap::new();
    for notification in state.outbox.values() {
        active_groups
            .entry(notification.check_id.clone())
            .or_insert_with(|| notification.group_id.clone());
    }

    state
        .outbox
        .values()
        .filter(|notification| {
            active_groups
                .get(&notification.check_id)
                .is_some_and(|group_id| group_id == &notification.group_id)
        })
        .map(|notification| NotificationDispatch {
            id: notification.id.clone(),
            check_id: notification.check_id.clone(),
            webhook_index: notification.webhook_index,
            payload: notification.payload.clone(),
        })
        .collect()
}

async fn deliver_notification(app: &AppState, dispatch: &NotificationDispatch) -> bool {
    let Some(check) = app.check_index.get(&dispatch.check_id) else {
        error!(
            check_id = %dispatch.check_id,
            notification_id = %dispatch.id,
            "queued notification references an unknown check"
        );
        return false;
    };
    let Some(webhook) = check.webhooks.get(dispatch.webhook_index).cloned() else {
        error!(
            check_id = %dispatch.check_id,
            notification_id = %dispatch.id,
            webhook_index = dispatch.webhook_index,
            "queued notification references an unknown webhook"
        );
        return false;
    };

    send_with_retry(
        app.client.clone(),
        webhook,
        app.config.webhook_retry_attempts,
        dispatch.payload.clone(),
    )
    .await
}

async fn complete_notification(app: &AppState, dispatch: &NotificationDispatch) -> Result<()> {
    let delivered_at = Utc::now();
    update_state(app, |state| {
        let Some(notification) = state.outbox.remove(&dispatch.id) else {
            return Ok(PersistedMutation {
                value: (),
                changed: false,
            });
        };
        let group_complete = !state
            .outbox
            .values()
            .any(|pending| pending.group_id == notification.group_id);

        if group_complete
            && let Some(check_state) = state.checks.get_mut(&notification.check_id)
        {
            mark_notified(check_state, notification.event, delivered_at);
        }

        Ok(PersistedMutation {
            value: (),
            changed: true,
        })
    })
    .await
}

fn mark_notified(state: &mut CheckState, event: NotificationEvent, delivered_at: DateTime<Utc>) {
    match event {
        NotificationEvent::Down | NotificationEvent::DownReminder => {
            state.last_down_notified_at = Some(delivered_at);
        }
        NotificationEvent::Recovery => {
            state.last_recovery_notified_at = Some(delivered_at);
        }
    }
}

async fn send_with_retry(
    client: Client,
    webhook: WebhookConfig,
    attempts: u8,
    payload: NotificationPayload,
) -> bool {
    let attempts = attempts.max(1);
    for attempt in 1..=attempts {
        match send_webhook(&client, &webhook, &payload).await {
            Ok(()) => {
                info!(
                    url = %webhook.url,
                    check_id = %payload.check_id,
                    event = ?payload.event,
                    attempt,
                    "webhook delivered"
                );
                return true;
            }
            Err(error) if attempt < attempts => {
                warn!(
                    url = %webhook.url,
                    check_id = %payload.check_id,
                    event = ?payload.event,
                    attempt,
                    error = %error,
                    "webhook attempt failed"
                );
                time::sleep(Duration::from_millis(250 * u64::from(attempt))).await;
            }
            Err(error) => {
                error!(
                    url = %webhook.url,
                    check_id = %payload.check_id,
                    event = ?payload.event,
                    attempt,
                    error = %error,
                    "webhook delivery failed"
                );
            }
        }
    }

    false
}

async fn send_webhook(
    client: &Client,
    webhook: &WebhookConfig,
    payload: &NotificationPayload,
) -> Result<()> {
    let mut request = client.post(&webhook.url).json(payload);
    let mut headers = reqwest_header::HeaderMap::new();

    for (name, value) in &webhook.headers {
        let name = reqwest_header::HeaderName::from_bytes(name.as_bytes())
            .with_context(|| format!("invalid webhook header name {name}"))?;
        let value = reqwest_header::HeaderValue::from_str(value)
            .with_context(|| format!("invalid webhook header value for {name}"))?;
        headers.insert(name, value);
    }

    request = request.headers(headers);
    let response = request.send().await.context("request failed")?;
    let status = response.status();

    if !status.is_success() {
        return Err(anyhow!("webhook returned HTTP {status}"));
    }

    Ok(())
}

fn due_at(check: &CheckConfig, state: &CheckState) -> DateTime<Utc> {
    let base = state.last_ping_at.unwrap_or(state.created_at);
    let seconds = check
        .period_seconds
        .checked_add(check.grace_seconds)
        .expect("config validation rejects deadline overflow");
    base + chrono::Duration::seconds(seconds as i64)
}

async fn shutdown_signal() {
    #[cfg(unix)]
    {
        let mut term = match tokio::signal::unix::signal(
            tokio::signal::unix::SignalKind::terminate(),
        ) {
            Ok(term) => term,
            Err(error) => {
                error!(error = %error, "failed to listen for SIGTERM");
                wait_for_ctrl_c().await;
                return;
            }
        };

        tokio::select! {
            _ = wait_for_ctrl_c() => {}
            _ = term.recv() => {}
        }
    }

    #[cfg(not(unix))]
    wait_for_ctrl_c().await;
}

async fn wait_for_ctrl_c() {
    if let Err(error) = tokio::signal::ctrl_c().await {
        error!(error = %error, "failed to listen for Ctrl-C");
    }
}

fn default_scan_interval_seconds() -> u64 {
    30
}

fn default_state_path() -> PathBuf {
    PathBuf::from("sema-state.json")
}

fn default_webhook_timeout_seconds() -> u64 {
    5
}

fn default_webhook_retry_attempts() -> u8 {
    3
}

#[cfg(test)]
mod tests {
    use super::*;
    use axum::http::HeaderValue;
    use chrono::SecondsFormat;

    fn check(remind_every_seconds: Option<u64>) -> CheckConfig {
        CheckConfig {
            id: "backup".to_string(),
            token: "abcdefghijklmnopqrstuvwxyz".to_string(),
            period_seconds: 60,
            grace_seconds: 180,
            remind_every_seconds,
            webhooks: vec![],
        }
    }

    fn check_with_webhooks(webhook_count: usize) -> CheckConfig {
        CheckConfig {
            webhooks: (0..webhook_count)
                .map(|index| WebhookConfig {
                    url: format!("https://example.com/hooks/{index}"),
                    headers: BTreeMap::new(),
                })
                .collect(),
            ..check(Some(3600))
        }
    }

    fn check_state(status: CheckStatus, now: DateTime<Utc>) -> CheckState {
        CheckState {
            created_at: now,
            last_ping_at: None,
            status,
            last_down_notified_at: None,
            last_recovery_notified_at: None,
        }
    }

    fn stored_state(now: DateTime<Utc>) -> StoredState {
        StoredState {
            checks: BTreeMap::from([(
                "backup".to_string(),
                check_state(CheckStatus::Up, now),
            )]),
            outbox: BTreeMap::new(),
        }
    }

    fn payload(
        event: NotificationEvent,
        status: CheckStatus,
        detected_at: DateTime<Utc>,
    ) -> NotificationPayload {
        NotificationPayload {
            event,
            check_id: "backup".to_string(),
            status,
            detected_at,
            last_ping_at: None,
            overdue_seconds: 60,
        }
    }

    fn config_with_state_path(state_path: PathBuf) -> Config {
        Config {
            bind_addr: "127.0.0.1:8080".parse().unwrap(),
            scan_interval_seconds: 30,
            state_path,
            webhook_timeout_seconds: 5,
            webhook_retry_attempts: 3,
            checks: vec![check(None)],
        }
    }

    #[test]
    fn due_at_includes_grace_time() {
        let created_at = DateTime::parse_from_rfc3339("2026-06-16T00:00:00Z")
            .unwrap()
            .with_timezone(&Utc);
        let state = CheckState {
            created_at,
            last_ping_at: None,
            status: CheckStatus::Up,
            last_down_notified_at: None,
            last_recovery_notified_at: None,
        };

        assert_eq!(
            due_at(&check(None), &state).to_rfc3339_opts(SecondsFormat::Secs, true),
            "2026-06-16T00:04:00Z"
        );
    }

    #[test]
    fn down_reminder_requires_interval() {
        let now = DateTime::parse_from_rfc3339("2026-06-16T01:00:00Z")
            .unwrap()
            .with_timezone(&Utc);
        let state = CheckState {
            created_at: now,
            last_ping_at: None,
            status: CheckStatus::Down,
            last_down_notified_at: Some(now - chrono::Duration::seconds(3599)),
            last_recovery_notified_at: None,
        };

        assert!(!should_send_reminder(&check(Some(3600)), &state, now));
        assert!(should_send_reminder(
            &check(Some(3600)),
            &CheckState {
                last_down_notified_at: Some(now - chrono::Duration::seconds(3600)),
                ..state
            },
            now
        ));
        assert!(!should_send_reminder(&check(None), &state, now));
        assert!(!should_send_reminder(&check(Some(0)), &state, now));
    }

    #[test]
    fn enqueue_notification_persists_one_item_per_webhook_without_marking_notified() {
        let now = DateTime::parse_from_rfc3339("2026-06-16T02:00:00Z")
            .unwrap()
            .with_timezone(&Utc);
        let mut state = stored_state(now);
        let check = check_with_webhooks(2);

        enqueue_notification(
            &mut state,
            &check,
            payload(NotificationEvent::Down, CheckStatus::Down, now),
            now,
        );

        assert_eq!(state.outbox.len(), 2);
        assert!(state.outbox.values().all(|item| item.check_id == "backup"));
        assert_eq!(
            state
                .checks
                .get("backup")
                .and_then(|item| item.last_down_notified_at),
            None
        );
    }

    #[test]
    fn enqueue_notification_is_idempotent_for_same_event() {
        let now = DateTime::parse_from_rfc3339("2026-06-16T02:00:00Z")
            .unwrap()
            .with_timezone(&Utc);
        let mut state = stored_state(now);
        let check = check_with_webhooks(2);
        let payload = payload(NotificationEvent::Down, CheckStatus::Down, now);

        enqueue_notification(&mut state, &check, payload.clone(), now);
        enqueue_notification(&mut state, &check, payload, now);

        assert_eq!(state.outbox.len(), 2);
    }

    #[test]
    fn dispatch_candidates_preserve_per_check_event_order() {
        let now = DateTime::parse_from_rfc3339("2026-06-16T02:00:00Z")
            .unwrap()
            .with_timezone(&Utc);
        let later = now + chrono::Duration::seconds(30);
        let mut state = stored_state(now);
        let check = check_with_webhooks(1);

        enqueue_notification(
            &mut state,
            &check,
            payload(NotificationEvent::Down, CheckStatus::Down, now),
            now,
        );
        enqueue_notification(
            &mut state,
            &check,
            payload(NotificationEvent::Recovery, CheckStatus::Up, later),
            later,
        );

        let candidates = dispatch_candidates(&state);

        assert_eq!(candidates.len(), 1);
        assert_eq!(candidates[0].payload.event, NotificationEvent::Down);
    }

    #[test]
    fn mark_notified_updates_only_after_group_is_complete() {
        let now = DateTime::parse_from_rfc3339("2026-06-16T02:00:00Z")
            .unwrap()
            .with_timezone(&Utc);
        let mut state = stored_state(now);
        let check = check_with_webhooks(2);

        enqueue_notification(
            &mut state,
            &check,
            payload(NotificationEvent::Down, CheckStatus::Down, now),
            now,
        );

        let first_id = state.outbox.keys().next().cloned().unwrap();
        let first = state.outbox.remove(&first_id).unwrap();
        let group_complete = !state
            .outbox
            .values()
            .any(|pending| pending.group_id == first.group_id);

        assert!(!group_complete);
        assert_eq!(
            state
                .checks
                .get("backup")
                .and_then(|item| item.last_down_notified_at),
            None
        );

        let second_id = state.outbox.keys().next().cloned().unwrap();
        let second = state.outbox.remove(&second_id).unwrap();
        let group_complete = !state
            .outbox
            .values()
            .any(|pending| pending.group_id == second.group_id);

        assert!(group_complete);
        mark_notified(
            state.checks.get_mut("backup").unwrap(),
            second.event,
            now,
        );
        assert_eq!(
            state
                .checks
                .get("backup")
                .and_then(|item| item.last_down_notified_at),
            Some(now)
        );
    }

    #[test]
    fn startup_grace_blocks_early_down_detection() {
        let started_at = DateTime::parse_from_rfc3339("2026-06-16T02:00:00Z")
            .unwrap()
            .with_timezone(&Utc);
        let check = check(Some(3600));

        assert!(is_in_startup_grace(
            started_at,
            &check,
            started_at + chrono::Duration::seconds(179)
        ));
        assert!(!is_in_startup_grace(
            started_at,
            &check,
            started_at + chrono::Duration::seconds(180)
        ));
    }

    #[test]
    fn token_header_is_required() {
        let mut headers = HeaderMap::new();

        assert!(extract_token(&headers).is_err());

        headers.insert(TOKEN_HEADER, HeaderValue::from_static("abcdefghijklmnopqrstuvwxyz"));
        assert_eq!(
            extract_token(&headers).unwrap(),
            "abcdefghijklmnopqrstuvwxyz"
        );
    }

    #[test]
    fn validate_config_rejects_invalid_webhook_url() {
        let config = Config {
            bind_addr: "127.0.0.1:8080".parse().unwrap(),
            scan_interval_seconds: 30,
            state_path: PathBuf::from("state.json"),
            webhook_timeout_seconds: 5,
            webhook_retry_attempts: 3,
            checks: vec![CheckConfig {
                webhooks: vec![WebhookConfig {
                    url: "file:///tmp/hook".to_string(),
                    headers: BTreeMap::new(),
                }],
                ..check(None)
            }],
        };

        assert!(validate_config(&config).is_err());
    }

    #[tokio::test]
    async fn load_or_init_state_recovers_from_invalid_state_file() {
        let path = std::env::temp_dir().join(format!(
            "sema-invalid-state-{}.json",
            Utc::now().timestamp_nanos_opt().unwrap()
        ));
        std::fs::write(&path, "{not valid json").unwrap();

        let state = load_or_init_state(&config_with_state_path(path.clone()))
            .await
            .unwrap();

        let _ = std::fs::remove_file(path);
        assert_eq!(state.outbox.len(), 0);
        assert!(state.checks.contains_key("backup"));
    }
}
