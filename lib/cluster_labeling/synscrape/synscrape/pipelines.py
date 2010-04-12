import cluster_labeling.words as words
import cluster_labeling.word_senses as ws

import scrapy.log as log

class DjangoWriterPipeline(object):
    def process_item(self, spider, item):
        word, word_dne = words.Word.create_if_dne_and_return(item['word'])
        if word_dne: word.save()

        name, name_dne = words.Word.create_if_dne_and_return(item['name'])
        if name_dne: name.save()

        pos = ws.pos_display_to_value[item['pos']]
        
        wordsense = None
        ws_qs = ws.WordSense.get_manager()\
                .filter(word=word, name=name)
        
        if ws_qs.count() == 0:
            wordsense = ws.WordSense(word=word, name=name, pos=pos,
                                     notes=item.get('notes', None))
            wordsense.save()
        else:
            wordsense = ws_qs[0]

        existing_defns, new_defns = \
            words.Word.create_multiple_if_dne_and_return(item['definition'])
        
        for defn in existing_defns:
            wordsense.definition.add(defn)
        for defn in new_defns:
            defn.save()
            wordsense.definition.add(defn)

        existing_synonyms, new_synonyms = \
            words.Word.create_multiple_if_dne_and_return(item['synonyms'])
        
        for synonym in existing_synonyms:
            wordsense.synonyms.add(synonym)
        for synonym in new_synonyms:
            synonym.save()            
            wordsense.synonyms.add(synonym)

        if 'antonyms' in item:
            existing_antonyms, new_antonyms = \
                words.Word.create_multiple_if_dne_and_return(item['antonyms'])
        
            for antonym in existing_antonyms:
                wordsense.antonyms.add(antonym)
            for antonym in new_antonyms:
                antonym.save()
                wordsense.antonyms.add(antonym)

        return item
