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

unless $:.include? File.dirname(__FILE__)
  $:.unshift(File.dirname(__FILE__))
  $:.unshift File.expand_path('../src/',File.dirname(__FILE__))
end

require "test/unit"

require 'sc_memory'

class ScMemoryTest < Test::Unit::TestCase

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    # Do nothing
    @mem = Sc::ScMemory.instance
  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.
  def teardown
    @mem.mem_clear
  end

  def test_add_elements
    n1 = @mem.create_el(:sc_node, :sc_const)[0]
    n2 = @mem.create_el(:sc_node, :sc_const)[0]
    a1 = @mem.gen3_f_a_f(n1, [:sc_arc, :sc_const], n2)[0]

  end
end