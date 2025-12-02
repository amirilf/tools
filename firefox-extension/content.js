function findTOTP() {
  return Array.from(document.querySelectorAll('input')).filter(i => {
    const txt = [i.name, i.id, i.placeholder, i.getAttribute('aria-label'), i.autocomplete].join(' ').toLowerCase();
    return (txt.includes('totp') || txt.includes('2fa') || txt.includes('verification') || 
            txt.includes('authenticator') || txt.includes('otp') || 
            (txt.includes('code') && i.type === 'text' && i.maxLength <= 8)) && i.type !== 'hidden';
  });
}

function fill(code) {
  const fields = findTOTP();
  if (!fields.length) return false;
  const field = fields.find(f => f.offsetParent) || fields[0];
  field.value = code;
  field.dispatchEvent(new Event('input', {bubbles: true}));
  field.dispatchEvent(new Event('change', {bubbles: true}));
  field.focus();
  return true;
}

function mark() {
  findTOTP().forEach(f => {
    if (!f.dataset.marked) {
      f.dataset.marked = '1';
      f.style.borderLeft = '3px solid #4CAF50';
      f.title = 'TOTP field detected';
    }
  });
}

browser.runtime.onMessage.addListener((msg, sender, respond) => {
  if (msg.action === 'fill') {
    respond({success: fill(msg.code)});
  }
});

setTimeout(mark, 500);
new MutationObserver(mark).observe(document.body, {childList: true, subtree: true});
