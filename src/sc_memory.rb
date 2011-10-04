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

require 'Singleton'
require 'sc_elements'
require 'sc_errors'

module Sc

  # Class implements search results in memory
  # It delegate search methods for functional style programming
  # realized in method_missing
  class MemResults < Array
    # Initialize method may get memory class or not
    def initialize _data = [], _mem=nil
      _data.each{|x| self << x}
      @mem = _mem || Sc::ScMemory.instance
    end

    # Method delegate unknown methods to ScMemory object if it respond it
    # If method (_meth) get params (_prms) simply delegate to memory object
    # If method hasn't params call this method in cycle with currents elements as input params
    def method_missing (_meth, *_prms)
      # Raise error if sc-memory object don't know called method
      raise ScMemoryException unless @mem.public_method_defined? _meth
      # create new result object
      res = MemResults.new
      # Next, if method get some params then simple delegate to memory
      # otherwise call method several times and give to it each of previous results
      if _prms.empty?
        self.each{ |x|
          res << @mem.send(_meth, *x).to_a
        }
      else
        res << @mem.send(_meth, *_prms).to_a
      end
      # return results
      res
    end
  end

  # Class ScMemory hold and manage sc-elements
  # Class is singleton
  # TODO: in future needs to make this class as interface or proxy
  class ScMemory
    include Singleton

    # Hash map with all elements holds in memory
    # link ID with ScElement
    attr_reader :mem

    # Initialize memory object
    def initialize
      @mem = Hash.new
      @arcs = Hash.new
      updateMemClass
    end

    # This method update instance methods to support functional style programming
    # It's mean some methods should be return a object of MemResult's class, to alloy
    # programmers write several methods in line
    # TODO: Do it cool (update memory methods)
    def updateMemClass
      (MODIFIED_METHODS).each{ |method|
        #puts method
      }
    end

    private :updateMemClass
    # List of memory methods witch shouldn't be updated
    MODIFIED_METHODS = [:add_elements, :add,
    :find_el_idtf, :find_el_uri,
    :create_el, :create_el_uri, :create_arc_uri,
    :gen3_f_a_f]

    # Method to add ScElements to memory
    # Input:
    # 1. els - lists of ScElements
    # Some phase in russian:
    #* получение элемента по его идентификатору @mem[id]
    #* поиск элементов по дуге @mem[id].beg @mem[id].end
    #* поиск входящих дуг в узел @arcs[id][:to], выходящих дуг @arcs[id][:from]
    #* удаление узла @mem[id].remove, @arcs[id][:from]... получить входящие и выходящие дуги и так же удалить (рекурсия)
    #* для удаления дуги получаем из хэша @mem (удаляем) ее начальный и конечный элемент и удаляем ее вхождение в хэше @arcs
    def add_elements(*els)
      added = []
      els.flatten.each{|x|
        next unless (x.class.ancestors - x.class.included_modules).include?(Sc::ScElement)
        next if @mem.include? x.id
        next if x.deleted
        @mem[x.id] = x
        if x.class == Sc::ScArc
          @arcs[x.beg.id] = {:to => [], :from => []} unless @arcs.key? x.beg.id
          @arcs[x.end.id] = {:to => [], :from => []} unless @arcs.key? x.end.id
          @arcs[x.beg.id][:from] << x.id
          @arcs[x.end.id][:to] << x.id
        end
        added << x.id
      }
      added
    end

    alias << add_elements
    alias add add_elements

    # Method to delete sc-elements
    # Input:
    # 1. _ids - list of IDs of ScElements
    def erase_el(*_ids)
      _ids.flatten.each{ |id|
        next unless @mem.key? id
        el = @mem.delete(id)
        el.del
        if el.class == Sc::ScArc
          if @arcs.key? el.beg.id
            @arcs[el.beg.id][:from] -= [id]
            @arcs.delete el.beg.id if @arcs[el.beg.id][:from].size == 0 and @arcs[el.beg.id][:to].size == 0
          end
          if @arcs.key? el.end.id
            @arcs[el.end.id][:to] -= [id]
            @arcs.delete el.end.id if @arcs[el.end.id][:from].size == 0 and @arcs[el.end.id][:to].size == 0
          end
        end

        return self unless @arcs.key? id
        arcs = @arcs.delete id
        arcs = arcs[:from] + arcs[:to]
        arcs.each { |x|
          erase_el(x)
        }
        self
      }
    end

    alias del erase_el

    # Method to clear all memory
    def mem_clear
      @arcs.clear
      @mem.each {|key, x|
        x.del
      }
      @mem.clear
      self
    end

    # Is memory empty?
    def mem_empty?
      @arcs.empty? and @mem.empty?
    end

    # Is memory have a sc-element with current id
    def mem_include? id
      @mem.key? id
    end

    alias mem_has? mem_include?


    # =Search sc-frames functions=

    # Method to search element by its string identifier
    # TODO: think and do search by idtf (last part of URI)
    def find_el_idtf(idtf)
      #@last =
    end

    # Method to search element by its URI
    def find_el_uri(uri)
      x = Sc::ScElement.new(uri.to_s).id
      add x unless mem_has? x.id
      x.id
    end
    
    # =Generate sc-frames functions=

    # Method to create new ScNode
    # Input:
    # 1. _types - list of sc-types
    def create_el(*_types)
      add_elements(Sc::ScNode.new(_types.flatten))
    end

    # Method to create new Node by URI
    # Input:
    # 1. _uri - String URI
    # 2. _types - list of sc-types
    def create_el_uri(_uri, *_types)
      add_elements(Sc::ScNode.new(_uri, _types.flatten))
    end

    # Method to generate arc between two sc-elements and set URI to arc
    # Input:
    # 1. _uri - String URI of generated arc
    # 2. _el1id - first element ID
    # 3. _types - list of sc-types of arc
    # 4. _el3id - second element ID
    def create_arc_uri(_uri, _el1id, _el3id, *_types)
      add_elements(Sc::ScArc.new(_uri, _el1id, _el3id, _types.flatten))
    end

    # Method to generate arc between two sc-elements
    # Input:
    # 1. _el1id - first element ID
    # 2. _types - list of sc-types of arc
    # 3. _el3id - second element ID
    def gen3_f_a_f(_el1id, _types, _el3id)
      add_elements(Sc::ScArc.new(@mem[_el1id], @mem[_el3id], _types.flatten))
    end
    
    # =Functions for work to load and dump data to files=

    # Method to load sc-frame from local file
    # TODO: do it
    def load_file(path)
      
    end
    
    def dump_file(frame, path)
      
    end 
  end
end