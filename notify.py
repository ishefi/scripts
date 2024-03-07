#!/usr/bin/env python3

import os
from argparse import ArgumentParser

if __name__ == "__main__":
    parser = ArgumentParser(description="Send a notification")
    parser.add_argument("title", metavar='TITLE', help="The title of the notification")
    parser.add_argument("text", metavar='TEXT', help="The text of the notification")
    parser.add_argument("sound", metavar='SOUND', help="The sound of the notification")
    args = parser.parse_args()
    
    os.system(f"osascript -e 'display notification \"{args.text}\" with title \"{args.title}\" sound name \"{args.sound}\"'")
