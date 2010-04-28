import re

def species_to_btxtr(text):
    return re.sub('\s+', '_', re.split('\*', text)[0].strip())

def feature_to_btxtr(text):
    return \
        " ".join(map(lambda s: re.sub('\s+', '_',
                             re.sub('\&amp;', '&', s.strip())),
                     re.split('\*', text)))

def colorrange_to_btxtr(text):
    return re.sub('\/', '_', text.strip())

def finish_to_btxtr(text):
    return re.sub('\s|-', '_', text.strip())

def warranty_to_btxtr(text):
    return re.sub('\s+', '_', text.strip())

def flooring_field_from_btxtr(text):
    return re.sub('_', ' ', text)
