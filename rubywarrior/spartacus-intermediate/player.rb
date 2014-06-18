class Player
  def play_turn(warrior)
    @ticking = listen_for_ticking warrior

    @enemy_directions = detect warrior, :enemy?
    if @ticking.size > 0
      deal_with_ticking warrior
    elsif outnumbered?
      warrior.bind!(@enemy_directions[0])
    elsif @enemy_directions.size == 1
      warrior.attack!(@enemy_directions[0])
    else
      @captive_directions = detect warrior, :captive?

      if warrior.health < 20
        warrior.rest!
      elsif captives?
        warrior.rescue!(@captive_directions[0])
      elsif warrior.listen.size > 0
        look_for_glory warrior
      else
        warrior.walk! warrior.direction_of_stairs
      end
    end
  end

  def listen_for_ticking warrior
    warrior.listen.select { |space| space.ticking? }
  end

  def deal_with_ticking warrior
    ticking_direction = warrior.direction_of(@ticking[0])
    space = warrior.feel(ticking_direction)

    case space
    when space.empty?
      warrior.walk! ticking_direction
    when space.enemy?
      warrior.attack! ticking_direction
    when space.stairs?
      avoid_stairs warrior
    when space.captive?
      warrior.rescue! ticking_direction
    else
      warrior.walk! ticking_direction
    end
  end

  def detect warrior, type
    [:forward,:backward,:left,:right].select { |direction|
      warrior.feel(direction).send(type)
    }
  end

  def look_for_glory warrior
    glory = warrior.listen[0]
    if warrior.feel( warrior.direction_of(glory) ).stairs?
      avoid_stairs warrior
    else
      warrior.walk! warrior.direction_of(glory)
    end
  end

  private

  def outnumbered?
    @enemy_directions.size > 1
  end

  def captives?
    @captive_directions.size > 0
  end

  def avoid_stairs warrior
    empty_spaces = detect warrior, :empty?
    if warrior.feel(empty_spaces[0]).stairs?
      warrior.walk! empty_spaces[1]
    else
      warrior.walk! empty_spaces[0]
    end
  end
end
