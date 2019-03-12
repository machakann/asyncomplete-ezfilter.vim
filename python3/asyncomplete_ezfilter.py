import re


class AsyncompleteEzfilter:
    def match_filter(self, items, start):
        pat = re.compile(re.escape(start), re.I)
        return [x for x in items if pat.match(x['word'])]


asyncomplete_ezfilter = AsyncompleteEzfilter()
