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
      raise ScMemoryException unless @mem.class.public_method_defined? _meth
      # create new result object
      res = MemResults.new
      res if self.empty?
      # Next, if method get some params then simple delegate to memory
      # otherwise call method several times and give to it each of previous results
      if _prms.empty?
        if self[0].instance_of?(Array)
          self.each{ |x|
            res << @mem.send(_meth, *x).to_a
          }
        else
          res << @mem.send(_meth, *(self.to_a)).to_a
        end
      else
        res << @mem.send(_meth, *_prms).to_a
      end
      # return results
      res
    end
    
    METH = [:collect, :map, :select, :reject, :inject]
    def self.updateMemClass
      (METH).each{ |m|
        self.class_eval %Q{
        def #{m.to_s}(*args, &block)
          if self[0].instance_of?(Array)
            MemResults.new super(*args, &block)
          else
            MemResults.new [self.to_a].#{m.to_s}(*args, &block)
          end
        end
        }
      }
    end
    updateMemClass
    
    def select(*args, &block)
      if self[0].instance_of?(Array)
        MemResults.new super(*args, &block)
      else
        MemResults.new [self.to_a].select(*args, &block)
      end
    end
  end

  # Class ScMemory hold and manage sc-elements
  # Class is singleton
  # TODO: in future needs to make this class as interface or proxy
  class ScMemory
    include Singleton
    
    # List of memory methods witch shouldn't be updated
    @@modified_methods = []
    
    # Initialize memory object
    def initialize
      # Hash map with all elements holds in memory
      # link ID with ScElement
      @mem = Hash.new
      # HashMap link ID with lists of output and input arcs
      # looks like this:
      # @arcs[elementID][:to][arcID] - input arcs
      # or
      # @arcs[elementID][:from][arcID] - output arcs
      @arcs = Hash.new
    end

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
        added << x.id
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
      }
      added
    end
    @@modified_methods << :add_elements

    alias << add_elements
    alias add add_elements
    @@modified_methods << :add

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

    # Method to setup content to sc-element
    # Input:
    # 1. _id - ID of sc-element to setup content
    # 2. _content - object witch is a content
    # Output:
    # sc_type of current content
    def set_content(_id, _content)
      return nil unless @mem.key? _id
      @mem[_id].set_content _content
    end

    # Method to get content
    # Return content data
    def get_content _id
      return nil unless @mem.key? _id
      return nil if @mem[_id].content.nil?
      @mem[_id].content.data
    end

    # Method to get content
    # Return content data
    def get_content_type _id
      return nil unless @mem.key? _id
      return nil if @mem[_id].content.nil?
      @mem[_id].content.type
    end

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
    #@@modified_methods << :find_el_uri
    
    # =Generate sc-frames functions=

    # Method to create new ScNode
    # Input:
    # 1. _types - list of sc-types
    def create_el(*_types)
      add_elements(Sc::ScNode.new(_types.flatten))[0]
    end
    #@@modified_methods << :create_el

    # Method to create new Node by URI
    # Input:
    # 1. _uri - String URI
    # 2. _types - list of sc-types
    def create_el_uri(_uri, *_types)
      add_elements(Sc::ScNode.new(_uri, _types.flatten))[0]
    end
    #@@modified_methods << :create_el_uri

    # Method to generate arc between two sc-elements and set URI to arc
    # Input:
    # 1. _uri - String URI of generated arc
    # 2. _el1id - first element ID
    # 3. _types - list of sc-types of arc
    # 4. _el3id - second element ID
    def create_arc_uri(_uri, _el1id, _el3id, *_types)
      add_elements(Sc::ScArc.new(_uri, @mem[_el1id], @mem[_el3id], _types.flatten))[0]
    end
    #@@modified_methods << :create_arc_uri

    # Method to generate arc between two sc-elements
    # Input:
    # 1. _el1id - first element ID
    # 2. _types - list of sc-types of arc
    # 3. _el3id - second element ID
    def gen3_f_a_f(_el1id, _types, _el3id)
      raise IncompatibleScTypes, "this element can't be an node" if _types.include? :sc_node
      [_el1id, create_arc_uri(nil, _el1id, _el3id, _types.flatten), _el3id].flatten
    end
    @@modified_methods << :gen3_f_a_f
    
    def gen3_f_a_a(_el1id, _types2, _types3)
      raise IncompatibleScTypes, "this element can't be an arc" if _types3.include? :sc_arc
      _el3id =  create_el(_types3.flatten)
      gen3_f_a_f(_el1id, _types2, _el3id)
    end                         
    @@modified_methods << :gen3_f_a_a
    
    def gen3_a_a_f(_types1, _types2, _el3id)
      raise IncompatibleScTypes, "this element can't be an arc" if _types1.include? :sc_arc
      _el1id = create_el(_types1.flatten)
      gen3_f_a_f(_el1id,_types2,_el3id)
    end                 
    @@modified_methods << :gen3_a_a_f
    
    def gen3_a_a_a(_types1, _types2, _types3)
      raise IncompatibleScTypes, "this element can't be an arc" if _types1.include? :sc_arc
      _el1id = create_el(_types1.flatten)
      gen3_f_a_a(_el1id, _types2, _types3)
    end
    @@modified_methods << :gen3_a_a_a
    
    def gen5_f_a_f_a_f(_el1id, _types2, _el3id, _types4, _el5id)
      r1 = gen3_f_a_f(_el1id, _types2, _el3id)
      r2 = gen3_f_a_f(_el5id, _types4, r1[1]) 
      [r1, r2[1], r2[0]].flatten
    end
    @@modified_methods << :gen5_f_a_f_a_f
    
    def gen5_f_a_a_a_f(_el1id, _types2, _types3, _types4, _el5id)
      _el3id = create_el(_types3.flatten)
      gen5_f_a_f_a_f(_el1id, _types2, _el3id, _types4, _el5id)
    end
    @@modified_methods << :gen5_f_a_a_a_f
    
    def gen5_f_a_f_a_a(_el1id, _types2, _el3id, _types4, _types5)
      _el5id = create_el(_types5.flatten)
      gen5_f_a_f_a_f(_el1id, _types2, _el3id, _types4, _el5id)
    end
    @@modified_methods << :gen5_f_a_f_a_a
    
    def gen5_a_a_f_a_f(_types1, _types2, _el3id, _types4, _el5id)
      _el1id = create_el(_types1.flatten)
      gen5_f_a_f_a_f(_el1id, _types2, _el3id, _types4, _el5id)
    end
    @@modified_methods << :gen5_a_a_f_a_f
    
    def gen5_a_a_a_a_f(_types1, _types2, _types3, _types4, _el5id)
      _el3id = create_el(_types3.flatten)
      _el1id = create_el(_types1.flatten) 
      gen5_f_a_f_a_f(_el1id, _types2, _el3id, _types4, _el5id)
    end
    @@modified_methods << :gen5_a_a_a_a_f
    
    def gen5_f_a_a_a_a(_el1id, _types2, _types3, _types4, _types5)
      _el3id = create_el(_types3.flatten)
      _el5id = create_el(_types5.flatten)
      gen5_f_a_f_a_f(_el1id, _types2, _el3id, _types4, _el5id)
    end
    @@modified_methods << :gen5_f_a_a_a_a
    
    def gen5_a_a_f_a_a(_types1, _types2, _el3id, _types4, _types5)
      _el1id = create_el(_types1.flatten)
      _el5id = create_el(_types5.flatten)
      gen5_f_a_f_a_f(_el1id, _types2, _el3id, _types4, _el5id)
    end
    @@modified_methods << :gen5_a_a_f_a_a
    
    def gen5_a_a_a_a_a(_types1, _types2, _types3, _types4, _types5)
      _el1id = create_el(_types1.flatten)
      _el3id = create_el(_types3.flatten)
      _el5id = create_el(_types5.flatten)
      gen5_f_a_f_a_f(_el1id, _types2, _el3id, _types4, _el5id)
    end
    @@modified_methods << :gen5_a_a_a_a_a
    
    # =Search functions=
    
    def search3_f_a_f(_el1id, _types2, _el3id)
      (@arcs[_el1id][:from] & @arcs[_el3id][:to]).inject([]){|r, arc|
        r << [_el1id, arc, _el3id] if @mem[arc].types? _types2
      }
    end
    @@modified_methods << :search3_f_a_f
    
    def search3_f_a_a(_el1id, _types2, _types3)
      @arcs[_el1id][:from].inject([]){|res, arc|
        e3 = @mem[arc].end
        res << [_el1id, arc, e3.id] if @mem[arc].types? _types2 and e3.types? _types3 
      }
    end
    @@modified_methods << :search3_f_a_a
    
    def search3_a_a_f(_types1, _types2, _el3id)          
      @arcs[_el3id][:to].inject([]){|res, arc|
        e1 = @mem[arc].beg
        res << [e1.id, arc, _el3id] if @mem[arc].types? _types2 and e1.types? _types1 
      }
    end
    @@modified_methods << :search3_a_a_f
    
    def search3_a_a_a(_types1, _types2, _types3)
      @arcs.keys.inject([]){|r1,x1|
        next r1 unless @mem[x1].types? _types1
        r1 += @arcs[x1][:from].inject([]){|r2,x2|
          next r2 unless @mem[x2].types? _types2 and @mem[x2].end.types? _types3
          r2 << [x1, x2, @mem[x2].end.id]
        }
      }
    end
    @@modified_methods << :search3_a_a_a
    
    def search5_a_a_a_a_a(_types1,_types2,_types3,_types4,_types5)
      # iteration by 5-th element
      @arcs.keys.inject([]){|r1, el|
        next r1 unless @mem[el].types? _types5
        # iteration by 4-th element
        r = @arcs[el][:from].inject([]){|r2,x|
          next r2 unless @mem[x].types?(_types4) and @mem[x].end.types?(_types2)
          r2 << [@mem[x].end.id, x, el]
        }
        next r1 if r.nil? or r.empty?
        # iteration by 2-nd element
        r =  r.inject([]){|r3,x|
          next r3 unless @mem[x[0]].end.types?(_types3) and @mem[x[0]].beg.types?(_types1)
          r3 << [@mem[x[0]].beg.id, x[0], @mem[x[0]].end.id, x[1], x[2]]
        }
        next r1 if r.nil? or r.empty?
        r1 += r
      }
    end
    @@modified_methods << :search5_a_a_a_a_a
    
    def search5_f_a_a_a_a(_el1id,_types2,_types3,_types4,_types5)
      @arcs[_el1id][:from].inject([]){|r1,x1|
        next r1 unless @mem[x1].types? _types2 and @mem[x1].end.types? _types3
        next r1 unless @arcs.key? x1
        r = @arcs[x1][:to].inject([]){|r2,x2|
          next r2 unless @mem[x2].types? _types4 and @mem[x2].beg.types? _types5
          r2 << [_el1id, x1, @mem[x1].end.id, x2, @mem[x2].beg.id]
        }
        r1 += r
      }
    end
    @@modified_methods << :search5_f_a_a_a_a
    
    def search5_a_a_f_a_a(_types1,_types2,_el3id,_types4,_types5)
      @arcs[_el3id][:to].inject([]){|r1,x1|
        next r1 unless @mem[x1].types? _types2 and @mem[x1].beg.types? _types1
        next r1 unless @arcs.key? x1
        r = @arcs[x1][:to].inject([]){|r2,x2|
          next r2 unless @mem[x2].types? _types4 and @mem[x2].beg.types? _types5
          r2 << [@mem[x1].beg.id, x1, _el3id, x2, @mem[x2].beg.id]
        }
        r1 += r
      }
    end
    @@modified_methods << :search5_a_a_f_a_a
    
    def search5_a_a_a_a_f(_types1,_types2,_types3,_types4,_el5id)
      @arcs[_el5id][:from].inject([]){|r1,x1|
        next r1 unless @mem[x1].types? _types4 and @mem[x1].end.types? _types2
        next r1 unless @mem[x1].end.beg.types? _types1 and @mem[x1].end.end.types? _types3
        r1 << [@mem[x1].end.beg.id, @mem[x1].end.id, @mem[x1].end.end.id, x1, _el5id]
      }
    end
    @@modified_methods << :search5_a_a_a_a_f
    
    def search5_f_a_f_a_a(_el1id,_types2,_el3id,_types4,_types5)
      @arcs[_el1id][:from].inject([]){|r1,x1|
        next r1 unless @mem[x1].end.id == _el3id and @mem[x1].types? _types2
        next r1 unless @arcs.key? x1
        r1 += @arcs[x1][:to].inject([]){|r2,x2|
          next r2 unless @mem[x2].types? _types4 and @mem[x2].beg.types? _types5
          r2 << [_el1id, x1, _el3id, x2, @mem[x2].beg.id]
        }
      }
    end
    @@modified_methods << :search5_f_a_f_a_a
    
    def search5_f_a_a_a_f(_el1id,_types2,_types3,_types4,_el5id)
      @arcs[_el5id][:from].inject([]){|r1,x1|
        next r1 unless @mem[x1].types? _types4 and @mem[x1].end.types? _types2
        next r1 unless @arcs[_el1id][:from].include? @mem[x1].end.id and @mem[@mem[x1].end.id].end.types? _types3
        r1 << [_el1id, @mem[x1].end.id, @mem[@mem[x1].end.id].end.id, x1, _el5id]
      }
    end
    @@modified_methods << :search5_f_a_a_a_f
    
    def search5_a_a_f_a_f(_types1,_types2,_el3id,_types4,_el5id)
      @arcs[_el5id][:from].inject([]){|r1,x1|
        next r1 unless @mem[x1].types? _types4 and @mem[x1].end.types? _types2
        next r1 unless @arcs[_el3id][:to].include? @mem[x1].end.id and @mem[@mem[x1].end.id].beg.types? _types1
        r1 << [@mem[@mem[x1].end.id].beg.id, @mem[x1].end.id, _el3id, x1, _el5id]
      }
    end
    @@modified_methods << :search5_a_a_f_a_f
    
    def search5_f_a_f_a_f(_el1id,_types2,_el3id,_types4,_el5id)
      @arcs[_el5id][:from].inject([]){|r1,x1|
        next r1 unless @mem[x1].types? _types4 and @mem[x1].end.types? _types2
        next r1 unless @arcs[_el1id][:from].include? @mem[x1].end.id
        next r1 unless @arcs[_el3id][:to].include? @mem[x1].end.id
        r1 << [_el1id, @mem[x1].end.id, _el3id, x1, _el5id]
      }
    end
    @@modified_methods << :search5_f_a_f_a_f
        
    # This method update instance methods to support functional style programming
    # It's mean some methods should be return a object of MemResult's class, to alloy
    # programmers write several methods in line
    def self.updateMemClass
      (@@modified_methods).each{ |m|
        _m = '_' + m.to_s
        self.class_eval %Q{
        alias #{_m} #{m.to_s}
        def #{m.to_s}(*args, &block)
        MemResults.new(#{_m}(*args, &block).to_a)  
        end
        }
      }
    end
    updateMemClass
  end
end

=begin
tn = [:sc_node, :sc_const]
ta = [:sc_arc, :sc_const]
puts '*'*10 + 'Gen' + '*'*10
puts '< ' + (n1 = Sc::ScMemory.instance.create_el(tn)).to_s
puts '< ' + (n2 = Sc::ScMemory.instance.create_el(tn)).to_s
puts '< ' + (n3 = Sc::ScMemory.instance.create_el(tn)).to_s
puts '*'*10 + 'Gen3' + '*'*10
puts '< ' + Sc::ScMemory.instance.gen3_f_a_f(n1, ta, n2).inspect
puts '> ' + Sc::ScMemory.instance.search3_f_a_f(n1,ta,n2).inspect
puts '< ' + Sc::ScMemory.instance.gen3_f_a_a(n1, ta, tn).inspect
puts '> ' + Sc::ScMemory.instance.search3_f_a_a(n1,ta,tn).inspect
puts '< ' + Sc::ScMemory.instance.gen3_a_a_f(tn, ta, n2).inspect
puts '> ' + Sc::ScMemory.instance.search3_a_a_f(tn,ta,n2).inspect
puts '< ' + Sc::ScMemory.instance.gen3_a_a_a(tn,ta,tn).inspect
puts '> ' + Sc::ScMemory.instance.search3_a_a_a(tn,ta,tn).inspect
puts '*'*10 + 'Gen5' + '*'*10
puts '< ' + Sc::ScMemory.instance.gen5_a_a_a_a_a(tn,ta,tn,ta,tn).inspect
puts '> ' + Sc::ScMemory.instance.search5_a_a_a_a_a(tn,ta,tn,ta,tn).inspect
puts '< ' + Sc::ScMemory.instance.gen5_f_a_a_a_a(n1,ta,tn,ta,tn).inspect
puts '> ' + Sc::ScMemory.instance.search5_f_a_a_a_a(n1,ta,tn,ta,tn).inspect
puts '< ' + Sc::ScMemory.instance.gen5_a_a_f_a_a(tn,ta,n2,ta,tn).inspect
puts '< ' + Sc::ScMemory.instance.gen5_f_a_f_a_a(n1,ta,n2,ta,tn).inspect
puts '< ' + Sc::ScMemory.instance.gen5_a_a_a_a_f(tn,ta,tn,ta,n3).inspect
puts '< ' + Sc::ScMemory.instance.gen5_f_a_a_a_f(n1,ta,tn,ta,n3).inspect
puts '< ' + Sc::ScMemory.instance.gen5_a_a_f_a_f(tn,ta,n2,ta,n3).inspect
puts '< ' + Sc::ScMemory.instance.gen5_f_a_f_a_f(n1,ta,n2,ta,n3).inspect
=begin
=end