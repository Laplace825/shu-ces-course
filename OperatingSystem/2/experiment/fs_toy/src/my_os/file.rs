use super::{Error, Result};
use chrono::{self, DateTime, Local};
use colored::Colorize;
use std::{cell::RefCell, ops};

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[repr(u8)]
pub enum Permission {
    Read = 0b100,
    Write = 0b010,
    Execute = 0b001,
}

impl From<Permission> for u8 {
    fn from(value: Permission) -> Self {
        value as u8
    }
}

impl From<u8> for Permission {
    fn from(value: u8) -> Self {
        match value {
            0b100 => Permission::Read,
            0b010 => Permission::Write,
            0b001 => Permission::Execute,
            _ => unreachable!(),
        }
    }
}

impl ops::BitAnd for Permission {
    type Output = u8;

    fn bitand(self, rhs: Self) -> Self::Output {
        u8::from(self) & u8::from(rhs)
    }
}

impl ops::BitOr for Permission {
    type Output = u8;

    fn bitor(self, rhs: Self) -> Self::Output {
        u8::from(self) | u8::from(rhs)
    }
}

/// permission u8 number for `Permission`
pub type PermissionNumber = u8;

pub fn permission2str(permission: PermissionNumber) -> String {
    let mut s = String::new();
    if permission & u8::from(Permission::Read) != 0 {
        s.push('r');
    } else {
        s.push('-');
    }
    if permission & u8::from(Permission::Write) != 0 {
        s.push('w');
    } else {
        s.push('-');
    }
    if permission & u8::from(Permission::Execute) != 0 {
        s.push('x');
    } else {
        s.push('-');
    }
    s
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[repr(u8)]
pub enum Op {
    Read,
    Write,
    Execute,
    Append,
    Delete,
    ChangeMode,
}

impl From<Op> for u8 {
    fn from(value: Op) -> Self {
        value as u8
    }
}

impl From<u8> for Op {
    fn from(value: u8) -> Self {
        match value {
            0b0000 => Op::Read,
            0b0001 => Op::Write,
            0b0010 => Op::Execute,
            0b0011 => Op::Append,
            0b0100 => Op::Delete,
            0b0101 => Op::ChangeMode,
            _ => unreachable!(),
        }
    }
}

/// File metadata
///
/// The `time_modified` and `size` are private fields.
///
/// The `time_modified` is updated when the file is modified.
///
/// The `size` is updated when the file is written or appended.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Meta {
    pub name: String, // file name
    pub permission: PermissionNumber,
    time_modified: DateTime<Local>, // time when file was modified
    size: u64,
}

/// File abstract with `meta` and bytes like `data`
///
/// The `meta` and `data` must be accessed through `RefCell`.
#[derive(Debug, Clone)]
pub struct File {
    pub meta: RefCell<Meta>,
    pub data: RefCell<Vec<u8>>,
}

impl File {
    fn new(
        name: String,
        permission: PermissionNumber,
        time_modified: DateTime<Local>,
        size: u64,
        data: Vec<u8>,
    ) -> Self {
        File {
            meta: RefCell::new(Meta {
                name,
                permission,
                time_modified,
                size,
            }),
            data: RefCell::new(data),
        }
    }

    /// Create a new file with the given name, user, and permission.
    ///
    /// If `permission` is `None`, the default permission is `Permission::Read`.
    ///
    pub fn create<S: Into<String>>(
        name: S,
        data: Option<Vec<u8>>,
        permission: Option<PermissionNumber>,
    ) -> Self {
        let now = chrono::offset::Local::now();
        if let Some(data) = data {
            match permission {
                Some(per) => File::new(name.into(), per, now, data.len() as u64, data),
                None => File::new(
                    name.into(),
                    Permission::Read.into(),
                    now,
                    data.len() as u64,
                    data,
                ),
            }
        } else {
            match permission {
                Some(per) => File::new(name.into(), per, now, 0, Vec::new()),
                None => File::new(name.into(), Permission::Read.into(), now, 0, Vec::new()),
            }
        }
    }

    pub fn check_permission(&self, op: Op) -> Result<()> {
        let permission = self.meta.borrow().permission;
        match op {
            Op::Read => {
                if permission & u8::from(Permission::Read) == 0 {
                    return Err(Error::PermissionDeniedRead);
                }
                Ok(())
            }
            Op::Write | Op::Append => {
                if permission & u8::from(Permission::Write) == 0 {
                    return Err(Error::PermissionDeniedWriteLike);
                }
                Ok(())
            }
            Op::Execute => {
                if permission & u8::from(Permission::Execute) == 0 {
                    return Err(Error::PermissionDeniedExecute);
                }
                Ok(())
            }
            _ => Ok(()),
        }
    }

    /// Perform an operation on the file.
    ///
    /// if the operation is successful, return `None`.
    pub fn op(
        &self,
        op: Op,
        src: Option<Vec<u8>>,
        mode: Option<PermissionNumber>,
    ) -> Result<Option<Vec<u8>>> {
        let mode = mode.unwrap_or(self.permission());
        self.check_permission(op)?;
        match op {
            Op::Read => Ok(Some(self.read())),
            Op::Write => {
                self.write(src.ok_or(Error::DataWriteIsNone)?);
                Ok(None)
            }
            Op::Execute => {
                let name = self.name();
                std::println!("{} {}", "Execute:".yellow(), name);
                Ok(None)
            }
            Op::Append => {
                self.append(src.ok_or(Error::DataWriteIsNone)?);
                Ok(None)
            }
            Op::ChangeMode => {
                self.change_mode(mode);
                Ok(None)
            }
            Op::Delete => Ok(None),
        }
    }

    fn write(&self, data: Vec<u8>) {
        self.update_time();
        self.meta.borrow_mut().size = data.len() as u64;
        *self.data.borrow_mut() = data;
    }

    fn append(&self, data: Vec<u8>) {
        self.update_time();
        self.meta.borrow_mut().size += data.len() as u64;
        self.data.borrow_mut().extend(data);
    }

    fn change_mode(&self, mode: PermissionNumber) {
        self.meta.borrow_mut().permission = mode;
        self.update_time();
    }

    fn update_time(&self) {
        self.meta.borrow_mut().time_modified = chrono::offset::Local::now();
    }

    fn read(&self) -> Vec<u8> {
        self.data.borrow().clone()
    }

    pub fn name(&self) -> String {
        self.meta.borrow().name.clone()
    }

    pub fn time_modified(&self) -> DateTime<Local> {
        self.meta.borrow().time_modified
    }

    pub fn size(&self) -> u64 {
        self.meta.borrow().size
    }

    pub fn data(&self) -> Vec<u8> {
        self.data.borrow().clone()
    }

    pub fn permission(&self) -> PermissionNumber {
        self.meta.borrow().permission
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_file() {
        let permission = Permission::Read | Permission::Write;

        let file = File::create("file1".to_string(), None, Some(permission));
        assert_eq!(file.name(), "file1");
        assert_eq!(file.permission(), 0b110);

        // default is readable
        let file = File::create("file1".to_string(), None, None);
        assert_eq!(file.permission(), Permission::Read.into());

        // error because unwriteable
        assert_eq!(
            file.op(Op::Write, Some("HI".into()), None).unwrap_err(),
            Error::PermissionDeniedWriteLike
        );
    }
}
