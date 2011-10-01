# -*- coding: utf-8 -*-

$:.unshift(File.dirname(__FILE__)) unless $:.include? File.dirname(__FILE__)

module Sc
  
  class ScsFile
    attr_reader :name, :includes
    def initialize(name, *includes)
      @name = name
      @includes = []
      add_includes includes
    end
    
    def to_s
      "file:#@name with #{@nodes.length} nodes, #{@arcs.length} arcs and #{@includes.length} included scs files"
    end
    
    def inspect
      "file:#@name 
      #{@nodes.length} nodes #@nodes,
      #{@arcs.length} arcs #@arcs,
      #{@includes.length} included scs files #@includes"
    end
    
    def add_includes(*incs)
      incs.flatten.each { |x|
        @includes << x if x.class == String
      }
      @includes.uniq!
      self
    end
    
  end
end

=begin
s = Scs::ScsFile.new "MegaFile",['1a',[2,3]]
s.add_includes "1b", "2b", "3b"
s.add_includes ["1a", "2a", "3a"]
puts s
puts s.inspect
=end