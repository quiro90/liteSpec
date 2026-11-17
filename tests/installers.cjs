// Run: node tests/installers.cjs [powershell|bash]
// Fixtures stay in an isolated temporary directory for inspection; no project installation.
const fs = require('node:fs');
const path = require('node:path');
const {spawnSync} = require('node:child_process');
const assert = require('node:assert/strict');
const source = path.resolve(__dirname, '..');
const engine = process.argv[2] || 'powershell';
assert(['powershell', 'bash'].includes(engine));
const base = fs.mkdtempSync(path.join(require('node:os').tmpdir(), `litespec-${engine}-`));
const sources = 'liste.spec.steps';

function fixture(name) {
  const root = path.join(base, name);
  fs.mkdirSync(root);
  fs.cpSync(path.join(source, sources), path.join(root, sources), {recursive:true});
  const script = path.join(root, `lite.spec.install.${engine === 'bash' ? 'sh' : 'ps1'}`);
  fs.copyFileSync(path.join(source, path.basename(script)), script);
  return {root, script};
}
function run(f, input, success = true) {
  const command = engine === 'bash' ? 'C:/Program Files/Git/bin/bash.exe' : 'powershell.exe';
  const args = engine === 'bash' ? [f.script.replaceAll('\\','/')] : ['-NoProfile','-ExecutionPolicy','Bypass','-File',f.script];
  const env = {...process.env};
  // The desktop shell may export PowerShell 7's module path to Windows PS 5.1.
  if (engine === 'powershell') env.PSModulePath = `${process.env.SystemRoot}\\System32\\WindowsPowerShell\\v1.0\\Modules`;
  const r = spawnSync(command, args, {input:input+'\n', encoding:'utf8', timeout:30000, env});
  assert.equal(r.status === 0, success, r.stdout+'\n'+r.stderr);
  return r.stdout;
}
function read(f,p) {return fs.readFileSync(path.join(f.root,p),'utf8');}
for (const agent of ['1','2','3','12','13']) {
  const f = fixture(`basic-${agent}`);
  const output = run(f, agent + (['1','2'].includes(agent) ? '\n' : '') + '\nno');
  assert.doesNotMatch(output, /gpt-6-luna/);
  assert(!fs.existsSync(path.join(f.root,'.codex/agents')));
  assert(!fs.existsSync(path.join(f.root,'.claude/agents')));
  if (agent === '13') assert(fs.existsSync(path.join(f.root,'.minimax/skills/litespec-explore/SKILL.md')));
}
{
  const f = fixture('normal-unrelated-native-path');
  fs.writeFileSync(path.join(f.root,'.codex'),'unrelated project file');
  run(f, '1\n\nno');
  assert.equal(read(f,'.codex'),'unrelated project file');
  assert(fs.existsSync(path.join(f.root,'.agents/skills/litespec-explore/SKILL.md')));
}
for (const [agent, adapter, ext] of [['1','codex','toml'],['2','claude','md']]) {
  const f = fixture(adapter);
  const rel = adapter === 'codex' ? '.agents/skills' : '.claude/skills';
  const output = run(f, `${agent}\n2\nmodel-search\nlow\nmodel-plan\nhigh\n\n\nno`);
  assert.match(output, /Facil .*gpt-6-luna.*medium.*haiku.*medium/);
  assert.match(output, /Media .*gpt-6\.1-sol.*medium.*sonnet.*medium/);
  assert.match(output, /Pesada .*gpt-6-astra.*medium.*opus.*medium/);
  const agents = `.${adapter}/agents`;
  const native = `${agents}/litespec-search.${ext}`;
  const marker = `${rel}/litespec-shared/delegation-active.md`;
  assert(read(f,native).includes('model-search'));
  assert.doesNotMatch(read(f,`${agents}/litespec-implement.${ext}`), /^(model\s*[:=]|effort:|model_reasoning_effort\s*=)/m);
  assert(read(f,marker).includes(`Adapter: ${adapter}`));
  const original = read(f,native)+'\n# personal customization\n';
  fs.writeFileSync(path.join(f.root,native),original);
  assert.match(run(f, `${agent}\n2\nno`), /Facil .*gpt-6-luna.*haiku/);
  assert.equal(read(f,native),original);
  fs.writeFileSync(path.join(f.root,agents,`unrelated.${ext}`),'personal agent');
  run(f, `${agent}\n\nno`);
  for (const role of ['search','plan','implement']) {
    assert(!fs.existsSync(path.join(f.root,agents,`litespec-${role}.${ext}`)), `${role} is still registered after disabling`);
  }
  assert(!fs.existsSync(path.join(f.root,marker)), 'routing marker is still active');
  assert.equal(read(f,`${agents}/unrelated.${ext}`),'personal agent');
  run(f, `${agent}\n1\nno`);
  run(f, `${agent}\n2\nno`);
  assert(read(f,marker).includes(`Adapter: ${adapter}`));
  assert.equal(read(f,native),original);
  const saved = `.litespec/disabled-agents/${adapter}/litespec-search.${ext}`;
  fs.mkdirSync(path.dirname(path.join(f.root,saved)), {recursive:true});
  fs.writeFileSync(path.join(f.root,saved),'different saved configuration');
  run(f, `${agent}\n1\nno`, false);
  assert.equal(read(f,native),original);
  assert.equal(read(f,saved),'different saved configuration');
  assert(fs.existsSync(path.join(f.root,marker)));
  fs.unlinkSync(path.join(f.root,saved));
  // Basic source cleanup also removes the renamed installer, preserving definitions.
  fs.mkdirSync(path.join(f.root,'steps'));
  fs.writeFileSync(path.join(f.root,'steps','keep.txt'),'unrelated project file');
  run(f, `${agent}\n1\nyes`);
  assert(!fs.existsSync(f.script));
  assert(!fs.existsSync(path.join(f.root,sources)));
  assert.equal(read(f,'steps/keep.txt'),'unrelated project file');
  assert(!fs.existsSync(path.join(f.root,native)));
  assert.equal(read(f,saved),original);
}
for (const kind of ['model','effort','collision','ancestor','missing']) {
  const f = fixture(`invalid-${kind}`);
  let input = '1\n2\nbad"model\n';
  if (kind === 'effort') input = '1\n2\nvalid\nunsupported\n';
  if (kind === 'collision') {
    fs.mkdirSync(path.join(f.root,'.codex/agents/litespec-search.toml'),{recursive:true});
    input = '1\n2\n';
  }
  if (kind === 'missing') fs.unlinkSync(path.join(f.root,sources,'litespec-shared/delegation.md'));
  if (kind === 'ancestor') {
    fs.writeFileSync(path.join(f.root,'.codex'),'preserve');
    input = '1\n2\n';
  }
  run(f,input,false);
  assert(!fs.existsSync(path.join(f.root,'.agents/skills')));
}
console.log(`PASS ${engine}: defaults, both adapters, disable/reactivate, customization, cleanup, invalid input and conflicts. Fixtures: ${base}`);
