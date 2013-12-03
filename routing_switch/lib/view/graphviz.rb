# -*- coding: utf-8 -*-
$LOAD_PATH.unshift File.expand_path(File.join File.dirname(__FILE__), 'lib')

require 'graphviz'
#require '/home/s-nakamr/ruby_topology_neo/lib/dijkstra'
require 'dijkstra'

module View
  #
  # Topology controller's GUI (graphviz).
  #
  class Graphviz
    def initialize(output = './topology.png')
      @nodes = {}
      @output = File.expand_path(output)
			@switch = []
    end

    def update(topology)
#			@graph = Graph.new
      @graphviz = GraphViz.new(:G, use: 'neato', overlap: false, splines: true)
      @nodes.clear
      add_nodes(topology)
      add_edges(topology)
      @graphviz.output(png: @output)
    end

    private

    def add_nodes(topology)
#p "000000000000000000000000000000"
      topology.each_switch do |dpid, ports|
#p "drawing switch***********************:"
        @nodes[dpid] = @graphviz.add_nodes(dpid.to_hex, 'shape' => 'box')
			end
      topology.each_host do |host, ports|
#p "drawing host***********************:"
        @nodes[host] = @graphviz.add_nodes(host, 'shape' => 'oval')
      end
    end

    def add_edges(topology)
      topology.each_link do |each|
        node_a, node_b = @nodes[each.dpid_a], @nodes[each.dpid_b]
        @graphviz.add_edges node_a, node_b if node_a && node_b
      end
    end
  end
end

### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
