
require 'ruby-prof'
require 'json'
require File.join(File.dirname(__FILE__), "common.rb")

def resFile(fileName)
  File.join(File.dirname(__FILE__), "..", "res-p2", fileName)
end

def calculateCounts(name)
  print "counting... - #{name} "
  `python ../res-p2/count_cfg_freq.py ../res-p2/#{name}.dat > ../res-p2/#{name}.count`
  puts "done."
end

def readCounts(countsFile)
  counts = {
      "NONTERMINAL" => Hash.new(0),
      "BINARYRULE" => Hash.new(0),
      "UNARYRULE" => Hash.new(0)
  }

  File.readlines(resFile(countsFile)).each do |line|
    res = /(\d+)\s+([\d\w-]+)\s+(.+)/.match line
    counts[res[2]][res[3]] = res[1].to_f
  end

  counts
end

def replaceRare(name)
  words = Hash.new(0)
  readCounts("#{name}.count")["UNARYRULE"].each do |w, count|
    words[w.split(" ")[1]] += count
  end
  words.keep_if { |k, v| v < 5 }
  puts words

  File.open(resFile("#{name}.rare.dat"), "w+") do |result|
    File.readlines(resFile("#{name}.dat")).each do |line|
      result.puts replaceRareInTree(words, JSON.parse(line)).to_s
    end
  end
end

def replaceRareInTree(rareWords, tree)
  trees = [tree]
  until trees.empty?
    current = trees.shift
    if current.size == 3
      trees.push(current[1], current[2])
    elsif current.size == 2
      current[1] = "_RARE_" if rareWords[current[1]] > 0
    else
      puts "MISTAKE !!!!!!!!!!!"
    end
  end

  tree
end

# { word -> [[X, count]...] }
$UNARY = Hash.new(nil)

# { X -> [[X, Y, Z, count]...] }
$BINARY = Hash.new(nil)

def init(countsFile)
  counts = readCounts("#{countsFile}.count")

  # { X -> count}
  $NONTERMINALS = counts["NONTERMINAL"]

  counts["UNARYRULE"].each do |k, count|
    rule = k.split(" ")
    $UNARY[rule[1]] = ($UNARY[rule[1]] || []).push([rule[0], count/$NONTERMINALS[rule[0]]])
  end

  counts["BINARYRULE"].each do |k, count|
    rule = k.split(" ")
    $BINARY[rule[0]] = ($BINARY[rule[0]] || []).push([rule[0], rule[1], rule[2], count/$NONTERMINALS[rule[0]]])
  end

  $NONTERMINALS = $NONTERMINALS.keys
end

class Leaf
  def initialize(value, x, word)
    @value, @x, @word = value, x, word
  end
  
  def value
    @value
  end

  def to_s
    "[\"#{@x}\", \"#{@word}\"]"
  end

end

class Node
  def initialize(value, x, y, z)
    @value, @x, @y, @z = value, x, y, z
  end

  def value
    @value
  end

  def to_s
    "[\"#{@x}\", #{@y}, #{@z}]"
  end

end

def set_pi(pi, i, j, x, value)
  pi[x] = {} if pi[x] == 0
  pi[x][i] = {} if pi[x][i].nil?

  pi[x][i][j] = value
end

def get_pi(pi, i, j, x)
  pi[x] && pi[x][i] && pi[x][i][j] || 0
end

def get_pix(pi, i, j, x)
  pi[x][i] && pi[x][i][j] || 0
end

def sentenceToTree(words)
  n = words.size
  words = words.unshift(nil)

  pi = Hash.new(0)
  words.each_with_index do |word, i|
    next if word.nil?
    ($UNARY[word] || $UNARY["_RARE_"] || []).each do |rule|
      set_pi(pi, i, i, rule[0], Leaf.new(rule[1], rule[0], word))
    end
  end

  1.upto(n-1) do |l|
    1.upto(n-l).each do |i|
      j = i + l

      $BINARY.each do |x, rules|
        max = Node.new(-1, nil, nil, nil)
        rules.each do |rule| # [X, Y, Z, count]
          piy = pi[rule[1]]
          next if piy == 0 || piy[i].nil?

          piy[i].each do |s, pi1|
            if (pi2 = get_pi(pi, s + 1, j, rule[2])) != 0 && (val = rule[3] * pi1.value * pi2.value) > max.value
              max = Node.new(val, x, pi1, pi2)
            end
          end
        end

        set_pi(pi, i, j, x, max) if max.value > 0
      end
      #puts "#{pi}"
    end
  end

  [get_pi(pi, 1, n, "SBARQ"), get_pi(pi, 1, n, "S")].max_by {|pi| pi != nil && pi.value}
end

#calculateCounts("parse_train.dat", "parse_train.count")
#puts replaceRareInTree({"?" => 3}, ["SBARQ", ["WHNP+PRON", "What"], ["SBARQ", ["SQ", ["VERB", "are"], ["NP+NOUN", "polymers"]], [".", "?"]]]).to_s

#replaceRare("parse_train_vert")
#calculateCounts("parse_train_vert.rare")

#$UNARY.each {|k, v| puts "#{k} -> #{v}"}
#puts readCounts("parse_train.rare.count")["BINARYRULE"]
#puts sentenceToTree("What was the monetary value of the Nobel Peace Prize in 1989 ?".split(" ")).to_s

def p2(data, output)
  init("parse_train_vert.rare")
  #puts $NONTERMINALS.size
  #puts $UNARY.size
  #puts $BINARY.size
  #File.open(resFile(output), "w+") do |result|
  #  File.readlines(resFile(data)).each do |line|
  #    result.puts sentenceToTree(line.split(" ")).to_s
  #    puts "DONE #{line}"
  #  end
  #end
  #
  #RubyProf.start
  #puts sentenceToTree("What was the monetary value of the Nobel Peace Prize in 1989 ?".split(" "))
  #puts sentenceToTree("Where did the 6th annual meeting of Indonesia-Malaysia forest experts take place ?".split(" "))
  #puts sentenceToTree("What Nobel laureate was expelled from the Philippines before the conference on East Timor ?".split(" "))
  #
  #result = RubyProf.stop
  #printer = RubyProf::GraphHtmlPrinter.new(result)
  #printer.print(File.open("performance03.html", "w+"))

  puts `python ../res-p2/eval_parser.py ../res-p2/parse_dev.key ../res-p2/parse_dev.out`
end

p2("parse_dev.key", "parse_dev.out")
#p2("parse_test.dat", "parse_test.p3.out")


