"""
Text Chunking Utility.

Splits long text into manageable chunks for processing while preserving
paragraph boundaries and context. This prevents LLM context overflow and
improves processing speed for long documents.
"""

import re
from typing import List, Tuple
from dataclasses import dataclass

from ..config import get_settings


@dataclass
class TextChunk:
    """A chunk of text with its offset in the original."""
    text: str
    start_offset: int
    end_offset: int
    paragraph_index: int


class TextChunker:
    """
    Splits text into chunks for processing.

    Strategy:
    1. First split by paragraphs (double newline)
    2. If paragraphs are too long, split by sentences
    3. Preserve offsets for issue mapping
    """

    def __init__(self, max_chunk_size: int = None):
        settings = get_settings()
        self.max_chunk_size = max_chunk_size or settings.chunk_size

    def chunk_text(self, text: str) -> List[TextChunk]:
        """
        Split text into processable chunks.

        Args:
            text: The full text to chunk

        Returns:
            List of TextChunk objects with text and offsets
        """
        if len(text) <= self.max_chunk_size:
            return [TextChunk(
                text=text,
                start_offset=0,
                end_offset=len(text),
                paragraph_index=0
            )]

        # Split by paragraphs first
        paragraphs = self._split_paragraphs(text)
        chunks = []
        current_offset = 0

        for para_idx, paragraph in enumerate(paragraphs):
            if len(paragraph) <= self.max_chunk_size:
                chunks.append(TextChunk(
                    text=paragraph,
                    start_offset=current_offset,
                    end_offset=current_offset + len(paragraph),
                    paragraph_index=para_idx
                ))
            else:
                # Split long paragraph by sentences
                sentence_chunks = self._split_by_sentences(
                    paragraph,
                    current_offset,
                    para_idx
                )
                chunks.extend(sentence_chunks)

            current_offset += len(paragraph)
            # Account for paragraph separator
            if para_idx < len(paragraphs) - 1:
                current_offset += 2  # \n\n

        return chunks

    def _split_paragraphs(self, text: str) -> List[str]:
        """Split text by paragraph boundaries."""
        # Split on double newlines, preserving empty paragraphs
        paragraphs = re.split(r'\n\n', text)
        return [p for p in paragraphs if p.strip()]

    def _split_by_sentences(
        self,
        text: str,
        base_offset: int,
        para_idx: int
    ) -> List[TextChunk]:
        """Split a long paragraph into sentence-based chunks."""
        # Sentence-ending patterns (handles abbreviations like Mr., Dr., etc.)
        sentence_pattern = r'(?<=[.!?])\s+(?=[A-Z])'
        sentences = re.split(sentence_pattern, text)

        chunks = []
        current_chunk = ""
        chunk_start = base_offset

        for sentence in sentences:
            if len(current_chunk) + len(sentence) <= self.max_chunk_size:
                current_chunk += sentence + " "
            else:
                if current_chunk:
                    chunks.append(TextChunk(
                        text=current_chunk.strip(),
                        start_offset=chunk_start,
                        end_offset=chunk_start + len(current_chunk.strip()),
                        paragraph_index=para_idx
                    ))
                    chunk_start += len(current_chunk)

                current_chunk = sentence + " "

        # Don't forget the last chunk
        if current_chunk.strip():
            chunks.append(TextChunk(
                text=current_chunk.strip(),
                start_offset=chunk_start,
                end_offset=chunk_start + len(current_chunk.strip()),
                paragraph_index=para_idx
            ))

        return chunks

    def merge_chunks(self, chunks: List[TextChunk]) -> str:
        """Merge chunks back into a single text."""
        if not chunks:
            return ""

        # Sort by offset
        sorted_chunks = sorted(chunks, key=lambda c: c.start_offset)

        result = []
        prev_para_idx = -1

        for chunk in sorted_chunks:
            if chunk.paragraph_index != prev_para_idx and prev_para_idx >= 0:
                result.append("\n\n")
            elif result:
                result.append(" ")

            result.append(chunk.text)
            prev_para_idx = chunk.paragraph_index

        return "".join(result)

    def adjust_issue_offsets(
        self,
        issues: List[dict],
        chunk: TextChunk
    ) -> List[dict]:
        """
        Adjust issue offsets from chunk-relative to document-relative.

        Args:
            issues: Issues with chunk-relative offsets
            chunk: The chunk these issues belong to

        Returns:
            Issues with document-relative offsets
        """
        adjusted = []
        for issue in issues:
            adjusted_issue = issue.copy()
            adjusted_issue["offset"] = issue["offset"] + chunk.start_offset
            adjusted.append(adjusted_issue)
        return adjusted
