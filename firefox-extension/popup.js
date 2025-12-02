const $ = id => document.getElementById(id);
let domain = '';

function show(state) {
  ['loading', 'auth', 'accounts'].forEach(s => $(s).classList.add('hidden'));
  $(state).classList.remove('hidden');
}

function msg(el, txt, type) {
  el.innerHTML = `<div class="msg ${type}">${txt}</div>`;
  if (type !== 'error') setTimeout(() => el.innerHTML = '', 3000);
}

async function getDomain() {
  const tabs = await browser.tabs.query({active: true, currentWindow: true});
  if (tabs[0]) {
    const url = new URL(tabs[0].url);
    return url.hostname.replace(/^www\./, '');
  }
  return '';
}

async function auth(pw) {
  const res = await browser.runtime.sendMessage({action: 'auth', password: pw});
  if (res.error) {
    msg($('authMsg'), res.error, 'error');
  } else {
    await load();
  }
}

async function load() {
  show('loading');
  const res = await browser.runtime.sendMessage({action: 'get', domain});
  if (res.error) {
    if (res.error.includes('not running')) {
      msg($('authMsg'), 'Server not running. Start: ath server', 'error');
      show('auth');
    } else {
      msg($('accountsMsg'), res.error, 'error');
      show('accounts');
    }
  } else {
    display(res.accounts);
  }
}

function display(accounts) {
  show('accounts');
  if (!accounts.length) {
    $('accounts').innerHTML = '<div class="empty"><strong>No accounts</strong><div>Add: ath add</div></div>';
    return;
  }
  
  $('accounts').innerHTML = '<div class="list"></div>';
  const list = $('accounts').querySelector('.list');
  
  accounts.forEach(a => {
    const item = document.createElement('div');
    item.className = 'item';
    item.innerHTML = `
      <div class="info">
        <div class="user">${esc(a.username)}</div>
        <div class="domain">${esc(a.domain)}</div>
      </div>
      <div class="code">${a.code}</div>
    `;
    item.onclick = () => fill(a.code);
    list.appendChild(item);
  });
  
  msg($('accountsMsg'), `${accounts.length} account(s)`, 'success');
}

async function fill(code) {
  await browser.runtime.sendMessage({action: 'fill', code});
  await navigator.clipboard.writeText(code);
  msg($('accountsMsg'), '✓ Filled & copied!', 'success');
  setTimeout(() => window.close(), 1000);
}

function esc(txt) {
  const m = {'&':'&amp;', '<':'&lt;', '>':'&gt;', '"':'&quot;', "'": '&#039;'};
  return txt.replace(/[&<>"']/g, c => m[c]);
}

$('loginForm').onsubmit = e => {
  e.preventDefault();
  auth($('password').value);
};

$('logout').onclick = () => {
  browser.runtime.sendMessage({action: 'logout'});
  show('auth');
};

getDomain().then(d => {
  domain = d;
  $('domain').textContent = d || 'Unknown';
  load();
});
