const { execSync } = require('child_process');

try {
    const toolchain = process.env['INPUT_TOOLCHAIN'];
    const component = process.env['INPUT_COMPONENT'];

    if (component === '') {
        execSync(`${__dirname}/install-rust.sh ${toolchain}`, { stdio: 'inherit' });
    } else if (toolchain.startsWith('nightly')) {
        execSync(`${__dirname}/install-component.sh ${component}`, { stdio: 'inherit' });
    } else {
        execSync(`${__dirname}/install-component.sh ${component} '' ${toolchain}`, { stdio: 'inherit' });
    }
} catch (e) {
    console.log(`error: ${e.message}`);
    process.exit(1);
}
