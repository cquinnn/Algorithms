include("sharing_function.jl")

function largeSet(items::Array{},sup::Array{}, minsup::Float64)
    L=[]
    for i=1:length(items)
        if sup[i]>=minsup
            push!(L,items[i])
        end
    end
    return L
end

function apriori(transaction::Array{},minsup::Float64)
    data=[]
    for set in transaction
        for item in set
            push!(data,item)
        end
    end
    unique_items=collect(IterTools.distinct(data))
    sups=supports(unique_items,transaction)
    L=largeSet(unique_items,sups,minsup)
    items=L
    res=L    
    i=2
    while length(items)>=i
        f=collect(IterTools.subsets(items,i))
        sups=supports(f,transaction)
        L=largeSet(f,sups,minsup)
        union!(res,L)
        i=i+1
        L_data=twodims_to_singledim_array(L)
        items=collect(IterTools.distinct(L_data))
    end
    return res
end
