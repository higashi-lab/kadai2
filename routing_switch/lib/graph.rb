#**********************************************************
# グラフ
#**********************************************************
class Graph
  
  def initialize( directed=false )
    @serial = 0
    @directed = directed
    @vertices = []
  end

  def connect( from, to, weight=1 )
    assert_vertex_exist from
    assert_vertex_exist to
    @vertices[from].connect( to, weight )
    @vertices[to].connect( from, weight ) unless @directed
  end

  def disconnect( from, to )
    assert_vertex_exist from
    assert_vertex_exist to
    @vertices[from].disconnect( to )
    @vertices[to].disconnect( from, weight ) unless @directed
  end
  
  def add_vertex( data )
    id = @serial
    @serial += 1
    @vertices[id] = Vertex.new( id, data )
    return id
  end

	def show
		p @vertices
	end

  def inspect
    return "---\n" + vertices.collect {|v| v.inspect }.join("\n")
  end
  
  attr_reader :vertices
  
private
  def assert_vertex_exist( id )
    if ( id < 0 || id >= @vertices.length || !@vertices[id] )
      raise "vertex not exist. id=#{id}" 
    end
  end
  
end

#**********************************************************
# 頂点
#**********************************************************
class Vertex
  def initialize( id, data )
    @id = id
    @data = data
    @edges = []
  end
  def connect( to, weight )
    @edges.push({
      :to=> to,
      :weight=> weight
    })
  end
  def disconnect( to )
    @edges.reject! {|e| e.to === to }
  end
  def inspect
    return "#{@id}:#{@data.inspect}\n" + @edges.collect{|e|
        "  -> #{e[:to]} : #{e[:weight]}"
      }.join("\n")
  end
  attr_reader :id, :data, :edges
end
