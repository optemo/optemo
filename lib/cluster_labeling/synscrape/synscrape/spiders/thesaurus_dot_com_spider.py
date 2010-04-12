from scrapy.spider import BaseSpider
from scrapy.http import Request

from scrapy.selector import HtmlXPathSelector

from synscrape.items import WordSenseItem

import re
import datetime

import cluster_labeling.usecases as usecases
import cluster_labeling.words as words

from django.db.models import Q

class ThesaurusDotComSpider(BaseSpider):
    domain_name = 'thesaurus.com'
    part_type_parse_fn_dict = None

    def get_url_for_word(self, word):
        return "http://thesaurus.com/browse/%s" % (word)

    def start_requests(self):
        # Get the list of words that are direct indicator words for
        # some usecase and have not been crawled since today.
        di_words = words.Word.get_manager()\
                   .filter(Q(directly_indicated_usecases__isnull=False),
                           Q(synonyms_last_crawled_date__isnull=True) |
                           Q(synonyms_last_crawled_date__lt=datetime.date.today()))

        return \
            map(lambda w:
                Request(url=self.get_url_for_word(w.word),
                        callback=self.parse),
                di_words)

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
        part_type = ' '.join(map(lambda w: w.strip(), row.select('td[1]//text()').extract()))
        part_contents = row.select('td[2]')[0]

        if part_type not in ThesaurusDotComSpider.part_type_parse_fn_dict:
            raise Exception("Spider parse error: %s" % part_type)

        ThesaurusDotComSpider.part_type_parse_fn_dict[part_type]\
        (self, word_sense, part_contents)

    def parse_sense(self, word, sense_selector):
        word_sense = WordSenseItem()
        word_sense['word'] = word
        word_sense['found'] = True
        
        for row in sense_selector.select('tr'):
            self.parse_sense_part(word_sense, row)

        return word_sense

    def parse_do_nothing(self, word_sense, junk):
        return word_sense

    def parse(self, response):
        hxs = HtmlXPathSelector(response)

        spellhdr = hxs.select('//div[@class="Spellhdr"]')
        if len(spellhdr) != 0:
            # Word was not found
            spellhdr = spellhdr[0]
            word = spellhdr.select('h1/text()')[0].extract()
            
            word_sense = WordSenseItem()
            word_sense['word'] = word
            word_sense['found'] = False
            
            return [word_sense]
        
        word = hxs.select('//h1[@class="query_h1"]/text()')[0]\
               .extract().lower()

        senses = []

        for sense in hxs.select('//table[@class="the_content"]'):
            if len(sense.select('div[@class="adjHdg"]')) != 0:
                break

            senses.append(sense)

        return map(lambda s: self.parse_sense(word, s), senses)

ThesaurusDotComSpider.part_type_parse_fn_dict = \
    { 'Main Entry:' : ThesaurusDotComSpider.parse_sense_name,
      'Part of Speech:' : ThesaurusDotComSpider.parse_sense_pos,
      'Definition:' : ThesaurusDotComSpider.parse_sense_definition,
      'Synonyms:' : ThesaurusDotComSpider.parse_sense_synonyms,
      'Antonyms:' : ThesaurusDotComSpider.parse_sense_antonyms,
      'Notes:' : ThesaurusDotComSpider.parse_sense_notes
    }

SPIDER = ThesaurusDotComSpider()
