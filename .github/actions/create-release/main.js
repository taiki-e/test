const { execFileSync } = require('child_process');

try {
    execFileSync('bash', [`${__dirname}/create-release.sh`], { stdio: 'inherit' });
} catch (e) {
    console.log(`error: ${e.message}`);
    process.exit(1);
}
