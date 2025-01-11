use colored::Colorize;

use crate::my_os::file::permission2str;

use super::file::Op;
use super::{file, Error, Result};
use std::cell::RefCell;

use std::collections::BTreeMap;

#[derive(Debug, Default)]
pub struct User {
    name: String,
    files: RefCell<BTreeMap<String, file::File>>,
}

impl User {
    pub fn new(name: &str) -> User {
        User {
            name: name.to_string(),
            files: RefCell::new(BTreeMap::new()),
        }
    }

    pub fn add_file(&self, file: file::File) {
        self.files.borrow_mut().insert(file.name().clone(), file);
    }

    pub fn get_file(&self, name: &str) -> Option<file::File> {
        self.files.borrow().get(name).cloned()
    }

    pub fn write_file(&self, name: &str, src: Vec<u8>) -> Result<()> {
        let e = self
            .files
            .borrow_mut()
            .get_mut(name)
            .ok_or(Error::FileNotFound)?
            .op(Op::Write, Some(src), None);
        if e.is_err() {
            Err(e.err().unwrap())
        } else {
            Ok(())
        }
    }

    pub fn read_file(&self, name: &str) -> Result<Vec<u8>> {
        let e = self
            .files
            .borrow_mut()
            .get_mut(name)
            .ok_or(Error::FileNotFound)?
            .op(Op::Read, None, None);
        if e.is_err() {
            Err(e.err().unwrap())
        } else {
            Ok(e.ok().unwrap().unwrap())
        }
    }

    pub fn delete_file(&self, name: &str) -> Result<()> {
        if self.files.borrow_mut().remove(name).is_none() {
            Err(Error::FileNotFound)
        } else {
            Ok(())
        }
    }

    pub fn change_mode_file(&self, name: &str, mode: file::PermissionNumber) -> Result<()> {
        let e = self
            .files
            .borrow_mut()
            .get_mut(name)
            .ok_or(Error::FileNotFound)?
            .op(Op::ChangeMode, None, Some(mode));
        if e.is_err() {
            Err(e.err().unwrap())
        } else {
            Ok(())
        }
    }

    pub fn append_file(&self, name: &str, src: Vec<u8>) -> Result<()> {
        let e = self
            .files
            .borrow_mut()
            .get_mut(name)
            .ok_or(Error::FileNotFound)?
            .op(Op::Append, Some(src), None);
        if e.is_err() {
            Err(e.err().unwrap())
        } else {
            Ok(())
        }
    }

    pub fn name(&self) -> String {
        self.name.clone()
    }

    pub fn show(&self) {
        println!("{} {}", "User".yellow(), self.name());
        let label = format!(
            "\t -> {:<10} {:<10} {:<10} {:<10}",
            "FileName", "Size(B)", "Permission", "Time"
        )
        .bright_green();
        let mut fmt = String::new();
        self.files.borrow().iter().for_each(|(k, v)| {
            let name = format!("\t -> {:<10}", k).bright_green();
            let size = format!("{:<10}", v.size()).bright_green();
            let permission = format!("{:<#10}", permission2str(v.permission())).bright_green();
            let time = format!("{:<10}", v.time_modified()).bright_green();
            fmt.push_str(format!("{} {} {} {}\n", name, size, permission, time).as_str());
        });

        println!("{}\n{}", label, fmt);
    }
}

#[cfg(test)]
mod tests {

    use super::*;

    #[test]
    fn test_user() {
        let user = User::new("user1");
        let file = file::File::create(
            "file1".to_string(),
            None,
            Some(file::Permission::Read | file::Permission::Write),
        );
        user.add_file(file);
        user.write_file("file1", "Hello".as_bytes().to_vec())
            .unwrap();
        let cont = user
            .read_file("file1")
            .unwrap()
            .iter()
            .map(|&x| x as char)
            .collect::<String>();
        assert_eq!(user.get_file("file1").unwrap().name(), "file1");
        assert_eq!(cont, "Hello");
        assert_eq!(user.name(), "user1");
    }
}
