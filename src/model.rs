pub mod module;

pub(crate) mod modules;

mod block;
mod command;
mod dir;
mod env;
mod file;
mod mode;
mod package;
mod platform_filter;
mod validations;

pub(crate) use block::Block;
pub(crate) use command::Command;
pub(crate) use dir::Dir;
pub(crate) use env::Env;
pub(crate) use file::File;
pub(crate) use mode::Mode;
pub(crate) use module::Module;
pub(crate) use package::Packages;
pub(crate) use platform_filter::PlatformFilter;

pub(in crate::model) fn default_platform_filter() -> crate::model::PlatformFilter {
    crate::model::PlatformFilter::Common
}
