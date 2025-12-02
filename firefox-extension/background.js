const API = 'http://localhost:18777/api';
let isAuth = false;

async function call(action, data = {}) {
  try {
    const res = await fetch(API, {
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      body: JSON.stringify({action, ...data})
    });
    if (!res.ok) throw new Error('Failed');
    return await res.json();
  } catch (e) {
    throw new Error('Server not running. Start: ath server');
  }
}

browser.runtime.onMessage.addListener((msg, sender, respond) => {
  if (msg.action === 'auth') {
    call('auth', {password: msg.password})
      .then(() => { isAuth = true; respond({success: true}); })
      .catch(e => respond({error: e.message}));
    return true;
  }
  
  if (msg.action === 'get') {
    call('get', {domain: msg.domain})
      .then(data => respond({success: true, accounts: data.accounts}))
      .catch(e => respond({error: e.message}));
    return true;
  }
  
  if (msg.action === 'logout') {
    call('logout').then(() => { isAuth = false; respond({success: true}); });
    return true;
  }
  
  if (msg.action === 'fill') {
    browser.tabs.query({active: true, currentWindow: true}).then(tabs => {
      if (tabs[0]) browser.tabs.sendMessage(tabs[0].id, {action: 'fill', code: msg.code});
    });
    respond({success: true});
    return false;
  }
});
