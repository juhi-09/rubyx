require_relative "helper"

module RubyX
  module Macro
    class TestObjectGet < MiniTest::Test
      include MacroHelper
      def source
        <<GET
        class Object
          def set_internal_word(at , value)
            X.set_internal_word
          end
        end
GET
      end
      def test_mom_meth
        assert_equal :set_internal_word , compiler.callable.name
      end
      def test_instr_len
        assert_equal 7 , compiler.mom_instructions.length
      end
      def test_instr_get
        assert_equal Mom::SetInternalWord , compiler.mom_instructions.next.class
      end
      def test_risc
        assert_equal 19 , compiler.to_risc.risc_instructions.length
      end
    end
  end
end