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

require 'sc_errors'

module Sc

  # Different types of sc-elements
  SC_TYPES = [:sc_node, :sc_arc]
  SC_CONST = [:sc_const, :sc_var, :sc_meta]
  SC_NODE_TYPES = [:sc_asymmetry, :sc_atom, :sc_attribute, :sc_group, :sc_nopredmet,
    :sc_not_define, :sc_predmet, :sc_relation, :sc_symmetry]
  SC_ARC_TYPES = [:sc_orient, :sc_fuz, :sc_temp, :sc_neg, :sc_pos]
  SC_META_TYPES = [:sc_link]

  # Class implements basic sc-element
  class ScElement
    attr_reader :id, :types, :uri, :content, :deleted

    # Redefined class method new to hide in it abstract method.
    # First argument may be a URI. If exits esc-element with the same
    # URI method return it, else create new one.
    def self.new *_prms
      uri = (_prms.size > 0 and _prms[0].instance_of? String) ? _prms[0].to_sym : nil
      @@uri2el ||= Hash.new
      # URI was given
      unless uri.nil?
        unless @@uri2el.key? uri
          @@uri2el[uri] = super(*_prms)
        end
        return @@uri2el[uri].proc(*_prms)
      end
      # URI is nill
      prms = _prms.size==0 ? [nil] : (_prms[0].nil? ? _prms : ([nil]+_prms))
      super(*prms)
    end

    # Method call to update current element
    # Input: should receive the same parameters as initialize method
    # Output: should be return self object
    def proc(*prms)
      self
    end

    # Basic initialize of sc-elements
    # *Important*: first parameter in redefined initialize methods
    # should be a URI, but in call it may be not present
    def initialize _uri
      @id = object_id 
      @types = []
      @uri = _uri
      @content = nil
      @deleted = false
      @alloy_types = []
    end

    # Basic string representation of sc-element
    def to_s
      "#{self.class} #{@uri ? @uri : @id}"
    end

    # Basic string representation of sc-element for developers
    def inspect
      "#{self.class} #@uri #@id: #@types"
    end

    # Set content for sc-element
    def content=(_cont)
      @content = Sc::Content.new(_cont)
    end

    alias set_content content=

    # Set delete flag to current sc-element
    def delete(_del=true)
      @deleted = _del
      @@uri2el.delete @uri unless @uri.nil?
    end

    alias del delete

    # Set types for current sc-element
    # Types checking by using @alloy_types var
    def set_types(*_types)
      _types.flatten!
      _types.each { |x|
        @types << x if @alloy_types.include? x
      }
      @types.uniq!
      self
    end

    # Logic method to check current sc-elements for some types
    def types?(*_types)
      _types.flatten.each{ |x|
        return false unless @types.include? x
      }
      true
    end
    
  end

  # Class implements sc-node
  class ScNode < ScElement

    # Initialize method
    # Input:
    # 1. URI (optional)
    # 2. _types - list of sc-types
    def initialize(_uri, *_types)
      super(_uri)
      @alloy_types += SC_CONST + SC_NODE_TYPES + [:sc_node]
      set_types(_types + [:sc_node])
    end

    # Method reset node types if its changed
    def proc(_uri,*_types)
      set_types _types
      self
    end
  end

  # Class implements sc-arc
  class ScArc < ScElement
    # @els is input and output elements of current acr
    attr_reader :els

    # Initialize method
    # Input:
    # 1. Uri (Optional)
    # 2. _beg - object of first element
    # 3. _end - object of second element
    # 4. _types - list of sc-types
    def initialize(_uri, _beg, _end, *_types)
      super(_uri)
      raise ScElementCreateException, 'Error: beg/end of arc can not be nil' if _beg.nil? or _end.nil?
      raise ScMemoryException, 'Error: beg/end of arc
should be a ScElement object' unless _beg.class <= Sc::ScElement and _end.class <= Sc::ScElement
      @els = [] << _beg << _end
      @alloy_types += SC_CONST + SC_ARC_TYPES + [:sc_arc]
      set_types(_types + [:sc_arc])
    end

    def proc(_uri, _beg, _end, *_types)
      raise ScElementCreateException, 'Error: beg/end of arc can not be nil' if _beg.nil? or _end.nil?
      raise ScMemoryException, 'Error: beg/end of arc
should be a ScElement object' unless _beg.class <= Sc::ScElement and _end.class <= Sc::ScElement
      @els = [] << _beg << _end
      set_types _types
      self
    end

    # Get first element of arc
    def beg; @els[0]; end
    # Set first element of arc
    def beg=(x); @els[0]=x if x.class <= Sc::ScElement; end
    # Get second element of arc
    def end; @els[1]; end
    # Set second element of arc
    def end=(x); @els[1]=x if x.class <= Sc::ScElement; end

    # Redefine string representation of sc-arc
    def to_s
      "#{self.class} #{@uri || @id}: <#{@els.join(@types.include?(:sc_orient)?' => ':' == ')}>"
    end

    # Redefine string representation of sc-arc for developers
    def inspect
      "#{self.class} ##@id #{@uri || ''} #@types:\n\t#@els"
    end
  end

  # Content types
  SC_CONTENT_TYPES = [:sc_text, :sc_digits, :sc_image, :sc_sound, :sc_video]
  CONTENT_CLASSES = {String => :sc_text, Fixnum => :sc_digits}

  # Class implements basic sc-element
  # TODO: finish content class
  class Content
    attr_reader :type, :data
    def initialize cont
      @type = Sc::CONTENT_CLASSES[cont.class] || :sc_text
      @data = @type == :sc_text ? cont.to_s : cont
    end
  end
  
end