# encoding: UTF-8

#class Float
#
#  def to_s
#    sprintf('%.4f', self)
#  end
#
#end

class HashArray < Hash

  def to_s
    self.values.to_s
  end

end

def resFile(fileName)
  File.join(File.dirname(__FILE__), "..", "res-p3", fileName)
end

class Sentence
  attr_reader :index, :english, :french

  def initialize (index, english, french)
    @index, @english, @french = index, ["NULL"].concat(english), french
    @delta = Array.new(@french.size) { Array.new(@english.size + 1) }
  end

  def calculateDeltaTable(q, t)
    qLM = q[@english.size][@french.size]
    @french.each_with_index do |fWord, fIndex|
      qLMI = qLM[fIndex]
      tF   = t[fWord]
      sum  = 0

      @english.each_with_index do |eWord, eIndex|
        d = qLMI[eIndex] * tF[eWord]
        @delta[fIndex][eIndex] = d
        sum += d
      end

      @delta[fIndex][@english.size] = sum
    end
  end

  def delta(fIndex, eIndex)
    @delta[fIndex][eIndex] / @delta[fIndex][@english.size]
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
    s = Sentence.new(index, eSentence.split(' '), frenchSentences.gets.split(' '))
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

  File.open(resFile("eDic.rb"), "w+") do |result|
    result.puts <<-RUBY
      # encoding: utf-8

      $eMaxSize = #{eMax}
      $fMaxSize = #{fMax}

      $eDic = #{eDic}
    RUBY
  end
end

def trainSave(res, t, q)
  puts "stady saving..."
  File.open(resFile("t.#{res}"), "w+:UTF-8") do |result|
    result.puts "# encoding: utf-8"
    result.puts "$t = Hash.new { |h, l| h[l] = Hash.new(0) }"

    t.each do |fWord, eWords|
      result.puts "$t['#{fWord}'] = #{eWords}"
    end
  end
  puts "stady T saving DONE #{Time.now}"

  File.open(resFile("q.#{res}"), "w+:UTF-8") do |result|
    result.puts "# encoding: utf-8"
    result.puts "$q = []"

    q.each do |eSize, cL|
      result.puts "$q[#{eSize}] = #{cL}"
    end
  end
  puts "stady Q saving DONE #{Time.now}"
end

def train (en, es, prev)

  t = Hash.new { |h, k| h[k] = Hash.new(0.0) }
  File.readlines(resFile(prev)).each do |line|
    ll = line.split(' ')
    t[ll[0]][ll[1]] = ll[2].to_f
  end

  # $eMaxSize, $fMaxSize , $eDic
  require(resFile("eDic.rb"))

  # q[l][m]][i][j]
  # q[eSentSize][fSentSize][eWordIndex][fWordIndex]
  puts "stady m -1"
  q = HashArray.new { |h, l| h[l] =
        HashArray.new { |h, m| h[m] =
          HashArray.new { |h, i| h[i] =
            HashArray.new { |h, j| h[j] = 1.0/(l + 1) }}}}
  puts "stady m -2 #{q}"

  5.times do |i|
    cEnglish = Hash.new {|h, k| h[k] = Counts.new(k)}
    c = Hash.new { |h, l| h[l] =
          Hash.new { |h, m| h[m] =
            Hash.new { |h, i| h[i] = Hash.new(0) }}}

    puts "stady #{i} #{Time.now}"

    readData(en, es) do |sentence|
      sentence.calculateDeltaTable(q, t)

      eSize = sentence.english.size
      fSize = sentence.french.size
      cLM = c[eSize][fSize]
      sentence.french.each_with_index do |fWord, fWordIndex|
        sentence.english.each_with_index do |eWord, eWordIndex|
          d = sentence.delta(fWordIndex, eWordIndex)

          cEnglish[eWord].inc(fWord, d)
          cLM[fWordIndex][eWordIndex] += d
          cLM[fWordIndex]["__!__"]    += d
        end
      end
    end

    cEnglish.each do |eWord, cEng|
      cEng.frenchWords.each do |fWord, value|
        t[fWord][eWord] = value / cEng.count
      end
    end

    c.each do |eSize, cL|
      cL.each do |fSize, cLM|
        cLM.each do |fInd, cLMI|
          cLMI.each do |eInd, cLMIJ|
            q[eSize][fSize][fInd][eInd] = cLMIJ / cLMI["__!__"] unless "__!__".eql?(eInd)
          end
        end
      end
    end
  end

  return t, q
end

def loadTrainy
  puts "#{Time.now} loading...!"
  require(resFile("t.#{res}"))
  puts "#{Time.now} data loaded - T"
  require(resFile("q.#{res}"))
  puts "#{Time.now} data loaded - Q"

  return $t, $q
end

def p3(englishFile, frenchFile, t, q, results)

  puts "translate #{Time.now}"
  File.open(resFile(results), "w+") do |result|
    readData(englishFile, frenchFile) do |sentence|
      eSentence = sentence.english
      fSentence = sentence.french

      qLM = q[eSentence.size][fSentence.size]
      fSentence.each_with_index do |fWord, fIndex|
        max, a, qLMI, tF = -1, 0, qLM[fIndex], t[fWord]
        #next if tF.nil? || qLMI.nil?

        eSentence.each_with_index do |eWord, eIndex|
          next if qLMI[eIndex].nil? || tF[eWord].nil?
          value = qLMI[eIndex] * tF[eWord]

          if value > max
            max, a = value, eIndex
          end
        end

        result.puts "#{sentence.index} #{a} #{fIndex+1}"
      end
    end
  end
  puts "translate #{Time.now} DONE"
end

#trainInit("dev.en", "dev.es")
#train("dev.en", "dev.es", "dev-en-es.params", "dev-en-es2.rb")
#train("corpus.en", "corpus.es", "corpus-en-es.params")

#trainInit("corpus.en", "corpus.es")
#trainSave("corpus-en-es2.rb", t, q)
#t, q = loadTrainy()
#p3("dev.en", "dev.es", *train("corpus.en", "corpus.es", "corpus-en-es.params"), "alignment_dev.p2.out")
p3("test.en", "test.es", *train("corpus.en", "corpus.es", "corpus-en-es.params"), "alignment_test.p2.out")