const { execSync } = require('child_process');

try {
    execSync(`${__dirname}/create-release.sh`, { stdio: 'inherit' });
} catch (e) {
    console.log(`error: ${e.message}`);
    process.exit(1);
}
