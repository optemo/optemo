from scrapy.item import Item, Field

class WordSenseItem(Item):
    found = Field()

    word = Field()
    
    name = Field()
    pos = Field()
    definition = Field()
    
    synonyms = Field()
    antonyms = Field()

    notes = Field()
