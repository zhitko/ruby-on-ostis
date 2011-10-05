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
    assert_not_nil(n1 = @mem.create_el(:sc_node, :sc_const)[0])
    assert_not_nil(n2 = @mem.create_el(:sc_node, :sc_const)[0])
    assert_not_nil(a1 = @mem.gen3_f_a_f(n1, [:sc_arc, :sc_const], n2)[0])
  end

  def test_functional_style_programming
    #assert_instance_of(Sc::MemResults,@mem.create_el(:sc_node, :sc_const))
  end

  def test_3_f_a_f
    r = @mem.gen3_f_a_f(n1, ta, n2)
  end

  def test_3_f_a_a
    r = @mem.gen3_f_a_a(n1, ta, tn)
  end

  def test_3_a_a_f
    r = @mem.gen3_a_a_f(tn, ta, n2)
  end

  def test_5_a_a_a_a_a
    r = @mem.gen5_a_a_a_a_a(tn,ta,tn,ta,tn)
  end

  def test_5_f_a_a_a_a
    r = @mem.gen5_f_a_a_a_a(n1,ta,tn,ta,tn)
  end

  def test_5_a_a_f_a_a
    r = @mem.gen5_a_a_f_a_a(tn,ta,n2,ta,tn)
  end

  def gen5_f_a_f_a_a
    r = @mem.gen5_f_a_f_a_a(n1,ta,n2,ta,tn)
  end

  def test_5_a_a_a_a_f
    r = @mem.gen5_a_a_a_a_f(tn,ta,tn,ta,n3)
  end

  def test_5_f_a_a_a_f
    r = @mem.gen5_f_a_a_a_f(n1,ta,tn,ta,n3)
  end

  def test_5_a_a_f_a_f
    r = @mem.gen5_a_a_f_a_f(tn,ta,n2,ta,n3)
  end

  def test_5_f_a_f_a_f
    r = @mem.gen5_f_a_f_a_f(n1,ta,n2,ta,n3)
  end
end