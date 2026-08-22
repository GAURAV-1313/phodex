"""Encryption for secrets stored at rest (per-user AI provider API keys).

Uses Fernet (symmetric, authenticated) keyed off a dedicated
SETTINGS_ENCRYPTION_KEY — deliberately separate from JWT_SECRET_KEY, which
has a different rotation lifecycle and blast radius.
"""

from functools import lru_cache

from cryptography.fernet import Fernet, InvalidToken

from app.core.config import Settings


class EncryptionKeyNotConfiguredError(RuntimeError):
    def __init__(self) -> None:
        super().__init__(
            "SETTINGS_ENCRYPTION_KEY is not set. Generate one with "
            "`python -c \"from cryptography.fernet import Fernet; "
            'print(Fernet.generate_key().decode())"` and add it to your .env.'
        )


@lru_cache
def _fernet(key: str) -> Fernet:
    return Fernet(key.encode("utf-8"))


def _get_fernet(settings: Settings) -> Fernet:
    if not settings.settings_encryption_key:
        raise EncryptionKeyNotConfiguredError
    return _fernet(settings.settings_encryption_key)


def encrypt_secret(settings: Settings, plaintext: str) -> str:
    return _get_fernet(settings).encrypt(plaintext.encode("utf-8")).decode("utf-8")


def decrypt_secret(settings: Settings, ciphertext: str) -> str:
    try:
        return _get_fernet(settings).decrypt(ciphertext.encode("utf-8")).decode("utf-8")
    except InvalidToken as exc:
        raise ValueError("Stored secret could not be decrypted (wrong or rotated key).") from exc
