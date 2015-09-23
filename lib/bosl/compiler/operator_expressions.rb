module Bosl
  Compiler.class_eval do
#    operator attr_reader  :operator, :left, :right
    def on_operator expression
      operator , left , right = *expression
      Virtual::Return.new(:int)
    end

    def on_assign expression
      name , value = *expression
      name = name.to_a.first
      v = process(value)
      index = method.ensure_local( name )
      method.source.add_code Virtual::Set.new(Virtual::FrameSlot.new(:int,index ) , v )
    end

  end
end
