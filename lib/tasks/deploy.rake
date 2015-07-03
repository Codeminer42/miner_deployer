# Based on https://gist.github.com/fgrehm/4253885
# which is a fork of https://gist.github.com/njvitto/362873

namespace :deploy do
  def heroku_cmd(cmd)
    Bundler.with_clean_env do
      sh "heroku #{cmd}"
    end
  end

  def red(str); "\033[31m#{str}\033[0m" end
  def green(str); "\033[32m#{str}\033[0m" end

  def after_error(e)
    Rake::Task['deploy:on'].invoke if defined?(MAINTENANCE)
    raise(e)
  end

  task :rollback, [:env] => [:check, :config, :off, :push_previous, :restart, :on]

  task :config, [:env] do |t, args|
    args.with_defaults(env: 'staging')

    config = YAML.load_file(Rails.root.join('config', 'deploy.yml'))[args.env]
    APP = config['app']
    URL = config['url']
    BRANCH = config['branch']
    REMOTE = config['remote']
    GIT_OPTS = config['git_opts']
    CHECK = config['check'] || {}
    CHECK_SELECTOR = CHECK['selector']
    CHECK_TEXT = CHECK['text']
  end

  task :check do
    at_exit do
      begin
        puts 'Let\'s try the system...'
        sleep 5
        page = open URL
        doc = Nokogiri::HTML page
        if CHECK_SELECTOR && doc.at(CHECK_SELECTOR).text.downcase == CHECK_TEXT
          puts green('System is ONLINE now! 🍺 👌')
        elsif page.status.first.to_i
          puts green('System is ONLINE now (or just respond 200)! 🍺 👌')
        else
          puts red('PROBLEMS! System is on, but something is wrong!!! 😭 😭 😭 ')
        end
      rescue OpenURI::HTTPError
        puts red('PROBLEMS! System is down!!! 😭 😭 😭 😭 😭')
      end
    end
  end

  task :push do
    begin
      puts 'Deploying site to Heroku ...'
      sh "git push #{GIT_OPTS} #{REMOTE}:#{APP}.git #{BRANCH}:master"
    rescue => e
      after_error(e)
    end
  end

  task :restart do
    begin
      puts 'Restarting app servers ...'
      heroku_cmd "restart --app #{APP}"
    rescue => e
      after_error(e)
    end
  end

  task :migrate do
    begin
      puts 'Running database migrations ...'
      heroku_cmd "run rake db:migrate --app #{APP}"
    rescue EOFError => e
      puts "Oh, no! we have a problem with migratons... 😭 😭 😭  But..."
      puts "Running database migrations #{green 'AGAIN!'} (last chance)..."
      heroku_cmd "run rake db:migrate --app #{APP}"
    end
  end

  task :tag do
    release_name = "#{APP}_release-#{Time.now.utc.strftime("%Y%m%d%H%M%S")}"
    puts "Tagging release as '#{release_name}'"
    sh "git tag -a #{release_name} -m 'Tagged release'"
    sh "git push origin --tags"
    sh "git push --tags -f #{REMOTE}:#{APP}.git"
  end

  task :off do
    heroku_cmd "maintenance:on --app #{APP}"
    puts red('Putting the app into maintenance mode ...')
    MAINTENANCE = true
  end

  task :on do
    heroku_cmd "maintenance:off --app #{APP}"
    puts green('Taking the app out of maintenance mode ...')
  end

  task :push_previous do
    prefix = "#{APP}_release-"
    releases = `git tag`.split("\n").select { |t| t[0..prefix.length-1] == prefix }.sort
    current_release = releases.last
    previous_release = releases[-2] if releases.length >= 2
    if previous_release
      puts "Rolling back to '#{previous_release}' ..."

      puts "Checking out '#{previous_release}' in a new branch on local git repo ..."
      sh "git checkout #{previous_release}"
      sh "git checkout -b #{previous_release}"

      puts "Removing tagged version '#{previous_release}' (now transformed in branch) ..."
      sh "git tag -d #{previous_release}"
      sh "git push #{REMOTE}:#{APP}.git :refs/tags/#{previous_release}"

      puts "Pushing '#{previous_release}' to Heroku master ..."
      sh "git push #{REMOTE}:#{APP}.git +#{previous_release}:master --force"

      puts "Deleting rollbacked release '#{current_release}' ..."
      sh "git tag -d #{current_release}"
      sh "git push #{REMOTE}:#{APP}.git :refs/tags/#{current_release}"

      puts "Retagging release '#{previous_release}' in case to repeat this process (other rollbacks)..."
      sh "git tag -a #{previous_release} -m 'Tagged release'"
      sh "git push --tags #{REMOTE}:#{APP}.git"

      puts "Turning local repo checked out on master ..."
      sh "git checkout master"
      puts 'All done!'
    else
      puts "No release tags found - can't roll back!"
      puts releases
    end
  end
end

desc 'Deploy Application to heroku'
task :deploy, [:env] => [
  'deploy:check',
  'deploy:config',
  'deploy:off',
  'deploy:push',
  'deploy:migrate',
  'deploy:restart',
  'deploy:on',
  'deploy:tag'
]
