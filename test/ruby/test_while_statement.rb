require_relative 'helper'

module Ruby
  class TestWhileStatement < MiniTest::Test
    include RubyTests

    def basic_while
      "while(10 < 12) ; true ; end"
    end
    def test_while_basic
      lst = compile( basic_while )
      assert_equal WhileStatement , lst.class
    end
    def test_while_basic_cond
      lst = compile( basic_while )
      assert_equal ScopeStatement , lst.condition.class
    end
    def test_while_basic_branches
      lst = compile( basic_while )
      assert_equal TrueConstant , lst.body.class
    end
    def reverse_while
      "true while(false)"
    end
    def test_while_reverse_branches
      lst = compile( reverse_while )
      assert_equal WhileStatement , lst.class
    end
    def test_while_reverse_cond
      lst = compile( reverse_while )
      assert_equal ScopeStatement , lst.condition.class
    end
    def test_while_reverse_branches
      lst = compile( reverse_while )
      assert_equal TrueConstant , lst.body.class
    end

  end
end
