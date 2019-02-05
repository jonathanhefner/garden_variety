module GardenVariety
  # @!visibility private
  module TalentScout

    module ModelSearchClassOverride
      def model_search_class
        @model_search_class ||= "#{model_class}Search".constantize
      end
    end

    ::TalentScout::Controller::ClassMethods.prepend(ModelSearchClassOverride)

    module FindCollectionOverride
      private
      def find_collection
        if self.class.model_search_class?
          @search = model_search
          @search.results.all
        else
          super
        end
      end
    end

    ::GardenVariety::Controller.prepend(FindCollectionOverride)

  end
end
