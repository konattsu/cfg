#[macro_export]
macro_rules! output {
    () => {
        tracing::info!(target: "moi::output", "")
    };
    ($($arg:tt)*) => {
        tracing::info!(target: "moi::output", $($arg)*)
    };
}
