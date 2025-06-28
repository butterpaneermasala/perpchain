const fs = require('fs');
const path = require('path');

const srcDir = __dirname;
const outputFile = path.join(srcDir, 'all_contracts.json');

const files = fs.readdirSync(srcDir).filter(f => f.endsWith('.sol'));

const contracts = files.map(filename => {
  const code = fs.readFileSync(path.join(srcDir, filename), 'utf8');
  return {

    name: filename.replace('.sol', ''),
    path: filename,
    code
  };
});

fs.writeFileSync(outputFile, JSON.stringify(contracts, null, 2));
console.log(`Exported ${contracts.length} contracts to ${outputFile}`);