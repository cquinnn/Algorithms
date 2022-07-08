#using Pkg
using Random
using CSV
using DataFrames
MINIMUM_SAMPLE_SIZE = 4
MAX_TREE_DEPTH = 3
# df = DataFrame(CSV.File("Iris.csv"));
# names(df)
# print(df)
# print("Hello")
#print("Hi")
mutable struct tree_node

    dataset::DataFrame
    is_leaf::Bool
    split_attribute::Union{Nothing,Any}
    split::Union{Nothing,Any}
    attribute_list::Array{String}
    attribute_values::Array{String}
    left_child::Union{Nothing, Any}
    right_child::Union{Nothing, Any}
    prediction::Any
    depth::Int

    function tree_node(training_set::DataFrame, attribute_list::Array{String}, attribute_values::Array{String}, tree_depth::Int)
        new(training_set, false, nothing,nothing,attribute_list,attribute_values,nothing,nothing,nothing,tree_depth)
    end
    function build()
        training_set = dataset
        if depth < MAX_TREE_DEPTH && len(training_set) >= MINIMUM_SAMPLE_SIZE && len(set([elem["species"] for elem in training_set])) > 1
            max_gain, attribute, split = max_information_gain(attribute_list, attribute_values, training_set)

            if max_gain > 0
                split = split
                split_attribute = attribute

                training_set_l = [elem for elem in training_set if elem[attribute] < split]
                training_set_r = [elem for elem in training_set if elem[attribute] >= split]
                left_child = tree_node(training_set_l, attribute_list, attribute_values, depth + 1)
                right_child = tree_node(training_set_r, attribute_list, attribute_values, depth + 1)
                left_child.build()
                right_child.build()
            else
                is_leaf = True
            end
        else
            is_leaf = True
        end
        if is_leaf
            setosa_count = versicolor_count = virginica_count = 0
            for elem in training_set
                if elem["species"] == "Iris-setosa"
                    setosa_count += 1
                elseif elem["species"] == "Iris-versicolor"
                    versicolor_count += 1
                else
                    virginica_count += 1
                end
            end
            dominant_class = "Iris-setosa"
            dom_class_count = setosa_count
            if versicolor_count >= dom_class_count
                dom_class_count = versicolor_count
                dominant_class = "Iris-versicolor"
            end
            if virginica_count >= dom_class_count
                dom_class_count = virginica_count
                dominant_class = "Iris-virginica"
            end
            prediction = dominant_class
        end
    end
    function predict(sample)
        if is_leaf
            return prediction
        else
            if sample[split_attribute] < split
                return left_child.predict(sample)
            else
                return right_child.predict(sample)
            end
        end
    end



    function merge_leaves()
        if !is_leaf
            left_child.merge_leaves()
            right_child.merge_leaves()
            if left_child.is_leaf && right_child.is_leaf && left_child.prediction == right_child.prediction
                is_leaf = True
                prediction = left_child.prediction
            end
        end
    end
    function print(prefix)
        if is_leaf
            println("\t" * depth + prefix + prediction)
        else
            print("\t" * depth + prefix + split_attribute + "<" + str(split) + "?")
            left_child.print("[True] ")
            right_child.print("[False] ")
        end
    end
end

struct ID3_tree
    root::Union{Nothing,Any}
    ID3_tree() = new(nothing)


    function build(training_set, attribute_list, attribute_values)
        root = tree_node(training_set, attribute_list, attribute_values, 0)
        root.build()
    end

    function merge_leaves()
        root.merge_leaves()
    end
    function predict(sample)
        return root.predict(sample)
    end
    function print()
        println("----------------")
        println("DECISION TREE")
        root.print("")
        println("----------------")
    end
end
function entropy(dataset)
    if len(dataset) == 0
        return 0
    end
    target_attribute_name = "species"
    target_attribute_values = ["Iris-setosa", "Iris-versicolor", "Iris-virginica"]

    data_entropy = 0
    for val in target_attribute_values
        p = len([elem for elem in dataset if elem[target_attribute_name] == val]) / len(dataset)
        if p > 0
            data_entropy += -p * log(p, 2)
        end
    end
    return data_entropy
end

function info_gain(attribute_name, split, dataset)
    set_smaller = [elem for elem in dataset if elem[attribute_name] < split]
    p_smaller = len(set_smaller) / len(dataset)
    set_greater_equals = [elem for elem in dataset if elem[attribute_name] >= split]
    p_greater_equals = len(set_greater_equals) / len(dataset)
    info_gain = entropy(dataset)
    info_gain -= p_smaller * entropy(set_smaller)
    info_gain -= p_greater_equals * entropy(set_greater_equals)

    return info_gain

end
function max_information_gain(attribute_list, attribute_values, dataset)
    max_info_gain = 0
    for attribute in attribute_list 
        for split in attribute_values[attribute]
            split_info_gain = info_gain(attribute, split, dataset)
            if split_info_gain >= max_info_gain
                max_info_gain = split_info_gain
                max_info_gain_attribute = attribute
                max_info_gain_split = split
            end
        end
    end
    return max_info_gain, max_info_gain_attribute, max_info_gain_split
end
function read_iris_dataset()
    dataset = []
    dataset = DataFrame(CSV.File("IRIS.csv"));
    return dataset
end
function TrainTest(dataset, at=2/3)
    n = nrow(dataset)
    index = shuffle(1:n)
    train_index = view(index,1:floor(Int,at*n))
    test_index = view(index,(floor(Int,at*n)+1):n)
    return dataset[train_index,:], dataset[test_index,:]
end

dataset= read_iris_dataset()
print(dataset)
training_set,test_set = TrainTest(dataset)

attr_list = ["sepal_length", "sepal_width", "petal_length", "petal_width"]

attr_domains = []
for attr in list(dataset[].keys())
    attr_domain = set()
    for s in dataset
        attr_domain.add(s[attr])
    attr_domains[attr] = list(attr_domain)
    end
end



