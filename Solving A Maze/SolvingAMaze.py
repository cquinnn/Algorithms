from abc import get_cache_token
from collections import deque
import math
import os
import matplotlib.pyplot as plt
import time
from numpy import ceil, matrix
def visualize_M(matrix, bonus, start, end, route=None, visited=None):
    walls=[(i,j) for i in range(len(matrix)) for j in range(len(matrix[0])) if matrix[i][j]=='x']

    if route:
        direction=[]
        for i in range(1,len(route)):
            if route[i][0]-route[i-1][0]>0:
                direction.append('v') 
            elif route[i][0]-route[i-1][0]<0:
                direction.append('^')         
            elif route[i][1]-route[i-1][1]>0:
                direction.append('>')
            else:
                direction.append('<')
        direction.pop(0)

    print(f'Starting point (x, y) = {start[0], start[1]}')
    print(f'Ending point (x, y) = {end[0], end[1]}')
    
    for _, point in enumerate(bonus):
      print(f'Bonus point at position (x, y) = {point[0], point[1]} with point {point[2]}')
    
    ax=plt.figure(dpi=100).add_subplot(111)

    for i in ['top','bottom','right','left']:
        ax.spines[i].set_visible(False)

    plt.scatter([i[1] for i in walls],[-i[0] for i in walls],
                marker='X',s=100,color='black')
    
    plt.scatter([i[1] for i in bonus],[-i[0] for i in bonus],
                marker='P',s=100,color='green')

    plt.scatter(start[1],-start[0],marker='*',
                s=100,color='gold')
    if visited:
        for i in range(len(visited)-2):
            plt.scatter(visited[i+1][1],-visited[i+1][0],marker='.',color='gray')

    if route:
        for i in range(len(route)-2):
            plt.scatter(route[i+1][1],-route[i+1][0],marker=direction[i],color='orange')

    plt.text(end[1],-end[0],'EXIT',color='red',
         horizontalalignment='center',
         verticalalignment='center')
    plt.xticks([])
    plt.yticks([])
    plt.show()

def read_file(file_name: str = 'maze.txt'):
    f=open(file_name,'r')
    n_bonus_points = int(next(f)[:-1])
    bonus_points = []
    for i in range(n_bonus_points):
        x, y, reward = map(int, next(f)[:-1].split(' '))
        bonus_points.append((x, y, reward))
    text=f.read()
    matrix=[list(i) for i in text.splitlines()]
    f.close()
    return matrix,bonus_points

def convert_matrix(M,bonus): #Chuyển về ma trận số với vị trí 0 là tường, vị trí 1 hoặc số khác là vị trí có thể đi qua
    for i in range(len(M)):
        for j in range(len(M[0])):
            if M[i][j]=='S':
                start=(i,j)
                M[i][j]=1
            elif M[i][j]==' ':
                M[i][j]=1
                if (i==0) or (i==len(M)-1) or (j==0) or (j==len(M[0])-1):
                    goal=(i,j)
                else:
                    pass
            elif M[i][j]=='+':
                for k in range(len(bonus)):
                    if bonus[k][0] == i and bonus[k][1] == j:
                        M[i][j]=bonus[k][2]
                        break
            else: 
                M[i][j]=0
    return M,start,goal

class __node():
    def __init__(self, parent=None, position=None):
        self.parent = parent
        self.position = position
        self.g = 0
        self.h = 0
    def __eq__(self,other):
        return self.position==other
def succs(M,p,close): 
    res=[]
    up=(p[0]-1,p[1])
    left=(p[0],p[1]-1)
    down=(p[0]+1,p[1])
    right=(p[0],p[1]+1)
    pos=[left,up,right,down]
    for po in pos:
        if po not in close and po[0] in range(0,len(M)) and po[1] in range(0,len(M[0])):
            if M[po[0]][po[1]]: 
                res.append(po)
    return res
def resetClosed(M,path,current):
    closed=[]
    for i in range(len(path)):
        closed.append(path[i][0].position)
    closed.append(current)
    return closed
def cal_cost(M,path):
    cost=0
    for i in range(len(path)):
        if path[i] in path[:i-1]: 
            cost+=1
        else: 
            cost+=M[path[i][0]][path[i][1]]
    return cost
def distance(point,start):
    return abs(point[0]-start[0])+abs(point[1]-start[1])
def findNearestBonusPoint(bonus,current_position):
    nearest_point=(0,0)
    min=100
    index=0
    for i in range(len(bonus)):
        if (bonus[i][0],bonus[i][1])==current_position:
            continue
        temp_distance=distance(bonus[i],current_position)
        if temp_distance < min:
            min=temp_distance
            nearest_point=bonus[i]
            index=i
    bonus.remove(bonus[index])
    return nearest_point
def DFS(M,start,goal,max_cost,visited): 
    closed=[]
    start_node=__node(None,start)
    path=[(start_node,succs(M,start,closed))]
    current=start
    while path:
        if current not in visited:
            visited.append(current)
        if current==goal:
            res=[]
            for i in range(len(path)):
                res.append(path[i][0].position)
            return res
        if not path[-1][1]: 
            closed=resetClosed(M,path,current)
            current=path.pop()[0].position
        else:
            closed.append(current)
            pre=current
            current=path[-1][1].pop()
            current_node=__node(pre,current)
            current_node.g=path[-1][0].g+1
            path.append((current_node,succs(M,current,closed)))
            if current_node.g > max_cost:
                closed=resetClosed(M,path,current)
                path.pop()
                current=pre
        
    return False
def DFS_findShortestPath(M,s,g,visited): 
    for max_cost in range(abs(s[0]-g[0])+abs(s[1]-g[1]),len(M[0])*len(M)):      
        res=DFS(M,s,g,max_cost,visited)
        if res:
            return res
def DFS_findShortestPathWithPoint(M,s,g,bonus,visited):
    route=[s]
    pre=s
    for i in range(len(bonus)):
        point=findNearestBonusPoint(bonus,pre)
        if point in route:
            continue
        x,y=point[0],point[1]
        temp_route=DFS_findShortestPath(M,pre,(x,y),visited)
        cost_through_point=cal_cost(M,temp_route) + cal_cost(M,DFS_findShortestPath(M,(x,y),g,visited))+point[2]
        cost = cal_cost(M,DFS_findShortestPath(M,pre,g,visited))
        if cost_through_point <= cost:
            for i in range(1,len(temp_route)):
                route.append(temp_route[i])
            pre=(point[0],point[1])
    temp_route=DFS_findShortestPath(M,route[-1],g,visited)
    for i in range(1,len(temp_route)):
        route.append(temp_route[i])
    return route

def isValid(M, parent, row, col):
    return (row >= 0) and (row < len(M)) and (col >= 0) and (col < len(M[0])) and M[row][col] != 0 and parent[row][col]==0
def BFS(maze,start,goal,visited):
    rows,cols = len(maze),len(maze[0])
    parent = []
    new =[]
    for i in range(rows):
        for j in range(cols):
            new.append(0)
        parent.append(new)
        new = []
    i,j = start[0],start[1]
    x,y = goal[0],goal[1]
    if (i,j) not in visited:
        visited.append((i,j))
    q = deque()
    q.append((i,j))
    row = [-1, 0, 0, 1]
    col = [0, -1, 1, 0]
    while q: 
        i,j = q.popleft()
        if (i,j) not in visited:
            visited.append((i,j))
        if i == x and j == y:
            break
        for k in range(4):
            a  = i + row[k]
            b = j + col[k]
            if (isValid(maze,parent,a,b)):
                parent[a][b] = (i,j)
                q.append((a,b))
    cost = 0
    path = []
    end = parent[x][y]
    currx,curry = goal[0],goal[1]
    i,j = start[0],start[1]
    while currx!=i or curry!=j:
        path.append((currx,curry))
        temp = parent[currx][curry]
        tempx = temp[0]
        tempy = temp[1]
        currx, curry = tempx,tempy
    path.append(start)
    path = path[::-1]
    return path
def BFS_findShortestPathWithPoint(M,s,g,bonus,visited):
    route=[s]
    pre=s
    for i in range(len(bonus)):
        point=findNearestBonusPoint(bonus,pre)
        if point in route:
            continue
        x,y=point[0],point[1]
        temp_route=BFS(M,pre,(x,y),visited)
        cost_through_point=cal_cost(M,temp_route) + cal_cost(M,BFS(M,(x,y),g,visited))+point[2]
        cost = cal_cost(M,BFS(M,pre,g,visited))
        if cost_through_point <= cost:
            for i in range(1,len(temp_route)):
                route.append(temp_route[i])
            pre=(point[0],point[1])
    temp_route=BFS(M,route[-1],g,visited)
    for i in range(1,len(temp_route)):
        route.append(temp_route[i])
    return route
def heuristic(s,g):
    dx = abs(g[0] - s[0])
    dy = abs(g[1] - s[1])
    return math.sqrt(dx * dx + dy * dy)
    #return (abs(g[0]-s[0])+abs(g[1]-s[1]))

def Astar(M,start,goal,visited):
    closed=[]
    start_node=__node(None,start)
    goal_node=__node(None,goal)
    open=[start_node]
    if start not in visited:
        visited.append(start)
    path = []
    current_node=start_node
    cost=0
    while open:
        current_node=open[0]
        for node in open:
            if node.h + node.g < current_node.h + current_node.g:       
                current_node=node
        if current_node.position not in visited:
            visited.append(current_node.position)
        open.remove(current_node)
        closed.append(current_node.position)
        if current_node.position==goal:
            path.append(current_node)
            res=[]
            cur=path[(len(path)-1)]

            for i in range(len(path)):
                res.append(cur.position)
                if cur.parent==start:
                    res.append(cur.parent)
                    break
                for j in range(len(path)-1,0,-1):
                    if cur.parent==path[j].position:
                        cur=path[j]
                        break
            return res[::-1]        
        path.append(current_node)

        for s in succs(M,current_node.position,closed):
            if s not in open and s not in closed:
                s_node = __node(current_node.position,s)
                s_node.g=current_node.g+1
                s_node.h=heuristic(s,goal)
                open.append(s_node)   
        cost+=1  
    return False
def Astar_findShortestPathWithPoint(M,s,g,bonus,visited):
    route=[s]
    pre=s
    for i in range(len(bonus)):
        point=findNearestBonusPoint(bonus,pre)
        if point in route:
            continue
        x,y=point[0],point[1]
        temp_route=Astar(M,pre,(x,y),visited)
        cost_through_point=cal_cost(M,temp_route) + cal_cost(M,Astar(M,(x,y),g,visited))+point[2]
        cost = cal_cost(M,Astar(M,pre,g,visited))
        if cost_through_point <= cost:
            for i in range(1,len(temp_route)):
                route.append(temp_route[i])
            pre=(point[0],point[1])
    temp_route=Astar(M,route[-1],g,visited)
    for i in range(1,len(temp_route)):
        route.append(temp_route[i])
    return route
def GBFS(M,start,goal,visited):
    closed=[]
    start_node=__node(None,start)
    goal_node=__node(None,goal)
    open=[start_node]
    if start not in visited:
        visited.append(start)
    path = []
    current_node=start_node
    while open:
        current_node=open[0]
        for node in open:
            if node.h < current_node.h:       
                current_node=node
        if current_node.position not in visited:
            visited.append(current_node.position)
        open.remove(current_node)
        closed.append(current_node.position)
        if current_node.position==goal:
            path.append(current_node)
            res=[]
            cur=path[(len(path)-1)]

            for i in range(len(path)):
                res.append(cur.position)
                if cur.parent==start:
                    res.append(cur.parent)
                    break
                for j in range(len(path)-1,0,-1):
                    if cur.parent==path[j].position:
                        cur=path[j]
                        break
            return res[::-1]   
        path.append(current_node)

        for s in succs(M,current_node.position,closed):
            if s not in open and s not in closed:
                s_node = __node(current_node.position,s)
                s_node.g=current_node.g+int(M[s[0]][s[1]])
                s_node.h=heuristic(s,goal)
                open.append(s_node)     
    return False
def GBFS_findShortestPathWithPoint(M,s,g,bonus,visited):
    route=[s]
    pre=s
    for i in range(len(bonus)):
        point=findNearestBonusPoint(bonus,pre)
        if point in route:
            continue
        x,y=point[0],point[1]
        temp_route=GBFS(M,pre,(x,y),visited)
        cost_through_point=cal_cost(M,temp_route) + cal_cost(M,GBFS(M,(x,y),g,visited))+point[2]
        cost = cal_cost(M,GBFS(M,pre,g,visited))
        if cost_through_point <= cost:
            for i in range(1,len(temp_route)):
                route.append(temp_route[i])
            pre=(point[0],point[1])
    temp_route=GBFS(M,route[-1],g,visited)
    for i in range(1,len(temp_route)):
        route.append(temp_route[i])
    return route
def BFS_FindAndPrintRoute(filename):
    print('Breadth-first Search:')
    M,bonus=read_file(filename)
    M,s,g=convert_matrix(M,bonus)
    visited=[]
    start_time = time.time()
    if bonus:
        res=BFS_findShortestPathWithPoint(M,s,g,bonus,visited)
    else:
        res=BFS(M,s,g,visited)
    print('Chi phi: ',cal_cost(M,res))
    total_time= time.time()-start_time
    M,bonus=read_file(filename)
    visualize_M(M,bonus,s,g,res,visited)
    print("BFS's time = ",total_time)
def DFS_FindAndPrintRoute(filename):
    print('Depth-first Search:')
    M,bonus=read_file(filename)
    M,s,g=convert_matrix(M,bonus)
    visited=[]
    start_time = time.time()
    if bonus:
        res=DFS_findShortestPathWithPoint(M,s,g,bonus,visited)
    else:
        res=DFS(M,s,g,10000,visited)
    print('Chi phi:',cal_cost(M,res))
    total_time= time.time()-start_time
    M,bonus=read_file(filename)
    visualize_M(M,bonus,s,g,res,visited)
    print("DFS's time = ", total_time)
def Astar_FindAndPrintRoute(filename):
    print('A* Search:')
    M,bonus=read_file(filename)
    M,s,g=convert_matrix(M,bonus)
    visited=[]
    start_time = time.time()
    if bonus:
        res=Astar_findShortestPathWithPoint(M,s,g,bonus,visited)
    else:
        res=Astar(M,s,g,visited)
    print('Chi phi: ',cal_cost(M,res))
    total_time= time.time()-start_time
    M,bonus=read_file(filename)
    visualize_M(M,bonus,s,g,res,visited)
    print("A-star's time = ", total_time)
def GBFS_FindAndPrintRoute(filename):
    print('Greedy Best-first Search:')
    M,bonus=read_file(filename)
    M,s,g=convert_matrix(M,bonus)
    visited=[]
    start_time = time.time()
    if bonus:
        res=GBFS_findShortestPathWithPoint(M,s,g,bonus,visited)
    else:
        res=GBFS(M,s,g,visited)
    print('Chi phi: ',cal_cost(M,res))
    total_time= time.time()-start_time
    M,bonus=read_file(filename)
    visualize_M(M,bonus,s,g,res,visited)
    print("Greedy best-first's time = ", total_time)

def main():
    filename = input()
    filename ='../Kiểm thử/'+filename
    BFS_FindAndPrintRoute(filename)
    DFS_FindAndPrintRoute(filename)
    Astar_FindAndPrintRoute(filename)
    GBFS_FindAndPrintRoute(filename)
main()