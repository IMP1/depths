local mst = {}

-- https://en.wikipedia.org/wiki/Prim's_algorithm

local function includes(list, element) 
    for _, item in pairs(list) do
        if item == element then 
            return true
        end
    end
    return false
end

function mst.minimum_spanning_tree(graph)
    local nodes = graph[1]
    local edge_forest = {}
    local isolated_nodes = {}

    for _, edge in pairs(graph[2]) do
        if not edge_forest[edge.source] then
            edge_forest[edge.source] = {}
        end
        table.insert(edge_forest[edge.source], {target = edge.target, length = edge.length, data = edge})
        if not edge_forest[edge.target] then
            edge_forest[edge.target] = {}
        end
        table.insert(edge_forest[edge.target], {target = edge.source, length = edge.length, data = edge})
    end

    for _, node in pairs(nodes) do
        if not edge_forest[node] then
            table.insert(isolated_nodes, node)
            print("Isolated node:", node)
        end
    end

    local start_node_index = 1
    while includes(isolated_nodes, nodes[start_node_index]) do
        start_node_index = start_node_index + 1
    end
    local spanning_nodes = {nodes[start_node_index]}
    local spanning_edges = {}

    while #spanning_nodes < #nodes - #isolated_nodes do
        local available_edges = {}
        for _, node in pairs(spanning_nodes) do
            for _, edge in pairs(edge_forest[node]) do
                if not includes(spanning_nodes, edge.target) then
                    table.insert(available_edges, edge)
                end
            end
        end
        if #available_edges == 0 then
            print("No available edges")
            print(#spanning_nodes .. "/" .. (#nodes - #isolated_nodes) .. " nodes connected.")
        end
        table.sort(available_edges, function(a, b) return a.length < b.length end)
        local shortest_edge = available_edges[1]
        table.insert(spanning_edges, shortest_edge.data)
        table.insert(spanning_nodes, shortest_edge.target)
    end

    return spanning_edges, isolated_nodes
end

return mst
