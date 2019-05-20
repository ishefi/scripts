#!/usr/bin/env python3
import argparse

BAR_LEN = 130


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('total', metavar='TOTAL', type=float, help='To do in total')
    parser.add_argument('done', metavar='DONE', type=float, help='Done so far')
    args = parser.parse_args()
    if args.done > args.total:
        parser.print_usage()
        print('error: DONE must be less than TOTAL')
        exit(1)

    percents = args.done / args.total
    percent_bar_len = int(BAR_LEN * percents)
    percent_bar = '#' * percent_bar_len
    empty_bar = '-' * (BAR_LEN - percent_bar_len)
    print(f'{args.done} / {args.total} are {percents * 100:.1f}%, {args.total - args.done} left \n'
          f'[{percent_bar}{empty_bar}]')


if __name__ == '__main__':
    main()
