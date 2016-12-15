require 'test_helper'

class GameTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end

  test "Game.possible_to_match_all?" do
      assert_not Game.possible_to_match_all?([10,5,3])
      assert Game.possible_to_match_all?([10,5,5])
      assert_not Game.possible_to_match_all?([10])
  end

  test "Game.assign_targets 2 players" do
      g = Game.create
      t1 = Team.create(game_id: g.id, name: "A")
      t2 = Team.create(game_id: g.id, name: "B")

      p1 = Player.create(name: "Bill", team_id: t1.id)
      p2 = Player.create(name: "Bob", team_id: t2.id)

      g.assign_targets

      p1.reload
      p2.reload

      assert p1.target_id == p2.id
      assert p2.target_id == p1.id
  end

end
