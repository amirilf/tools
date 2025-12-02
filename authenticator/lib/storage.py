#!/usr/bin/env python3
import json
import os
from pathlib import Path
from .crypto import Crypto
from .totp import TOTPGenerator

class SecretStorage:
    def __init__(self, storage_path=None):
        if storage_path:
            self.storage_path = Path(storage_path)
        else:
            config_home = os.environ.get('XDG_DATA_HOME', os.path.expanduser('~/.local/share'))
            self.storage_path = Path(config_home) / 'secure-tools' / 'secrets.enc'
        self.storage_path.parent.mkdir(parents=True, exist_ok=True)
        self.crypto = Crypto()
        self.totp = TOTPGenerator()
        
    def _load_encrypted(self):
        return self.storage_path.read_bytes() if self.storage_path.exists() else b''
    
    def _save_encrypted(self, data):
        self.storage_path.write_bytes(data)
        self.storage_path.chmod(0o600)
    
    def load(self, password):
        encrypted = self._load_encrypted()
        if not encrypted:
            return []
        try:
            decrypted = self.crypto.decrypt(encrypted, password)
            return json.loads(decrypted.decode('utf-8'))
        except:
            raise ValueError("Failed to decrypt: invalid password")
    
    def save(self, secrets, password):
        data = json.dumps(secrets, indent=2).encode('utf-8')
        encrypted = self.crypto.encrypt(data, password)
        self._save_encrypted(encrypted)
    
    def add(self, password, domain, username, secret):
        domain = self.totp.normalize_domain(domain)
        if not self.totp.validate_secret(secret):
            raise ValueError("Invalid TOTP secret")
        secrets = self.load(password)
        for s in secrets:
            if s['domain'] == domain and s['username'] == username:
                raise ValueError(f"Already exists: {username}@{domain}")
        new_secret = {'domain': domain, 'username': username, 'secret': secret.replace(' ', '').upper()}
        secrets.append(new_secret)
        self.save(secrets, password)
        return new_secret
    
    def remove(self, password, domain, username):
        domain = self.totp.normalize_domain(domain)
        secrets = self.load(password)
        new_secrets = [s for s in secrets if not (s['domain'] == domain and s['username'] == username)]
        if len(new_secrets) == len(secrets):
            raise ValueError(f"Not found: {username}@{domain}")
        self.save(new_secrets, password)
    
    def get_by_domain(self, password, domain):
        domain = self.totp.normalize_domain(domain)
        secrets = self.load(password)
        return [s for s in secrets if self.totp.match_domain(s['domain'], domain)]
    
    def list_all(self, password):
        secrets = self.load(password)
        return [{'domain': s['domain'], 'username': s['username']} for s in secrets]
    
    def initialize(self, password):
        if self.storage_path.exists():
            raise ValueError("Already initialized")
        self.save([], password)
    
    def is_initialized(self):
        return self.storage_path.exists()
    
    def verify_password(self, password):
        encrypted = self._load_encrypted()
        return self.crypto.verify_password(encrypted, password) if encrypted else False

