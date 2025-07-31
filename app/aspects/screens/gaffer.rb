# frozen_string_literal: true

require "dry/monads"
require "initable"

module Terminus
  module Aspects
    module Screens
      # Creates error with problem details for device.
      # :reek:DataClump
      class Gaffer
        include Deps[
          "aspects.screens.creator",
          "aspects.screens.creators.temp_path",
          repository: "repositories.screen",
          view: "views.gaffe.new"
        ]
        include Initable[payload: Creators::Payload]
        include Dry::Monads[:result]

        def call device, problem
          repository.find_by(name: device.system_name("error"))
                    .then do |screen|
                      screen ? update(screen, device, problem) : create(device, problem)
                    end
        end

        def create device, problem
          creator.call content: String.new(view.call(problem:)),
                       **device.system_screen_attributes("error")
        end

        def update screen, device, problem
          temp_path.call build_payload(device, problem) do |path|
            screen.upload StringIO.new(path.read), metadata: {"filename" => path.basename}

            Success repository.update(
              screen.id,
              label: device.system_label("Error"),
              image_data: screen.image_attributes
            )
          end
        end

        # :reek:FeatureEnvy
        def build_payload device, problem
          payload[
            model: device.model,
            label: device.system_label("Error"),
            name: device.system_name("error"),
            content: String.new(view.call(problem:))
          ]
        end
      end
    end
  end
end
