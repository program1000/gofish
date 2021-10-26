class Deck

  VALUES=%w[2 3 4 5 6 7 8 9 10 B V H A]

  def initialize
	@cards = []
	@@value_map = {}
	create
  end

  private def create
	VALUES.each{ |v| @@value_map[v] = VALUES.index(v)+1 }
	suits = [:harten,:schoppen,:ruiten,:klaver]
	deck = []
	VALUES.each do |value|
	  suits.each do |suit| 
	    deck << Card.new(value,suit)
	  end
	end
	@cards = deck
  end

  private def shuffle( deck )
    while deck.empty? == false do
	  i = rand(deck.size)
	  @cards << deck.delete_at(i)
	end
	#puts @cards
  end

  def draw
	card=nil
	if @cards.empty? == false then
	  card = @cards.sample
	  @cards.reject!{|c| c==card}
	end
	
	card
  end
  
  def reshuffle( cards )
    cards.each{ |card| @cards << card }
  end
  
  def Deck.value( value ) 
    @@value_map[value]
  end
  
end

class Card 
 include Comparable
 attr_reader :value
 attr_reader :suit
 
  def initialize(value, suit)
    @value = value
	@suit = suit
  end
  
  def <=>(other)
    value = Deck.value(@value)
    otherValue = Deck.value(other.value)
    #puts "this #{value} other #{otherValue}"
    value <=> otherValue
  end
  
  def ==(o)
    self.class == o.class && @value == o.value && @suit == o.suit
  end
  
  def to_s
    "#{@value} #{@suit}"
  end
end

class Player
  attr_reader :id
  attr_reader :books_amount
  
  def initialize( id )
    @name = "Player #{id}"
	@hand = []
	@id = id
	@books = []
	@books_amount = 0
  end
  
  def add_card( card )
    #puts "#{self} #{card}"
    @hand << card unless card.nil?
  end
  
  def add_cards( cards )
	cards.each{ |card|  @hand << card }
  end
  
  def check_book( value )
    has_book = @hand.count{ |c| c.value==value}==4
	if has_book then
	  @hand.reject!{ |c| c.value==value }
	  @books << value
	  @books_amount+=1
	end
	has_book
  end
  
  def empty_hand?
	@hand.empty?
  end
  
  def has_value( value )
    @hand.any?{ |c| c.value==value }
  end
  
  def get_cards( value )
   cards = @hand.select{ |c| c.value==value }
   if cards.empty? == false
     @hand.reject!{ |c| c.value==value }
	else
	 puts "#{self} says: Go fish!"
	end
   cards
  end
  
  def show_hand
    r="#{self} hand: "
    @hand.each{ |c| r << "#{c} "}
	r = "#{r} books: #{@books.sort{ |a, b| Deck.value(a) <=> Deck.value(b) }.join(' ')}" if @books_amount > 0
	puts r
  end
  
  def show_values
    r=[]
	@hand.each{ |c| r << c.value }
	r.uniq.sort{ |a, b| Deck.value(a) <=> Deck.value(b) }.join(' ')
  end
  
  def to_s
    @name
  end
end

class Game
 require 'set'
  def initialize
    @deck = Deck.new
	@players = []
	@sp = 0
	@running = false
	@player_ids = Set.new
	@remaining_books = Set.new(Deck::VALUES)
  end
  
  def init
    puts 'Amount of players (2-5) ?'
	players = gets.to_i
	if players < 2 or players > 5 then
	  puts "Only accepts 2 to 5 players"
	  exit(0)
	end
	players.times { |i| @players<<Player.new(i + 1) }
	@players.each { |p| @player_ids.add(p.id) }
	puts 'Determine dealer'
	dealerRound = {}
	@players.each { |p| dealerRound[@deck.draw]=p }
	dealerRound.each { |c,p| puts "#{p} draws #{c}" }
	dealerCards = dealerRound.keys
	winCard = dealerCards.sort.first
	winPlayer = dealerRound[winCard]
	puts "#{winPlayer} is dealer"
	
	#2/3 players > 7 cards
	#4/5 players > 5 cards
	@deck.reshuffle( dealerCards )
	pi = (@players.index(winPlayer) + 1) % players
	@sp=pi
	
	amountCards = players < 4 ? 7 : 5
	amountCards.times do
	  players.times do
	    @players[pi].add_card(@deck.draw)
		pi = (pi+1) % players
	  end
	end
	
	show_hands( pi )
	@running=true
  end

  def loop
    pi=@sp
	players=@players.size
    while @running
	  turn=true
	  while turn
	    player = @players[pi]
		if player.empty_hand? then
		  puts "#{player} has no cards, draws card"
		  card=@deck.draw
		  player.add_card(card)
		  puts "#{player} #{card}"
    	  if check_book( player, card.value ) then
		    turn = false
		    @running = false
			break
		  end
		end
		if @players.reject{ |p| p==player}.count{ |p| p.empty_hand? }==players-1 then
		  puts "Other players are empty handed"
		end
	    tp,tv = request_card( player )
		op_cards = @players[tp-1].get_cards(tv)
		if op_cards.empty? then
		  turn = false
		  card = @deck.draw
		  player.add_card(card)
		  puts "#{player} #{card}"
		  tv = card.value
		else
		  player.add_cards( op_cards )
		end
    	if check_book( player, tv ) then
		  turn = false
		  @running = false
		end
		if turn==true and player.empty_hand? then
		  puts "#{player} has no cards, skip turn"
		  turn=false
		end
	  end
	  pi = (pi+1) % players
	  if pi==@sp then
	    #one round
		show_hands( pi )
	  end
	  
    end
	win_player = @players.sort_by(&:books_amount).last
	puts "Winner #{win_player} with #{win_player.books_amount} books"
	
  end
  
  private def show_hands( pi )
    players = @players.size
    players.times do
	  @players[pi].show_hand
	  pi = (pi+1) % players
	end
  end
  
  private def request_card( player )
    invalid_input=true
	tp,tv = [nil,nil]
	while invalid_input
	  valid_ids = @player_ids.reject{ |i| i==player.id }
      puts "#{player} : (player value)"
	  inp = gets.chomp
	  if inp=='q' or inp=='e' then
	    exit(0)
	  end
      tp,tv = inp.split(' ')
	  tp = tp.to_i
	  if valid_ids.include?(tp)==false then
	    puts "Invalid target player #{tp}, allowed are #{valid_ids}"
	  elsif player.has_value(tv)==false then
        puts "Player does not have #{tv}, allowed are #{player.show_values}"
	  else
	    invalid_input = false
	  end
	end
	[tp, tv]
  end
  
  private def check_book( player, value )
    if player.check_book( value ) then
      puts "#{player} has book for #{value}"
	  @remaining_books.delete( value )
	  puts "Remaining books: #{@remaining_books}"
	  if @remaining_books.size==0 then
	    return true
	  end
	end
	return false
   end
  
end

g = Game.new
g.init
g.loop
