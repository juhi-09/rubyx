require_relative "stream_writer"
require_relative 'object_file'
require_relative 'symbol_table_section'
require_relative 'text_section'
require_relative 'string_table_section'

module Elf

  class ObjectWriter
    def initialize( linker )
      @linker = linker
      target = Elf::Constants::TARGET_ARM
      @object = Elf::ObjectFile.new(target)
      sym_strtab = Elf::StringTableSection.new(".strtab")
      @object.add_section sym_strtab
      @symbol_table = Elf::SymbolTableSection.new(".symtab", sym_strtab)
      @object.add_section @symbol_table

      @text = Elf::TextSection.new(".text")
      @object.add_section @text

      assembler = Risc::TextWriter.new(@linker)
      set_text assembler.write_as_string

      # for debug add labels for labels
      @linker.assemblers.each do |asm|
        meth = asm.callable
        asm.instructions.each do |label|
          next unless label.is_a?(Risc::Label)
          add_symbol "#{meth.self_type.name}@#{meth.name}:Label=#{label.name}" , Risc::Position.get(label).at
        end
        meth.binary.each_block do |code|
          label = "BinaryCode@#{meth.name}"
          add_symbol label , Risc::Position.get(code).at
        end
      end

      @linker.object_positions.each do |slot , position|
        next if slot.is_a?(Parfait::BinaryCode)
        next if slot.class.name.include?("Arm")
        if( slot.respond_to? :rxf_reference_name )
          label = "#{slot.rxf_reference_name}"
        else
          label = "#{slot.class.name}::#{Risc::Position.get(slot)}"
        end
        label += "=#{slot}" if slot.is_a?(Symbol) or slot.is_a?(String)
        add_symbol label , Risc::Position.get(slot).at
      end
    end

    attr_reader :text

    def set_text(text)
      @text.text = text
      add_symbol "_start", 0
    end

    def add_symbol(name, offset, linkage = Elf::Constants::STB_GLOBAL)
      return add_symbol( name + "_" , offset ) if @symbol_table.has_name(name)
      @symbol_table.add_func_symbol name, offset, @text, linkage
    end

    def save(filename)
      to = File.open(filename, 'wb')
      @object.write to
      to.close
    end

  end
end
