import sys
import os
import json
import re

sys.stdout.reconfigure(encoding='utf-8')
from chat_parser import parse_whatsapp_file

p1 = os.path.join('..', 'mobile', 'assets', 'resources', 'WhatsApp Chat with PARIL.txt')
p2 = os.path.join('..', 'mobile', 'assets', 'resources', 'WhatsApp Chat with Paril About To Sleep.txt')

turns1 = parse_whatsapp_file(p1)
turns2 = parse_whatsapp_file(p2)
all_turns = turns1 + turns2

# Filter out media, links, very short messages
clean_turns = []
for t in all_turns:
    msg = t['message'].strip()
    if not msg or '<media omitted>' in msg.lower() or 'http://' in msg or 'https://' in msg:
        continue
    clean_turns.append({'sender': t['sender'], 'message': msg})

# Sample multi-turn exchanges where Paril and Sahan are talking
exchanges = []
for i in range(len(clean_turns) - 5):
    t0, t1, t2, t3 = clean_turns[i:i+4]
    if (t0['sender'] != t1['sender'] and 
        t1['sender'] != t2['sender'] and 
        t2['sender'] != t3['sender'] and
        10 < len(t0['message']) < 100 and
        10 < len(t1['message']) < 100 and
        10 < len(t2['message']) < 100 and
        10 < len(t3['message']) < 100):
        exchanges.append([t0, t1, t2, t3])

print(f"Found {len(exchanges)} candidate 4-turn exchanges")

# Sample 10 distinct exchanges
sample_exchanges = exchanges[::max(1, len(exchanges)//12)][:10]
for idx, ex in enumerate(sample_exchanges):
    print(f"\n--- Exchange {idx+1} ---")
    for t in ex:
        print(f"{t['sender']}: {t['message']}")
