# -*- coding: utf-8 -*-

$:.unshift(File.dirname(__FILE__)) unless $:.include? File.dirname(__FILE__)
require 'sc_memory'

module Sc
  
  class ScsFrame
    attr_reader :nodes, :arcs, :keynodes
    
    def initialize
      @nodes = []
      @arcs = []
      @keynodes = []
    end
    
    #def to_s
    #  "Sc frame with #{@nodes.length} nodes (with #{@keynodes.length} keynodes), #{@arcs.length} arcs"
    #end
    
    def inspect
      "#{self.class}:
      #{@nodes.length} nodes #@nodes,
      with #{@keynodes.length} keynodes #@keynodes,
      #{@arcs.length} arcs #@arcs"
    end
    
  end
end


=begin
puts a = Scs::ScsFrame.new
a.create_el(:sc_const, :sc_group)
puts a.create_el(:sc_const, :sc_atom).name
puts a.inspect
  
=end