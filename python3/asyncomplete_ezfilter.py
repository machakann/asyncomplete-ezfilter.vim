import re


class AsyncompleteEzfilter:
    def match_filter(self, items, start, *, ignorecase=True):
        if ignorecase:
            pat = re.compile(re.escape(start), re.I)
        else:
            pat = re.compile(re.escape(start))
        return [x for x in items if pat.match(x['word'])]

    def _commonchar(self, a, b):
        na = len(a)
        nb = len(b)
        window = (max(na, nb, 4) // 2) - 1
        c = 0.0
        acommons = []
        bindexes = []
        for i in range(na):
            j = i - window
            while j <= i + window:
                start = j
                j = b.find(a[i], max(start, 0))
                if j == -1 or (j not in bindexes):
                    break
                j += 1
            if j != -1 and j <= i + window:
                acommons.append(a[i])
                bindexes.append(j)
                c += 1.0
        bindexes.sort()
        bcommons = [b[j] for j in bindexes]
        return [c, acommons, bcommons]

    def _transposechar(self, acommons, bcommons):
        n = len(acommons)
        if n <= 1:
            return 0.0
        t = 0.0
        for i in range(n):
            if acommons[i] != bcommons[i]:
                t += 1.0
        return t / 2

    def _commonprefix(self, a, b):
        na = len(a)
        nb = len(b)
        ll = 0
        while ll < min(3, na, nb):
            if a[ll] != b[ll]:
                break
            ll += 1
        if ll > 4:
            return 4
        return ll

    def jaro_winkler_similarity(self, a, b, *, ignorecase=True):
        if a == "" and b == "":
            return 1.0
        elif a == "" or b == "":
            return 0.0
        if ignorecase:
            a = a.upper()
            b = b.upper()
        if a == b:
            return 1.0
        na = len(a)
        nb = len(b)
        c, acommons, bcommons = self._commonchar(a, b)
        if c == 0.0:
            return 0.0
        t = self._transposechar(acommons, bcommons)
        dj = (c / na + c / nb + 1.0 - t / c) / 3.0
        ll = self._commonprefix(a, b)
        p = 0.1
        djw = dj + ll * p * (1.0 - dj)
        return djw

    def jaro_winkler_distance(self, a, b, **kwargs):
        similarity = self.jaro_winkler_similarity(a, b, **kwargs)
        return 1.0 - similarity

    def jaro_winkler_filter(self, items, base, thr, **kwargs):
        thr = float(thr)
        n = len(base)
        matchlist = []
        for x in items:
            lead = x['word'][:n]
            x['_distance'] = self.jaro_winkler_distance(lead, base, **kwargs)
            if x['_distance'] <= thr:
                matchlist.append(x)
        matchlist.sort(key=lambda x: x['_distance'])
        return matchlist

    # pattern match dictionary is a kind of cache. It is not essential but
    # accelerates self._get_pattern_match_vector()
    def _get_pattern_match_dict(self, base):
        pd = {c: 0 for c in base}
        for i, c in enumerate(base):
            pd[c] |= 1 << i
        return pd

    def _get_pattern_match_vector(self, pd, word):
        pm = [0] * (len(word) + 1)
        for j, c in enumerate(word):
            if c in pd:
                pm[j + 1] |= pd[c]
        return pm

    # optimal string alignment distance by bit-parallel algorithm [1,2]
    # 1. "A Bit-Vector Algorithm for Computing Levenshtein and Damerau Edit Distances",
    # Heikki Hyyrö, Journal Nordic Journal of Computing 10, 29-39, 2003
    # 2. "Explaining and Extending the Bit-parallel Approximate String Matching Algorithm of Myers",
    # Heikki Hyyrö, Technical report A2001-10 of the Department of Computer and Information Sciences, University of Tampere, 2001
    def _osa_distance_BP(self, word, base, pd=None):
        if pd is None:
            pd = self._get_pattern_match_dict(base)
        pm = self._get_pattern_match_vector(pd, word)
        vp = ~0
        vn = 0
        dt = len(base)
        d0 = 0
        ms = 1 << (dt - 1)
        for j in range(1, len(word) + 1):
            d0 = (((~d0) & pm[j]) << 1) & pm[j - 1]
            d0 = d0 | (((pm[j] & vp) + vp) ^ vp) | pm[j] | vn
            hp = vn | ~(d0 | vp)
            hn = d0 & vp
            if hp & ms != 0:
                dt += 1
            if hn & ms != 0:
                dt -= 1
            vp = (hn << 1) | ~(d0 | ((hp << 1) | 1))
            vn = d0 & ((hp << 1) | 1)
        return dt

    def optimal_string_alignment_distance(self, a, b, *, ignorecase=True):
        na = len(a)
        nb = len(b)
        if na == 0 or nb == 0:
            return max(na, nb)
        if ignorecase:
            a = a.upper()
            b = b.upper()
        if a == b:
            return 0
        return self._osa_distance_BP(a, b)

    def optimal_string_alignment_filter(self,
                                        items,
                                        base,
                                        thr,
                                        *,
                                        ignorecase=True):
        if not base:
            return items
        if ignorecase:
            base = base.upper()
        n = len(base)
        pd = self._get_pattern_match_dict(base)
        thr = float(thr)
        matchlist = []
        for x in items:
            lead = x['word'][:n]
            if ignorecase:
                lead = lead.upper()
            x['_distance'] = self._osa_distance_BP(lead, base, pd)
            if x['_distance'] <= thr:
                matchlist.append(x)
        matchlist.sort(key=lambda x: x['_distance'])
        return matchlist


asyncomplete_ezfilter = AsyncompleteEzfilter()
