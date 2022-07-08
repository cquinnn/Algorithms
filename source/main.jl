include("fpgrowth.jl")
include("apriori.jl")
using PlotlyJS
print("Nhap duong dan den file du lieu: ")
filename=readline()
println("Duong dan den file du lieu: ",filename)
print("Nhap minsup: ")
minsup=parse(Float64,readline())
trans=readFile(filename)

println("Thuat toan apriori:")
res_ap=FPgrowth(trans,minsup)
@time(FPgrowth(trans,minsup))
println("Length of frequentSet: ", length(res_ap))


println("Thuat toan FP tree: ")
res_fp=FPgrowth(trans,minsup)
@time(FPgrowth(trans,minsup))
println("Length of frequentSet: ",length(res_ap))
show_frequent_itemset(res_fp,trans)
