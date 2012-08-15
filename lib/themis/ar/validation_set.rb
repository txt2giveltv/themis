module Themis
  module AR

    # Used to store options about validation sets on every single ActiveRecord model class.
    class ValidationSet < Struct.new(:name, :module, :default, :nested, :block)
      # Redefine `new` to initialize structure with hash
      def initialize(hash)
        members = self.class.members.map!(&:to_sym)
        super(*hash.values_at(*members))
      end
    end

  end  # module AR
end  # module Themis
