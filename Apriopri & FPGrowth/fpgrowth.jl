include("sharing_function.jl")

function frequentItemSet(trans,minsup)
    data=twodims_to_singledim_array(trans)
    c=counter(data)
    t=collect_by_counts(c)
    n=length(t)
    del=[]
    for i=1:n
        if c[t[i]]<minsup
            push!(del,i)
        end
    end
    deleteat!(t,del)
    t
end
function orderedItemSet(trans,frequentSet)
    orderedSet=[]
    for set in trans
        push!(orderedSet,intersect(frequentSet,set))
    end
    orderedSet
end

function getHeaderTable(arr)
    row=length(arr)
    col=0
    for x in arr
        if length(x)>col
            col=length(x)
        end
    end

    table_count=[[]]
    for i=1:col
        push!(table_count,[])
    end
    
    for i=1:length(arr)
        for j=1:length(arr[i])
            push!(table_count[j],arr[i][j])
        end
    end
    count=[]
    for i in table_count
        c=counter(i)
        set=collect_by_counts(c)
        push!(count,[[set[i],c[set[i]]] for i=1:length(c)])
    end
    res=[]
    for i=1:length(arr)
        res_row=[]
        for j=1:length(arr[i])
            for value in count[j]
                if value[1]==arr[i][j]
                    push!(res_row,value)
                    continue
                end
            end
        end
        push!(res,res_row)
    end
    res
end
function getBaseCondition(itemset,header)
    cond=[]
    for k=length(itemset):-1:1
        item=itemset[k]
        values=[]
        for x in header
            value_row=[]
            for i in x
                push!(value_row,i[1])
            end
            push!(values,value_row)
        end
        res=[]
        for i=1:length(header)
            if item in values[i]
                set=header[i]
                route=[]
                for j=1:length(set)
                    push!(route,set[j])
                    if set[j][1]==item
                        break
                    end
                end
                min=10000
                for j=1:length(route)
                    if route[j][2]<min
                        min=route[j][2]
                    end
                end
                for j=1:length(route)
                    route[j][2]=min
                end
                push!(res,route)
            end
        end
        push!(cond,(itemset[k],res))
    end
    return cond
end

function getFPcondition(base,frequency)
    res=[]
    for set in base
        arr=set[2]
        a=arr[1]
        for j=2:length(arr)
            b=arr[j]
            temp=[]
            node=[]
            for i in b
                for x in a
                    if x[1]==i[1] && !(x[1] in [item[1] for item in [set for set in temp]])
                        push!(temp,[x[1],x[2]+i[2]])
                    end
                end
            end
            for i in b 
                if !(i[1] in [item[1] for item in [set for set in temp]]) 
                    push!(temp,i)
                end
            end
            for i in a 
                if !(i[1] in [item[1] for item in [set for set in temp]]) 
                    push!(temp,i)
                end
            end
            a=temp
        end
        a=filter!(e->e[2]>=frequency,a) 
        push!(res,a)
    end
    res
end

function FPgrowth(trans,minsup)
    data=twodims_to_singledim_array(trans)
    set=frequentItemSet(data,round(minsup*length(trans)))
    orderedSet=orderedItemSet(trans,set)
    header=getHeaderTable(orderedSet)
    base=getBaseCondition(set,header)
    fpnodes=getFPcondition(base,round(minsup*length(trans)))
    res=[]
    for i in fpnodes
        row=[]
        for x in i
            push!(row,x[1])
        end
        for x in collect(IterTools.subsets(row))
            sort!(x)
            if (length(x))>0 && !([x] in res)
                union!(res,[x])
            end
        end
    end
    res=filter!(e->support(e,trans)>=minsup,res)
    res
end




