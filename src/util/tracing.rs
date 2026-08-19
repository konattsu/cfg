#[derive(Debug, Clone, Copy)]
pub enum TracingLevel {
    Error,
    Warn,
    Info,
    Debug,
    Trace,
}

impl TracingLevel {
    pub fn into_tracing_level_filter(self) -> tracing::level_filters::LevelFilter {
        match self {
            TracingLevel::Error => tracing::level_filters::LevelFilter::ERROR,
            TracingLevel::Warn => tracing::level_filters::LevelFilter::WARN,
            TracingLevel::Info => tracing::level_filters::LevelFilter::INFO,
            TracingLevel::Debug => tracing::level_filters::LevelFilter::DEBUG,
            TracingLevel::Trace => tracing::level_filters::LevelFilter::TRACE,
        }
    }
}

impl std::str::FromStr for TracingLevel {
    type Err = String;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s.trim().to_lowercase().as_str() {
            "error" => Ok(TracingLevel::Error),
            "warn" => Ok(TracingLevel::Warn),
            "info" => Ok(TracingLevel::Info),
            "debug" => Ok(TracingLevel::Debug),
            "trace" => Ok(TracingLevel::Trace),
            _ => Err(format!("Invalid tracing level: {s}")),
        }
    }
}

impl std::fmt::Display for TracingLevel {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        let level_str = match self {
            TracingLevel::Error => "error",
            TracingLevel::Warn => "warn",
            TracingLevel::Info => "info",
            TracingLevel::Debug => "debug",
            TracingLevel::Trace => "trace",
        };
        write!(f, "{level_str}")
    }
}

#[derive(Debug, Clone, Copy)]
pub struct StdoutSettings {
    pub quiet: bool,
    pub verbose: u8,
}

pub fn apply_tracing_settings(
    log_file_base_name: &str,
    stdout: StdoutSettings,
    file_level: Option<tracing::level_filters::LevelFilter>,
) -> Option<tracing_appender::non_blocking::WorkerGuard> {
    use tracing_subscriber::Layer;
    use tracing_subscriber::layer::SubscriberExt;
    use tracing_subscriber::util::SubscriberInitExt;

    let output_layer = tracing_subscriber::fmt::layer()
        .with_writer(std::io::stdout)
        .event_format(OutputFormatter)
        .with_filter(output_filter(stdout.quiet));

    let diagnostic_layer = tracing_subscriber::fmt::layer()
        .with_writer(std::io::stderr)
        .event_format(DiagnosticFormatter)
        .with_filter(diagnostic_filter(stdout.verbose));

    let (file_layer, guard) = match file_level {
        Some(level) => {
            let file_name = format!("{log_file_base_name}.log");
            let file_appender = tracing_appender::rolling::daily("./logs", file_name);
            let (non_blocking, guard) = tracing_appender::non_blocking(file_appender);
            let layer = tracing_subscriber::fmt::layer()
                .json()
                .with_writer(non_blocking)
                .with_filter(filter_level(Some(level)));
            (Some(layer), Some(guard))
        }
        None => (None, None),
    };

    tracing_subscriber::registry()
        .with(output_layer)
        .with(diagnostic_layer)
        .with(file_layer)
        .init();

    tracing::trace!(
        "tracing settings applied: stdout={stdout:?}, file_level={file_level:?}"
    );
    guard
}

fn output_filter(quiet: bool) -> tracing_subscriber::EnvFilter {
    if quiet {
        return tracing_subscriber::EnvFilter::new("off");
    }
    tracing_subscriber::EnvFilter::new("off,moi::output=info")
}

fn diagnostic_filter(verbose: u8) -> tracing_subscriber::EnvFilter {
    match verbose {
        0 => tracing_subscriber::EnvFilter::new("off"),
        1 => tracing_subscriber::EnvFilter::new("debug,moi::output=off,hyper_util=off"),
        _ => tracing_subscriber::EnvFilter::new("trace,moi::output=off"),
    }
}

fn filter_level(
    level: Option<tracing::level_filters::LevelFilter>,
) -> tracing_subscriber::EnvFilter {
    use tracing_subscriber::EnvFilter;

    let log_off = || {
        const NO_OUTPUT: &str = "off";
        EnvFilter::new(NO_OUTPUT)
    };

    match level.and_then(|lv| lv.into_level()) {
        Some(level) => match level {
            tracing::Level::TRACE => EnvFilter::new(level.as_str()),
            _ => {
                // trace 以外は hyper_util を off
                EnvFilter::new(format!("{level},hyper_util=off"))
            }
        },
        None => log_off(),
    }
}

// ref: https://docs.rs/tracing-subscriber/latest/tracing_subscriber/fmt/trait.FormatEvent.html

struct OutputFormatter;

impl<S, N> tracing_subscriber::fmt::FormatEvent<S, N> for OutputFormatter
where
    S: tracing::Subscriber + for<'a> tracing_subscriber::registry::LookupSpan<'a>,
    N: for<'a> tracing_subscriber::fmt::FormatFields<'a> + 'static,
{
    fn format_event(
        &self,
        ctx: &tracing_subscriber::fmt::FmtContext<'_, S, N>,
        mut writer: tracing_subscriber::fmt::format::Writer<'_>,
        event: &tracing::Event<'_>,
    ) -> std::fmt::Result {
        ctx.field_format().format_fields(writer.by_ref(), event)?;
        writeln!(writer)
    }
}

struct DiagnosticFormatter;

impl<S, N> tracing_subscriber::fmt::FormatEvent<S, N> for DiagnosticFormatter
where
    S: tracing::Subscriber + for<'a> tracing_subscriber::registry::LookupSpan<'a>,
    N: for<'a> tracing_subscriber::fmt::FormatFields<'a> + 'static,
{
    fn format_event(
        &self,
        ctx: &tracing_subscriber::fmt::FmtContext<'_, S, N>,
        mut writer: tracing_subscriber::fmt::format::Writer<'_>,
        event: &tracing::Event<'_>,
    ) -> std::fmt::Result {
        // Format values from the event's's metadata:
        let metadata = event.metadata();
        // write!(&mut writer, "{} {}: ", metadata.level(), metadata.target())?;

        write!(
            &mut writer,
            "{:<5} [{}:ln{}] ",
            metadata.level(),
            metadata.target(),
            metadata.line().unwrap_or_default()
        )?;

        if let Some(scope) = ctx.event_scope() {
            for span in scope.from_root() {
                write!(writer, "{}", span.name())?;

                // `FormattedFields` is a formatted representation of the span's
                // fields, which is stored in its extensions by the `fmt` layer's
                // `new_span` method. The fields will have been formatted
                // by the same field formatter that's provided to the event
                // formatter in the `FmtContext`.
                let ext = span.extensions();
                let fields = &ext
                    .get::<tracing_subscriber::fmt::FormattedFields<N>>()
                    .expect("will never be `None`");

                // Skip formatting the fields if the span had no fields.
                if !fields.is_empty() {
                    write!(writer, "{{{fields}}}")?;
                }
                write!(writer, ": ")?;
            }
        }

        // Write fields on the event
        ctx.field_format().format_fields(writer.by_ref(), event)?;

        writeln!(writer)
    }
}
