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
  run(f, '3\n\nno\ni');
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
  run(f, '3\n\nno\n'+answer);
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
  run(f, '1\n1\n2\n\n\n\n\nno');
  assert.equal(read(f, native), originalNative, 'same options regenerate the same file');
}

for (const agent of Array.from({length:13}, (_,i) => String(i+1))) {
  const f = fixture(`basic-${agent}`);
  const output = run(f, agent + (['1','2'].includes(agent) ? '\n\n' : ['3','4','5','7','8'].includes(agent) ? '\n' : '') + '\nno');
  assert.doesNotMatch(output, /gpt-6-luna/);
  assert(!fs.existsSync(path.join(f.root,'.gitignore')), 'do not create a missing .gitignore');
  assert.match(output, /Agente: .+ \| Modo: Clasico/);
  assert.match(output, /Aviso: LiteSpec es experimental/);
  assert.match(output, /creados=0; reemplazados=0; eliminados=0/);
  const destinations = ['.agents','.claude','.github','.cursor','.opencode','.qoder','.gemini','.qwen','.cline','.devin','.ade','.agents','.minimax'];
  const skills = destinations[Number(agent)-1]+'/skills';
  assert(!fs.existsSync(path.join(f.root,skills,'litespec-shared/delegation-active.md')));
  assert(!fs.existsSync(path.join(f.root,skills,'litespec-shared/adaptive-active.md')));
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
  assert.match(output, /creados=3; reemplazados=0; eliminados=0/);
  assert.match(output, /Modelos no comprobados en ejecucion/);
  const agents = `.${adapter}/agents`;
  const native = `${agents}/litespec-search.${ext}`;
  const marker = `${rel}/litespec-shared/delegation-active.md`;
  assert(read(f,native).includes('model-search'));
  assert(!fs.existsSync(path.join(f.root,agents,`litespec-implement.${ext}`)), 'no implement role is created');
  assert(read(f,`${agents}/litespec-plan.${ext}`).includes('model-plan'));
  assert.doesNotMatch(read(f,marker), /implement|Experimental/);
  assert(read(f,marker).includes(`Adapter: ${adapter}`));
  // Reinstalling regenerates the exact files from the options chosen now.
  fs.writeFileSync(path.join(f.root,native),read(f,native)+'\n# personal customization\n');
  fs.writeFileSync(path.join(f.root,agents,`unrelated.${ext}`),'personal agent');
  const reinstall = run(f, `${agent}\n1\n2\nother-search\n\nmodel-plan\nhigh\nno`);
  assert.match(reinstall, /creados=0; reemplazados=3; eliminados=0/);
  assert(read(f,native).includes('other-search'));
  assert(!read(f,native).includes('personal customization'));
  assert.equal(read(f,`${agents}/unrelated.${ext}`),'personal agent');
  const disabled = run(f, `${agent}\n1\n1\nno`);
  assert.match(disabled, /creados=0; reemplazados=0; eliminados=3/);
  for (const role of ['search','plan']) {
    assert(!fs.existsSync(path.join(f.root,agents,`litespec-${role}.${ext}`)), `${role} is still registered after disabling`);
  }
  assert(!fs.existsSync(path.join(f.root,marker)), 'routing marker is still active');
  assert.equal(read(f,`${agents}/unrelated.${ext}`),'personal agent', 'only exact LiteSpec files are removed');
  assert(!fs.existsSync(path.join(f.root,'.litespec/disabled-agents')), 'nothing is saved aside');
  assert.match(run(f, `${agent}\n1\n1\nno`), /creados=0; reemplazados=0; eliminados=0/);
  // Basic source cleanup also removes the renamed installer, preserving unrelated files.
  fs.mkdirSync(path.join(f.root,'steps'));
  fs.writeFileSync(path.join(f.root,'steps','keep.txt'),'unrelated project file');
  run(f, `${agent}\n1\n1\nyes`);
  assert(!fs.existsSync(f.script));
  assert(!fs.existsSync(path.join(f.root,sources)));
  assert.equal(read(f,'steps/keep.txt'),'unrelated project file');
  assert.equal(read(f,`${agents}/unrelated.${ext}`),'personal agent');
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
  assert(!fs.existsSync(path.join(f.root,skillsRoot,'litespec-shared/adaptive-active.md')), 'Codex/Claude never use the other-client marker');
  fs.writeFileSync(path.join(f.root,profile), read(f,profile).replace(model,'custom-model'));
  // Adaptive + roles prompts search, plan and easy (model and effort each).
  const both = run(f, `${agent}\n2\n2\n\n\n\n\n\n\nno`);
  assert.match(both, /creados=3; reemplazados=1; eliminados=0/);
  assert(read(f,profile).includes(model) && !read(f,profile).includes('custom-model'));
  assert(fs.existsSync(path.join(f.root,`.${adapter}/agents/litespec-search.${ext}`)));
  // Roles default to enabled while their marker exists.
  const classic = run(f, `${agent}\n1\n\n\n\n\n\nno`);
  assert.match(classic, /Modo: Clasico \+ Auto model/);
  assert.match(classic, /creados=0; reemplazados=3; eliminados=1/);
  assert(!fs.existsSync(path.join(f.root,profile)));
  run(f, `${agent}\n2\n1\n\n\nno`);
  assert(read(f,profile).includes(model));
  assert(!fs.existsSync(path.join(f.root,`.${adapter}/agents/litespec-search.${ext}`)));
}
// Experimental Adaptive for other clients: a native Easy worker plus a marker naming the client.
for (const [agent, adapter, skills, worker, name] of [
  ['3','copilot','.github/skills','.github/agents/litespec-easy.agent.md','GitHub Copilot'],
  ['4','cursor','.cursor/skills','.cursor/agents/litespec-easy.md','Cursor'],
  ['5','opencode','.opencode/skills','.opencode/agents/litespec-easy.md','OpenCode'],
  ['7','gemini','.gemini/skills','.gemini/agents/litespec-easy.md','Gemini CLI'],
  ['8','qwen','.qwen/skills','.qwen/agents/litespec-easy.md','Qwen Code'],
]) {
  const f = fixture('adaptive-'+adapter);
  const marker = skills+'/litespec-shared/adaptive-active.md';
  const model = {
    copilot: 'Claude Sonnet 4.5 (copilot)',
    cursor: 'composer-2.5[fast=false]',
    opencode: 'anthropic/claude-sonnet-5-5#high',
  }[adapter] || 'provider/model-easy';
  const output = run(f, `${agent}\n2\n${model}\nno`);
  assert.match(output, /Adaptive experimental/);
  assert.match(output, /creados=2; reemplazados=0; eliminados=0/);
  const profile = read(f, worker);
  assert(profile.startsWith('---\n'));
  assert(profile.includes(`model: '${model}'`));
  assert(profile.includes(skills+'/litespec-shared/easy-worker.md'));
  assert.equal(profile.includes('name: litespec-easy'), adapter !== 'opencode');
  assert.equal(profile.includes('mode: subagent'), adapter === 'opencode');
  assert.equal(profile.includes('kind: local'), adapter === 'gemini');
  assert(read(f, marker).includes(`Client: ${name}.`));
  assert.doesNotMatch(read(f, marker), /Experimental/);
  if (adapter === 'opencode' || adapter === 'qwen') {
    assert.match(read(f, marker), /Invoke the litespec-easy subagent through native subagent delegation/);
  }
  if (adapter === 'copilot') {
    assert.match(read(f, marker), /VS Code, Copilot CLI or other/);
    assert.doesNotMatch(read(f, marker), /runSubagent/, 'Copilot marker stays surface-neutral');
    assert.match(output, /Copilot CLI usa IDs/);
  }
  assert(!fs.existsSync(path.join(f.root,'.codex')) && !fs.existsSync(path.join(f.root,'.claude')));
  // Reinstalling regenerates both files; an empty model now keeps the client default.
  fs.writeFileSync(path.join(f.root,worker), profile + '\n# personal\n');
  fs.writeFileSync(path.join(path.dirname(path.join(f.root,worker)),'unrelated.md'), 'personal agent');
  assert.match(run(f, `${agent}\n2\n\nno`), /creados=0; reemplazados=2; eliminados=0/);
  assert(!read(f, worker).includes('# personal') && !read(f, worker).includes('model:'));
  const classic = run(f, `${agent}\n1\nno`);
  assert.match(classic, /Modo: Clasico/);
  assert.match(classic, /creados=0; reemplazados=0; eliminados=2/);
  assert(!fs.existsSync(path.join(f.root,worker)) && !fs.existsSync(path.join(f.root,marker)));
  assert.equal(read(f, path.join(path.dirname(worker),'unrelated.md')), 'personal agent');
  assert(!fs.existsSync(path.join(f.root,'.litespec/disabled-agents')), 'nothing is saved aside');
  assert.match(run(f, `${agent}\n2\n${model}\nno`), /creados=2; reemplazados=0; eliminados=0/);
  assert(read(f, worker).includes(`model: '${model}'`));
  assert(read(f, marker).includes(`Client: ${name}.`));
}
{
  const f = fixture('adaptive-default-model');
  run(f, '5\n2\n\nno');
  assert.doesNotMatch(read(f,'.opencode/agents/litespec-easy.md'), /model:/, 'empty model keeps the client default');
}
for (const [label, bad] of [['quote', "3\n2\nbad'model\n"], ['space', '5\n2\nwith space\n'], ['mode', '7\n3\n']]) {
  const f = fixture('adaptive-invalid-'+label);
  run(f, bad, false);
  for (const dir of ['.github','.opencode','.gemini']) assert(!fs.existsSync(path.join(f.root,dir)), dir);
}
// A directory where a configuration file is expected stops before anything is written or removed.
for (const [agent, adapter, ext] of [['1','codex','toml'],['2','claude','md']]) {
  const f = fixture('disable-collision-'+adapter);
  const rel = adapter === 'codex' ? '.agents/skills' : '.claude/skills';
  run(f, `${agent}\n1\n2\n\n\n\n\nno`);
  const plan = path.join(f.root,`.${adapter}/agents/litespec-plan.${ext}`);
  fs.unlinkSync(plan);
  fs.mkdirSync(plan);
  fs.writeFileSync(path.join(plan,'keep.txt'),'keep');
  run(f, `${agent}\n1\n1\nno`, false);
  assert.equal(read(f,`.${adapter}/agents/litespec-plan.${ext}/keep.txt`),'keep');
  assert(fs.existsSync(path.join(f.root,rel,'litespec-shared/delegation-active.md')));
  assert(fs.existsSync(path.join(f.root,`.${adapter}/agents/litespec-search.${ext}`)));
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
console.log(`PASS ${engine}: all 13 agents, Codex/Zed isolation contract, summaries, both adapters, regenerate/remove exact files, cleanup, invalid input and conflicts. Fixtures: ${base}`);
