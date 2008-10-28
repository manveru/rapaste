#          Copyright (c) 2008 Michael Fellinger m.fellinger@gmail.com
#            This file is subject to the terms of the Ruby license.

# I wrote the filter after reading articles from Paul Graham and trying the
# related ruby library from Lucas Carlson called `classifier`.
# Classifier proved to be a bothersome experience, and caused me some problems
# and issuing warnings on startup.
# But I took the core algorithm, tuned it a bit and for now the filter resides
# in `vendor/bayes.rb`.
# It's pure Ruby, reasonably fast and accurate.
#
# Some design decisions were to limit it to words longer than 4 characters
# (apart from a few exceptions), smaller words tend to skew the results and are
# often not meaningful enough.
# Unknown words have minimal impact on the result.
#
# # Usage
#
# bayes = Bayes.new
# bayes.train :good, "here are some good words. I hope you love them"
# bayes.train :bad, "here are some bad words. I hate you"
# bayes.classify('I love you') # => :good
#
# # Persistence
#
# bayes = Bayes.new('bayes.marshal')
# bayes.train :good, "here are some good words. I hope you love them"
# bayes.train :bad, "here are some bad words. I hate you"
# bayes.classify('I love you') # => :good
# bayes.store
#
# bayes = Bayes.new('bayes.marshal')
# bayes.classify('I love you') # => :good
#
# # Further reading on Bayesian filtering:
#
# * http://www.paulgraham.com/spam.html
# * http://www.process.com/precisemail/bayesian_filtering.htm
# * http://en.wikipedia.org/wiki/Bayesian_filtering
#

class Bayes
  attr_accessor :categories, :filename

  # only get words (and no numbers) with 4 chars or longer
  # we take a few short spammy words into account though.
  WORDS = /sex|buy|ass|ape|gay|hot|[a-zA-Z'!?]{4,}/

  def initialize(filename = nil)
    @filename = filename
    @categories = {}

    restore(filename) if filename and File.file?(filename)
  end

  # Use this if you are curious what words the filter is using for scoring.
  # It's rather easy to override, so feel free to fine-tune for your needs.
  def split(text)
    text.downcase.scan(WORDS).uniq
  end

  # pass the name of the category (like :spam or :ham) and a string containing
  # the text you want to classify.
  # It will answer with the words used for training.
  #
  #   b = Bayes.new
  #   b.train :good, "here are some good words. I hope you love them"
  #   # => ["here", "some", "good", "words", "hope", "love", "them"]

  def train(category, text)
    hash = @categories[category.to_sym] ||= Hash.new(0)
    split(text).each{|word| hash[word] += 1 }
  end

  # Used with care, this method can help reverting mistakes easily without
  # having to retrain the whole filter.
  def untrain(category, text)
    hash = @categories[category.to_sym] ||= Hash.new(0)

    split(text).each do |word|
      if hash[word] - 1 > 0
        hash[word] -= 1
      else
        hash.delete(word)
      end
    end
  end

  # Use this instead of first #classifications and then #classify, it only does
  # the scoring once and is shorter to type :)
  # Answers with the result of classify and classifications hash.
  #
  # Example:
  #
  #   b = Bayes.new
  #   b.train :good, "here are some good words. I hope you love them"
  #   b.train :bad, "here are some bad words. I hate you"
  #   b.classify_info('I love you')
  #   # => [:good, {:good => -1.94, :bad => -3.68}]

  def classify_info(text)
    classification = classifications(text)
    return choose(classification), classification
  end

  # Answers with a hash with the scoring for each category for the given text.
  # The scoring is done per category.
  # First we determine the total number of occurrences of all words in one
  # category, then we take the occurrences of every word passed.
  # If the word isn't in the category hash yet it will still be be used to
  # smooth out the results a bit.
  #
  # Step by step this works like:
  #
  #   b = Bayes.new
  #   b.train :good, "here are some good words. I hope you love them"
  #   b.train :bad, "here are some bad words. I hate you"
  #   b.classifications('I love you') # => {:good => -1.94, :bad => -3.68}

  def classifications(text)
    score = Hash.new(0)

    text_words = split(text)

    @categories.each do |category, words|
      total = words.values.inject(:+)

      next if total == 0

      text_words.each do |word|
        seed = words.fetch(word, 0.1).to_f
        score[category] += Math.log(seed/total)
      end
    end

    return score
  end

  # Simply returns the category that matches best.
  #   b = Bayes.new
  #   b.train :good, "here are some good words. I hope you love them"
  #   b.train :bad, "here are some bad words. I hate you"
  #   b.classify('I love you') # => :good

  def classify(text)
    choose classifications(text)
  end

  # Answers with the name of the category whose value is closest to 0 (zero)
  #
  # Example:
  #   bayes.choose(:spam => -0.5, :ham => -0.4) # => :ham
  def choose(classification)
    sorted = classification.sort_by{|k,v| -v }

    case sorted.size
    when 0
      return classification
    when 1
      return sorted[0][0]
    when 2
      delta_choose(*sorted)
    else
      delta_choose(*sorted.first(2))
    end
  end

  def store(filename = @filename)
    File.open(filename, 'w+') do |io|
      dump = Marshal.dump(@categories)
      io.print(dump)
    end
  end

  def restore(filename)
    @filename = filename
    @categories = Marshal.load(File.read(filename))
  end

  private

  def delta_choose(left, right, delta = 0.0001)
    left_key, left_value = left
    right_key, right_value = right

    if (right_value - left_value).abs <= delta
      return nil
    elsif right_value < left_value
      return left_key
    else
      return right_key
    end
  end
end
