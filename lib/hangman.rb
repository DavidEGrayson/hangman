Letters = ('a'..'z').to_a
Dictionary = File.open('/usr/share/dict/words').map(&:strip).grep %r(^[a-z]+$)

class HangmanState
  attr_accessor :words, :pattern, :used_letters

  def done?
    !pattern.include?('_')
  end

  def unused_letters
    Letters - used_letters
  end
end

def filter_words(words, pattern, used_letters)
  char_class = if used_letters.empty?
                 '.'
               else
                 '[^'+used_letters.join+']'
               end
  regexp = Regexp.new('^' + pattern.gsub('_', char_class) + '$')
  words.grep regexp
end

def make_state(pattern, used_letters)
  state = HangmanState.new
  state.words = filter_words(Dictionary, pattern, used_letters)
  state.pattern = pattern
  state.used_letters = used_letters
  state
end

def initial_state(word_size)
  used_letters = []
  pattern = '_' * word_size
  make_state(pattern, used_letters)
end

def generate_pattern(word, pattern, guess)
  pattern = pattern.dup
  word.length.times do |i|
    if word[i] == guess
      pattern[i] = guess
    end
  end
  pattern
end

def possible_responses(state, guess)
  new_used_letters = state.used_letters + [guess]

  options = {}
  state.words.each do |word|
    pattern = generate_pattern(word, state.pattern, guess)
    options[pattern] ||= []
    options[pattern] << word
  end

  options.map do |pattern, words|
    new_state = HangmanState.new
    new_state.words = words
    new_state.pattern = pattern
    new_state.used_letters = new_used_letters
    new_state
  end
end


def prompt_for_guess(state)
  while true
    print 'Your guess? '
    guess = gets.strip

    if guess == ''
      guess = choose_guess(state)
      puts "Guessed #{guess}"
    end

    return guess if state.unused_letters.include?(guess)
  end
end

def interactive_game
  state = initial_state(8)
  until state.done?
    puts "#{state.pattern} (used: #{state.used_letters.join})"
    guess = prompt_for_guess(state)
    state = choose_response(state, guess)
  end
  puts "#{state.pattern} - you got it!"
end

def choose_response(state, guess)
  responses = possible_responses(state, guess)
  responses.max_by { |s| s.words.size }
end

def choose_guess(state)
  choose_guess_core(state, 99)[0]
end

# Returns the guess we should make, and the number of
# incorrect guesses before victory (including the returned one).
# Returns nil if we cannot find any guesses with *fewer* incorrect guesses
# than the budget.
def choose_guess_core(state, incorrect_guess_budget)
  best_guess = nil
  best_incorrect_guess_count = nil

  state.unused_letters.each do |guess|
    incorrect_guess_count = 0

    new_state = choose_response(state, guess)

    if new_state.pattern == state.pattern
      incorrect_guess_count += 1

      if new_state.words.size == state.words.size
        # This guess has no value.
        next
      end
    end

    next if incorrect_guess_count > incorrect_guess_budget

    if new_state.done?
      puts "!#{new_state.pattern} #{new_state.used_letters.join}"
    else
      new_budget = incorrect_guess_budget - incorrect_guess_count
      r = choose_guess_core(new_state, new_budget)
      next if !r
      incorrect_guess_count += r[1]
    end

    next if incorrect_guess_count > incorrect_guess_budget

    best_guess = guess
    best_incorrect_guess_count = incorrect_guess_count

    puts "-#{state.pattern} #{state.used_letters.join} #{guess} => " \
      "#{incorrect_guess_count}"

    if best_incorrect_guess_count == 0
      # Can't do better than this guess.
      break
    end

    incorrect_guess_budget = incorrect_guess_count - 1
  end

  [best_guess, best_incorrect_guess_count] if best_guess
end
