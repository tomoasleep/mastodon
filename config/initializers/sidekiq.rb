host = ENV.fetch('REDIS_HOST') { 'localhost' }
port = ENV.fetch('REDIS_PORT') { 6379 }
password = ENV.fetch('REDIS_PASSWORD') { false }
db = ENV.fetch('REDIS_DB') { 0 }

Sidekiq.configure_server do |config|
  config.redis = { host: host, port: port, db: db, password: password }
  
  if Rails.env.production?
    require 'ddtrace/contrib/sidekiq/tracer'

    name_base = ENV['DATADOG_SERVICE_NAME_BASE'] || 'qiitadon'
    config.server_middleware do |chain|
      chain.add(
        Datadog::Contrib::Sidekiq::Tracer,
        sidekiq_service: "#{name_base}-sidekiq",
      )
    end
  end
end

Sidekiq.configure_client do |config|
  config.redis = { host: host, port: port, db: db, password: password }
end
