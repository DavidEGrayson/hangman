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

  def generate_pattern(word, pattern, guess)
    p = pattern.dup
    word.length.times do |i|
      if word[i] == guess
        p[i] = guess
      end
    end
    p
  end

  def get_options(words, pattern, guess)
    options = {}
    words.each do |word|
      p = generate_pattern(word, pattern, guess)
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
    make_guess_core(words, pattern, used_letters)[0]
  end

  # Returns the guess we should make, and the number of
  # incorrect guesses remaining before victory.
  def make_guess_core(words, pattern, used_letters)
    unused_letters = Letters - used_letters

    guesses = {}
    unused_letters.each do |guess|
      incorrect_guess_count = 0

      options = {}
      words.each do |word|
        p = generate_pattern(word, pattern, guess)
        options[p] ||= []
        options[p] << word
      end
      opponent_choice, remaining_words = options.max_by { |k, v| v.size }

      if opponent_choice == pattern
        incorrect_guess_count += 1

        if remaining_words.size == words.size
          # This guess has no value.
          #puts "Bad guess: #{pattern} #{guess} #{words.size}"
          next
        end
      end

      if opponent_choice.include?('_')
        r = make_guess_core(remaining_words, opponent_choice, used_letters + [guess])
        incorrect_guess_count += r[1]
      end

      guesses[guess] = incorrect_guess_count

      puts "-#{used_letters.join} #{guess} => #{incorrect_guess_count}"

      if incorrect_guess_count == 0
        # Can't do better than this guess.
        break
      end
    end

    guesses.min_by { |k, v| v } or raise "All guesses are bad #{pattern} #{used_letters.join}"
  end
end
