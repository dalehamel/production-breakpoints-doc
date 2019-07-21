# frozen_string_literal: true

require 'rake/testtask'

DOCKER_DIR = 'docker'
SPELLFILE = '~/.dotfiles/vim/spell/en.utf-8.add'

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.test_files = FileList['test/**/*_test.rb'].exclude
  t.verbose = true
end

namespace :report do
  desc 'Create doc to publish'
  task :init do
    puts `mkdir -p docs output .bin`
    puts `ln -sf ../img output/img`
    puts `[ ! -f .bin/pandoc ] && wget https://github.com/jgm/pandoc/releases/download/2.7.2/pandoc-2.7.2-linux.tar.gz && tar -xvpf pandoc-2.7.2-linux.tar.gz && mv pandoc-2.7.2/bin/pandoc .bin/ && mv pandoc-2.7.2/bin/pandoc-citeproc .bin/ && rm -rf pandoc-2.7.2 && rm -f *.tar.gz*`
    puts `[ ! -f .bin/pandoc-include-code ] && wget https://github.com/owickstrom/pandoc-include-code/releases/download/v1.2.0.2/pandoc-include-code-linux-ghc8-pandoc-1-19.tar.gz && tar -xvpf pandoc-include-code-linux-ghc8-pandoc-1-19.tar.gz && mv ./pandoc-include-code .bin/ && rm -f *.tar.gz*`
    puts `bundle install`
  end

  desc 'Spellcheck this document against a custom word list'
  task :spellcheck do
    path = File.expand_path(SPELLFILE)
    FileUtils.copy(path, '.spelling_ignore') if File.exists?(path)
    errs = `bundle exec mdspell docs/* --ignored "$(ruby -e "STDOUT.print File.read(File.expand_path('.spelling_ignore')).lines.map { |l| l.strip }.join(',')")"`

    if !errs.empty?
      puts "There were spelling errors"
      puts errs
      exit 1
    end
  end

  desc 'Publish the documents with pandoc'
  task :publish => :init do
    %w[html pdf epub].each do |doctype|
      puts `.bin/pandoc docs/*.md --toc \
            --top-level-division=chapter \
            --metadata date="$( date +'%D %X %Z')" \
            --metadata link-citations=true \
            --bibliography=bibliography.yaml \
            --csl ieee-with-url.csl \
            #{"--template=./templates/GitHub.html5" if doctype == "html"} \
            --filter .bin/pandoc-citeproc \
            --filter .bin/pandoc-include-code -s --highlight-style espresso \
            -o output/doc.#{doctype}`
    end
  end
end

namespace :docker do
  desc 'Build the development image'
  task :build do
    system("docker build -t quay.io/dalehamel/usdt-report-doc .")
  end

  desc 'Run the development image'
  task :run do
    system("docker run -v $(pwd):/app --name usdt-report-doc -d quay.io/dalehamel/usdt-report-doc /bin/sh -c 'sleep infinity'")
  end

  desc 'push the development image to quay'
  task :push do
    system("docker push quay.io/dalehamel/usdt-report-doc")
  end

  desc 'pull the development image to quay'
  task :pull do
    system("docker push quay.io/dalehamel/usdt-report-doc")
  end

  desc 'Build target publications'
  task :publish do
    system("docker exec usdt-report-doc ./scripts/build.sh #{"CI" if ENV['CI']}")
  end

  desc 'Run tests inside docker'
  task :test do
    command = "docker exec #{"-e CI=true" if ENV['CI']} usdt-report-doc  ./scripts/spellcheck.sh #{"CI" if ENV['CI']}"
    puts command
    exit system(command)
  end

  desc 'Cleanup development image'
  task :clean do
    system("docker container ls --quiet --filter name=usdt-report-doc* | xargs -I@ docker container rm --force @")
  end

  desc 'Debug shell for docker container'
  task :shell do
    system("docker exec -ti #{latest_running_container_id} bash")
  end

  def latest_running_container_id
    container_id = `docker container ls --latest --quiet --filter status=running --filter name=usdt-report-doc*`.strip
    if container_id.empty?
      raise "No containers running, please run rake docker:run and then retry this task"
    else
      container_id
    end
  end

end

task :rubocop do
  system("bundle exec rubocop --auto-correct */**.rb")
end
