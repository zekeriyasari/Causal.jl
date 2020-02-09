macro sayhello(name)
    @show typeof(name)
    quote
        println("Hello, ", $(esc(name))) 
    end
end

myname = "ali"
macroexpand(Main, :(@sayhello myname))

