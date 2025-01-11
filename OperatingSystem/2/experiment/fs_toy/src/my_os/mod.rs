pub mod file;
pub mod user;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[repr(u32)]
pub enum Error {
    PermissionDeniedRead,
    PermissionDeniedWriteLike,
    PermissionDeniedExecute,
    NoPermissionSpecified,
    NoNameSpecified,
    DataWriteIsNone,
    FileNotFound,
    UserAlreadyExist,
    UserDoesNotExist,
}

pub type Result<T> = std::result::Result<T, Error>;
