require 'filepaths'
require 'rules'
require 'fields'

module BtxtrLabels
  class ParseError < Exception
    attr_accessor :line

    def initialize(line)
      super()
      @line = line
    end

    def message()
      return @line
    end
  end

  def is_blankline(line)
    return (line =~ /^\s*$/) != nil
  end

  Rule_header_re = /^\s*(\d+(\.\d+)?)\s+Text:([A-Z]+):([a-z_]+):([&A-Za-z0-9_#\(\)\n\.]+)?\s*$/
  def parse_rule_header(line)
    match = line.scan(Rule_header_re)

    if match.size() == 0
      raise ParseError.new(line)
    end

    # Not sure what this number is for. Rule weight?
    junk = match[0][1]

    rule_info = {}

    rule_info['type'] = match[0][3]
    rule_info['fieldname'] = match[0][4]

    if rule_info['type'] == 'SGRAM'
      sgram = match[0][5].strip().sub(/[#\s]/, ' ')
      field = Boosting_fields[$model][rule_info['fieldname']]

      if len(field) == 2 and field[1].is_key('text_to_btxtr_fn')
        rule_info['sgram'] = field[1]['btxtr_to_text_fn'](sgram)
      else
        rule_info['sgram'] = sgram
      end
    end

    return rule_info
  end

  Number_line_re = /^\s*(-?\d+(\.\d+)?)\s+(-?\d+(\.\d+)?)\s*$/
  def parse_number_line(line)
    match = line.scan(Number_line_re)

    if match.size() == 0
      raise ParseError.new(line)
    end

    return [match[0][1].to_f(), match[0][3].to_f()]
  end

  def parse_sgram_rule(fieldname, sgram, fh)
    weights = [[0, 0], [0, 0]]
    rowidx = 0

    while(true)
      line = fh.gets()
      if not line
        raise ParserError.new(line)
      elsif is_blankline(line)
        next
      end

      weights[rowidx] = parse_number_line(line)
      rowidx += 1

      if rowidx == 2
        break
      end
    end

    return BtxtrSGramRule(fieldname, weights, sgram)
  end

  Threshold_re = /^\s*(-?\d+(\.\d+)?)\s*$/
  def parse_threshold_rule(fieldname, fh)
    weights = [[0, 0], [0, 0], [0, 0]]
    threshold = nil

    rowidx = 0

    while(true)
      line = fh.gets()
      if not line
        raise ParseError.new(line)
      elsif is_blankline(line)
        next
      end

      weights[rowidx] = parse_number_line(line)
      rowidx += 1

      if rowidx == 3
        break
      end
    end

    while(true)
      line = fh.gets()
      if not line
        raise ParseError.new(line)
      elsif is_blankline(line)
        next
      end

      match = line.scan(Threshold_re)
      if match.size() == 0
        raise ParseError.new(line)
      end
      threshold = match[0][1].to_f()
      break
    end

    return BtxtrThresholdRule.new(fieldname, weights, threshold)
  end

  def parse_next_rule(fh)
    line = nil

    while(true)
      line = fh.gets()

      if not line
        return nil
      elsif is_blankline(line)
        next
      else
        break
      end
    end

    rule_info = parse_rule_header(line)

    rule = nil

    # Parse the rule!
    if rule_info['type'] = 'THRESHOLD'
      rule = parse_threshold_rule(rule_info['fieldname'], fh)
    elsif rule_info['type'] = 'SGRAM'
      rule = parse_sgram_rule(rule_info['fieldname'], rule_info['sgram'], fh)
    else
      raise ParseError.new(line)
    end

    return rule
  end

  def parse_num_rules(line)
    match = line.scan(/^\s*(\d+)\s*$/)
    if match.size() == 0
      raise ParseError.new(line)
    end

    return match[0][0].to_i()
  end

  def get_rules(cluster)
    filename = get_strong_hypothesis_filename(cluster)
    shyp = File.new(filename, "r")

    line = shyp.gets()
    numrules = parse_num_rules(line)

    rules = []
    while(true)
      rule = parse_next_rule(shyp)

      if rule == nil
        break
      end

      rules.push(rule)
    end

    if rules.size() != numrules
      raise ParseError.new(line)
    end

    return rules
  end
end
