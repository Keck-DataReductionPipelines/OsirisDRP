#!/usr/bin/env python
# -*- coding: utf-8 -*-

import sys, argparse
from drptestbones.backbone import consume_queue_directory

def main():
    """Main function for consume queue."""
    parser = argparse.ArgumentParser(description="A script to run the OSIRIS DRP to consume a single queue.")
    parser.add_argument("queue_directory", type=str, help="The queue directory to use for the pipeline.")
    opt = parser.parse_args()
    return consume_queue_directory(opt.queue_directory)

if __name__ == '__main__':
    sys.exit(main())