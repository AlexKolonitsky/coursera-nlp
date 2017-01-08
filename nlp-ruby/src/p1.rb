require 'bigdecimal'

def resFile(fileName)
  File.join(File.dirname(__FILE__), "..", "res-p1", fileName)
end

def calculateCounts(source, target)
  `python ../res-p1/count_freqs.py ../res-p1/#{source} > ../res-p1/#{target}`
  puts "counts in #{target}"
end

def replaceRare(train, counts, rareTrain, pppp)
  file = File.open(resFile(train), "r")
  data = file.read

  File.readlines(resFile(counts)).each do |line|
    res = /(\d+)\s+WORDTAG\s+([\w-]+)\s+([^\s]+)/.match line
    if res
      data = data.gsub(/^#{Regexp.escape(res[3])} #{res[2]}/, (res[1].to_i < pppp ? rareClass(res[3]) : res[3].downcase) + " #{res[2]}")
    end
  end

  rareData = File.open(resFile(rareTrain), "w+")
  rareData.write(data)
  rareData.flush
  rareData.close
end

def readCounts(countsFile)
  counts = Hash.new(0)
  File.readlines(resFile(countsFile)).each do |line|
    res = /(\d+)\s+([\d\w-]+)\s+(.+)/.match line
    counts[res[3]] = res[1].to_f if res
  end

  counts
end

def e(tag, word)
  res = $counts["#{tag} #{word.downcase}"] / $counts[tag]
  if res == 0
    exist = tags.inject(0) { |sum, t| sum + $counts["#{t} #{word.downcase}"] }
    res = $counts["#{tag} #{rareClass(word)}"] / $counts[tag] if exist == 0
    #res = (tag == "I-GENE" ? 0.1 : 0) if exist == 0
    #res = $counts["#{tag} __RARE__"] / $counts[tag]
  end


  if "HBx".eql? word
    puts <<-OUT
      ---------------------------      ---------------------------
      --------------------------- HBx ---------------------------
      ---------------------------      ---------------------------
      $counts["#{tag} #{word.downcase}"] = #{$counts["#{tag} #{word.downcase}"] }
      $counts["#{tag} #{rareClass(word)}"] = #{$counts["#{tag} #{rareClass(word)}"]}
      rareClass(word) = #{rareClass(word)}
      res = #{res}
    OUT
  end

  res
end

def q(w1, w2, w3)
  res = $counts["#{w1} #{w2} #{w3}"] / $counts["#{w1} #{w2}"]
  res *= 3 if "O O I-GENE".eql?("#{w1} #{w2} #{w3}")
  res
end

def p1(word)
  oCount = e("O", word)
  iCount = e("I-GENE", word)

  oCount != 0 && (iCount == 0 || oCount > iCount) ? "O" : "I-GENE"
end

def p1_do (data)
  taggedWords = File.open(resFile("#{data.gsub(/\./, "_")}.p1.out"), "w+")
  File.readlines(resFile(data)).each do |word|
    word = word.strip
    if word.empty?
      taggedWords.write("\n")
    else
      taggedWords.write("#{word} #{p1(word)}\n")
    end
  end
  taggedWords.flush
  taggedWords.close
end


def tags(k = 0)
  return %w(*) if k == -2 || k == -1

  %w(O I-GENE)
end

def p2(words)
  pi = {%w(* *) => {value: 1, path: []}}
  words.each_with_index do |xk, k|
    pi = tags(k-1).product(tags(k)).inject({}) do |res, uv|
      res[uv] = tags(k-2).map { |wi| {
         :value => pi[[wi, uv[0]]][:value] * q(wi, uv[0], uv[1]) * e(uv[1], xk),
         :path => [].concat(pi[[wi, uv[0]]][:path]).concat([wi])
      }}.max_by {|wHash| wHash[:value]}

      res
    end

    # it is hack to use float numbers, without that it become 0
    mult = 10 ** pi.map {|k, p| p[:value] == 0 ? 100 : Math.log10(p[:value]).round.abs }.min
    pi.each {|k, v| v[:value] *= mult }
  end

  uv = tags.product(tags).max_by {|uv| pi[uv][:value] * q(uv[0], uv[1], "STOP")}
  pi[uv][:path].shift
  pi[uv][:path].shift
  words.zip(pi[uv][:path].concat(uv))
end

def p2_do (data)
  words = []
  File.readlines(resFile(data)).each do |word|
    word = word.strip
    words.push(word) unless word.empty?
  end

  words = p2(words)
  wordsIndex = 0
  taggedWords = File.open(resFile("#{data.gsub(/\./, "_")}.p3.out"), "w+")
  File.readlines(resFile(data)).each do |word|
    word = word.strip
    if word.empty?
      taggedWords.write("\n")
    else
      taggedWords.write("#{word} #{words[wordsIndex][1]}\n")
      wordsIndex += 1
    end
  end
  taggedWords.flush
  taggedWords.close
end

#calculateCounts("gene.train", "gene.counts")
#replaceRare("gene.train", "gene.counts", "gene.rare5+.train", 5)
#calculateCounts("gene.rare5+.train", "gene.rare5+.counts")

# <tag> <word>      -> <num>
# <tag>             -> <num>
# <tag> <tag>       -> <num>
# <tag> <tag> <tag> -> <num>
#$counts = readCounts("gene.counts")
$counts = readCounts("gene.rare5+.counts")


#p1_do("gene.dev")
#puts `python ../res-p1/eval_gene_tagger.py ../res-p1/gene.key ../res-p1/gene_dev.p1.out`
#p1_do("gene.test")

p2_do("gene.dev")
puts `python ../res-p1/eval_gene_tagger.py ../res-p1/gene.key ../res-p1/gene_dev.p3.out`
#
#p2_do("gene.test")

#p2_do("gene.dev1")
#puts `python ../res-p1/eval_gene_tagger.py ../res-p1/gene.key ../res-p1/gene_dev1.p2.out`
#p2_do("gene.test")

def rareOutput rareClassName
  puts "     O #{rareClassName} -> #{$counts["O #{rareClassName}"] / $counts["O"]}"
  puts "I-GENE #{rareClassName} -> #{$counts["I-GENE #{rareClassName}"] / $counts["I-GENE"]}"
  puts "#{rareClassName}: O / I-GENE #{rareClassName} -> #{($counts["I-GENE #{rareClassName}"] / $counts["I-GENE"]) / ($counts["O #{rareClassName}"] / $counts["O"])}"
end

rareOutput("__RARE_NUMBERS__")
rareOutput("__RARE_ALPHA_NUMBERS__")
rareOutput("__RARE_CAPITAL__")
rareOutput("__RARE_LAST_CAPITAL__")
rareOutput("__RARE_MIXED_CASE__")
rareOutput("__RARE_ALPHA_NUMBERS2__")
rareOutput("__RARE__")

puts "=> q(O, O, O)      = #{q("O", "O", "O")}"
puts "=> q(O, O, I-GENE) = #{q("O", "O", "I-GENE")}"
puts "=> q(O / I-GENE)   = #{q("O", "O", "O")/q("O", "O", "I-GENE")}"

# Alex.Kolonitsky@gmail.com
# QgfTu4G7vc