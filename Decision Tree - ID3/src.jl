using DataFrames
using CSV
using Random
using Counters
mutable struct node
    data::DataFrame
    attr::Union{Nothing,Any}
    threshold::Union{Nothing,Any}
    left::Union{Nothing,Any}
    right::Union{Nothing,Any}
    depth::Union{Nothing,Any}
    node(data,depth)=new(data,nothing,nothing,nothing,nothing,depth)
end
function partitionTrainTest(data,at=2/3)
    n=nrow(data)
    idx=shuffle(1:n)
    train_idx=view(idx,1:floor(Int,at*n))
    test_idx=view(idx,(floor(Int,at*n)+1):n)
    data[train_idx,:],data[test_idx,:]
end

function entropy(data)
    unique_item=unique(data)
    if length(unique_item)<=1
        return 0
    end
    c=counter(data)
    return -sum(c[u]/length(data)*log(c[u]/length(data)) for u in unique_item)
end
function entropyOfAttrs(data,label)
    if length(unique(label)) <=1
        return 0
    end
    g=0
    unique_items=unique(data)
    for i in unique_items
        v=[]
        foreach(j->data[j] == i && push!(v,label[j]),eachindex(data))
        g=g+length(v)/length(data)*entropy(v)
    end
    g
end

function cutoffData(df_value)
    min=1000
    threshold=0
    at=0
    attrs=names(df_value)[1:end-1]
    label=names(df_value)[end]
    
    for attribute in attrs
        a=[i for i in df_value[!,attribute]]
        for split in unique(df_value[!,attribute])
            b=[]
            c=[]
            foreach(i->a[i] < split && push!(b,df_value[i,label]),eachindex(a))
            foreach(i->a[i] >= split && push!(c,df_value[i,label]),eachindex(a))

            e=length(b)/length(a)*entropy(b)+length(c)/length(a)*entropy(c)
            if e<min
                min=e
                threshold=split
                at=attribute
            end
        end
    end
    a=DataFrame()
    b=DataFrame()
    cols=[]
    foreach(i->names(df_value)[i]!=at && push!(cols,names(df_value)[i]),eachindex(names(df_value)))
    foreach(i->df_value[i,at] < threshold && (df_value[i,at]=0),eachindex(df_value[!,at]))
    foreach(i->df_value[i,at] >= threshold && (df_value[i,at]=1),eachindex(df_value[!,at]))
    foreach(i->df_value[i,at] == 0 && push!(a,df_value[i,cols]),eachindex(df_value[!,at]))
    foreach(i->df_value[i,at] == 1 && push!(b,df_value[i,cols]),eachindex(df_value[!,at]))
    return at,threshold,df_value,a,b
end

function preprocessing(df)
    select!(df,Not(:Id))
    df
end

function print_tree(tree)
    #print("data: ",nrow(tree.data))
    print(tree.attr)
    println(" < ",tree.threshold)
    #println(" depth: ",tree.depth," ")
    print("    " ^ tree.depth * "T -> ")
    if typeof(tree.left)==node
        print_tree(tree.left)
    else
        println(tree.left)
    end
    print("    " ^ tree.depth * "F -> ")
    if typeof(tree.right)==node
        print_tree(tree.right)
    else
        println(tree.right)
    end
end
function predict(tree,sample)
    if sample[tree.attr]<tree.threshold
        if typeof(tree.left)==node
            predict(tree.left,sample)
        else
            return tree.left
        end
    else
        if typeof(tree.right)==node
            predict(tree.right,sample)
        else
            return tree.right
        end
    end
end
function predict_set(tree,test::DataFrame)
    return [predict(tree,test[i,:]) for i=1:nrow(test)]
end 
function accuracy(y_pred,y_true)
    correct=sum(y_pred[i]==y_true[i] for i=1:length(y_pred))
    return correct/length(y_true)
end

function getLabel(data,label)
    max=0
    l=0
    for val in unique(data[!,label])
        count_v=sum(data[i,label]==val for i=1:nrow(data))
        if count_v>max
            max=count_v
            l=val
        end
    end
    return l
end

function decisionTreeID3(df)
    label=names(df)[end]
    tree=node(df,1)
    s=[tree]
    pre_tree=tree
    while length(s)>0 
        node_tree=popat!(s,1)
        data=node_tree.data
        at,v,data,a,b=cutoffData(data)
        setfield!(node_tree,:attr,at)
        setfield!(node_tree,:threshold,v)
    
        if nrow(a)>0
            if entropy(a[!,label])==0
                setfield!(node_tree,:left,a[1,label])
            elseif ncol(a)>=2
                node_left=node(a,node_tree.depth+1)
                setfield!(node_tree,:left,node_left)
                push!(s,node_left)
            else
                setfield!(node_tree,:left,getLabel(a,label))
            end
        end
        if nrow(b)>0
            if entropy(b[!,label])==0
                setfield!(node_tree,:right,b[1,label])
            elseif ncol(b)>=2
                node_right=node(b,node_tree.depth+1)
                setfield!(node_tree,:right,node_right)
                push!(s,node_right)
            else
                setfield!(node_tree,:right,getLabel(b,label))
            end
        end
    end
    return tree
end
function isLeafSame(no)
    if typeof(no)==node
        if no.left==no.right
            return true
        end
    end
    false
end
function prune(tree)
    s=[tree]
    while length(s) >0
        n=popat!(s,1)
        if typeof(n)==node 
            if typeof(n.left)==node
                if isLeafSame(n.left)
                    setfield!(n,:left,n.left.left)
                else
                    push!(s,n.left)
                end
            end
            if typeof(n.right)==node
                if isLeafSame(n.right)
                    setfield!(n,:right,n.right.left)
                else
                    push!(s,n.right)
                end
            end
        end
    end
end      
function isSameLeafInTree(tree)
    s=[tree]
    while length(s) >0
        n=popat!(s,1)
        if typeof(n)==node 
            if typeof(n.left)==node
                if isLeafSame(n.left)
                    return true
                else
                    push!(s,n.left)
                end
            end
            if typeof(n.right)==node
                if isLeafSame(n.right)
                    return true
                else
                    push!(s,n.right)
                end
            end
        end
    end
    false
end    
function pruneTree(tree)
    while isSameLeafInTree(tree)==true
        prune(tree)
    end
end
function main()
    #####################
    df=DataFrame(CSV.File("iris.csv"))
    df=preprocessing(df)
    train,test = partitionTrainTest(df)
    #####################
    tree=decisionTreeID3(train)
    pruneTree(tree)
    print_tree(tree)
    ##########################
    label=names(df)[end]
    features=test[!,1:ncol(test)-1]
    y_pred=predict_set(tree,features)
    y_true=[test[i,label] for i=1:nrow(test)]
    println("Accuracy: ", accuracy(y_pred,y_true))
end
main()