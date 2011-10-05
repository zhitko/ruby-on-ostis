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

class ScMemoryException < RuntimeError
  def message; "Sc memory Exception" end
end

class IncompatibleScTypes < ScMemoryException
  def initialize element = nil, type=nil
    @element, @type = element, type
    super()
  end
  def message; "Incompatible sc-types (#@type||'') for sc-element (#@element||'')" end
end

class ScElementCreateException < ScMemoryException
  def message; "Fail during sc element building" end
end


=begin
puts "Yoyoyo"
raise IncompatibleScTypes.new(5, 4), "Tototo"
puts "Nonono"
rescue IncompatibleScTypes => e
  puts e.backtrace
=end