#![allow(dead_code)]

use std::{collections::BTreeMap, io::Write};

use colored::Colorize;
use fs_toy::my_os::{self, file::Permission, *};
use sysinfo::System;

fn main() -> my_os::Result<()> {
    let mut c = Controller::new();
    c.add_user("lap", "114514")?;
    c.user_add_file(
        "lap",
        file::File::create(
            "Hello",
            Some("This is my first bytes file".into()),
            Some(Permission::Read.into()),
        ),
    )?;

    c.user_add_file(
        "lap",
        file::File::create(
            "Makefile",
            Some(
                r#"clean:
	@echo "Cleaning up..."
	@cargo clean

debug:
	@echo "Building in debug mode..."
	@cargo build

release:
	@echo "Building in release mode..."
	@cargo build --release

run:
	@echo "Running..."
	@cargo run --release

all: debug release

.Phony: all debug release clean run
                "#
                .into(),
            ),
            Some(Permission::Read | Permission::Write),
        ),
    )?;

    c.user_add_file(
        "lap",
        file::File::create(
            "Cargo.toml",
            Some(
                r#"[package]
name = "fs_toy"
version = "0.1.0"
edition = "2021"

[dependencies]
colored = "2"
chrono = "*"
sysinfo = "0.33"
"#
                .into(),
            ),
            Some(Permission::Read | Permission::Write),
        ),
    )?;
    // get the arch and system info
    let sys_msg = format!(
        "{} os {} kernel {}",
        System::name().unwrap(),
        System::os_version().unwrap(),
        System::kernel_version().unwrap()
    );

    let mut usr_login;

    loop {
        usr_login = read_line(Some(&format!(
            "{} {}: ",
            sys_msg.yellow(),
            "login".yellow()
        )));

        if c.get_user(&usr_login).is_none() {
            println!("{}", "No that User".red());
            continue;
        }
        break;
    }

    let shell_impl = format!(
        "{}@{}: ",
        usr_login.yellow(),
        System::name().unwrap().to_lowercase().green()
    );

    loop {
        let passwd = read_line(Some(&format!("{}: ", "Password".yellow())));
        if let Some(login_user) = c.user_login(&usr_login, &passwd) {
            println!("{}[ {} ]", "Welcome! ".bold(), shell_impl);
            show_help();
            login_user.u.show();
            break;
        } else {
            println!("{}", "Login failed! Retry".red());
        }
    }

    colored::control::set_override(true);

    loop {
        let cmd = read_line(Some(&shell_impl));
        // trim all the leading and trailing whitespaces
        let cmd = cmd.trim();

        match cmd {
            "exit" => {
                println!("Goodbye!");
                break;
            }
            "close" => {
                let file_name = read_line(Some("File name: "));
                if let Err(e) = c.user_get_file(&usr_login, &file_name) {
                    println!("{} < {:?} >", "Permission denied".red(), e);
                }
            }
            "show" => {
                c.user_show(&usr_login)?;
            }
            "create" => {
                let file_name = read_line(Some("File name: "));
                if let Ok(file_mod) = read_line(Some("Mode: ")).parse::<u8>() {
                    let file = file::File::create(file_name.clone(), None, Some(file_mod));
                    c.user_add_file(&usr_login, file)?;
                } else {
                    println!("{}", "Invalid mode < Please input number >".red());
                }
            }
            "read" | "open" => {
                let file_name = read_line(Some("File name: "));
                if let Ok(file) = c.user_get_file(&usr_login, &file_name) {
                    if let Ok(content) = file.op(file::Op::Read, None, None) {
                        println!("{}", String::from_utf8_lossy(&content.unwrap()));
                    } else {
                        println!("{}", "Permission denied < File can't be read >".red());
                    }
                } else {
                    println!("{}", "File Not Exist".red());
                }
            }
            "write" => {
                let file_name = read_line(Some("File name: "));
                let content = read_line(Some("Content: "));
                if c.user_write_file(&usr_login, &file_name, content.into_bytes())
                    .is_err()
                {
                    println!("{}", "Permission denied < File can't be written >".red());
                }
            }
            "append" => {
                let file_name = read_line(Some("File name: "));
                let content = read_line(Some("Content: "));
                if c.user_append_file(&usr_login, &file_name, content.into_bytes())
                    .is_err()
                {
                    println!("{}", "Permission denied < File can't be append >".red());
                };
            }
            "delete" => {
                let file_name = read_line(Some("File name: "));
                if c.user_delete_file(&usr_login, &file_name).is_err() {
                    println!("{}", "Permission denied < File can't be found >".red());
                }
            }
            "chmod" => {
                let file_name = read_line(Some("File name: "));
                let mode = read_line(Some("Mode: "));
                if let Ok(mode) = mode.parse::<u8>() {
                    if let Err(e) = c.user_change_mode_file(&usr_login, &file_name, mode) {
                        println!("{} < {:?} >", "Permission denied".red(), e);
                    }
                } else {
                    println!("{}", "Invalid mode < Please input number >".red());
                }
            }
            "help" => {
                show_help();
            }
            _ => {
                println!("{}", format!("Unknown command: {}", cmd).red());
            }
        }
    }
    Ok(())
}

fn show_help() {
    println!(
        "{}",
        r#"This is a simple shell for file system toy.
Commands
    help: show this help message
    exit: exit the shell
    show: show the user info
    create: create a file
    read: read a file (will auotmatically open and close)
    write: write a file (will auotmatically open and close)
    append: append a file (will auotmatically open and close)
    chmod: change the mode of a file
    open: open a file and show the content
    close: close a file
    "#
        .cyan()
    );
}

fn read_line(msg: Option<&str>) -> String {
    if let Some(msg) = msg {
        print!("{}", msg);
        std::io::stdout().flush().unwrap();
    }
    let mut cmd = String::new();
    std::io::stdin().read_line(&mut cmd).unwrap();
    cmd.trim().into()
}

#[derive(Debug)]
struct User {
    u: user::User,
    passwd: String,
}

#[derive(Debug)]
struct Controller {
    users: BTreeMap<String, User>,
}

impl Default for Controller {
    fn default() -> Self {
        let mut c = Controller {
            users: BTreeMap::new(),
        };
        c.add_user("root", "114514").unwrap();
        c
    }
}

impl Controller {
    fn new() -> Self {
        Controller::default()
    }

    /// if `user` already exists, return `Error::UserAlreadyExists`
    fn add_user(&mut self, name: &str, passwd: &str) -> Result<()> {
        if self
            .users
            .insert(
                name.to_string(),
                User {
                    u: user::User::new(name),
                    passwd: passwd.to_string(),
                },
            )
            .is_some()
        {
            Err(Error::UserAlreadyExist)
        } else {
            Ok(())
        }
    }

    fn get_user(&self, name: &str) -> Option<&User> {
        self.users.get(name)
    }

    fn user_show(&self, name: &str) -> Result<()> {
        let u = self.users.get(name).ok_or(Error::UserDoesNotExist)?;
        u.u.show();
        Ok(())
    }

    fn user_login(&self, name: &str, passwd: &str) -> Option<&User> {
        self.users.get(name).filter(|u| u.passwd == passwd)
    }

    fn user_logout(&self, _: &str) {}

    fn user_add_file(&self, name: &str, file: file::File) -> Result<()> {
        self.users
            .get(name)
            .ok_or(Error::FileNotFound)?
            .u
            .add_file(file);
        Ok(())
    }

    fn user_get_file(&self, name: &str, file_name: &str) -> Result<file::File> {
        self.users
            .get(name)
            .ok_or(Error::FileNotFound)?
            .u
            .get_file(file_name)
            .ok_or(Error::FileNotFound)
    }

    fn user_write_file(&self, name: &str, file_name: &str, src: Vec<u8>) -> Result<()> {
        self.users
            .get(name)
            .ok_or(Error::FileNotFound)?
            .u
            .write_file(file_name, src)
    }

    fn user_read_file(&self, name: &str, file_name: &str) -> Result<Vec<u8>> {
        self.users
            .get(name)
            .ok_or(Error::FileNotFound)?
            .u
            .read_file(file_name)
    }

    fn user_delete_file(&self, name: &str, file_name: &str) -> Result<()> {
        self.users
            .get(name)
            .ok_or(Error::FileNotFound)?
            .u
            .delete_file(file_name)
    }

    fn user_change_mode_file(
        &self,
        name: &str,
        file_name: &str,
        mode: file::PermissionNumber,
    ) -> Result<()> {
        self.users
            .get(name)
            .ok_or(Error::FileNotFound)?
            .u
            .change_mode_file(file_name, mode)
    }

    fn user_append_file(&self, name: &str, file_name: &str, src: Vec<u8>) -> Result<()> {
        self.users
            .get(name)
            .ok_or(Error::FileNotFound)?
            .u
            .append_file(file_name, src)
    }
}
