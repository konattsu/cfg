#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub(crate) struct Mode(u32);

impl Mode {
    pub(crate) fn value(self) -> u32 {
        self.0
    }

    pub(crate) fn new(mode: &str) -> Result<Self, String> {
        if !(3..=4).contains(&mode.len())
            || !mode.chars().all(|c| matches!(c, '0'..='7'))
        {
            return Err(format!("invalid mode: {mode}"));
        }
        u32::from_str_radix(mode, 8)
            .map(Self)
            .map_err(|_| format!("invalid mode: {mode}"))
    }
}

impl std::fmt::Display for Mode {
    fn fmt(&self, formatter: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(formatter, "{:04o}", self.0)
    }
}

impl<'de> serde::Deserialize<'de> for Mode {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: serde::Deserializer<'de>,
    {
        let raw = <String as serde::Deserialize>::deserialize(deserializer)?;
        Mode::new(&raw).map_err(serde::de::Error::custom)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_parse_success() {
        let valid_modes = [
            ("111", 0o111),
            ("155", 0o155),
            ("777", 0o777),
            ("0146", 0o146),
            ("7777", 0o7777),
            ("1755", 0o1755),
            ("0000", 0o0000),
            ("000", 0o000),
        ];

        for (mode, expected) in valid_modes {
            assert_eq!(Mode::new(mode).unwrap().value(), expected);
        }
    }

    #[test]
    fn test_parse_failure() {
        let invalid_modes = ["", "11", "11111", "811", "999", "7a7", "-777"];

        for mode in invalid_modes {
            assert!(Mode::new(mode).is_err());
        }
    }

    #[test]
    fn test_display_uses_four_octal_digits() {
        assert_eq!(Mode::new("7").unwrap_err(), "invalid mode: 7");
        assert_eq!(Mode::new("007").unwrap().to_string(), "0007");
        assert_eq!(Mode::new("644").unwrap().to_string(), "0644");
        assert_eq!(Mode::new("1755").unwrap().to_string(), "1755");
    }
}
