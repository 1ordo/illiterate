"""
Caching Utility for Grammar Check Results.

Provides in-memory caching with TTL to avoid redundant LanguageTool
and LLM calls for the same text.
"""

import hashlib
import time
from typing import Optional, Dict, Any
from dataclasses import dataclass, field
from threading import Lock

from ..config import get_settings


@dataclass
class CacheEntry:
    """A cached result with timestamp."""
    value: Any
    timestamp: float
    hits: int = 0


class GrammarCache:
    """
    In-memory cache for grammar check results.

    Features:
    - TTL-based expiration
    - Thread-safe operations
    - Hit counting for analytics
    - Memory-bounded (max entries)
    """

    def __init__(self, ttl: int = None, max_entries: int = 1000):
        settings = get_settings()
        self.ttl = ttl or settings.cache_ttl
        self.max_entries = max_entries
        self._cache: Dict[str, CacheEntry] = {}
        self._lock = Lock()
        self._stats = {
            "hits": 0,
            "misses": 0,
            "evictions": 0
        }

    def _make_key(self, text: str, language: str, mode: str = None) -> str:
        """Generate a cache key from text and parameters."""
        content = f"{text}|{language}|{mode or ''}"
        return hashlib.md5(content.encode()).hexdigest()

    def get(self, text: str, language: str, mode: str = None) -> Optional[Any]:
        """
        Get a cached result.

        Args:
            text: The original text
            language: Language code
            mode: Check mode (optional)

        Returns:
            Cached value if valid, None otherwise
        """
        key = self._make_key(text, language, mode)

        with self._lock:
            entry = self._cache.get(key)

            if entry is None:
                self._stats["misses"] += 1
                return None

            # Check TTL
            if time.time() - entry.timestamp > self.ttl:
                del self._cache[key]
                self._stats["misses"] += 1
                return None

            entry.hits += 1
            self._stats["hits"] += 1
            return entry.value

    def set(
        self,
        text: str,
        language: str,
        value: Any,
        mode: str = None
    ) -> None:
        """
        Cache a result.

        Args:
            text: The original text
            language: Language code
            value: The result to cache
            mode: Check mode (optional)
        """
        key = self._make_key(text, language, mode)

        with self._lock:
            # Evict old entries if at capacity
            if len(self._cache) >= self.max_entries:
                self._evict_oldest()

            self._cache[key] = CacheEntry(
                value=value,
                timestamp=time.time()
            )

    def _evict_oldest(self) -> None:
        """Evict the oldest entries to make room."""
        if not self._cache:
            return

        # Sort by timestamp and remove oldest 10%
        sorted_keys = sorted(
            self._cache.keys(),
            key=lambda k: self._cache[k].timestamp
        )

        evict_count = max(1, len(sorted_keys) // 10)
        for key in sorted_keys[:evict_count]:
            del self._cache[key]
            self._stats["evictions"] += 1

    def invalidate(self, text: str, language: str, mode: str = None) -> bool:
        """
        Remove a specific entry from cache.

        Returns:
            True if entry was found and removed
        """
        key = self._make_key(text, language, mode)

        with self._lock:
            if key in self._cache:
                del self._cache[key]
                return True
            return False

    def clear(self) -> None:
        """Clear all cached entries."""
        with self._lock:
            self._cache.clear()

    def get_stats(self) -> Dict[str, Any]:
        """Get cache statistics."""
        with self._lock:
            total_requests = self._stats["hits"] + self._stats["misses"]
            hit_rate = (
                self._stats["hits"] / total_requests
                if total_requests > 0 else 0
            )

            return {
                "entries": len(self._cache),
                "max_entries": self.max_entries,
                "hits": self._stats["hits"],
                "misses": self._stats["misses"],
                "evictions": self._stats["evictions"],
                "hit_rate": round(hit_rate, 3)
            }

    def cleanup_expired(self) -> int:
        """
        Remove all expired entries.

        Returns:
            Number of entries removed
        """
        now = time.time()
        removed = 0

        with self._lock:
            expired_keys = [
                key for key, entry in self._cache.items()
                if now - entry.timestamp > self.ttl
            ]

            for key in expired_keys:
                del self._cache[key]
                removed += 1

        return removed


# Global cache instance
_cache_instance: Optional[GrammarCache] = None


def get_cache() -> GrammarCache:
    """Get the global cache instance."""
    global _cache_instance
    if _cache_instance is None:
        _cache_instance = GrammarCache()
    return _cache_instance
