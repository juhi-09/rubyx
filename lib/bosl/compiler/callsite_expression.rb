module Bosl
  Compiler.class_eval do

    def on_call expression
      name , arguments , receiver = *expression
      name = name.to_a.first

      if receiver
        me = process( receiver.to_a.first  )
      else
        me = Virtual::Self.new :int
      end
      ## need two step process, compile and save to frame
      # then move from frame to new message
      method.source.add_code Virtual::NewMessage.new
      method.source.add_code Virtual::Set.new( me , Virtual::NewSelf.new(me.type))
      method.source.add_code Virtual::Set.new( name.to_sym , Virtual::NewMessageName.new(:int))
      compiled_args = []
      arguments.to_a.each_with_index do |arg , i|
        #compile in the running method, ie before passing control
        val = process( arg)
        # move the compiled value to it's slot in the new message
        # + 1 as this is a ruby 0-start , but 0 is the last message ivar.
        # so the next free is +1
        to = Virtual::NewArgSlot.new(i + 1 ,val.type , val)
        # (doing this immediately, not after the loop, so if it's a return it won't get overwritten)
        method.source.add_code Virtual::Set.new( val , to )
        compiled_args << to
      end
      method.source.add_code Virtual::MessageSend.new(name , me , compiled_args) #and pass control
      # the effect of the method is that the NewMessage Return slot will be filled, return it
      # (this is what is moved _inside_ above loop for such expressions that are calls (or constants))
      Virtual::Return.new( method.source.return_type )
    end
  end
end
