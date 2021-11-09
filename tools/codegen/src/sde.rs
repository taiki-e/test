/*
Intel® Software Development Emulator

https://software.intel.com/content/www/us/en/develop/articles/intel-software-development-emulator.html
https://software.intel.com/content/www/us/en/develop/tools/isa-extensions.html

*/

use std::env;

use anyhow::*;
use bzip2::read::BzDecoder;
use tar::Archive;

const VERSION: &str = "8.69.1-2021-07-18";

fn download_and_unpack() -> Result<()> {
    // https://software.intel.com/content/www/us/en/develop/articles/pre-release-license-agreement-for-intel-software-development-emulator-accept-end-user-license-agreement-and-download.html
    let os = if cfg!(any(target_os = "linux", target_os = "macos", target_os = "windows")) {
        // lin/mac/win
        &env::consts::OS[..3]
    } else {
        bail!("Intel SDE only available on Linux, macOS, and Windows");
    };
    let url = format!("https://software.intel.com/content/dam/develop/external/us/en/documents/downloads/sde-external-{VERSION}-{os}.tar.bz2");

    let response = ureq::get(&url).call()?;
    let decoder = BzDecoder::new(response.into_reader());
    let mut archive = tar::Archive::new(decoder);
    let prefix = format!("stdarch-{REVISION}");

    let local_path = &stdarch_dir();
    if local_path.exists() {
        fs::remove_dir_all(local_path)?;
    }

    for entry in archive.entries()? {
        let mut entry = entry?;
        let path = entry.path()?;
        if path == Path::new("pax_global_header") {
            continue;
        }
        let relative = path.strip_prefix(&prefix)?;
        let out = local_path.join(relative);
        entry.unpack(&out)?;
    }

    fs::write(local_path.join("COMMIT"), REVISION)?;
    Ok(())
}
