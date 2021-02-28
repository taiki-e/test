fn main() {
    #[cfg(target_os = "macos")]
    println!("macos");
    #[cfg(target_os = "linux")]
    println!("linux");
    #[cfg(windows)]
    println!("windows");
}
@
