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
require "sc_elements"

class ScElementsTest < Test::Unit::TestCase

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    # Do nothing
  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.
  def teardown
    # Do nothing
  end

  def test_create_elements
    assert_not_nil(n1 = Sc::ScElement.new(),"Failed on create simple element")
    assert_not_nil(n2 = Sc::ScNode.new(:sc_group,:SC_CONST),"Failed on create node")
    assert_not_nil(Sc::ScArc.new(n1, n2, :sc_group,:SC_CONST),"Failed on create arc")
  end

  def test_create_uniq_keynodes
    n1 = Sc::ScNode.new '/test/node1', :sc_const
    assert_instance_of(Sc::ScNode,Sc::ScElement.new('/test/node1'),"Failed on type keynode check")
    assert_equal(n1, Sc::ScNode.new('/test/node1',:sc_node),"Failed on get existing keynode")
  end

  def test_content
    n1 = Sc::ScElement.new()
    n2 = Sc::ScElement.new()
    c1 = Object.new
    c2 = "Test content"
    n1.content = c1
    n2.set_content c2
    assert_not_nil(n1.content,"Content not created for unknown object")
    assert_not_nil(n2.content,"Content not created for known object")
    assert_equal(n2.content.data,c2,"Content data not equal")
    assert_instance_of(String, n1.content.data,"Content type wrong for unknown object")
    assert_instance_of(c2.class, n2.content.data,"Content type wrong for known object")
    assert_equal(n1.content.type, :sc_text, "Content sc-type wrong for unknown object")
    assert_equal(n2.content.type, :sc_text, "Content sc-type wrong for known object")
  end
end