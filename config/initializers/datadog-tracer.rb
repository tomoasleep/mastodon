name_base = ENV['DATADOG_SERVICE_NAME_BASE'] || 'qiitadon'

Rails.configuration.datadog_trace = {
  enabled: Rails.env.production?,
  auto_instrument: true,
  auto_instrument_redis: true,
  default_service: "#{name_base}-rails",
  default_database_service: "#{name_base}-postgres",
  default_cache_service: "#{name_base}-cache",
  default_controller_service: "#{name_base}-controller",
}

Datadog::Monkey.patch_module(:redis) if Rails.env.production?
