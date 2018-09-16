import difflib


d = difflib.Differ()


def _dump(tag, x, lo, hi):
        """Generate comparison results for a same-tagged range."""
        for i in range(lo, hi):
            yield '%s %s' % (tag, x[i])


def _fancy_helper(a, alo, ahi, b, blo, bhi):
        g = []
        if alo < ahi:
            if blo < bhi:
                g = fancy_replace(a, alo, ahi, b, blo, bhi)
            else:
                g = _dump('-', a, alo, ahi)
        elif blo < bhi:
            g = _dump('+', b, blo, bhi)

        yield from g


def fancy_replace(a, alo, ahi, b, blo, bhi):
        best_ratio, cutoff = 0.74, 0.75
        cruncher = difflib.SequenceMatcher(None)

        eqi, eqj = None, None   # 1st indices of equal lines (if any)

        # search for the pair that matches best without being identical
        # (identical lines must be junk lines, & we don't want to synch up
        # on junk -- unless we have to)
        for j in range(blo, bhi):
            bj = b[j]
            cruncher.set_seq2(bj)
            for i in range(alo, ahi):
                ai = a[i]
                if ai == bj:
                    if eqi is None:
                        eqi, eqj = i, j
                    continue
                cruncher.set_seq1(ai)
                # computing similarity is expensive, so use the quick
                # upper bounds first -- have seen this speed up messy
                # compares by a factor of 3.
                # note that ratio() is only expensive to compute the first
                # time it's called on a sequence pair; the expensive part
                # of the computation is cached by cruncher
                print (cruncher.real_quick_ratio())
                if cruncher.real_quick_ratio() > best_ratio and \
                      cruncher.quick_ratio() > best_ratio and \
                      cruncher.ratio() > best_ratio:
                    best_ratio, best_i, best_j = cruncher.ratio(), i, j
        print ('best_ratio,cutoff: ',best_ratio,cutoff)
        if best_ratio < cutoff:
            # no non-identical "pretty close" pair
            if eqi is None:
                # no identical pair either -- treat it as a straight replace
                yield from plain_replace(a, alo, ahi, b, blo, bhi)
                return
            # no close pair, but an identical pair -- synch up on that
            best_i, best_j, best_ratio = eqi, eqj, 1.0
        else:
            # there's a close pair, so forget the identical pair (if any)
            eqi = None

        # a[best_i] very similar to b[best_j]; eqi is None iff they're not
        # identical

        # pump out diffs from before the synch point
        yield from _fancy_helper(a, alo, best_i, b, blo, best_j)

        # do intraline marking on the synch pair
        aelt, belt = a[best_i], b[best_j]
        if eqi is None:
            # pump out a '-', '?', '+', '?' quad for the synched lines
            atags = btags = ""
            cruncher.set_seqs(aelt, belt)
            for tag, ai1, ai2, bj1, bj2 in cruncher.get_opcodes():
                la, lb = ai2 - ai1, bj2 - bj1
                if tag == 'replace':
                    atags += '^' * la
                    btags += '^' * lb
                elif tag == 'delete':
                    atags += '-' * la
                elif tag == 'insert':
                    btags += '+' * lb
                elif tag == 'equal':
                    atags += ' ' * la
                    btags += ' ' * lb
                
                else:
                    raise ValueError('unknown tag %r' % (tag,))
                
                print (tag, ai1, ai2, bj1, bj2)
                print (la,lb,atags,btags)
            yield from _qformat(aelt, belt, atags, btags)
        else:
            # the synch pair is identical
            yield '  ' + aelt

        # pump out diffs from after the synch point
        yield from _fancy_helper(a, best_i+1, ahi, b, best_j+1, bhi)


def _count_leading(line, ch):
    """
    Return number of `ch` characters at the start of `line`.

    Example:

    >>> _count_leading('   abc', ' ')
    3
    """

    i, n = 0, len(line)
    while i < n and line[i] == ch:
        i += 1
    return i


def _qformat(aline, bline, atags, btags):
        r"""
        Format "?" output and deal with leading tabs.

        Example:

        >>> d = Differ()
        >>> results = d._qformat('\tabcDefghiJkl\n', '\tabcdefGhijkl\n',
        ...                      '  ^ ^  ^      ', '  ^ ^  ^      ')
        >>> for line in results: print(repr(line))
        ...
        '- \tabcDefghiJkl\n'
        '? \t ^ ^  ^\n'
        '+ \tabcdefGhijkl\n'
        '? \t ^ ^  ^\n'
        """

        # Can hurt, but will probably help most of the time.
        print (_count_leading(aline, "\t") ,_count_leading(bline, "\t"))
        common = min(_count_leading(aline, "\t"),
                     _count_leading(bline, "\t"))
        common = min(common, _count_leading(atags[:common], " "))
        common = min(common, _count_leading(btags[:common], " "))
        atags = atags[common:].rstrip()
        btags = btags[common:].rstrip()

        yield "- " + aline
        if atags:
            yield "? %s%s\n" % ("\t" * common, atags)

        yield "+ " + bline
        if btags:
            yield "? %s%s\n" % ("\t" * common, btags)


def plain_replace(a, alo, ahi, b, blo, bhi):
        assert alo < ahi and blo < bhi
        # dump the shorter block first -- reduces the burden on short-term
        # memory if the blocks are of very different sizes
        if bhi - blo < ahi - alo:
            first  = _dump('+', b, blo, bhi)
            second = _dump('-', a, alo, ahi)
        else:
            first  = _dump('-', a, alo, ahi)
            second = _dump('+', b, blo, bhi)
        for g in first, second:
            yield from g


if __name__ == '__main__':
    results = fancy_replace(['Sedlctfromyysdfdsm1\n','abcdefg\n'], 0, 2, \
                           ['Selectfromsysdfdsmy1\n','abcde\n','aBcdef\n'], 0, 3)


    print (''.join(results))
