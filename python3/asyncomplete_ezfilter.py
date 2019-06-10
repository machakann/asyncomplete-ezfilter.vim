import re


class AsyncompleteEzfilter:
    def match_filter(self, items, start):
        pat = re.compile(re.escape(start), re.I)
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

    def jaro_winkler_similarity(self, a, b):
        if a == "" and b == "":
            return 1.0
        elif a == "" or b == "":
            return 0.0
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

    def jaro_winkler_distance(self, a, b):
        return 1.0 - self.jaro_winkler_similarity(a, b)

    def jaro_winkler_filter(self, items, base, thr):
        thr = float(thr)
        n = len(base)
        matchlist = []
        for x in items:
            lead = x['word'][:n]
            x['_distance'] = self.jaro_winkler_distance(lead, base)
            if x['_distance'] <= thr:
                matchlist.append(x)
        matchlist.sort(key=lambda x: x['_distance'])
        return matchlist

    def _get_pattern_match_vector(self, a, b):
        pm = [0 for i in range(len(b) + 1)]
        for i, _a in enumerate(a):
            for j, _b in enumerate(b):
                if _a == _b:
                    pm[j + 1] |= 1 << i
        return pm

    # optimal string alignment distance by bit-parallel algorithm
    def _osa_distance_BP(self, a, b):
        pm = self._get_pattern_match_vector(a, b)
        vp = ~0
        vn = 0
        dt = len(a)
        d0 = 0
        ms = 1 << (dt - 1)
        for j in range(1, len(b) + 1):
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

    def optimal_string_alignment_distance(self, a, b):
        na = len(a)
        nb = len(b)
        if na == 0 or nb == 0:
            return max(na, nb)
        a = a.upper()
        b = b.upper()
        if a == b:
            return 0
        return self._osa_distance_BP(a, b)

    def optimal_string_alignment_filter(self, items, base, thr):
        thr = float(thr)
        n = len(base)
        matchlist = []
        for x in items:
            lead = x['word'][:n]
            x['_distance'] = self.optimal_string_alignment_distance(lead, base)
            if x['_distance'] <= thr:
                matchlist.append(x)
        matchlist.sort(key=lambda x: x['_distance'])
        return matchlist


asyncomplete_ezfilter = AsyncompleteEzfilter()
