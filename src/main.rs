//! Oration: a Rocket/Elm self hosted commenting system for static sites.
//!
//! Inspired by ![Isso](https://posativ.org/isso/), which is a welcomed change from Disqus.
//! However, the codebase is unmaintained and ![security concerns](https://axiomatic.neophilus.net/posts/2017-04-16-from-disqus-to-isso.html) abound.
//! Oration aims to be a fast, lightweight and secure platform for your comments. Nothing more, but importantly, nothing less.


#![cfg_attr(feature="clippy", feature(plugin))]
#![cfg_attr(feature="clippy", plugin(clippy))]
#![cfg_attr(feature="clippy", warn(missing_docs_in_private_items))]
#![cfg_attr(feature="clippy", warn(single_match_else))]

#![feature(plugin, custom_derive, use_extern_macros)]
#![plugin(rocket_codegen)]

// `error_chain!` can recurse deeply
#![recursion_limit = "1024"]

extern crate dotenv;
#[macro_use]
extern crate error_chain;
extern crate rand;
extern crate rocket;
extern crate rocket_contrib;
extern crate serde_json;
#[macro_use]
extern crate serde_derive;
#[macro_use]
extern crate diesel;
#[macro_use]
extern crate diesel_codegen;
extern crate r2d2_diesel;
extern crate r2d2;
extern crate yansi;
#[macro_use(log)] extern crate log;

/// Handles the database connection pool.
mod db;
/// SQL <----> Rust inerop using Diesel.
mod models;
/// Verbose schema for the comment database.
mod schema;
/// Serves up static files through Rocket.
mod static_files;
/// Handles the error chain of the program.
mod errors;
/// Tests for the Rocket side of the app.
#[cfg(test)]
mod tests;

use std::collections::HashMap;
use rocket::http::{Cookie, Cookies};
use rocket::http::RawStr;
use rocket::request::Form;
use rocket_contrib::Template;
use models::preferences::Preference;
use std::process;
use yansi::Paint;

/// Serve up the index file, which ultimately launches the Elm app.
#[get("/")]
fn index(mut cookies: Cookies) -> Template {
    let mut user = HashMap::new();
    let values = &["name", "email", "url"];
    for v in values.iter() {
        let cookie = cookies.get_private(&v);
        if let Some(cookie) = cookie {
            user.insert(v, cookie.value().to_string());
        }
    }

    log::info!("{:?}", user);

    Template::render("index", &user)
}

//NOTE: we can use FormInput<'c>, url: &'c RawStr, for unvalidated data if/when we need it.
#[derive(Debug, FromForm)]
/// Incoming data from the web based form for a new comment.
struct FormInput<'c> {
    /// Comment from textarea.
    comment: &'c RawStr,
    /// Optional name.
    name: String,
    /// Optional email.
    email: String,
    /// Optional website.
    url: String,
}

/// Process comment input from form.
#[post("/", data = "<comment>")]
fn new_comment<'c>(mut cookies: Cookies, comment: Result<Form<'c, FormInput<'c>>, Option<String>>) -> String {
    match comment {
        Ok(f) => {
            let form = f.get();
            cookies.add_private(Cookie::new("name", form.name.to_string()));
            cookies.add_private(Cookie::new("email", form.email.to_string()));
            cookies.add_private(Cookie::new("url", form.url.to_string()));
            format!("{:?}", form)
        },
        Err(Some(f)) => format!("Invalid form input: {}", f),
        Err(None) => format!("Form input was invalid UTF8."),
    }
}

/// Test function that returns the session hash from the database.
#[get("/session")]
fn get_session(conn: db::Conn) -> String {
    match Preference::get_session(&conn) {
        Ok(s) => s,
        Err(err) => {
            log::warn!("{}", err);
            for e in err.iter().skip(1) {
                log::warn!("    {} {}", Paint::white("=> Caused by:"), Paint::red(&e));
            }
            err.to_string()
        }
    }
}

/// Ignite Rocket, connect to the database and start serving data.
/// Exposes a connection to the database so we can set the session on startup.
fn rocket() -> (rocket::Rocket, db::Conn) {
    let pool = db::init_pool();
    let conn = db::Conn(pool.get().expect("database connection for initialisation"));
    let rocket = rocket::ignite().manage(pool).attach(Template::fairing()).mount(
        "/",
        routes![
            index,
            static_files::files,
            new_comment,
            get_session,
        ],
    );

    (rocket, conn)
}

/// Application entry point.
fn main() {
    //Initialise webserver routes and database connection pool
    let (rocket, conn) = rocket();

    //Set the session info in the database
    log::info!("💿  {}", Paint::purple("Saving session hash to database"));
    match Preference::set_session(&conn) {
        Ok(set) => {
            if !set {
                //TODO: This may need to be a crit as well. Unsure.
                log::warn!("Failed to set session hash");
            }
        }
        Err(err) => {
            log::error!("{}", err);
            for e in err.iter().skip(1) {
                log::error!("    {} {}", Paint::white("=> Caused by:"), Paint::red(&e));
            }
            process::exit(1);
        },
    };

    log::info!("📢  {}", Paint::blue("Oration is now serving your comments"));
    //Start the web service
    rocket.launch();
}
