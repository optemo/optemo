
module PrinterConstants
  $model = Printer
  $scrapedmodel = ScrapedPrinter
  $brands = $printer_brands
  $series = $printer_series
  $descriptors = [/\smfp\s/i, /\smultifunct?ion\s/i, /\sduplex\s/i, /\sfaxcent(er|re)\s/i, \
    /\sworkcent(re|er)\s/i, /\smono\s/i, /\slaser\s/i, /\sdig(ital)?\s/i, /\scolou?r\s/i,\
    /\sb(lack\sand\s)?w(hite)?/i, /\snetwork\s/i, /\sall\s?-?\s?in\s?-?\s?one\s/i, /\sink\s/i,\
    /\schrome\s/i, /\stabloid\s/i, /\saio\sint\s/i, /\s\d+\s?x\s?\d+\s?(dpi)?\s/i, \
    /\sfast\s/i, /\sethernet\s/i, /\sled\s/i, /\d+\s?ppm/i]
end