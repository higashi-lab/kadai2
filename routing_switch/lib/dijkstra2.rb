require "pp"

class SwitchNode
	INFINITY = 99999
	ITSELF = -1
  COST = 1
#---------------------------------------------------
	def initialize(topology, dpid)
		@mydpid = dpid
		#2次元ハッシュの初期化
		@neighbor = Hash.new { |hash,key| hash[key] = Hash.new {} }

		#スイッチのdpidを登録
		topology.each_switch do |dpid,ports|
			@neighbor[dpid].default = false
		end
		#各スイッチの隣接ノードを登録（@neighbor[src][dest]=trueのときsrcとdestが隣接）
		topology.each_link do |each|
			#リンクのsrcのdpidがスイッチのdpidと一致したときだけ登録（ホストが登録されるのを回避）
			if topology.get_switchlist.key?(each.dpid_a)
				@neighbor[each.dpid_a][each.dpid_b] = true
#				p "src " + each.dpid_a.to_s
#				p "dest " + each.dpid_b.to_s
			end
		end

		#ダイクストラ実行用ハッシュ初期化（訪れた頂点をどんどん増やしていくやつ）
		@visited = {}
		topology.each_switch do |dpid,ports|
			@visited[dpid] = false
		end
		#自身（src）のみ訪問済みとする
		@visited[@mydpid] = true

#p @visited

	  #dijkstra method
		@dest = {}
		@former = {}
		#initializing table
		topology.each_switch do |dpid,ports|
	    if @neighbor[@mydpid][dpid] == true  # if rinsetsu
	      @dest[dpid] = 1
	      @former[dpid] = @mydpid
	    else
	      @dest[dpid] = INFINITY
	      @former[dpid] = nil
	    end
	  end
#		@dest[@mydpid] = ITSELF
#p @mydpid
#p @dest

  # CAUTION: if there're nodes that have no connection to @mypid, this program can't work. 
=begin
	  while allVisit(@visited) == false do # N ga umaru made
	    @nearest = @mydpid
#    @nearest_length = INFINITY
	    for dpid  in @dest.keys do
	      if ((@dest[@nearest] > @dest[dpid] )&&( @visited[dpid] == false))
	        @nearest = dpid
	      end
	    end
#visitedがすべてtrueにならないので変なエラーがでる
	    @visited[@nearest] = true

	    for dpid in @dest.keys do
	      if((@dest[dpid] > @dest[@nearest]+COST)&&(@neighbor[dpid][@nearest]==true))         
	        @dest[dpid] = @dest[@nearest]+COST
	   		 	@former[dpid] = @nearest
	      end
	    end
	  end
=end 
	end
#---------------------------------------------------
	def run_dijkstra(dstIP)
p dstIP
	

	end
#---------------------------------------------------

  def allVisit(visited) #function for checking
    for dpid in visited.keys do
      if visited[dpid] == false
        return false
      end
    end
    return true
  end

#---------------------------------------------------

end
