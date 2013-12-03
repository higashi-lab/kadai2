# -*- coding: utf-8 -*-
require 'forwardable'
require 'link'
require 'observer'
require 'trema-extensions/port'

#
# Topology information containing the list of known switches, ports,
# and links.
#
class Topology
  include Observable
  extend Forwardable

  def_delegator :@ports, :each_pair, :each_switch
  def_delegator :@links, :each, :each_link
  def_delegator :@hosts, :each_pair, :each_host

  def initialize(view)
    @ports = Hash.new { [].freeze }
    @links = []
		@hosts = {}
		@hostMAC = {}
		@next = {}
		@switch = {}

		@route = Hash.new { |hash,key| hash[key] = Hash.new {} }
		@index = {}
		@init = true

		@fdb = Hash.new { |hash,key| hash[key] = Hash.new {} }
    add_observer view
  end

  def delete_switch(dpid)
    @ports[dpid].each do | each |
      delete_port each
			@fdb[each.dpid].delete(dpid)
    end
    @ports.delete dpid
		@fdb.delete(dpid)
		update_graph
  end

  def update_port(port)
    if port.down?
      delete_port port
    elsif port.up?
      add_port port
    end
  end

  def add_port(port)
    @ports[port.dpid] += [port]
if !@init
#p "add port"
		update_graph# unless @init
end
  end

  def delete_port(port)
#p "delete port"
    @ports[port.dpid] -= [port]
    delete_link_by port
  end

  def add_link_by(dpid, packet_in)
#    fail 'Not an LLDP packet!' unless packet_in.lldp?
    begin
      maybe_add_link Link.new(dpid, packet_in)
    rescue
      return
    end
    changed
    notify_observers self
  end

	def add_host(dpid, msg)
		ip = msg.ipv4_saddr.to_s
		if !is_all_zero_addr(ip)
			if !@hosts.key?(ip)
				@hosts[ip] = 10000
				@hostMAC[ip] = msg.macsa
				#ホストに接続されたスイッチのdpidを格納
				@next[ip] = dpid
				changed
				notify_observers self
			end
			if @init
				@init = false
				update_graph
			end
		end
	end

	def checkMAC(ip,mac)
		return (@hostMAC[ip].to_s == mac.to_s)
	end

	def get_switchlist
		return @ports
	end

	def set_switchlist(dpid,list)
#		@switch[dpid] = list
	end

	def getDest(dstIP)
		if @next.key?(dstIP)
			return @next[dstIP]
		else
			return -1
		end
	end

	def getNext(now,dstSwitch)
		if now==dstSwitch
			return -1
		elsif @route.key?(now)
			if @route[now].key?(dstSwitch)
				return @route[now][dstSwitch]#[0]
			end
		end
		return -1
	end

	def getPort(now,dst)
		if @fdb.key?(now)
			if @fdb[now].key?(dst)
				return @fdb[now][dst]
			end
		end
		return -1
	end

	def update_graph
#p "------update------"
		graph = Graph.new
		@index.clear
		@ports.each{|dpid,port|
			@index[dpid] = graph.add_vertex( dpid )
		}
		for each in @links do
			i_a, i_b = @index[each.dpid_a], @index[each.dpid_b]
			if (i_a!=nil)&&(i_b!=nil)#&&(@switch.length>0)
				graph.connect(i_a, i_b, 1.0)
			end
		end
		run_dijkstra(graph)
	end

	def run_dijkstra(graph)
		@index.each_value{|val|
			finder = ShortestPathFinder.new( graph ).traverse(val)
			graph.vertices.each {|v|
				idx = finder.shortest_path_to(v.id)[0]
				if idx!=nil
					path = graph.vertices[idx].data
				else
					path = -1
				end
				setPath(graph.vertices[val].data, v.data, path)
			}
		}
	end

	def setPath(src, dst, path)
=begin
p src.to_s
p dst.to_s
p path
=end
		@route[src][dst] = path
	end

  private

  def maybe_add_link(link)
    fail 'The link already exists.' if @links.include?(link)
    @links << link
		@fdb[link.dpid_b][link.dpid_a] = link.port_b
#p "add link: " + link.dpid_a.to_s
#p "add link: " + link.dpid_b.to_hex.to_s + " and " + link.dpid_a.to_hex.to_s + " by " + link.port_b.to_s
		update_graph
#    @links.sort!
  end

  def delete_link_by(port)
    @links.each do |each|
      if each.has?(port.dpid, port.number)
        changed
        @links -= [each]
      end
    end
    notify_observers self
  end

	def is_all_zero_addr ip
		bit = ip.split(".")
		if (bit[0].to_i == 0)&&(bit[1].to_i == 0)&&(bit[2].to_i == 0)&&(bit[3].to_i == 0)
			return true
		else
			return false
		end
	end


	def is_broadcast ip
		bit = ip.split(".")
		if (bit[0].to_i == 255)&&(bit[1].to_i == 255)&&(bit[2].to_i == 255)&&(bit[3].to_i == 255) 
			return true
		else
			return false
		end
	end
end

### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
