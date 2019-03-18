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

      puts "#{pattern} (used: #{used_letters.join})"
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
    # greg_guess(words, used_letters)

    make_guess_core(words, pattern, used_letters, 99)[0]
  end

  def greg_guess(words, used_letters)
    letter_freq = {}
    words.each do |word|
      word.each_char do |letter|
        letter_freq[letter] ||= 0
        letter_freq[letter] += 1
      end
    end

    used_letters.each do |letter|
      letter_freq.delete(letter)
    end

    p letter_freq

    letter_freq.max_by { |k, v| v }.first
  end

  # Returns the guess we should make, and the number of
  # incorrect guesses before victory (including the returned one).
  # Returns nil if we cannot find any guesses with *fewer* incorrect guesses
  # than the budget.
  def make_guess_core(words, pattern, used_letters, incorrect_guess_budget)
    unused_letters = Letters.reverse - used_letters

    best_guess = nil
    best_incorrect_guess_count = nil

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
          next
        end
      end

      next if incorrect_guess_count > incorrect_guess_budget

      if opponent_choice.include?('_')
        r = make_guess_core(remaining_words,
          opponent_choice,
          used_letters + [guess],
          incorrect_guess_budget - incorrect_guess_count)
        next if !r
        incorrect_guess_count += r[1]
      else
        puts "!#{opponent_choice} #{used_letters.join}#{guess}"
      end

      next if incorrect_guess_count > incorrect_guess_budget

      best_guess = guess
      best_incorrect_guess_count = incorrect_guess_count

      puts "-#{pattern} #{used_letters.join} #{guess} => #{incorrect_guess_count}"

      if best_incorrect_guess_count == 0
        # Can't do better than this guess.
        break
      end

      incorrect_guess_budget = incorrect_guess_count - 1
    end

    [best_guess, best_incorrect_guess_count] if best_guess
  end
end
