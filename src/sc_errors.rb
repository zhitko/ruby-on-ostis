# -*- coding: utf-8 -*-

$:.unshift(File.dirname(__FILE__)) unless $:.include? File.dirname(__FILE__)

class ScMemoryException < RuntimeError
  def message; "Sc memory Exception" end
end

class IncompatibleScTypes < ScMemoryException
  def initialize element, type
    @element, @type = element, type
    super()
  end
  def message; "Incompatible sc-types (#@element) for element (#@type)" end
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