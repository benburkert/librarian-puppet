require 'librarian/source/git'
require 'librarian/puppet/source/local'

module Librarian
  module Source
    class Git
      class Repository
        def hash_from(remote, reference)
          branch_names = remote_branch_names[remote]
          if branch_names.include?(reference)
            reference = "#{remote}/#{reference}"
          end

          command = %W(rev-parse #{reference}^{commit} --quiet)
          run!(command, :chdir => true).strip
        end
      end
    end
  end

  module Puppet
    module Source
      class Git < Librarian::Source::Git
        include Local

        def cache!
          return vendor_checkout! if vendor_cached?

          if environment.local?
            raise Error, "Could not find a local copy of #{uri} at #{sha}."
          end

          super

          cache_in_vendor(repository.path) if environment.vendor?
        end

        def vendor_tgz
          environment.vendor_source + "#{sha}.tar.gz"
        end

        def vendor_cached?
          vendor_tgz.exist?
        end

        def vendor_checkout!
          repository.path.rmtree if repository.path.exist?
          repository.path.mkpath

          Dir.chdir(repository.path.to_s) do
            %x{tar xzf #{vendor_tgz}}
          end

          repository_cached!
        end

        def cache_in_vendor(tmp_path)
          Dir.chdir(tmp_path.to_s) do
            %x{git archive #{sha} | gzip > #{vendor_tgz}}
          end
        end

      end
    end
  end
end
