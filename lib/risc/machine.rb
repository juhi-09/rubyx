require_relative "collector"
require_relative "binary_writer"

module Risc
  # The Risc Machine is an abstraction of the register level. This is seperate from the
  # actual assembler level to allow for several cpu architectures.
  # The Instructions (see class Instruction) define what the machine can do (ie load/store/maths)

  # From code, the next step down is Vool, then Mom (in two steps)
  #
  # The next step transforms to the register machine layer, which is quite close to what actually
  #  executes. The step after transforms to Arm, which creates executables.
  #

  class Machine
    include Logging
    log_level :info

    def initialize
      @booted = false
      @constants = []
    end
    attr_reader  :constants , :risc_init , :cpu_init , :binary_init
    attr_reader  :booted , :translated

    # translate to arm, ie instantiate an arm translator and pass it to translate
    #
    # currently we have no machanism to translate to other cpu's (nor such translators)
    # but the mechanism is ready
    def translate_arm
      @translated = true
      translate(Arm::Translator.new)
    end

    # translate the methods to whatever cpu the translator translates to
    def translate( translator )
      methods = Parfait.object_space.collect_methods
      translate_methods( methods , translator )
      @cpu_init = translator.translate( @risc_init )
      @binary_init = Parfait::BinaryCode.new(1)
    end

    def translate_methods(methods , translator)
      methods.each do |method|
        log.debug "Translate method #{method.name}"
        method.translate_cpu(translator)
      end
    end

    # machine keeps a list of all objects. this is lazily created with a collector
    def objects
      @objects ||= Collector.collect_space
    end

    def position_all
      translate_arm unless @translated
      #need the initial jump at 0 and then functions
      cpu_init.set_position( 0 )
      Positioned.set_position(cpu_init.first , 0)
      Positioned.set_position(binary_init,0)
      at = position_objects( binary_init.padded_length )
      # and then everything code
      position_code_from( at )
    end

    def position_objects( at )
      at +=  8 # thats the padding
      # want to have the objects first in the executable
      objects.each do | id , objekt|
        case objekt
        when Parfait::BinaryCode
        when Risc::Label
        else
          Positioned.set_position(objekt,at)
          at += objekt.padded_length
        end
      end
      at
    end

    def position_code_from( at )
      objects.each do |id , method|
        next unless method.is_a? Parfait::TypedMethod
        log.debug "CODE1 #{method.name}:#{at}"
        method.cpu_instructions.set_position( at + 12) # BinaryCode header
        before = at
        nekst = method.binary
        while(nekst)
          Positioned.set_position(nekst , at)
          at += nekst.padded_length
          nekst = nekst.next
          #puts "LENGTH #{len}"
        end
        log.debug "CODE2 #{method.name}:#{at} len: #{at - before}"
      end
      at
    end

    def create_binary
      objects.each do |id , method|
        next unless method.is_a? Parfait::TypedMethod
        #puts "Binary for #{method.name}:#{}"
        writer = BinaryWriter.new(method.binary)
        writer.assemble(method.cpu_instructions)
      end
      BinaryWriter.new(binary_init).assemble(cpu_init)
    end

    def boot
      initialize
      @objects = nil
      @translated = false
      boot_parfait!
      @risc_init = Branch.new( "__initial_branch__" , Parfait.object_space.get_init.risc_instructions )
      @booted = true
      self
    end

  end

  # Module function to retrieve singleton
  def self.machine
    unless defined?(@machine)
      @machine = Machine.new
    end
    @machine
  end

end

require_relative "boot"
