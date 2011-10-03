# -*- coding: utf-8 -*-

# This source file is part of OSTIS (Open Semantic Technology for Intelligent Systems)
# For the latest info, see http://www.ostis.net
#
# Author::    Vladimir Zhitko  (mailto:zhitko.vladimir@gmail.com)
# Date::      01.10.2011
# Copyright:: Copyright (c) 2011 OSTIS
# License::   GNU Lesser General Public License
#
# OSTIS is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# OSTIS is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with OSTIS.  If not, see <http://www.gnu.org/licenses/>.
#
# Modified::

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