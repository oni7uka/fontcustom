require "json"
require "open3"

module Fontcustom
  module Generator
    class Font
      include Utility

      attr_reader :manifest

      def initialize(manifest,glyphs = {})
        @glyphs = glyphs
        @manifest = Fontcustom::Manifest.new manifest
        @options = @manifest.get :options
      end

      def generate
        create_output_dirs
        delete_old_fonts
        set_glyph_info
        create_fonts
      end

      private

      def create_output_dirs
        dirs = @options[:output].values.uniq
        dirs.each do |dir|
          unless File.directory? dir
            empty_directory dir, :verbose => false
            say_message :create, dir
          end
        end
      end

      def delete_old_fonts
        @manifest.delete :fonts
      end

      def set_glyph_info
        @manifest.set :glyphs, @glyphs
      end

      def create_fonts
        cmd = "fontforge -script #{Fontcustom.gem_lib}/scripts/generate.py #{@manifest.manifest}"
        stdout, stderr, status = Open3::capture3(cmd)
        stdout = stdout.split("\n")
        stdout = stdout[1..-1] if stdout[0] == "CreateAllPyModules()"

        debug_msg = " Try again with --debug for more details."
        if @options[:debug]
          messages = stderr.split("\n") + stdout
          say_message :debug, messages.join(line_break)
          debug_msg = ""
        end

        if status.success?
          @manifest.reload
          say_changed :create, @manifest.get(:fonts)
        else
          raise Fontcustom::Error, "`fontforge` compilation failed.#{debug_msg}"
        end
      end
    end
  end
end
