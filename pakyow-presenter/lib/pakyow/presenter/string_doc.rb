# frozen_string_literal: true

require "pakyow/support/silenceable"

module Pakyow
  module Presenter
    # String-based XML document optimized for fast manipulation and rendering.
    #
    # In Pakyow, we rarely care about every node in a document. Instead, only significant nodes and
    # immediate children are available for manipulation. StringDoc provides "just enough" for our
    # purposes. A StringDoc is represented as a multi- dimensional array of strings, making
    # rendering essentially a +flatten.join+.
    #
    # Because less work is performed during render, StringDoc is consistently faster than rendering
    # a document using Nokigiri or Oga. One obvious tradeoff is that parsing is much slower (we use
    # Oga to parse the XML, then convert it into a StringDoc). This is an acceptable tradeoff
    # because we only pay the parsing cost once (when the Pakyow application boots).
    #
    # All that to say, StringDoc is a tool that is very specialized to Pakyow's use-case. Use it
    # only when a longer parse time is acceptable and you only care about a handful of identifiable
    # nodes in a document.
    #
    class StringDoc
      class << self
        # Registers a significant node with a name and an object to handle parsing.
        #
        def significant(name, object)
          significant_types[name] = object
        end

        # Creates a +StringDoc+ from an array of +StringNode+ objects.
        #
        def from_nodes(nodes)
          allocate.tap do |instance|
            instance.instance_variable_set(:@nodes, nodes)

            nodes.each do |node|
              node.parent = instance
            end
          end
        end

        # Yields nodes from an oga document, breadth-first.
        #
        def breadth_first(doc)
          queue = [doc]

          until queue.empty?
            element = queue.shift

            if element == doc
              queue.concat(element.children.to_a); next
            end

            yield element
          end
        end

        # Returns attributes for an oga element.
        #
        def attributes(element)
          if element.is_a?(Oga::XML::Element)
            element.attributes
          else
            []
          end
        end

        # Builds a string-based representation of attributes for an oga element.
        #
        def attributes_string(element)
          attributes(element).each_with_object(String.new) do |attribute, string|
            string << " #{attribute.name}=\"#{attribute.value}\""
          end
        end

        # Returns the significant object builder for the provided Oga element.
        #
        def significant_builder(element)
          significant_types.values.each do |object|
            return object if object.significant?(element)
          end

          false
        end

        # Returns true if the given Oga element contains a child node that is significant.
        #
        def contains_significant_child?(element)
          element.children.each do |child|
            return true if significant_builder(child)
            return true if contains_significant_child?(child)
          end

          false
        end

        # @api private
        def significant_types
          @significant_types ||= {}
        end

        # @api private
        def nodes_from_doc_or_string(doc_node_or_string)
          if doc_node_or_string.is_a?(StringDoc)
            doc_node_or_string.nodes
          elsif doc_node_or_string.is_a?(StringNode)
            [doc_node_or_string]
          else
            StringDoc.new(doc_node_or_string.to_s).nodes
          end
        end
      end

      include Support::Silenceable

      # Array of +StringNode+ objects.
      #
      attr_reader :nodes

      # Creates a +StringDoc+ from an html string.
      #
      def initialize(html)
        @nodes = parse(Oga.parse_html(html))
      end

      # @api private
      def initialize_copy(_)
        super

        @nodes = @nodes.map { |node|
          node.dup.tap do |duped_node|
            duped_node.parent = self
          end
        }
      end

      # Returns nodes matching the significant type.
      #
      # If +with_children+ is true, significant nodes from child nodes will be included.
      #
      def find_significant_nodes(type, with_children: true)
        significant_nodes = if with_children
          @nodes.map(&:with_children).flatten
        else
          @nodes.dup
        end

        significant_nodes.select { |node|
          node.type == type
        }
      end

      # Returns nodes matching the significant type and name.
      #
      # @see find_significant_nodes
      #
      def find_significant_nodes_with_name(type, name, with_children: true)
        find_significant_nodes(type, with_children: with_children).select { |node|
          node.name == name
        }
      end

      # Clears all nodes.
      #
      def clear
        tap do
          @nodes.clear
        end
      end

      # Replaces the current document.
      #
      # Accepts a +StringDoc+ or XML +String+.
      #
      def replace(doc_or_string)
        tap do
          @nodes = self.class.nodes_from_doc_or_string(doc_or_string)
        end
      end

      # Appends to this document.
      #
      # Accepts a +StringDoc+ or XML +String+.
      #
      def append(doc_or_string)
        tap do
          @nodes.concat(self.class.nodes_from_doc_or_string(doc_or_string))
        end
      end

      # Prepends to this document.
      #
      # Accepts a +StringDoc+ or XML +String+.
      #
      def prepend(doc_or_string)
        tap do
          @nodes.unshift(*self.class.nodes_from_doc_or_string(doc_or_string))
        end
      end

      # Inserts a node after another node contained in this document.
      #
      def insert_after(node_to_insert, after_node)
        tap do
          if after_node_index = @nodes.index(after_node)
            @nodes.insert(after_node_index + 1, *self.class.nodes_from_doc_or_string(node_to_insert))
          end
        end
      end

      # Inserts a node before another node contained in this document.
      #
      def insert_before(node_to_insert, before_node)
        tap do
          if before_node_index = @nodes.index(before_node)
            @nodes.insert(before_node_index, *self.class.nodes_from_doc_or_string(node_to_insert))
          end
        end
      end

      # Removes a node from the document.
      #
      def remove_node(node_to_delete)
        tap do
          @nodes.delete_if { |node|
            node.object_id == node_to_delete.object_id
          }
        end
      end

      # Replaces a node from the document.
      #
      def replace_node(node_to_replace, replacement_node)
        tap do
          if replace_node_index = @nodes.index(node_to_replace)
            nodes_to_insert = self.class.nodes_from_doc_or_string(replacement_node).map { |node|
              node.instance_variable_set(:@parent, self); node
            }
            @nodes.insert(replace_node_index + 1, *nodes_to_insert)
            @nodes.delete_at(replace_node_index)
          end
        end
      end

      # Converts the document to an xml string.
      #
      def to_xml
        render
      end
      alias :to_html :to_xml
      alias :to_s :to_xml

      def ==(other)
        other.is_a?(StringDoc) && @nodes == other.nodes
      end

      # @api private
      def string_nodes
        @nodes.map(&:string_nodes)
      end

      private

      def render
        # @nodes.flatten.reject(&:empty?).map(&:to_s).join

        # we save several (hundreds) of calls to `flatten` by pulling in each node and dealing with
        # them together instead of calling `to_s` on each
        arr = string_nodes
        arr.flatten!
        arr.compact!
        arr.map!(&:to_s)
        arr.join
      end

      # Parses an Oga document into an array of +StringNode+ objects.
      #
      def parse(doc)
        nodes = []

        unless doc.is_a?(Oga::XML::Element) || !doc.respond_to?(:doctype) || doc.doctype.nil?
          nodes << StringNode.new(["<!DOCTYPE html>", StringAttributes.new, []])
        end

        self.class.breadth_first(doc) do |element|
          significant_object = self.class.significant_builder(element)

          unless significant_object || self.class.contains_significant_child?(element)
            # Nothing inside of the node is significant, so collapse it to a single node.
            nodes << StringNode.new([element.to_xml, StringAttributes.new, []]); next
          end

          node = if significant_object
            build_significant_node(element, significant_object)
          elsif element.is_a?(Oga::XML::Text) || element.is_a?(Oga::XML::Comment)
            StringNode.new([element.to_xml, StringAttributes.new, []])
          else
            StringNode.new(["<#{element.name}#{self.class.attributes_string(element)}", ""])
          end

          if element.is_a?(Oga::XML::Element)
            node.close(element.name, parse(element))
          end

          nodes << node
        end

        nodes
      end

      def build_significant_node(element, object)
        node = object.node(element)
        node.parent = self
        node
      end
    end
  end
end
