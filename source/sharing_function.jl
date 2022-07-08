using IterTools
using Statistics
using Counters

function readFile(filename::String)
    inn = open(filename,"r")
    inp=readline(inn)
    arr=[]
    while inp!=""
        x=[parse(Int64,x) for x in split(inp)]
        push!(arr,x)
        inp=readline(inn)
    end
    close(inn)
    return arr
end 
function twodims_to_singledim_array(arr::Array{})
    data=[]
    for set in arr
        for item in set
            push!(data,item)
        end
    end
    return data
end
function support(item,trans::Array{})
    return count(x->issubset(item,x),trans)/length(trans)
end
function supports(items::Array{},trans::Array{})
    return [count(x->issubset(i,x) ,trans)/length(trans) for i in items]
end
function show_frequent_itemset(frequent_itemset::Array{},trans::Array{})
    println("Length of frequentSet:",length(frequent_itemset))
    for item in frequent_itemset
        println(item,": ",support(item,trans))
    end
end

