#!/usr/bin/env python3
import pyotp
import re
from urllib.parse import urlparse

class TOTPGenerator:
    @staticmethod
    def generate(secret: str) -> str:
        return pyotp.TOTP(secret).now()
    
    @staticmethod
    def validate_secret(secret: str) -> bool:
        try:
            pyotp.TOTP(secret.replace(' ', '').upper())
            return True
        except:
            return False
    
    @staticmethod
    def normalize_domain(domain: str) -> str:
        if '://' in domain:
            domain = urlparse(domain).netloc or domain
        domain = re.sub(r'^www\.', '', domain.lower()).split('/')[0]
        return domain
    
    @staticmethod
    def match_domain(stored: str, current: str) -> bool:
        stored = TOTPGenerator.normalize_domain(stored)
        current = TOTPGenerator.normalize_domain(current)
        return stored == current or current.endswith('.' + stored) or stored.endswith('.' + current)

