# encoding: utf-8

require 'rubygems'
require 'rake'
require 'tempfile'
require 'rake/clean'
require 'scss_lint/rake_task'
require 'w3c_validators'
require 'nokogiri'
require 'rubocop/rake_task'
require 'English'
require 'net/http'
require 'html-proofer'

task default: [
  :clean,
  :build,
  :pages,
  :garbage,
  :snippets,
#  :orphans,
#  :jslint,
#  :proofer,
#  :rubocop,
#  :scss_lint,
  :spell,
  :regex,
  :excerpts,
  :ping
]

def done(msg)
  puts msg + "\n\n"
end

def all_html()
  Dir['_site/**/*.html'].reject{ |f| f.end_with? '.amp.html' }
end

def all_links()
  all_html().reduce([]) do |array, f|
    array + Nokogiri::HTML(File.read(f)).xpath(
      '//article//a/@href'
    ).to_a.map(&:to_s)
  end.sort.map{ |a| a.gsub(/^\//, 'https://www.auraImmigration.com/') }
end

desc 'Delete _site directory'
task :clean do
  rm_rf '_site'
  done 'Jekyll site directory deleted'
end

desc 'Lint SASS sources'
SCSSLint::RakeTask.new do |t|
  f = Tempfile.new(['auraImmigration-', '.scss'])
  f << File.open('css/layout.scss').drop(2).join("\n")
  f.flush
  f.close
  t.files = Dir.glob([f.path])
end

desc 'Build Jekyll site'
task :build do
  if File.exist? '_site'
    done 'Jekyll site already exists in _site (run "rake clean" first)'
  else
    system('jekyll build')
    fail 'Jekyll failed' unless $CHILD_STATUS.success?
    done 'Jekyll site generated without issues'
  end
end

desc 'Check the existence of all critical pages'
task pages: [:build] do
  File.open('_rake/pages.txt').map(&:strip).each do |p|
    file = "_site/#{p}"
    fail "Page #{file} is not found" unless File.exist? file
    puts "#{file}: OK"
  end
  done 'All files are in place'
end

desc 'Check the absence of garbage'
task garbage: [:build] do
  File.open('_rake/garbage.txt').map(&:strip).each do |p|
    file = "_site/#{p}"
    fail "Page #{file} is still there" if File.exist? file
    puts "#{file}: absent, OK"
  end
  done 'There is no garbage'
end

desc 'Validate a few pages for W3C compliance'
# It doesn't work now, because of: https://github.com/alexdunae/w3c_validators/issues/16
task w3c: [:build] do
  include W3CValidators
  validator = MarkupValidator.new
  [
    'index.html',
    '2014/04/06/introduction.html'
  ].each do |p|
    file = "_site/#{p}"
    results = validator.validate_file(file)
    if results.errors.length > 0
      results.errors.each do |err|
        puts err.to_s
      end
      fail "Page #{file} is not W3C compliant"
    end
    puts "#{p}: OK"
  end
  done 'HTML is W3C compliant'
end

desc 'Validate a few pages through HTML proofer'
task proofer: [:build] do
  HTMLProofer.check_directory(
    '_site',
    log_level: :warn,
    check_favicon: true,
    check_html: true,
    file_ignore: [/201[4-6].*/]
  ).run
  done 'HTML passed through html-proofer'
end

desc 'Check spelling in all HTML pages'
task spell: [:build] do
  typos = all_html().reduce(0) do |total, f|
    html = Nokogiri::HTML(File.read(f))
    html.search('//code').remove
    html.search('//script').remove
    html.search('//pre').remove
    html.search('//header').remove
    html.search('//footer').remove
    tmp = Tempfile.new(['auraImmigration-', '.txt'])
    text = html.xpath('//article//p|//article//h2|//article//h3').to_a.join(' ')
      .gsub(/[\n\r\t ]+/, ' ')
      .gsub(/&[a-z]+;/, ' ')
      .gsub(/&#[0-9]+;/, ' ')
      .gsub(/n't/, ' not')
      .gsub(/'ll/, ' will')
      .gsub(/'ve/, ' have')
      .gsub(/'s/, ' ')
      .gsub(/[,:;<>?!-#$%^&@]+/, ' ')
    tmp << text
    tmp.flush
    tmp.close
    stdout = `cat "#{tmp.path}" \
      | aspell -a --lang=en_US -W 3 --ignore-case --encoding=utf-8 -p ./_rake/aspell.en.pws \
      | grep ^\\&`
    if stdout.empty?
      puts "#{f}: OK (#{text.split(' ').size} words)"
    else
      puts "Typos in #{f}:"
      puts stdout
    end
    total + stdout.split("\n").size
  end
  fail "#{typos.size} typo(s)" unless typos == 0
  done 'No spelling errors'
end

desc 'Ping all foreign links'
task ping: [:build] do
  links = all_links().uniq
    .reject{ |a| a.start_with? 'https://www.auraImmigration.com/' }
    .reject{ |a| a.include? 'linkedin.com' }
    .reject{ |a| !(a =~ /^https?:\/\/.*/) }
  tmp = Tempfile.new(['auraImmigration-', '.txt'])
  tmp << links.join("\n")
  tmp.flush
  tmp.close
  out = Tempfile.new(['auraImmigration-', '.txt'])
  out.close
  puts "#{links.size} links found, testing them..."
  system("./_rake/ping.sh #{tmp.path} #{out.path}")
  errors = File.read(out).split("\n").reduce(0) do |cnt, p|
    code, link = p.split(' ')
    next if link.nil?
    if code != '200'
      puts "#{link}: #{code}"
      cnt + 1
    else
      cnt
    end
  end
  fail "#{errors} broken link(s)" unless errors < 20
  done "#{links.size} links are valid, #{errors} are broken"
end

desc 'Run RuboCop on all Ruby files'
RuboCop::RakeTask.new do |t|
  t.fail_on_error = true
  t.requires << 'rubocop-rspec'
end

desc 'Test all JavaScript files with JSLint'
task :jslint do
  Dir['js/**/*.js'].each do |f|
    stdout = `jslint #{f}`
    fail "jslint failed at #{f}:\n#{stdout}" unless $CHILD_STATUS.success?
  end
  done 'JSLint says JavaScript files are clean'
end

desc 'Make sure all pages have excerpts'
task :excerpts do
  Dir['_posts/**/*.md'].each do |f|
    fail "No excerpt in #{f}" unless File.read(f).include? '<!--more-->'
  end
  done 'All articles have excerpts'
end

desc 'Make sure there are no prohibited RegEx-es'
task :regex do
  ptns = [
    /\s&mdash;/,
    /&mdash;\s/
  ]
  all_html().each do |f|
    html = File.read(f)
    ptns.each do |re|
      fail "#{f}: #{re}" if re.match html
    end
  end
  done 'Not prohibited regular expressions'
end
desc 'Make sure all snippets are compact enough'
task :snippets do
  all_html().each do |f|
    lines = Nokogiri::HTML(File.read(f)).xpath(
      '//article//figure[@class="highlight"]/pre/code[not(contains(@class,"text"))]'
    ).to_a.map(&:to_s)
      .join("\n")
      .gsub(/<code [^>]+>/, '')
      .gsub(/<span class="[A-Za-z0-9-]+">/, '')
      .gsub(/<\/code>/, "\n")
      .gsub(/<\/span>/, '')
      .gsub(/&lt;/, '<')
      .gsub(/&gt;/, '>')
      .split("\n")
    long = lines.reject{ |s| s.length < 81 }
    fail "Too wide snippet in #{f}: #{long}" unless long.empty?
    puts "#{f}: OK (#{lines.size} lines)"
  end
  done 'All snippets are compact enough'
end

desc 'Make sure there are no orphan articles'
task orphans: [:build] do
  links = all_links()
    .reject{ |a| !a.start_with? 'https://www.auraImmigration.com/' }
    .map{ |a| a.gsub(/#.*/, '') }
  links += all_html().map { |f| f.gsub(/_site/, 'https://www.auraImmigration.com') }
  counts = {}
  links
    .reject{ |a| !a.match /.*\/[0-9]{4}\/[0-9]{2}\/[0-9]{2}\/.*/ }
    .reject{ |a| a.end_with? '.amp.html' }
    .group_by(&:itself).each { |k,v| counts[k] = v.length }
  orphans = 0
  counts.each do |k,v|
    if v < 4
      puts "#{k} is an orphan (#{v})"
      orphans += 1
    else
      puts "#{k}: #{v}"
    end
  end
  fail "There are #{orphans} orphans" unless orphans == 0
  done "There are no orphans in #{links.size} links"
end

desc 'Publishing application on aws'
task :deploy do
  system "bundle exec s3_website push"
end

desc 'Server _site on localhost'
task :serve do
  system "http-server _site/"
end

