require_relative '../../soml/helper'

# Benchmarks for the stuff in results.md

module BenchTests

  include RuntimeTests

  def setup
    @stdout =  ""
    @machine = Register.machine.boot
    Soml::Compiler.load_parfait
  end

  def main
runko = <<HERE
class Object
  int main()
    PROGRAM
  end
end
HERE
  runko.sub("PROGRAM" , @main )
  end

  def check_remote val
    check_r val , true
  end

  def connected
    make_box
  end
end