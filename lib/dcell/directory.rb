module DCell
  # Directory of nodes connected to the DCell cluster
  module Directory
    extend self

    # Get the URL for a particular Node ID
    def get(node_id)
      DCell.registry.get_node node_id
    end
    alias_method :[], :get

    # Set the address of a particular Node ID
    def set(node_id, addr)
      DCell.registry.set_node node_id, addr
    end
    alias_method :[]=, :set

    # List all of the node IDs in the directory
    def all
      DCell.registry.nodes
    end

    def clear_all
      DCell.registry.clear_all_nodes
    end

    def remove(node)
      DCell.registry.remove_node node
    end
  end
end
