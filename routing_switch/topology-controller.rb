# -*- coding: utf-8 -*-
$LOAD_PATH.unshift File.expand_path(File.join File.dirname(__FILE__), 'lib')

require 'rubygems'
require 'bundler/setup'

require 'command-line'
require 'topology'
require 'trema'
require 'trema-extensions/port'

require 'dijkstra'
#require 'dijkstraruby'

#
# This controller collects network topology information using LLDP.
#
class TopologyController < Controller
  MIN_INDEX = 250
  MAX_INDEX = 254
  periodic_timer_event :flood_lldp_frames, 1

  def start
		@fdbList = {}
    @command_line = CommandLine.new
    @command_line.parse(ARGV.dup)
    @topology = Topology.new(@command_line.view)
		@graph = Graph.new
  end

  def switch_ready(dpid)
    send_message dpid, FeaturesRequest.new
#		search_host(dpid)
  end

  def features_reply(dpid, features_reply)
    features_reply.physical_ports.select(&:up?).each do |each|
      @topology.add_port each
#p "features reply"
    end
  end

  def switch_disconnected(dpid)
    @topology.delete_switch dpid
#p "switch disconnected"
#		@topology.each_switch do |d, ports|
#			send_flow_mod_delete(d)
#		end
  end

  def port_status(dpid, port_status)
    updated_port = port_status.port
    return if updated_port.local?
    @topology.update_port updated_port
#send_flow_mod_delete(d)
#p "port status"
  end

  def packet_in(dpid, packet_in)
		if packet_in.arp_reply?
#			p "reply"
		end
		if packet_in.arp_request?
#			p "request"
		end

		if packet_in.ipv4?
			@topology.add_host(dpid, packet_in)
			init = @topology.checkMAC(packet_in.ipv4_saddr.to_s,packet_in.macsa)
			notzero = !is_all_zero_addr(packet_in.ipv4_saddr.to_s)
			if init&&notzero
				p "------------------------------"
				p "new packet from " + packet_in.ipv4_saddr.to_s
				p "------------------------------"
   			@topology.add_link_by dpid, packet_in
			end
			routing(dpid, packet_in)
		elsif packet_in.lldp?
	   	@topology.add_link_by dpid, packet_in
		end
  end

	def init_dijkstra
		#@finder = ShortestPathFinder.new( graph ).traverse(ids[0])
	end

  private
#-------------------------------------
	def routing(dpid, msg)
		if is_all_zero_addr(msg.ipv4_saddr.to_s)
			return
		end
		p "***" + dpid.to_hex.to_s + "***"
		port = -1
		ip = msg.ipv4_daddr.to_s
		#宛先IPアドレスに対する目的スイッチ(宛先ホストの隣接スイッチ)のdpidを取得する
		dst = @topology.getDest(ip)
		#返り値が0より大きければ宛先ホストの隣接スイッチが分かっているのでルーティング可能
		if dst > 0
			p "dest:" + dst.to_s
			if dpid.to_i==dst.to_i
				port = @topology.getPort(dpid,ip)
				p "hostport:" + port.to_s
			else
				#宛先ホストの隣接スイッチに対する最短経路より
				#現在のスイッチに隣接しているもののうち、次にパケットを送るべきスイッチを調べる
				nxt = @topology.getNext(dpid,dst)
				if nxt.to_i > 0
					p "next:" + nxt.to_s
					port = @topology.getPort(dpid,nxt)
					p "port:" + port.to_s
				end
			end
		end

		if port==-1
p "destintion isn't resistered"
			return
#			port = OFPP_FLOOD
		end
#		@fdbList[msg.macsa] = msg.in_port
#		port = @fdbList[msg.macda] ? @fdbList[msg.macda] : OFPP_FLOOD
	  send_packet_out(
		  dpid,
	  	:packet_in => msg,
		  :actions => [
				ActionSetDlSrc.new( "00:00:00:00:00:00" ),
#				ActionSetNwSrc.new( "0.0.0.0" ),
				Trema::SendOutPort.new(port)
			] )

		send_flow_mod_add(
			dpid,
			#1秒間使わなかったらflow_removerdが起こる
      :idle_timeout => 10,
    	:match => Match.new(
	              :nw_dst => msg.ipv4_daddr),
			:actions => Trema::SendOutPort.new(port) )

	end
#-------------------------------------

  def flood_lldp_frames
    @topology.each_switch do |dpid, ports|
      send_lldp dpid, ports
    end
  end

  def send_lldp(dpid, ports)
    ports.each do |each|
      port_number = each.number
      send_packet_out(
        dpid,
        actions: SendOutPort.new(port_number),
        data: lldp_binary_string(dpid, port_number)
      )
    end
  end

  def lldp_binary_string(dpid, port_number)
    destination_mac = @command_line.destination_mac
    if destination_mac
      Pio::Lldp.new(dpid: dpid,
                    port_number: port_number,
                    destination_mac: destination_mac.value).to_binary
    else
      Pio::Lldp.new(dpid: dpid, port_number: port_number).to_binary
    end
  end

#-------------------------------------------------------------------------------------------------
  def search_host dpid
    for i in MIN_INDEX..MAX_INDEX
      arp_req = create_arp_req(i)
      flood_arp(dpid, arp_req.to_binary)
    end
  end
#-------------------------------------------------------------------------------------------------
  def create_arp_req n
    ip = '192.168.0.' + n.to_s
    Pio::Arp::Request.new(
      :source_mac => '00:00:00:00:00:00',
      :sender_protocol_address => '0.0.0.0',
      :target_protocol_address => ip
    )
  end

  def flood_arp dpid,arp
    send_packet_out(
      dpid,
      :data => arp,
      :actions => Trema::SendOutPort.new( OFPP_FLOOD )
    )
  end
#-------------------------------------------------------------------------------------------------
	def is_all_zero_addr ip
		if ip==""
			return true
		end
		bit = ip.split(".")
		if (bit[0].to_i == 0)&&(bit[1].to_i == 0)&&(bit[2].to_i == 0)&&(bit[3].to_i == 0)
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
