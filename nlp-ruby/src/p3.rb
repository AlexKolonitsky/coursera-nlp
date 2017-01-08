

def resFile(fileName)
  File.join(File.dirname(__FILE__), "..", "res-p3", fileName)
end

class Sentence
  attr_reader :index, :english, :french, :alignments

  def initialize (index, english, french, alignments)
    @index, @english, @french, @alignments = index, ["NULL"].concat(english), french, alignments
  end
end

class Counts
  attr_reader :english, :count, :frenchWords

  def initialize(english)
    @english, @count, @frenchWords = english, 0.0, Hash.new(0.0)
  end

  def inc(frenchWord, more)
    @count += more
    @frenchWords[frenchWord] += more
  end

end

def readData(englishFile, frenchFile)
  index = 1
  englishSentences = File.open(resFile(englishFile))
  frenchSentences = File.open(resFile(frenchFile))

  while (eSentence = englishSentences.gets)
    s = Sentence.new(index, eSentence.split(' '), frenchSentences.gets.split(' '), [])
    if !s.english.empty? && !s.french.empty?
      yield s
    end

    index += 1
  end

  englishSentences.close()
  frenchSentences.close()
end

def trainInit(en, es)
  eDic = Hash.new {|h, k| h[k] = []}
  eMax, fMax = 0, 0

  readData(en, es) do |sentence|
    sentence.english.each do |eWord|
      eDic[eWord].concat(sentence.french)
    end

    eMax = sentence.english.size if sentence.english.size > eMax
    fMax = sentence.french.size if sentence.french.size > fMax
  end
  eDic.each{ |k,words| eDic[k] = words.uniq.size }

  File.open(resFile("eDic"), "w+") do |result|
    result.puts <<-RUBY
      # encoding: utf-8

      eMaxSize = #{eMax}
      fMaxSize = #{fMax}

      eDic = #{eDic}
    RUBY
  end
end

def trainInitLoad
  load(resFile("eDic"))
  eDic
end

def train (en, es, res)

  eDic = trainInitLoad
  t = Hash.new { |h, k| h[k] = Hash.new(1.0/eDic[k]) }

  5.times do |i|
    cEnglish = Hash.new {|h, k| h[k] = Counts.new(k)}
    puts "stady #{i} #{Time.now}"

    readData(en, es) do |sentence|
      puts "sentence #{sentence.index}"
      sentence.french.each do |fWord|
        sentence.english.each do |eWord|
          more = t[eWord][fWord] / sentence.english.inject(0) { |sum, eWord| sum + t[eWord][fWord]}
          cEnglish[eWord].inc(fWord, more)
        end
      end
    end

    cEnglish.each do |eWord, cEng|
      cEng.frenchWords.each do |fWord, value|
        t[eWord][fWord] = value / cEng.count
      end
    end
  end

  File.open(resFile(res), "w+") do |result|
    t.each do |eWord, fList|
      fList.each do |fWord, value|
        result.puts "#{fWord} #{eWord} #{value}"
      end
    end
  end
end

def train2 (en, es, prev, res)

  t = Hash.new { |h, k| h[k] = Hash.new(0.0) }
  File.readlines(resFile(prev)).each do |line|
    ll = line.split(' ')
    t[ll[0]][ll[1]] = ll[2].to_f
  end

  # q[[l, m]][[i, j]]
  # q[[eSentSize, fSentSize]][[eWordIndex, fWordIndex]]
  q = Hash.new do |h, k|
    if k.kind_of? Array
      puts "#{k}"
      h[k] = Hash.new(1.0/(k[0] + 1))
    else
      h[k] = 0
    end
  end

  5.times do |i|
    cEnglish = Hash.new {|h, k| h[k] = Counts.new(k)}
    cQ = Hash.new do |h, k|
      h[k] = (k.kind_of? Array) ? Hash.new(0) : 0
    end

    puts "stady #{i} #{Time.now}"

    readData(en, es) do |sentence|
      puts "sentence #{sentence.index}"
      sizes = [sentence.english.size, sentence.french.size]
      qq = q[sizes]
      cQQ = cQ[sizes]
      sentence.french.each_with_index do |fWord, fWordIndex|
        sentence.english.each_with_index do |eWord, eWordIndex|
          sum = 0
          sentence.english.each_with_index { |eWord, eWordIndex| sum += qq[[eWordIndex, fWordIndex]]*t[eWord][fWord]}
          more = (qq[[eWordIndex, fWordIndex]] * t[eWord][fWord]) / sum


          cEnglish[eWord].inc(fWord, more)
          cQQ[[eWordIndex, fWordIndex]] += more
          cQQ[eWordIndex] += more
        end
      end
    end

    cEnglish.each do |eWord, cEng|
      cEng.frenchWords.each do |fWord, value|
        t[eWord][fWord] = value / cEng.count
      end
    end

    cQ.each do |sizes, values|
      values.select {|a| a.kind_of? Array}.each do |indexes, value|
        q[sizes][indexes] = value / values[indexes[0]]
      end
    end

    File.open(resFile(res), "w+") do |result|
      result.puts "t = #{t}"
    end

    File.open(resFile("#{res}.q"), "w+") do |result|
      result.puts "q = #{q}"
    end
  end
end

def p3(englishFile, frenchFile, res1, results)
  englishSentences = File.open(resFile(englishFile))
  frenchSentences = File.open(resFile(frenchFile))

  t = Hash.new { |h, k| h[k] = Hash.new(0.0) }
  File.readlines(resFile(res1)).each do |line|
    ll = line.split(' ')
    t[ll[0]][ll[1]] = ll[2].to_f
  end

  File.open(resFile(results), "w+") do |result|
    index = 1

    while (eSentence = englishSentences.gets)
      eSentence = ["NULL"].concat(eSentence.split(' '))
      fSentence = frenchSentences.gets.split(' ')

      fSentence.each_with_index do |fWord, fIndex|
        eIndex = eSentence.index(eSentence.max_by { |eWord| t[fWord][eWord] })

        result.puts "#{index} #{eIndex} #{fIndex+1}"
      end
      index += 1
    end
  end

  englishSentences.close()
  frenchSentences.close()
end

def p32(englishFile, frenchFile, res1, results)

  t = nil
  load(resFile(res1))

  q = nil
  load(resFile("#{res1}.q"))

  File.open(resFile(results), "w+") do |result|
    readData(englishFile, frenchFile) do |sentence|
      eSentence = sentence.english
      fSentence = sentence.french

      qq = q[[eSentence.size, fSentence.size]]
      fSentence.each_with_index do |fWord, fIndex|
        max = -1
        a = 0
        eSentence.each_with_index do |eWord, eIndex|
          value = qq[[eIndex, fIndex]] * t[fWord][eWord]
          if value > max
            max, a = value, eIndex
          end
        end

        result.puts "#{sentence.index} #{a} #{fIndex+1}"
      end
    end
  end
end

trainInit("corpus.en", "corpus.es")
#train("corpus.en", "corpus.es", "corpus-en-es.params")
#p3("dev.en", "dev.es", "corpus-en-es.params", "alignment_dev.p1.out")
#p3("test.en", "test.es", "corpus-en-es.params", "alignment_test.p1.out")

#train2("dev.en", "dev.es", "dev-en-es.params", "dev-en-es2.params")
#p32("dev.en", "dev.es", "dev-en-es.params", "alignment_dev.p2.out")
#p32("test.en", "test.es", "dev-en-es2.params", "alignment_test.p2.out")

