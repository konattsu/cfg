#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub(crate) enum PlatformFilter {
    Common,
    Debian,
    Arch,
}

impl PlatformFilter {
    pub(crate) fn matches(self, platform: crate::platform::Platform) -> bool {
        match self {
            PlatformFilter::Common => true,
            PlatformFilter::Debian => platform == crate::platform::Platform::Debian,
            PlatformFilter::Arch => platform == crate::platform::Platform::Arch,
        }
    }

    pub(crate) fn label(self) -> &'static str {
        match self {
            PlatformFilter::Common => "",
            PlatformFilter::Debian => " [debian]",
            PlatformFilter::Arch => " [arch]",
        }
    }
}

impl<'de> serde::Deserialize<'de> for PlatformFilter {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: serde::Deserializer<'de>,
    {
        let raw = <String as serde::Deserialize>::deserialize(deserializer)?;
        match raw.as_str() {
            "common" => Ok(PlatformFilter::Common),
            "debian" => Ok(PlatformFilter::Debian),
            "arch" => Ok(PlatformFilter::Arch),
            _ => Err(serde::de::Error::custom(format!("unknown platform: {raw}"))),
        }
    }
}
