from scrapy.spider import BaseSpider
from scrapy.http import Request

from scrapy.selector import HtmlXPathSelector

from synscrape.items import WordSenseItem

import re

class ThesaurusDotComSpider(BaseSpider):
    domain_name = 'thesaurus.com'
    words = ['clunky']

    part_type_parse_fn_dict = None

    def start_requests(self):
        return \
            map(lambda w:
                Request(url="http://thesaurus.com/browse/%s" % (w),
                        callback=self.parse),
                self.words)

    def parse_sense_name(self, word_sense, part_contents):
        sense_name = part_contents.select('text()')[0].extract()
        word_sense['name'] = sense_name

    def parse_sense_pos(self, word_sense, part_contents):
        sense_pos = part_contents.select('i/text()')[0].extract()
        word_sense['pos'] = sense_pos

    def parse_sense_definition(self, word_sense, part_contents):
        self.parse_sense_wordlist('definition', word_sense,
                                  part_contents)

    def parse_sense_synonyms(self, word_sense, part_contents):
        self.parse_sense_wordlist('synonyms', word_sense,
                                  part_contents)

    def parse_sense_antonyms(self, word_sense, part_contents):
        self.parse_sense_wordlist('antonyms', word_sense,
                                  part_contents)

    def parse_sense_wordlist(self, ws_key, word_sense, part_contents):
        wordlist = \
            ','.join(part_contents.select('.//text()').extract()).split(',')
        
        wordlist = filter(lambda x: len(x) > 0 and re.match('^\w+$', x),
                          map(lambda x: x.strip().lower(), wordlist))
        word_sense[ws_key] = wordlist

    def parse_sense_notes(self, word_sense, part_contents):
        sense_notes = part_contents.select('span/text()')[0].extract()
        word_sense['notes'] = sense_notes

    def parse_sense_part(self, word_sense, row):
        part_type = row.select('td[1]/text()')[0].extract().strip()
        part_contents = row.select('td[2]')[0]

        if part_type not in ThesaurusDotComSpider.part_type_parse_fn_dict:
            raise Exception("Spider parse error: %s" % part_type)

        ThesaurusDotComSpider.part_type_parse_fn_dict[part_type]\
        (self, word_sense, part_contents)

    def parse_sense(self, word, sense_selector):
        word_sense = WordSenseItem()
        word_sense['word'] = word
        
        for row in sense_selector.select('tr'):
            self.parse_sense_part(word_sense, row)

        return word_sense

    def parse(self, response):
        hxs = HtmlXPathSelector(response)
        word = hxs.select('//h1[@class="query_h1"]/text()')[0]\
               .extract().lower()

        return map(lambda s: self.parse_sense(word, s),
                   hxs.select('//table[@class="the_content"]'))

ThesaurusDotComSpider.part_type_parse_fn_dict = \
    { 'Main Entry:' : ThesaurusDotComSpider.parse_sense_name,
      'Part of Speech:' : ThesaurusDotComSpider.parse_sense_pos,
      'Definition:' : ThesaurusDotComSpider.parse_sense_definition,
      'Synonyms:' : ThesaurusDotComSpider.parse_sense_synonyms,
      'Antonyms:' : ThesaurusDotComSpider.parse_sense_antonyms,
      'Notes:' : ThesaurusDotComSpider.parse_sense_notes
    }

SPIDER = ThesaurusDotComSpider()
