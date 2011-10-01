# -*- coding: utf-8 -*-

$:.unshift(File.dirname(__FILE__)) unless $:.include? File.dirname(__FILE__)

require 'Singleton'
require 'sc_elements'
require 'sc_errors'

module Sc
  
  class ScMemory
    include Singleton

    attr_reader :mem

    def initialize
      @mem = Hash.new
      @arcs = Hash.new
      @last = []
      updateMemClass
    end

    def [](x)
      @last[x]
    end

    def updateMemClass
      (self.class.public_instance_methods - NOT_MODIFIED_METHODS - Sc::ScMemory.superclass.methods).each{ |method|
        #puts method
      }
    end

    private :updateMemClass
    NOT_MODIFIED_METHODS = [:initialize, :each, :[], :erase_el, :del, :mem_clear,
    :mem_empty?, :mem_has?, :mem_include?, :find_el_idtf, :find_el_uri, :load_file,
    :dump_file, :<<]

=begin
* получение элемента по его идентификатору @mem[id]
* поиск элементов по дуге @mem[id].beg @mem[id].end
* поиск входящих дуг в узел @arcs[id][:to], выходящих дуг @arcs[id][:from]
* удаление узла @mem[id].remove, @arcs[id][:from]... получить входящие и выходящие дуги и так же удалить (рекурсия)
* для удаления дуги получаем из хэша @mem (удаляем) ее начальный и конечный элемент и удаляем ее вхождение в хэше @arcs
=end
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
    
    def erase_el(id)
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
    end

    alias del erase_el

    def mem_clear
      @arcs.clear
      @mem.each {|key, x|
        x.del
      }
      @mem.clear
      self
    end

    def mem_empty?
      @arcs.empty? and @mem.empty?
    end

    def mem_include? id
      @mem.key? id
    end

    alias mem_has? mem_include?

# Search sc-frames functions
    
    def find_el_idtf(idtf)
      #@last =
    end

    def find_el_uri(uri)
      x = Sc::ScElement.new(uri).id
      add x unless mem_has? x.id
      x.id
    end
    
    #def create_iterator(constr)
    #
    #end
    #
    #def sc_constraint_new(constr_uid, *arguments)
    #
    #end
    #
    #def search_one_shot(const)
    #
    #end
    
# Generate sc-frames functions

    def create_el(*_types)
      add_elements(Sc::ScNode.new(_types.flatten))
    end
    
    def create_el_uri(_uri, *_types)
      add_elements(Sc::ScNode.new(_uri, _types.flatten))
    end
    
    def gen3_f_a_f(_el1id, _types, _el3id)
      add_elements(Sc::ScArc.new(@mem[_el1id], @mem[_el3id], _types))
    end
    
    def create_arc_uri(_uri, _el1id, _el3id, *_types)
      add_elements(Sc::ScArc.new(_uri, _el1id, _el3id, _types.flatten))
    end
    
# Functions for work to load and dump data to files
    
    def load_file(path)
      
    end
    
    def dump_file(path)
      
    end 
  end

  class MemResults < Array
    def initialize _mem
      @mem = _mem
    end

    def method_missing (_meth, *_prms)
      #if _prms.empty?
      #  return @mem. if @mem.respond_to(_meth)
      #raise RuntimeError
    end
  end
end