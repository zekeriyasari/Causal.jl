
export @defmodel

function check_macro_syntax(name, ex)
    name isa Symbol || error("Invalid usage of @model")
    ex isa Expr && ex.head == :block || error("Invalid usage of @model")
end

function check_block_syntax(node_expr, branch_expr)
    #-------------------  Node expression check ---------------
    # Check syntax the following syntax
    # @nodes begin 
    #   label1 = Component1() 
    #   label2 = Component2() 
    #       ⋮
    # end 
    (
        node_expr isa Expr && 
        node_expr.head === :(macrocall) && 
        node_expr.args[1] === Symbol("@nodes")
    ) ||  error("Invalid usage of @nodes")
    node_block = node_expr.args[3]
    (
        node_block.head === :block && 
        all([ex.head === :(=) for ex in filter(arg -> isa(arg, Expr), node_block.args)])
    ) || error("Invalid usage of @nodes")

    #---------------------  Branch expression check --------------
    # Check syntax the following syntax
    # @branches begin 
    #   src1[srcidx1] => dst1[dstidx1]
    #   src2[srcidx2] => dst2[dstidx2]
    #       ⋮
    # end 
    (
        branch_expr isa Expr && 
        branch_expr.head === :(macrocall) && 
        branch_expr.args[1] === Symbol("@branches") 
    ) || error("Invalid usage of @branches")
    branch_block = branch_expr.args[3]
    (
        branch_block.head === :block && 
        all([ex.head === :call && ex.args[1] == :(=>) for ex in filter(arg -> isa(arg, Expr), branch_block.args)])
    ) || error("Invalid usage of @branches")
end

"""
    @defmodel name ex 

Construts a model. The expected syntax is. 
```
    @defmodel mymodel begin 
        @nodes begin 
            label1 = Component1()
            label2 = Component1()
                ⋮
        end
        @branches begin 
            src1 => dst1 
            src2 => dst2 
                ⋮
        end
    end
```
Here `@nodes` and `@branches` blocks adefine the nodes and branches of the model, respectively. 
"""
macro defmodel(name, ex) 
    # Check syntax 
    check_macro_syntax(name, ex) 
    node_expr = ex.args[2]
    branch_expr = ex.args[4]
    check_block_syntax(node_expr, branch_expr)

    # Extract nodes info
    node_block = node_expr.args[3] 
    node_labels = [expr.args[1] for expr in node_block.args if expr isa Expr]
    node_components = [expr.args[2] for expr in node_block.args if expr isa Expr]

    # Extract branches info 
    branch_block = branch_expr.args[3] 
    lhs = [expr.args[2] for expr in filter(ex -> isa(ex, Expr), branch_block.args)]
    rhs = [expr.args[3] for expr in filter(ex -> isa(ex, Expr), branch_block.args)]
    quote 
        # Construct model 
        $name = Model()

        # Add nodes to model  
        for (node_label, node_component) in zip($node_labels, $node_components)
            addnode!($name, eval(node_component), label=node_label)
        end

        # Add braches to model 
        for (src, dst) in zip($lhs, $rhs)
            if src isa Symbol && dst isa Symbol 
                addbranch!($name, src => dst)
            elseif src isa Expr && dst isa Expr # src and dst has index.
                if src.args[2] isa Expr && dst.args[2] isa Expr     
                    # array or range index.
                    addbranch!($name, src.args[1] => dst.args[1], eval(src.args[2]) => eval(dst.args[2]))
                else   
                    # integer index
                    addbranch!($name, src.args[1] => dst.args[1], src.args[2] => dst.args[2])
                end
            else 
                error("Ambigiuos connection. Specify the indexes explicitely.")
            end
        end
    end |> esc
end

