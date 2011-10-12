# -*- coding: utf-8 -*-

# This source file is part of OSTIS (Open Semantic Technology for Intelligent Systems)
# For the latest info, see http://www.ostis.net
#
# Author::    Vladimir Zhitko  (mailto:zhitko.vladimir@gmail.com)
# Date::      08.10.2011
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
require 'sc_memory'

require 'Sigleton'

module Sc

  # Abstract factory to build frames
  module AbstractFrameFactory
    # Method witch create in frame class @@memory var
    def self.included c
      c.class_eval %Q{
      def create(*prms)
        frame = super(*prms)
        frame.class.class_variable_set(:@@memory,self.memory)
        frame
      end
                   }
    end

    # Method to setup memory object
    def memory
      raise NotImplementedError, "You should implement this method"
    end

    # Method to create frame object
    def create
      raise NotImplementedError, "You should implement this method"
    end
  end

  # Abstract frame
  module AbstractFrame
    # Method witch reimplemented public_method_defined?
    # to make possible to delegate methods it to memory object
    def self.included c
      c.class_eval %Q{
      def self.public_method_defined? _meth
        r = super _meth
        r = @@memory.class.public_method_defined? _meth if r==false
        r
      end
                   }
    end

    # Method to delegate some methods to memory, and
    # save elements from generate methods
    # Additional: memory return specific result class object witch
    # delegate functions to memory, this method make this object
    # delegate methods to this object
    def method_missing (_meth, *_prms, &_block)
      raise ScMemoryException unless @@memory.class.public_method_defined? _meth
      r = @@memory.send(_meth, *_prms, &_block)
      watch r unless _meth.match(/^(gen.*|create.*)/).nil?
      forget r unless _meth.match(/^(del.*|erase.*)/).nil?
      # MemResults must delegate methods to frame class
      r.mem = self
      r
    end

    # Method to remember elements witch created in this frame
    def watch *els
      @@usedEls ||= {}
      @ownEls ||= []
      els.flatten.each{ |x|
        next if @ownEls.include? x
        @@usedEls[x] ||= 0
        @@usedEls[x] += 1
        @ownEls << x
      }
    end
    alias spy watch

    # Method to remove element from current frame, also called
    # after remove methods
    def remove_from_frame *els
      @@usedEls ||= {}
      @ownEls ||= []
      els.flatten.each{|x|
        @ownEls.delete x
        @@usedEls[x] -= 1 if @@usedEls.key? x
      }
    end
    alias forget remove_from_frame

    # Method to clear in memory (delete from memory) all element from
    # this frame, if they aren't in another frame
    def clear
      @ownEls.each{|x|
        if @@usedEls.key? x
          @@usedEls[x] -= 1
          next if @@usedEls[x] > 0
        end
        @@memory.del x
      }
      @ownEls.clear
    end

    # Method to save changes (or create new offline storage) with all
    # elements in this frame
    def dump
      raise NotImplementedError, "You should implement this method"
    end
    alias save dump
  end
end