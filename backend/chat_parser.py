import re
import os
from typing import List, Dict, Any
from langchain_text_splitters import RecursiveCharacterTextSplitter

# Aliases used in exports
SAHAN_NAMES = {"carbon monoxide", "obstech systems", "sahan"}
PARIL_NAMES = {"paril", "paril about to sleep"}

# Pattern for WhatsApp exports: "DD/MM/YYYY, HH:MM [am/pm] - Sender: Message"
CHAT_LINE_PATTERN = re.compile(
    r'^(\d{1,2}/\d{1,2}/\d{2,4}),?\s+(\d{1,2}:\d{2}(?:\s*[ap]m)?)\s*-\s*([^:]+):\s*(.*)$',
    re.IGNORECASE
)

def normalize_sender(raw_sender: str) -> str:
    cleaned = raw_sender.strip().lower()
    if cleaned in PARIL_NAMES or "paril" in cleaned:
        return "Paril"
    if cleaned in SAHAN_NAMES or "sahan" in cleaned:
        return "Sahan"
    return raw_sender.strip()

def parse_whatsapp_file(file_path: str) -> List[Dict[str, str]]:
    """Parse WhatsApp text file into structured turns."""
    turns = []
    if not os.path.exists(file_path):
        return turns

    with open(file_path, "r", encoding="utf-8", errors="replace") as f:
        curr_sender = None
        curr_date = None
        curr_time = None
        curr_msg = []

        for line in f:
            match = CHAT_LINE_PATTERN.match(line)
            if match:
                # Flush previous message
                if curr_sender and curr_msg:
                    text = "\n".join(curr_msg).strip()
                    if text and "<media omitted>" not in text.lower():
                        turns.append({
                            "sender": normalize_sender(curr_sender),
                            "date": curr_date or "",
                            "time": curr_time or "",
                            "message": text
                        })
                curr_date = match.group(1).strip()
                curr_time = match.group(2).strip()
                curr_sender = match.group(3).strip()
                curr_msg = [match.group(4).strip()]
            else:
                if curr_sender is not None:
                    curr_msg.append(line.rstrip())

        # Flush last
        if curr_sender and curr_msg:
            text = "\n".join(curr_msg).strip()
            if text and "<media omitted>" not in text.lower():
                turns.append({
                    "sender": normalize_sender(curr_sender),
                    "date": curr_date or "",
                    "time": curr_time or "",
                    "message": text
                })

    return turns

def group_turns_into_dialogue_chunks(turns: List[Dict[str, str]], window_size: int = 4) -> List[Dict[str, Any]]:
    """
    Groups conversational turns into sliding dialogue chunks to preserve conversational flow and context.
    Each chunk records the primary speaker, the dialogue snippet, and metadata.
    """
    chunks = []
    if not turns:
        return chunks

    # Group sequential turns by same speaker if consecutive
    collapsed = []
    for turn in turns:
        if collapsed and collapsed[-1]["sender"] == turn["sender"]:
            collapsed[-1]["message"] += "\n" + turn["message"]
        else:
            collapsed.append(turn.copy())

    # Build dialogue context windows (step by 3 to avoid redundant single-turn shifts)
    for i in range(0, len(collapsed), 3):
        window = collapsed[max(0, i - window_size + 1): i + 1]
        dialogue_text = "\n".join([f"{t['sender']}: {t['message']}" for t in window])
        last_turn = collapsed[i]
        
        chunks.append({
            "content": dialogue_text,
            "speaker": last_turn["sender"],
            "last_message": last_turn["message"],
            "date": last_turn.get("date", ""),
            "time": last_turn.get("time", ""),
            "turn_index": i
        })

    return chunks
