class Hangman
  Letters = ('a'..'z').to_a

  def filter_words(words, pattern, used_letters)
    char_class = if used_letters.empty?
                   '.'
                 else
                   '[^'+used_letters.join+']'
                 end
    regexp = Regexp.new('^'+pattern.gsub('_',char_class)+'$')
    words.grep regexp
  end

  def get_options(words, pattern, guess)
    options = {}
    words.each do |word|
      p = pattern.dup
      word.length.times do |i|
        if word[i] == guess
          p[i] = guess
        end
      end
      options[p] ||= 0
      options[p] += 1
    end
    options
  end

  def best_option(options)
    options.max_by { |pattern, word_count| word_count }[0]
  end

  def load_words
    File.open('/usr/share/dict/words').map(&:strip).grep %r(^[a-z]+$)
  end

  def initialize
    @words = load_words
    nil
  end

  def game
    pattern = '________'
    used_letters = []
    while(pattern =~ /_/) do
      @words = filter_words(@words, pattern, used_letters)

      puts "#{pattern} (used: #{used_letters.sort.join})"
      #puts "words: #{@words.size}"

      unused_letters = Letters - used_letters

      while true
        print 'Your guess? '
        guess = gets.strip

        if guess == ''
          guess = make_guess(@words, pattern, used_letters)
          puts "Guessed #{guess}"
        end

        break if unused_letters.include?(guess)
      end

      used_letters << guess
      options = get_options(@words, pattern, guess)
      pattern = best_option(options)
    end

    puts "#{pattern} - you got it!"
  end

  def make_guess(words, pattern, used_letters)
    unused_letters = Letters - used_letters

    guesses = {}
    unused_letters.each do |guess|
      options = get_options(words, pattern, guess)
      opponent_option = best_option(options)
      guesses[guess] = options[opponent_option]
    end

    guesses.min_by { |k, v| v }.first
  end
end
