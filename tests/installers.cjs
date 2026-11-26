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
function run(f, input, success = true, overrides = {}) {
  const command = engine === 'bash' ? 'C:/Program Files/Git/bin/bash.exe' : 'powershell.exe';
  const args = engine === 'bash' ? [f.script.replaceAll('\\','/')] : ['-NoProfile','-ExecutionPolicy','Bypass','-File',f.script];
  const env = {...process.env, ...overrides};
  // The desktop shell may export PowerShell 7's module path to Windows PS 5.1.
  if (engine === 'powershell') env.PSModulePath = `${process.env.SystemRoot}\\System32\\WindowsPowerShell\\v1.0\\Modules`;
  const r = spawnSync(command, args, {input:input+'\n', encoding:'utf8', timeout:30000, env});
  assert.equal(r.status === 0, success, r.stdout+'\n'+r.stderr);
  return r.stdout;
}
function read(f,p) {return fs.readFileSync(path.join(f.root,p),'utf8');}
// Edge checks can run separately after the full suite: third argument gitignore-edge.
{
  const f = fixture('ignore-single-crlf');
  fs.writeFileSync(path.join(f.root,'.gitignore'),'# Windows\r\n');
  run(f, '3\nno\ni');
  assert(!read(f,'.gitignore').replaceAll('\r\n','').includes('\n'), 'preserve CRLF for appended rules');
}
{
  const f = fixture('ignore-no-repository');
  fs.writeFileSync(path.join(f.root,'.gitignore'),'/.agents/\n/liste.spec.steps/\n');
  const overrides = {GIT_DIR:path.join(f.root,'missing-repository')};
  run(f, '1\n1\n1\nno\ns', true, overrides);
  const expected = '/.agents/\n/liste.spec.steps/\n/'+path.basename(f.script)+'\n';
  assert.equal(read(f,'.gitignore'), expected);
  run(f, '1\n1\n1\nno\ns', true, overrides);
  assert.equal(read(f,'.gitignore'), expected, 'fallback must not duplicate literal or parent rules');
}
if (process.argv[3] === 'gitignore-edge') { console.log('PASS '+engine+': CRLF and no-repository fallback'); process.exit(0); }
// Optional .gitignore update is the final step, including after source cleanup.
{
  const f = fixture('ignore-both');
  fs.writeFileSync(path.join(f.root,'.gitignore'),'# reglas propias\r\nnode_modules/');
  run(f, '1\n1\n1\nno\nyes');
  const text = read(f,'.gitignore');
  assert(text.startsWith('# reglas propias\r\nnode_modules/'));
  assert(text.includes('/'+path.basename(f.script)));
  assert(text.includes('/liste.spec.steps/'));
  for (const name of ['explore','propose','apply','modify','verify','archive','shared']) assert(text.includes('/.agents/skills/litespec-'+name+'/'));
  assert(!text.split(/\r?\n/).includes('/.agents/skills/'));
  run(f, '1\n1\n1\nno\ny');
  assert.equal(read(f,'.gitignore'), text, 'reinstall must not duplicate ignore rules');
}
for (const answer of ['i','INS','no','']) {
  const f = fixture('ignore-answer-'+(answer || 'empty'));
  fs.writeFileSync(path.join(f.root,'.gitignore'),'# keep\n');
  run(f, '3\nno\n'+answer);
  const text = read(f,'.gitignore');
  if (['i','INS'].includes(answer)) {
    assert(text.includes('/'+path.basename(f.script)));
    assert(text.includes('/liste.spec.steps/'));
    assert(!text.includes('.github'));
  } else assert.equal(text, '# keep\n');
}
{
  const f = fixture('ignore-cleanup');
  fs.writeFileSync(path.join(f.root,'.gitignore'),'');
  run(f, '2\n1\n1\nyes\ns');
  assert(!fs.existsSync(f.script));
  assert(read(f,'.gitignore').includes('/.claude/skills/litespec-apply/'));
}
{
  const f = fixture('ignore-covered');
  fs.writeFileSync(path.join(f.root,'.gitignore'),'/.agents/\n/liste.spec.steps/\n/'+path.basename(f.script)+'\n');
  const original = read(f,'.gitignore');
  run(f, '1\n1\n1\nno\nsi');
  assert.equal(read(f,'.gitignore'), original, 'existing parent exclusion already covers skills');
}
// Shared Codex/Zed skills must scope routing to the current client.
{
  const f = fixture('codex-zed');
  run(f, '1\n1\n2\n\n\n\n\nno');
  const marker = '.agents/skills/litespec-shared/delegation-active.md';
  const native = '.codex/agents/litespec-search.toml';
  const originalMarker = read(f, marker);
  const originalNative = read(f, native);
  const output = run(f, '12\nno');
  assert.equal(read(f, marker), originalMarker);
  assert.equal(read(f, native), originalNative);
  const protocol = read(f, '.agents/skills/litespec-shared/protocol.md');
  assert.match(protocol, /only if its adapter matches the current client/);
  assert.match(protocol, /Unknown or different client: normal workflow/);
  assert.match(output, /Agente: Zed \| Modo: Clasico/);
  assert.match(output, /configuracion de Codex se conserva/);
  run(f, '1\n1\n2\nno');
  assert.equal(read(f, native), originalNative);
}

for (const agent of Array.from({length:13}, (_,i) => String(i+1))) {
  const f = fixture(`basic-${agent}`);
  const output = run(f, agent + (['1','2'].includes(agent) ? '\n\n' : '') + '\nno');
  assert.doesNotMatch(output, /gpt-6-luna/);
  assert(!fs.existsSync(path.join(f.root,'.gitignore')), 'do not create a missing .gitignore');
  assert.match(output, /Agente: .+ \| Modo: Clasico/);
  assert.match(output, /creados=0; restaurados=0; conservados=0; guardados=0/);
  const destinations = ['.agents','.claude','.github','.cursor','.opencode','.qoder','.gemini','.qwen','.cline','.devin','.ade','.agents','.minimax'];
  const skills = destinations[Number(agent)-1]+'/skills';
  assert(!fs.existsSync(path.join(f.root,skills,'litespec-shared/delegation-active.md')));
  for (const skill of ['explore','propose','apply','modify','verify','archive']) {
    const rel = 'litespec-'+skill+'/SKILL.md';
    assert.equal(read(f,skills+'/'+rel), fs.readFileSync(path.join(source,sources,rel),'utf8'));
  }
  assert(!fs.existsSync(path.join(f.root,'.codex/agents')));
  assert(!fs.existsSync(path.join(f.root,'.claude/agents')));
  if (agent === '13') assert(fs.existsSync(path.join(f.root,'.minimax/skills/litespec-explore/SKILL.md')));
}
{
  const f = fixture('normal-unrelated-native-path');
  fs.writeFileSync(path.join(f.root,'.codex'),'unrelated project file');
  run(f, '1\n1\n1\nno');
  assert.equal(read(f,'.codex'),'unrelated project file');
  assert(fs.existsSync(path.join(f.root,'.agents/skills/litespec-explore/SKILL.md')));
}
for (const [agent, adapter, ext] of [['1','codex','toml'],['2','claude','md']]) {
  const f = fixture(adapter);
  const rel = adapter === 'codex' ? '.agents/skills' : '.claude/skills';
  const output = run(f, `${agent}\n1\n2\nmodel-search\nlow\nmodel-plan\nhigh\nno`);
  assert.match(output, /Modo: Clasico \+ Auto model/);
  assert.match(output, /creados=3; restaurados=0; conservados=0; guardados=0/);
  assert.match(output, /Modelos no comprobados en ejecucion/);
  const agents = `.${adapter}/agents`;
  const native = `${agents}/litespec-search.${ext}`;
  const marker = `${rel}/litespec-shared/delegation-active.md`;
  assert(read(f,native).includes('model-search'));
  assert(!fs.existsSync(path.join(f.root,agents,`litespec-implement.${ext}`)), 'retired implement role is not created');
  assert(read(f,`${agents}/litespec-plan.${ext}`).includes('model-plan'));
  assert.doesNotMatch(read(f,marker), /implement/);
  assert(read(f,marker).includes(`Adapter: ${adapter}`));
  const original = read(f,native)+'\n# personal customization\n';
  fs.writeFileSync(path.join(f.root,native),original);
  const reinstall = run(f, `${agent}\n1\n2\nno`);
  assert.match(reinstall, /creados=0; restaurados=0; conservados=3; guardados=0/);
  assert.equal(read(f,native),original);
  fs.writeFileSync(path.join(f.root,agents,`unrelated.${ext}`),'personal agent');
  const disabled = run(f, `${agent}\n1\n1\nno`);
  assert.match(disabled, /creados=0; restaurados=0; conservados=0; guardados=3/);
  for (const role of ['search','plan']) {
    assert(!fs.existsSync(path.join(f.root,agents,`litespec-${role}.${ext}`)), `${role} is still registered after disabling`);
  }
  assert(!fs.existsSync(path.join(f.root,marker)), 'routing marker is still active');
  assert.equal(read(f,`${agents}/unrelated.${ext}`),'personal agent');
  run(f, `${agent}\n1\n1\nno`);
  const restored = run(f, `${agent}\n1\n2\nno`);
  assert.match(restored, /creados=0; restaurados=3; conservados=0; guardados=0/);
  assert(read(f,marker).includes(`Adapter: ${adapter}`));
  assert.equal(read(f,native),original);
  const saved = `.litespec/disabled-agents/${adapter}/litespec-search.${ext}`;
  fs.mkdirSync(path.dirname(path.join(f.root,saved)), {recursive:true});
  fs.writeFileSync(path.join(f.root,saved),'different saved configuration');
  run(f, `${agent}\n1\n1\nno`, false);
  assert.equal(read(f,native),original);
  assert.equal(read(f,saved),'different saved configuration');
  assert(fs.existsSync(path.join(f.root,marker)));
  fs.unlinkSync(path.join(f.root,saved));
  // Basic source cleanup also removes the renamed installer, preserving definitions.
  fs.mkdirSync(path.join(f.root,'steps'));
  fs.writeFileSync(path.join(f.root,'steps','keep.txt'),'unrelated project file');
  run(f, `${agent}\n1\n1\nyes`);
  assert(!fs.existsSync(f.script));
  assert(!fs.existsSync(path.join(f.root,sources)));
  assert.equal(read(f,'steps/keep.txt'),'unrelated project file');
  assert(!fs.existsSync(path.join(f.root,native)));
  assert.equal(read(f,saved),original);
}
for (const [agent, adapter, ext, model] of [
  ['1','codex','toml','gpt-6.2-sol'], ['2','claude','md','sonnet']
]) {
  const f = fixture('adaptive-'+adapter);
  const profile = `.${adapter}/agents/litespec-easy.${ext}`;
  const output = run(f, `${agent}\n2\n1\n\n\nno`);
  assert.match(output, /Ejecucion de pasos: 1\) Clasico .*2\) Adaptive/);
  assert.match(output, /Delegacion interna de las skills/);
  assert.match(output, /Modo: Adaptive/);
  assert(read(f,profile).includes(model));
  const skillsRoot = adapter === 'codex' ? '.agents/skills' : '.claude/skills';
  const workerRules = skillsRoot + '/litespec-shared/easy-worker.md';
  assert(read(f,profile).includes(workerRules));
  assert.equal(read(f,workerRules), read({root:source}, sources+'/litespec-shared/easy-worker.md'));
  assert(!read(f,profile).includes('tools: Read, Grep, Glob'));
  const personalized = read(f,profile).replace(model,'custom-model');
  fs.writeFileSync(path.join(f.root,profile), personalized);
  run(f, `${agent}\n2\n2\n\n\n\n\nno`);
  assert.equal(read(f,profile), personalized);
  assert(fs.existsSync(path.join(f.root,`.${adapter}/agents/litespec-search.${ext}`)));
  const classic = run(f, `${agent}\n1\n\nno`);
  assert.match(classic, /Modo: Clasico \+ Auto model/);
  assert(!fs.existsSync(path.join(f.root,profile)));
  run(f, `${agent}\n2\n1\nno`);
  assert.equal(read(f,profile), personalized);
  assert(!fs.existsSync(path.join(f.root,`.${adapter}/agents/litespec-search.${ext}`)));
}
// A legacy implement role is retired: any Codex/Claude run moves it aside and keeps its content.
for (const [agent, adapter, ext] of [['1','codex','toml'],['2','claude','md']]) {
  const f = fixture('retired-implement-'+adapter);
  const legacy = `.${adapter}/agents/litespec-implement.${ext}`;
  fs.mkdirSync(path.dirname(path.join(f.root,legacy)), {recursive:true});
  fs.writeFileSync(path.join(f.root,legacy), 'legacy implement role');
  const output = run(f, `${agent}\n2\n2\n\n\n\n\n\n\nno`);
  assert.match(output, /creados=4; restaurados=0; conservados=0; guardados=1/);
  assert(!fs.existsSync(path.join(f.root,legacy)));
  assert.equal(read(f,`.litespec/disabled-agents/${adapter}/litespec-implement.${ext}`), 'legacy implement role');
  run(f, `${agent}\n2\n2\nno`);
  assert(!fs.existsSync(path.join(f.root,legacy)), 'retired role is never restored');
}
// An older marker that names the implement role is regenerated whether active or saved.
for (const [agent, adapter, ext] of [['1','codex','toml'],['2','claude','md']]) {
  const rel = adapter === 'codex' ? '.agents/skills' : '.claude/skills';
  const marker = `${rel}/litespec-shared/delegation-active.md`;
  const savedMarker = `.litespec/disabled-agents/${adapter}/delegation-active.md`;
  const legacyText = 'Use litespec-search, litespec-plan and litespec-implement when useful.';
  for (const where of ['active','saved']) {
    const f = fixture(`legacy-marker-${where}-${adapter}`);
    run(f, `${agent}\n1\n2\n\n\n\n\nno`);
    const target = where === 'active' ? marker : savedMarker;
    if (where === 'saved') run(f, `${agent}\n1\n1\nno`);
    fs.writeFileSync(path.join(f.root,target), legacyText);
    const output = run(f, `${agent}\n1\n2\nno`);
    assert.match(output, /creados=1;/);
    assert.doesNotMatch(read(f,marker), /implement/);
    assert(read(f,marker).includes(`Adapter: ${adapter}`));
    assert(!fs.existsSync(path.join(f.root,savedMarker)));
  }
}
for (const kind of ['model','effort','collision','ancestor','missing']) {
  const f = fixture(`invalid-${kind}`);
  let input = '1\n1\n2\nbad"model\n';
  if (kind === 'effort') input = '1\n1\n2\nvalid\nunsupported\n';
  if (kind === 'collision') {
    fs.mkdirSync(path.join(f.root,'.codex/agents/litespec-search.toml'),{recursive:true});
    input = '1\n1\n2\n';
  }
  if (kind === 'missing') fs.unlinkSync(path.join(f.root,sources,'litespec-shared/delegation.md'));
  if (kind === 'ancestor') {
    fs.writeFileSync(path.join(f.root,'.codex'),'preserve');
    input = '1\n1\n2\n';
  }
  run(f,input,false);
  assert(!fs.existsSync(path.join(f.root,'.agents/skills')));
}
console.log(`PASS ${engine}: all 13 agents, Codex/Zed isolation contract, summaries, both adapters, disable/reactivate, customization, cleanup, invalid input and conflicts. Fixtures: ${base}`);
