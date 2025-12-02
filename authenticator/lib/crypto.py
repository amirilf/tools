#!/usr/bin/env python3
import os
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
from cryptography.hazmat.primitives import hashes

class Crypto:
    SALT_SIZE = 32
    NONCE_SIZE = 12
    ITERATIONS = 600000
    
    def derive_key(self, password: str, salt: bytes) -> bytes:
        kdf = PBKDF2HMAC(algorithm=hashes.SHA256(), length=32, salt=salt, iterations=self.ITERATIONS)
        return kdf.derive(password.encode('utf-8'))
    
    def encrypt(self, data: bytes, password: str) -> bytes:
        salt = os.urandom(self.SALT_SIZE)
        nonce = os.urandom(self.NONCE_SIZE)
        key = self.derive_key(password, salt)
        ciphertext = AESGCM(key).encrypt(nonce, data, None)
        return salt + nonce + ciphertext
    
    def decrypt(self, encrypted_data: bytes, password: str) -> bytes:
        salt = encrypted_data[:self.SALT_SIZE]
        nonce = encrypted_data[self.SALT_SIZE:self.SALT_SIZE + self.NONCE_SIZE]
        ciphertext = encrypted_data[self.SALT_SIZE + self.NONCE_SIZE:]
        key = self.derive_key(password, salt)
        return AESGCM(key).decrypt(nonce, ciphertext, None)
    
    def verify_password(self, encrypted_data: bytes, password: str) -> bool:
        try:
            self.decrypt(encrypted_data, password)
            return True
        except:
            return False

