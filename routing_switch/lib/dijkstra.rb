require 'graph'
require 'priority_queue'
# ダイクストラ アルゴリズムでノード間の最短経路を算出する
class ShortestPathFinder
  
  def initialize( graph )
    @graph = graph
  end
  
  # startからすべてのノードへの最短経路を探索する
  def traverse( start )
    initialize_state( start )
    @queue.push( start, 0 )
    while( vertex_id_and_distance = @queue.delete_min )
#p vertex_id_and_distance
      visit_vertex(vertex_id_and_distance[0], vertex_id_and_distance[1])
    end
    return self
  end
  
  # 指定頂点までの最短パスを構築する。
  def shortest_path_to( vertex_id )
    raise "not traversed" unless @start
    path = []
#p @previous.include?( vertex_id )
#p (vertex_id != @start)
    while( (@previous.include?( vertex_id )) && (vertex_id != @start) )
#p vertex_id
      path.unshift(vertex_id)
      vertex_id = @previous[vertex_id]
    end
    return path
  end
  
private

  # 状態を初期化する
  def initialize_state(start)
    @queue = PriorityQueue.new
    @distances = {}
    @previous = {}
    @start = start
  end
  
  # 頂点を訪問する
  def visit_vertex( vertex_id, distance )
    @graph.vertices[vertex_id].edges.each {|e|
      to = e[:to]
      distance_of_next_node = distance + e[:weight]
      if ( not_visited_or_shorter_path?( to, distance_of_next_node ) )
        @previous[to] = vertex_id
        @distances[to] = distance_of_next_node
        @queue[to] = distance_of_next_node
      end
    }
  end
  
  # 訪問済みでない、またはより短いパスであるか評価する。
  def not_visited_or_shorter_path?( vertex_id, distance )
    return !@distances.include?(vertex_id) || @distances[vertex_id] > distance
  end

end
