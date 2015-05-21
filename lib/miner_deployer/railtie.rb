require 'miner_deployer'
require 'rails'
module MinerDeployer
  class Railtie < Rails::Railtie
    railtie_name :miner_deployer

    rake_tasks do
      load "tasks/deploy.rake"
    end
  end
end
