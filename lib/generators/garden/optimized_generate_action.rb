# @!visibility private
module Garden
  module OptimizedGenerateAction
    def generate(what, *args)
      log :generate, what

      in_root do
        silence_warnings do
          ::Rails::Command.invoke("generate", [what, *args])
        end
      end
    end
  end
end
